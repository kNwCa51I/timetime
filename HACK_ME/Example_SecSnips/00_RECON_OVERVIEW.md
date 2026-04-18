# 01 RECONNAISSANCE — Overview & Decision Flow

## ⚡ EXAM RULES — READ FIRST
```
# EXAM RULE - Never skip UDP — SNMP on 161 has given passwords before
# EXAM RULE - No open ports on TCP? Check UDP top 1000 immediately
# EXAM RULE - Add bossingit.biz to /etc/hosts before ANY Kerberos or LDAP work
# EXAM RULE - Credential found? Spray ALL protocols before moving on
# EXAM RULE - Anonymous/null session on SMB/RPC always worth trying first
# EXAM RULE - NXC confirms RDP works but xfreerdp3 fails? Try evil-winrm immediately
```

---

## Setup — Do This First

```bash
# Set working vars
export IP="192.168.102.227"
export bossingit.biz="bossingit.biz.local"
export URL="http://192.168.102.227"

# Create working directory
mkdir machine && cd machine

# Add to hosts file
echo "192.168.102.227 bossingit.biz.local" | sudo tee -a /etc/hosts; cat /etc/hosts
```

---

## Phase Decision Flow

```
Start
  │
  ├── Run AutoRecon (background)
  │     └── sudo autorecon 192.168.102.227 -vv
  │
  ├── Run nmap top 5000 (foreground, results faster)
  │     └── see 01_Network_Scanning.md
  │
  ├── Review open ports → match to service files:
  │     ├── 21        → FTP          (04_Service_Specific.md)
  │     ├── 22        → SSH          (04_Service_Specific.md)
  │     ├── 25/587    → SMTP         (04_Service_Specific.md)
  │     ├── 53        → DNS          (04_Service_Specific.md)
  │     ├── 69 UDP    → TFTP         (04_Service_Specific.md)
  │     ├── 80/443    → WEB          (02_Web_Enumeration.md)
  │     ├── 88        → KERBEROS     (03_AD_External.md)
  │     ├── 111       → NFS/RPC      (04_Service_Specific.md)
  │     ├── 135       → RPC/MSRPC    (03_AD_External.md)
  │     ├── 139/445   → SMB          (03_AD_External.md)
  │     ├── 161 UDP   → SNMP         (04_Service_Specific.md)
  │     ├── 389/636   → LDAP         (03_AD_External.md)
  │     ├── 1433      → MSSQL        (04_Service_Specific.md)
  │     ├── 3268/3269 → LDAP GC      (03_AD_External.md)
  │     ├── 3389      → RDP          (03_AD_External.md)
  │     └── 5985/5986 → WinRM        (03_AD_External.md)
  │
  ├── No creds yet? → Enumerate everything anonymously first
  │
  └── Got creds? → Go to Have_Creds.md immediately
```

---

## Information to Record

After initial scan, note down:
- [ ] Operating Systems and versions
- [ ] Hostnames (add to /etc/hosts)
- [ ] Open Ports and services
- [ ] Service versions (searchsploit each one)
- [ ] Anonymous/guest access available?
- [ ] Unknown port? `nc IP PORT` or `echo "version" | nc IP PORT`

---

## Quick Reference — HackTricks Links by Port

| Port | Service | Link |
|------|---------|-------|
| 21 | FTP | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-ftp |
| 22 | SSH | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-ssh.html |
| 25 | SMTP | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-smtp |
| 53 | DNS | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-dns.html |
| 80 | WEB | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-web |
| 88 | Kerberos | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-kerberos-88 |
| 111 | NFS | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-rpcbind.html |
| 135 | RPC | https://book.hacktricks.wiki/en/network-services-pentesting/135-pentesting-msrpc.html |
| 139/445 | SMB | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-smb |
| 161 | SNMP | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-snmp |
| 389 | LDAP | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-ldap.html |
| 1433 | MSSQL | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-mssql-microsoft-sql-server |
| 3389 | RDP | https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-rdp.html |
| 5985 | WinRM | https://book.hacktricks.wiki/en/network-services-pentesting/5985-5986-pentesting-winrm.html |
