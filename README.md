<p align="center">
  <!--<img src="https://github.com/user-attachments/assets/b7002b57-9a0a-44ab-9de3-fef44fb56ce0e"/><img src="https://github.com/user-attachments/assets/4e9cad6d-c134-44b1-9bd7-6f0b78b8a41a"/>-->
  <img width="825" height="108" alt="text-1752496235457" src="https://github.com/user-attachments/assets/6e072117-94d2-496e-8710-b140ce7c23da" />
</p>

Sonda is a lightweight, terminal-focused system information toolkit for Linux. It consolidates uptime, running processes, hardware details, network configuration, and package metadata into a single, consistent interface, so you do not need to juggle multiple utilities.

Sonda can also stream real-time updates directly to your terminal, including package installation activity, disk usage, memory pressure, CPU utilization, and more. This makes it well suited for performance monitoring and troubleshooting without graphical overhead.

## Coverage

- [x] **System Information**

  - Collects CPU, memory, storage, and detailed hardware specifications.
  - Reports uptime, load averages, and resource pressure in real time.
  - Monitors memory, disk, and CPU utilization during normal operation.

- [x] **Network Details**

  - Displays all interfaces, IP addresses (local and public), MAC addresses, and routes.
  - Lists open ports, active connections, and firewall status.
  - Tracks traffic statistics and per-interface information in real time.

- [x] **Package Management**

  - Monitors installed packages and available updates.
  - Highlights when packages are added or updated at the system or user level.
  - Provides version history for installed and pending packages.

- [x] **Live Notifications**

  - Sends real-time alerts to the terminal without requiring a graphical interface.
  - Covers system changes, network state, package activity, and other key events.

- [x] **System Health**

  - Watches CPU, memory, disk capacity, and uptime continuously.

- [x] **Process Visibility**

  - Shows active processes and their resource usage.
  - Helps quickly identify resource-intensive or misbehaving tasks.

- [x] **Real-Time Monitoring**

  - Continuously tracks CPU, memory, disk, and network performance metrics.

- [x] **Clean Interface**

  - Presents information in a structured, readable layout designed for the terminal.
  - Focuses on essential data, formatted to be easy to scan.

- [ ] **Output and Logging** _`temporarily disabled`_

  - Designed for both quick inspection and deeper analysis.
  - Supports file-based logging for later review or automation when enabled.

- [x] **Operating System Integration**

  - Integrates with systemd and other core services to provide richer context.

- [x] **Modular Architecture**

  - Allows enabling only the components that are relevant to a given workflow.
  - Designed to be straightforward to extend with additional modules.

## Installation
To install Sonda, clone the repository and run the Debian packaging helper script:

```bash
git clone https://github.com/yonasuriv/sonda && cd sonda && ./install_debian.sh all
```

All required dependencies are handled automatically by the packaging process. To uninstall Sonda, run `sudo dpkg -r sonda`.

After installation, Sonda is available on the PATH and can be invoked from the terminal:

```bash
sonda
```

This command provides a comprehensive, real-time overview of system and network information, depending on the options supplied.

For more convenient access, it is recommended to define shell aliases such as:

```bash
alias ipconfig='sonda net'
alias sysinfo='sonda sys'
```

## Usage

<p align="center"> 
  <img src="https://github.com/user-attachments/assets/f44ddefa-5ea9-4a78-b92d-c06f7bff4b8e"/>
</p>

## Flags

### `-s` Argument

<p align="center">
  <img src="https://github.com/user-attachments/assets/1e71d4b6-a201-4db5-811b-4b3db4fd5c71"/>
</p>

### `-n` Argument

<p align="center">
  <img src="https://github.com/user-attachments/assets/4ae89af0-f96c-42fc-9058-f0a6bfa42163"/>
</p>

## Compatibility

Sonda has been tested and validated on Kali Linux and is intended to be compatible with Debian-based GNU/Linux distributions. All runtime dependencies are managed by the Debian package (see `packaging/debian/control`).

## Support and Contributions

To request support or contribute changes, fork the repository and open an issue or pull request.

Contributions of all types are welcome, including bug fixes, new features, and additional distribution compatibility testing.

## License

Sonda is open-source software licensed under the MIT License. For full details, refer to the `LICENSE` file.
