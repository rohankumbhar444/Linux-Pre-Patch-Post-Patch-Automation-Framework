# Linux-Pre-Patch-Post-Patch-Automation-Framework
Automated scripts &amp; Ansible playbook for system validation, compliance reporting, and maintenance readiness checks in enterprise Linux environments.


README — Linux Pre-Patch & Post-Patch Automation Framework
Overview

This project provides automated scripts and an Ansible playbook used for system validation before and after patching/maintenance activities on Linux servers.
It helps ensure system stability, compliance, and safe change execution in enterprise environments.

Features
Capability	Details

🔹 Pre-Patch System Health Check	Baseline system state collection

🔹 Post-Patch Verification	Confirms services & system stability after reboot/patch

🔹 Central Log Collection	Saves output for audit & troubleshooting

🔹 Ansible Automation	Run checks on multiple remote hosts

🔹 Safe & Non-Intrusive	Read-only checks — no configuration change

Components
1️Pre-Check Script
Collects system configuration and health details before patching, including:
System date, uptime, kernel version
Filesystem & disk status
LVM & multipath info
Network configuration & routing
Memory & CPU usage
Running services & processes
GRUB bootloader config

Output saved as:

/home/<user>/precheck_<date-time>.txt

2️) Post-Check Script

Validates system health after patching/reboot, verifying:
Services & startup health
SELinux & firewall status
Network reachability, DNS checks
Listening ports & connectivity
Memory/CPU usage & logs
Storage, LVM & multipath status
Time sync verification (NTP/chrony)

Output saved as:
/home/<user>/postcheck_<date-time>.txt

3️) Ansible Playbook

Runs precheck/postcheck scripts across multiple servers.
Centralized reporting
Automation for patch cycles
Ideal for production environments

Directory Structure

📁 server-maintenance-automation
 ┣ 📜 precheck.sh
 
 ┣ 📜 postcheck.sh
 
 ┣ 📜 auto_patching.yml     # Run precheck and postcheck via Ansible
 
 ┣ 📜 inventory             # List of target servers
 
 ┗ 📜 README.md

How to Use
Run Pre-Check
chmod +x precheck.sh
./precheck.sh

Run Post-Check
chmod +x postcheck.sh
./postcheck.sh

Run via Ansible
Pre-Check
ansible-playbook -i inventory prepatch.yml

Post-Check
ansible-playbook -i inventory postpatch.yml

Use Cases
Use Case	Benefit
Enterprise Patching Cycle	Safe maintenance execution
Audit & Compliance	Documented server health before/after changes
Troubleshooting	Identify issues caused by updates
Change Management	DR & rollback preparation
Safety Notes

Scripts are read-only — no system modifications

Works on RHEL, Rocky, CentOS, Ubuntu, Debian

Run as root/sudo for complete info

Contributions

PRs and suggestions are welcome.
Add your custom checks & automation steps!

Contact / Support

For improvements, advanced automation, or CI/CD patch pipelines — feel free to discuss.
