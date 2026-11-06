# Network Assessment and Hardening Lab

A full assess, harden and verify cycle in an isolated VMware network: scanning and enumerating an Ubuntu web server from Kali Linux, hardening it, then scanning again to measure which measures actually worked.

> **Status:** One cycle completed on the VMware lab: the firewall works and the default page is gone, but the Apache version stayed exposed and a directory listing appeared. The corrected configuration then passed an automated [retest](#retest) in Docker. It has not been repeated on the original VM.

> **Kurzfassung (DE):** Ein kompletter Durchlauf im isolierten VMware-Netz: Ubuntu-Webserver von Kali aus prüfen, härten und danach erneut messen. Der Re-Scan zeigt 998 gefilterte Ports, die Standardseite ist weg, aber die Apache-Version blieb sichtbar und ein Verzeichnislisting kam hinzu. Die korrigierte Konfiguration hat einen automatisierten Nachtest in Docker bestanden, auf der ursprünglichen VM steht die Wiederholung noch aus.

![Nmap scan after hardening](screenshots/phase4-rescan/nmap_after.png)

## Lab environment

| Component | Details |
|---|---|
| Attacker | Kali Linux, 192.168.38.131 |
| Target | Ubuntu Desktop with Apache2, 192.168.38.129 |
| Platform | VMware Workstation |
| Network | Host-only (isolated) |

**Tools:** Nmap, WhatWeb, Nikto, Gobuster, Apache2, UFW

## Results at a glance

| Phase | Activity | Outcome |
|---|---|---|
| 1. Scanning | Ping and Nmap (`-sC -sV`) | Port 80 open, Apache 2.4.58 (Ubuntu) identified |
| 2. Enumeration | WhatWeb, Nikto, Gobuster | Version disclosure, default page, missing security headers |
| 3. Hardening | Apache configuration, default page removed, UFW enabled, system updated | Applied |
| 4. Re-scan | Nmap, Nikto, `curl -I` | Partly effective, see [Phase 4](#phase-4-re-scan-and-validation) |

## Phase 1: Network scanning

**Objective:** Identify active hosts, open ports and running services.

- Verified connectivity with `ping`
- Scanned with Nmap, using `-sC -sV` for service detection

**Result:** Port 80 (HTTP) is open, running Apache HTTP Server 2.4.58 (Ubuntu).

<details>
<summary>Screenshots</summary>

### Ping test

![Ping test](screenshots/phase1-scanning/ping.png)

### Nmap scan

![Nmap scan](screenshots/phase1-scanning/nmap-open-port.png)

### Service detection (-sC -sV)

![Nmap service detection](screenshots/phase1-scanning/nmap-advanced.png)

### Apache default page

![Apache default page](screenshots/phase1-scanning/apache-page.png)

</details>

## Phase 2: Web enumeration

**Objective:** Analyse the web service for weaknesses and hidden resources, using WhatWeb, Nikto and Gobuster.

**Findings:**

- Apache version information exposed
- Default Apache page accessible
- Missing security headers (X-Frame-Options, X-Content-Type-Options)
- Potential information leakage through ETags
- Default and restricted directories present

<details>
<summary>Screenshots</summary>

### WhatWeb

![WhatWeb scan](screenshots/phase2-enumeration/whatweb_scan.png)

### Nikto

![Nikto scan](screenshots/phase2-enumeration/nikto_scan.png)

### Gobuster

![Gobuster scan](screenshots/phase2-enumeration/gobuster_scan.png)

</details>

## Phase 3: System hardening

**Objective:** Reduce the attack surface.

1. **Apache configuration:** Edited `/etc/apache2/conf-available/security.conf` to hide version information. The file ended up with these two lines:

   ```apache
   ServerTokens Prod
   ServerTokens off
   ```

   The second line was meant to be `ServerSignature Off`. Phase 4 shows the effect.
2. **Default page:** Deleted `/var/www/html/index.html`.
3. **Firewall:** Enabled UFW and allowed only port 22 (SSH) and port 80 (HTTP).
4. **Updates:** Updated the system packages.

<details>
<summary>Screenshots</summary>

### Apache configuration before

![Apache configuration before](screenshots/phase3-hardening/apache_config_before.png)

### Apache configuration after

![Apache configuration after](screenshots/phase3-hardening/apache_config_after.png)

### Default page removal: verification

![Default page removal verification](screenshots/phase3-hardening/remove_default_page_verification.png)

### Default page removal: result

![Default page removal result](screenshots/phase3-hardening/remove_default_page_result.png)

### UFW enabled

![UFW enabled](screenshots/phase3-hardening/ufw_enable.png)

### UFW rules

![UFW rules](screenshots/phase3-hardening/ufw_rules.png)

### UFW status

![UFW status](screenshots/phase3-hardening/ufw_status.png)

</details>

## Phase 4: Re-scan and validation

**Objective:** Verify whether the applied measures improved the security posture, by repeating the Nmap scan (`-sC -sV`), running Nikto and checking the HTTP headers with `curl -I`.

**Effective:**

- The firewall is active: Nmap now reports 998 filtered TCP ports
- The default Apache page is gone

**Not effective:**

| Finding | Evidence | Cause |
|---|---|---|
| Apache version still exposed | `Server: Apache/2.4.58 (Ubuntu)` in `curl -I`, Nmap and Nikto | Apache rejects `ServerTokens off` as a syntax error, so a reload fails and the previous configuration stays active. Reproduced in the [retest](#retest), not confirmed on the original VM |
| Version still shown in the page footer | Footer of the `Index of /` page | `ServerSignature Off` was never set |
| New issue: directory listing | Browser shows `Index of /`, Nikto reports directory indexing | Removing `index.html` left the directory without an index page, and `Indexes` is enabled |
| Security headers still missing | Nikto: no X-Frame-Options, no X-Content-Type-Options | Not addressed in this run |

<details>
<summary>Screenshots</summary>

### Nikto after hardening

![Nikto after hardening](screenshots/phase4-rescan/nikto_after.png)

### HTTP headers after hardening

![HTTP headers after hardening](screenshots/phase4-rescan/headers_after.png)

</details>

## Analysis

The firewall reduced the network exposure and the default page was removed. The information disclosure remained because of a single invalid configuration line, most likely because Apache refused to load the edited file, and removing the default page introduced a directory listing.

Without the re-scan, the hardening would have looked complete.

## Retest

An automated retest on GitHub Actions starts Apache 2.4.58 on Ubuntu 24.04 in Docker, applies each configuration with a reload and scans it from a second container.

**Correction:** An earlier version of this README said Apache falls back to `ServerTokens Full`. The retest shows that this was wrong: Apache rejects the line.

```text
AH00526: Syntax error on line 3 of /etc/apache2/conf-enabled/security.conf:
ServerTokens takes 1 argument: 'Prod(uctOnly)', 'Major', 'Minor', 'Min(imal)', 'OS', or 'Full'
```

| Check | Original configuration | Corrected configuration |
|---|---|---|
| `apache2ctl configtest` | Syntax error | Syntax OK |
| Server header | `Apache/2.4.58 (Ubuntu)` | `Apache` |
| Request for `/` | `200`, `Index of /` | `403` |
| Version in the page footer | Yes | No |
| X-Frame-Options, X-Content-Type-Options | Missing | Set |

The corrected configuration:

```apache
ServerTokens Prod
ServerSignature Off
TraceEnable Off
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"

<Directory /var/www/>
    Options -Indexes
</Directory>
```

All 16 checks passed. See the [results](retest/evidence/results.txt), [evidence](retest/evidence/) and [workflow](.github/workflows/retest.yml).

**Limits:**

- This is a rebuild in Docker, not the original VM, so the fix still has to be repeated there.
- UFW was not part of the retest.
- Nikto stopped at its 120-second limit, so its scan is not complete.
- The retest was built and run with AI assistance (Claude).

## Key takeaways

- A hardening step is only finished once a re-scan confirms it.
- A fix can create a new finding, as the removed default page did.
- `apache2ctl configtest` belongs before every reload. It would have shown the error immediately.

## Disclaimer

This project was carried out in a controlled virtual lab environment for educational purposes only.
