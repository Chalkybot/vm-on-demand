# Port Forwarding to One-Time Use VM

This project enables port forwarding to a new, fresh, one-time use virtual machine. By connecting to a specific port within a port range, users will be automatically forwarded to a temporary virtual machine. This README provides an overview of the project and explains how to set it up.

## Project Setup

### Prerequisites
- The host machine should have the following components installed:
  - `qemu-img`
  - `virsh`
- Ensure that the host machine has appropriate permissions to manage virtual machines using `virsh`.

### Configuration
1. Clone or download the project repository to the desired location on the host machine.

2. Ensure that the `create-new-vm.sh` file has execution permissions:
   ```bash
   chmod +x create-new-vm.sh
   ```

3. Open the `create-new-vm.sh` file in a text editor and make the following modifications:
   - Adjust the paths and filenames for the original and new VM images, as well as the XML configuration file, to match your setup.
   - Customize any other variables or settings according to your requirements.

## Usage

### SSH Port Forwarding
1. SSH into the host machine using the specified port range and the desired VM number:
   ```bash
   ssh -p <port> user@host
   ```

   Replace `<port>` with the specific port from the defined range, and `user@host` with the appropriate SSH credentials.

2. Upon successful SSH connection, the `create-new-vm.sh` script will automatically run and perform the necessary operations to set up a new virtual machine.

### Management Operations
The `debug.sh` script also provides additional management operations for virtual machines. These operations can be executed separately as needed.

To execute the management operations, SSH into the host machine using the regular SSH port (not the port range for one-time use VMs). Then, navigate to the project directory and run the `debug.sh` script with the desired option.

Available management options:

- `--info`: Displays information about running virtual machines.
- `--restart`: Restarts all running virtual machines.
- `--down`: Gracefully shuts down all running virtual machines.
- `--up`: Starts every virtual machine in the swarm.
- `--net-refresh`: Refreshes the network by restarting all running virtual machines and restarting the network DHCP controller.
- `--purge`: Purges (removes) temporary virtual machines.

Example:
```bash
cd /path/to/project/directory
./debug.sh --info
```

**Note**: Make sure you have the necessary permissions to manage virtual machines using `virsh`. The user running the script should have the required privileges.

## Additional Notes
- The `create-new-vm.sh` file contains comments explaining each step of the process. You can refer to these comments for a deeper understanding of the script's functionality.
- Take caution when using the `--purge` option, as it permanently removes temporary virtual machines. Confirm your intentions before proceeding.
- Feel free to modify the script according to your specific requirements. However, ensure that you have a backup of any important data before making any modifications.

**Note**: Ensure you have a backup of any important data before performing any destructive operations.