# LTE Network Manager for Raspberry CM/Pi

`lte-net-manager.sh` is a Bash script designed to manage LTE connections on a Raspberry CM/Pi, particularly for devices like Sierra Wireless modems. The script allows for easy management of network connections and IP configuration, with options for debugging and skipping iptables rules configuration.

### Features

- **Start/Stop LTE Network**: Easily start and stop LTE network connections with proper network interface and IP configuration.
- **iptables Configuration**: Automatically sets up iptables rules for network forwarding, with an option to skip the configuration using the `--no-fwd` flag.
- **Debug Mode**: Provides detailed logs for debugging purposes. Logs can be saved to both the console and a log file.
- **Restart Functionality**: Restart the network connection with a single command.
- **Device Check**: Verifies the existence of the specified LTE device before attempting to configure it.
- **PID Management**: Manages process IDs for the `udhcpc` process to ensure proper network configuration.

### Prerequisites

- **Operating System**: Raspberry Pi OS (or any Linux distribution).
- **Root Privileges**: The script must be executed with root privileges.
- **Dependencies**: Make sure the following tools are installed:
  - `qmi-network`
  - `udhcpc`
  - `iptables`


You can install these dependencies using your package manager. For example, on Debian-based systems:

```bash
sudo apt-get install qmi-utils busybox iptables
```

## Installation
1. Open the configuration file in a text editor:

```bash
git clone https://github.com/sephiroth6/lte-network-manager
cd lte-net-manager
chmod +x lte-net-manager.sh
sudo ln -s $(pwd)/lte-net-manager.sh /usr/local/bin/lte-net-manager
```

- **Configuration**: You need to configure the Access Point Name (APN):
1. Open the configuration file in a text editor:
```bash
sudo nano /etc/qmi-network.conf
```
2. Add or modify the APN settings. For example:
```bash
APN="your-apn-here"
```

## Usage

The `lte-net-manager.sh` script can be used with several commands to manage the LTE network connection. Below are the available commands and options:

### Basic Commands

- **Start the LTE connection**:
  ```bash
  ./lte-net-manager.sh start
  ```
- **Stop the LTE connection:**
  ```bash
  ./lte-net-manager.sh stop
  ```
- **Restart the LTE connection:**
  ```bash
  ./lte-net-manager.sh restart
  ```
- **Debug Mode:**
  ```bash
  ./lte-net-manager.sh debug
  ```
- **Advanced Usage, Start the LTE connection with iptables no forwarding rules:**
  ```bash
    ./lte-net-manager.sh start --no-fwd
    ./lte-net-manager.sh debug --no-fwd
  ```


## Logs

The `lte-net-manager.sh` script generates logs to help you monitor its activity and diagnose issues. The logs are stored in the following location:

- **Log File**: `/var/log/lte-network.log`

### Log Details

- **Log File Location**: `/var/log/lte-network.log`
  - This file contains timestamped entries of the script's operations, including status messages, errors, and debugging information.

### Viewing Logs

To view the logs, you can use standard command-line tools such as `cat`, `less`, or `tail`. For example:

- To view the entire log file:
  ```bash
  cat /var/log/lte-network.log
  ```

## Troubleshooting

If you encounter issues while using the `lte-net-manager.sh` script, the following troubleshooting steps may help resolve common problems:

### Common Issues and Solutions

1. **Script Not Executing Properly**

   - **Symptom**: The script fails to run or produces unexpected errors.
   - **Solution**: Ensure you are running the script as the root user. You can check the script's execution permissions and verify that the script is executable:
     ```bash
     sudo chmod +x /path/to/lte-net-manager.sh
     sudo /path/to/lte-net-manager.sh start
     ```

2. **Device Not Found**

   - **Symptom**: Error message indicating that the device `/dev/cdc-wdm0` does not exist.
   - **Solution**: Confirm that the device is correctly connected and recognized by your system. Check for the presence of the device file:
     ```bash
     ls -l /dev/cdc-wdm0
     ```
     If the device is not present, you may need to check the hardware connections or drivers.

3. **Network Not Starting**

   - **Symptom**: The script reports an error when trying to start the network.
   - **Solution**: Ensure that the `qmi-network` command is installed and properly configured. Verify that the device is correctly initialized and compatible with the `qmi-network` tool. Check the log file for detailed error messages:
     ```bash
     tail -f /var/log/lte-network.log
     ```

4. **IP Address Not Obtained**

   - **Symptom**: The script fails to obtain an IP address and times out.
   - **Solution**: Verify that the `udhcpc` command is available and working correctly. Check that the `wwan0` interface is up and properly configured. Review the log file for additional information about the issue.

5. **iptables Rules Not Applied**

   - **Symptom**: The iptables rules are not applied when the `--no-fwd` option is not used.
   - **Solution**: Ensure that the `iptables` command is installed and properly configured. Check if any conflicting firewall rules exist and verify that the script has the necessary permissions to modify iptables rules.

### Additional Help

If the above solutions do not resolve your issue, consider the following:

- **Consult the Logs**: The log file `/var/log/lte-network.log` contains detailed information about script operations and errors.
- **Seek Community Assistance**: Check the [GitHub Issues page](https://github.com/sephiroth6/lte-net-manager/issues) for similar issues or open a new issue if needed.
- **Contact Support**: If you require further assistance, contact the script's author or maintainers through the [project repository](https://github.com/sephiroth6/lte-net-manager).

Providing detailed information about the issue, including log file entries and steps to reproduce, can help in diagnosing and resolving the problem more effectively.


## License

This project is open source and is licensed under the [MIT License](https://opensource.org/licenses/MIT). 

### MIT License Summary

The MIT License is a permissive license that allows for:

- **Commercial Use**: You can use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software.
- **Private Use**: You can use the Software for private purposes without any obligation to share modifications.
- **Attribution**: You must include the original copyright notice and permission notice in all copies or substantial portions of the Software.

### License Conditions

The Software is provided "as is", without warranty of any kind. For more details, refer to the full text of the license.


## Author

This script was created by [4n93l0](https://github.com/sephiroth6). 

### Contributing

We welcome contributions to enhance the functionality and performance of this script. If you'd like to contribute, please feel free to push request.