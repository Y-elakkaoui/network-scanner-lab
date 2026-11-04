# 🔐 Network Scanner Lab (VMware Cybersecurity Project)

## 📌 Project Overview

This project documents a complete assess-harden-verify cycle in a VMware lab: network scanning, web enumeration, system hardening and a re-scan to check the result.

The objective is to identify exposed services, apply security improvements and measure which of them actually worked. The re-scan showed that some measures worked and others did not, and this README documents both.

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

### Apache Default Page
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

- Apache version information exposed  
- Default Apache page accessible  
- Missing security headers (X-Frame-Options, X-Content-Type-Options)  
- Potential information leakage via ETags  
- Presence of default and restricted directories  

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
Reduce attack surface and improve system security.

## 🛠️ Actions Performed

### 1. Apache Configuration
Edited `/etc/apache2/conf-available/security.conf` to hide version information. The file ended up with these two lines:

```apache
ServerTokens Prod
ServerTokens off
```

The second line was meant to be `ServerSignature Off`. See Phase 4 for the effect.

### 2. Removed Default Page
- Deleted `/var/www/html/index.html`

### 3. Firewall Configuration
- Enabled UFW
- Allowed only:
  - Port 22 (SSH)
  - Port 80 (HTTP)

### 4. System Update
- Updated system packages to patch vulnerabilities

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

# 🔁 Phase 4: Re-Scan & Validation

## 🧠 Objective
Verify whether the applied security measures improved the system's security posture.

## 🛠️ Actions Performed
- Re-ran the Nmap scan with `-sC -sV`
- Performed a Nikto vulnerability scan
- Checked HTTP headers using `curl -I`

## 📊 Results

**What worked**

- The firewall is active: Nmap now reports 998 filtered TCP ports
- The default Apache page is gone

**What did not work**

| Finding | Evidence | Cause |
| :--- | :--- | :--- |
| Apache version is still exposed | `Server: Apache/2.4.58 (Ubuntu)` in `curl -I`, Nmap and Nikto | The later `ServerTokens off` line overrides `ServerTokens Prod`, and `off` is not a valid value, so Apache falls back to its default (`Full`) |
| Version still appears in the page footer | Footer of the `Index of /` page | `ServerSignature Off` was never set |
| New issue: directory listing | Browser shows `Index of /`, Nikto reports directory indexing | Removing `index.html` left the directory without an index page, and `Indexes` is enabled |
| Security headers still missing | Nikto: no X-Frame-Options, no X-Content-Type-Options | Not addressed in this run |

## 📸 Screenshots

### Nmap After Hardening
![Nmap After](screenshots/phase4-rescan/nmap_after.png)

### Nikto After Hardening
![Nikto After](screenshots/phase4-rescan/nikto_after.png)

### Headers After Hardening
![Headers After](screenshots/phase4-rescan/headers_after.png)

---

# 📊 Overall Analysis

The firewall reduced the network exposure and the default page was removed. The information disclosure remained because of a single wrong line in the configuration, and removing the default page introduced a directory listing.

Without the re-scan, the hardening would have looked complete.

---

# ➡️ Next Run

Planned fixes for the next run, followed by the same re-scan:

```apache
# /etc/apache2/conf-available/security.conf
ServerTokens Prod
ServerSignature Off
Header set X-Frame-Options "SAMEORIGIN"
Header set X-Content-Type-Options "nosniff"
```

```apache
# Apache configuration for /var/www/
Options -Indexes
```

```bash
sudo a2enmod headers
sudo apache2ctl configtest
sudo systemctl reload apache2
```

---

# 📚 What I Learned

- Network scanning and service detection using Nmap  
- Web enumeration techniques and tools  
- Identifying vulnerabilities and misconfigurations  
- System hardening and defensive security practices  
- A hardening step is only finished once a re-scan confirms it  
- A fix can create a new finding, as the removed default page did  

---

# ⚠️ Disclaimer

This project was conducted in a controlled virtual lab environment for educational purposes only.
