# 🔐 Network Scanner Lab (VMware Cybersecurity Project)

## 📌 Project Overview

This project demonstrates a complete cybersecurity workflow including network scanning, web enumeration, and system hardening using a controlled VMware lab environment.

The objective is to identify open services, assess potential vulnerabilities, and apply security improvements to reduce the attack surface.

---

## 🖥️ Lab Setup

- **Attacker Machine:** Kali Linux  
- **Target Machine:** Ubuntu Desktop  
- **Platform:** VMware Workstation  
- **Network Type:** Host-only (isolated lab)  

---

## 🌐 Network Configuration

- Kali Linux IP: 192.168.38.131  
- Target IP: 192.168.38.129  

Both systems are connected within the same internal network.

---

## 🔧 Tools Used

- Nmap  
- WhatWeb  
- Nikto  
- Gobuster  
- Apache2  
- UFW (Firewall)  
- Kali Linux  

---

# 🔍 Phase 1: Network Scanning

## 🧠 Objective
Identify active hosts, open ports, and running services.

## 🛠️ Actions Performed
- Verified connectivity using `ping`
- Performed Nmap scan
- Used `-sC -sV` for service detection

## 📊 Results
- Port **80 (HTTP)** is open
- Service: **Apache HTTP Server 2.4.58 (Ubuntu)**

## 📸 Screenshots

### Ping Test
![Ping](screenshots/phase1-scanning/ping.png)

### Nmap Scan
![Nmap](screenshots/phase1-scanning/nmap-open-port.png)

### Advanced Scan (-sC -sV)
![Advanced Scan](screenshots/phase1-scanning/nmap-advanced.png)

### Apache Web Page
![Apache](screenshots/phase1-scanning/apache-page.png)

---

# 🔍 Phase 2: Web Enumeration

## 🧠 Objective
Analyze the discovered web service for vulnerabilities and hidden resources.

## 🛠️ Tools Used
- WhatWeb
- Nikto
- Gobuster

## 🔎 Findings

- Apache version information is exposed  
- Default Apache page is accessible  
- Missing security headers (X-Frame-Options, X-Content-Type-Options)  
- Potential information leakage via ETags  
- Limited directory exposure, but default resources are present  

## 📸 Screenshots

### WhatWeb Scan
![WhatWeb](screenshots/phase2-enumeration/whatweb_scan.png)

### Nikto Scan
![Nikto](screenshots/phase2-enumeration/nikto_scan.png)

### Gobuster Scan
![Gobuster](screenshots/phase2-enumeration/gobuster_scan.png)

---

# 🔐 Phase 3: System Hardening

## 🧠 Objective
Apply security measures to reduce attack surface and improve system security.

## 🛠️ Actions Performed

### 1. Apache Hardening
- Disabled version disclosure:
  - `ServerTokens Prod`
  - `ServerSignature Off`

### 2. Removed Default Page
- Deleted `/var/www/html/index.html`

### 3. Firewall Configuration
- Enabled UFW
- Allowed only:
  - Port 22 (SSH)
  - Port 80 (HTTP)

### 4. System Update
- Updated packages to patch vulnerabilities

---

## 📸 Screenshots

### Apache Config (Before)
![Before](screenshots/phase3-hardening/apache_config_before.png)

### Apache Config (After)
![After](screenshots/phase3-hardening/apache_config_after.png)

### Remove Default Page (Verification)
![Verify](screenshots/phase3-hardening/remove_default_page_verification.png)

### Remove Default Page (Result)
![Result](screenshots/phase3-hardening/remove_default_page_result.png)

### UFW Enable
![UFW Enable](screenshots/phase3-hardening/ufw_enable.png)

### UFW Rules
![UFW Rules](screenshots/phase3-hardening/ufw_rules.png)

### UFW Status
![UFW Status](screenshots/phase3-hardening/ufw_status.png)

---

# 📊 Overall Analysis

The initial assessment revealed multiple security weaknesses, including information disclosure, default configurations, and lack of protective controls.

After applying hardening measures:
- Sensitive information exposure was reduced  
- Default content was removed  
- Network access was restricted  
- System security posture improved significantly  

---

# 📚 What I Learned

- Network scanning and service detection using Nmap  
- Web enumeration techniques and tools  
- Identifying misconfigurations and vulnerabilities  
- System hardening and defensive security practices  
- Importance of reducing attack surface  

---

# ⚠️ Disclaimer

This project was conducted in a controlled virtual lab environment for educational purposes only.
