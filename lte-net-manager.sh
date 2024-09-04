#!/bin/bash
### BEGIN INIT INFO
# Provides:          lte-network-manager
# Required-Start:    network-online.target
# Required-Stop:     network.target
# Should-Start:      syslog.service
# Should-Stop:       syslog.service
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: LTE Network Manager for handling LTE connections
# Description:       This script manages LTE network connections using the
#                    qmi-network tool. It starts and stops the network service,
#                    configures IP settings, and optionally applies iptables rules
#                    for network address translation (NAT) and forwarding. Designed
#                    for use with Raspberry Pi and similar devices. 
#                    It supports options for debug mode and skipping iptables rules.
### END INIT INFO

DEVICE="/dev/cdc-wdm0"
PIDFILE='/tmp/lte-network.pid'
LOGFILE="/var/log/lte-network.log"
DEBUG_MODE=false  # Variable to control debug mode
NO_FWD=false      # Variable to control the --no-fwd option

# Function to display help
help() {
    echo "Usage: $0 {start|stop|debug|restart|--no-fwd|--help}"
    echo
    echo "Commands:"
    echo "  start          Start the LTE network connection."
    echo "  stop           Stop the LTE network connection."
    echo "  debug          Start the service in debug mode with verbose output."
    echo "  restart        Restart the LTE network connection."
    echo "  --no-fwd       Skip the application of iptables rules for forwarding."
    echo "  --help         Display this help message and exit."
    echo
    echo "Options:"
    echo "  --no-fwd       Skip setting up iptables rules for NAT and forwarding."
    echo "  debug          Enable debug mode for more detailed logs."
}

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root." >&2
  exit 1
fi

# Logging function with timestamp
log() {
    local message="$1"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    if [ "$DEBUG_MODE" = true ]; then
        echo "$timestamp - $message" | tee -a "$LOGFILE"
    else
        echo "$timestamp - $message"
    fi
}

start() {
    log "Starting LTE network connection..."
    
    # Clean up existing connections
    log "Cleaning up existing connections..."
    qmi-network "$DEVICE" stop 2>/dev/null

    # Bring down network interfaces if they exist
    [ -d /sys/class/net/wwan0 ] && ip link set wwan0 down
    [ -d /sys/class/net/wwan1 ] && ip link set wwan1 down  # Necessary for Sierra Wireless modems

    # Clean up previous state
    log "Removing previous state..."
    rm -f /tmp/qmi-network-state-cdc-wdm0

    # Check if the device exists
    if [ ! -e "$DEVICE" ]; then
        log "Error: Device $DEVICE does not exist." >&2
        exit 1
    fi

    # Start the network
    if qmi-network "$DEVICE" start; then
        log "Network started successfully."
    else
        log "Error starting the network." >&2
        rm -f "${PIDFILE}"  # Clean up PID file
        exit 1
    fi

    ip link set wwan0 up
    
    # IP configuration with retries
    local retry=0
    while [ $retry -lt 3 ]; do
        if timeout 30 udhcpc -i wwan0 &  # Start udhcpc in the background
        then
            sleep 2  # Wait for udhcpc to initialize
            
            # Get the PID of the udhcpc process for wwan0
            local UDHCP_PID
            UDHCP_PID=$(pgrep -f "udhcpc -i wwan0" | head -n 1)  # Take only the first PID

            if [ -n "$UDHCP_PID" ]; then
                echo $UDHCP_PID > "${PIDFILE}"  # Save PID to the PID file
                log "IP address obtained successfully. PID: $UDHCP_PID"
                break
            else
                log "Error: Unable to find the udhcpc process." >&2
                retry=$((retry+1))
            fi
        else
            log "Attempt $((retry+1)) failed to obtain IP address." >&2
            retry=$((retry+1))
        fi
    done

    if [ $retry -eq 3 ]; then
        log "Error obtaining IP address after 3 attempts." >&2
        rm -f "${PIDFILE}"  # Clean up PID file
        exit 1
    fi

    # Apply iptables rules if --no-fwd is not specified
    if [ "$NO_FWD" = true ]; then
        log "Skipping iptables rules application due to --no-fwd option."
    else
        log "Applying iptables rules..."
        iptables -t nat -A POSTROUTING -o wwan0 -j MASQUERADE
        iptables -A FORWARD -i eth0 -o wwan0 -j ACCEPT
        iptables -A FORWARD -i wwan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    fi
}

stop() {
    log "Stopping LTE network connection..."

    # Stop udhcpc process if PID file exists and process is running
    if [ -f "${PIDFILE}" ]; then
        local PID
        PID=$(cat "${PIDFILE}")
        if ps -p $PID > /dev/null; then
            kill "$PID"
            log "udhcpc process stopped."
        else
            log "PID file found, but udhcpc process is not running."
        fi
        rm -f "${PIDFILE}"  # Remove the PID file
    else
        log "No PID file found."
    fi

    # Ensure no other udhcpc processes are active for wwan0
    local UDHCP_PIDS
    UDHCP_PIDS=$(pgrep -f "udhcpc -i wwan0")
    if [ -n "$UDHCP_PIDS" ]; then
        log "Found additional udhcpc processes for wwan0, stopping..."
        kill $UDHCP_PIDS
        log "Additional udhcpc processes stopped."
    fi

    # Stop the network
    if qmi-network "$DEVICE" stop; then
        log "Network stopped successfully."
    else
        log "Error stopping the network." >&2
        exit 1
    fi

    ip link set wwan0 down
}

debug() {
    DEBUG_MODE=true  # Enable debug mode
    log "Running in debug mode..."
    # Verbose execution of start
    log "Running 'start' in verbose mode..."
    start
    log "Start operation completed."
}

restart() {
    stop
    log "Restarting..."
    start
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        --no-fwd)
        NO_FWD=true
        shift # Remove --no-fwd from the parameters
        ;;
        --help)
        help
        exit 0
        ;;
        debug)
        DEBUG_MODE=true
        ;;
    esac
done

# Main
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    debug)
        debug
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usage: $0 {start|stop|debug|restart|--no-fwd|--help}"
        exit 1
        ;;
esac

exit 0
