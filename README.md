<p align="center">
  <!--<img src="https://github.com/user-attachments/assets/b7002b57-9a0a-44ab-9de3-fef44fb56ce0e"/><img src="https://github.com/user-attachments/assets/4e9cad6d-c134-44b1-9bd7-6f0b78b8a41a"/>-->
  <img width="825" height="108" alt="text-1752496235457" src="https://github.com/user-attachments/assets/6e072117-94d2-496e-8710-b140ce7c23da" />
</p>

Sonda is a no-nonsense tool I built to pull together basically everything you’d want from a system info utility on Linux. Uptime, running processes, hardware stats, network configs, package versions — instead of juggling a bunch of separate tools, sonda gives it all to you in one spot.

It also pushes real-time updates straight to your terminal — things like package installs, disk usage, memory pressure, CPU spikes, etc. Handy if you're keeping an eye on performance or troubleshooting something live without the fluff.



## Coverage

- [x] **System Info**

  - Pulls CPU, RAM, storage, and full hardware specs
  - Shows uptime, load averages, and resource pressure in real time
  - Keeps tabs on memory, disk, and CPU usage while you work

- [x] **Network Details**

  - Shows all interfaces, IPs (local + public), MACs, and routes
  - Lists open ports, active connections, and firewall status
  - Tracks traffic stats and per-interface info in real time

- [x] **Package Management**

  - Monitors installed packages and available updates live
  - Sends alerts when packages are added/updated — system or user
  - Gives you full version history on everything installed or pending

- [x] **Live Notifications**

  - Real-time alerts right in your terminal — no bloat, no GUI
  - Covers system changes, network status, package installs, and more

- [x] **System Health**

  - Watches CPU, memory, disk space, and uptime 24/7

- [x] **Process Viewer**

  - Displays all running processes and what they’re doing
  - Lets you catch memory hogs or zombie tasks instantly

- [x] **Real-Time Monitoring**

  - Constantly tracks CPU, RAM, disk, and network performance
- [x] **Clean Interface**

  - Everything is readable and sorted — made for the terminal
  - No fluff, just straight data, formatted for humans

- [ ] **Output & Logging** _`disabled temp.`_

  - Easy to skim or deep dive
  - Can log to file for later review or automation

- [x] **OS Integration**

  - Hooks into systemd and other core services for better insight

- [x] **Modular Setup**

  - Only enable the parts you care about
  - Easy to extend if you’ve got custom needs

## Installation
To install Sonda, simply clone the repository and run the packaging helper:

```bash
git clone https://github.com/yonasuriv/sonda && cd sonda && ./install_debian.sh all
```

All requirements and dependencies are handled automatically. To uninstall it run `sudo dpkg -r sonda`.

Once installed, you can run Sonda from the terminal:

```bash
sonda
```

This will provide a comprehensive, real-time overview of your system and network information, depending on the argument passed.

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

Tested and fully functional on Kali linux, but should be fully compatible with all debian-based GNU/Linux distributions. All dependencies are automatically handled by the Debian package (see `packagng/debian/control`).

## Support
To contribute or get support, simply fork the repository and submit your issues or pull requests. 

All forms of contributions are welcome, from bug fixes to new features and OS compatibility testing.

## License
Sonda is open-source software licensed under the MIT License. See the LICENSE file for more details.
