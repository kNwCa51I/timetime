# 01 Network Scanning

## AutoRecon — Run First (Background)

```bash
# Basic
sudo autorecon 192.168.102.227 -vv --dirbuster.wordlist /usr/share/wordlists/dirb/common.txt

# With context (usernames/passwords already known)
sudo autorecon 192.168.102.227 -vv --dirbuster.wordlist /usr/share/wordlists/dirb/common.txt --global.username-wordlist ./users.txt --global.password-wordlist ./passwords.txt
```

---

## Nmap — Standard Progression

### 1. Top 5000 (Fast, run first)
```bash
sudo nmap -vv -sS -sV -sC --top-ports 5000 -oN nmap_0_top5000.nmap 192.168.102.227
```

### 2. Full TCP (All ports, run in background)
```bash
# With ICMP
sudo nmap -p- -vv -sC -sV -O -oN PortFull.nmap 192.168.102.227 --open

# Without ICMP (use if host appears down)
sudo nmap -Pn -p- -vv -sC -sV -O -oN PortFull-Pn.nmap 192.168.102.227 --open
```

### 3. UDP Top 1000 (Don't skip — SNMP is here)
```bash
sudo nmap --top-ports=1000 -Pn -sU -oN UDP-top1000.nmap 192.168.102.227 --open
# Note: without --open you catch FILTERED ports too (useful for port knocking scenarios)
```

### 4. Multiple Hosts
```bash
# From file
sudo nmap -iL Hosts.txt -p- -vv -sC -sV -O -oN PortFull-MultiHost.nmap --open

# Loop
for ip in $(cat Full-IPs.txt); do
  sudo nmap -p- -sC -sV -O -oN PortFull-${ip}.nmap $ip -Pn --open
done
```

### 5. Grepable output (for subnet discovery)
```bash
sudo nmap -p- -Pn -n --open -vvv 192.168.102.227 -oG openPorts
```

---

## Service-Specific Nmap Scripts

```bash
# SMB
nmap -v -p 135,139,445 -oN SMB-nmap.txt -d --script smb-* 192.168.102.227

# LDAP
sudo nmap -sV -p 389,636,3268,3269 192.168.102.227 --script "ldap* and not brute" -oN ldap-scripts-nmap.txt

# Kerberos
nmap -v -p 88 -oN krb-nmap.txt --script krb5-* 192.168.102.227 --open
nmap -v -p 88 -oN Kerb-nmap.txt --script krb5-enum-users 192.168.102.227 --open

# SNMP (UDP)
sudo nmap -sU -p 161 192.168.102.227 --script "snmp* and not brute" -oN snmp-scripts-udp-161-nmap.txt

# RPC / MSRPC
nmap -v -p 135,593,49664-49674 -oN msrpc-enum-nmap.txt --script msrpc-enum 192.168.102.227 --open

# FTP
sudo nmap -sV -p 21 192.168.102.227 --script "ftp* and not brute" -oN ftp-nmap.txt

# SSL/TLS certificate inspection
echo | openssl s_client -showcerts -servername 192.168.102.227 -connect 192.168.102.227:443 2>/dev/null | openssl x509 -inform pem -noout -text
```

---

## Netcat — Banner Grab and Probe

```bash
# TCP port scan range
nc -nvv -w 1 -z 192.168.102.227 PORT-RANGE

# With payload
echo "Hello" | nc -nvv -w 1 -z 192.168.102.227 PORT-RANGE
echo "GET / HTTP/1.0\r\n\r\n" | nc -nvv -w 1 -z 192.168.102.227 PORT-RANGE

# UDP scan
nc -nv -u -z -w 1 192.168.102.227 PORT

# Quick connectivity check through tunnel (nc hangs = firewall; refused = nothing there)
nc -zv TARGET_IP 1433
```

---

## Enum4Linux

```bash
# Full enum (works on Windows too)
enum4linux -A 192.168.102.227 | tee enumforLinux-A-Report.txt

# Users only via null session
enum4linux -U 192.168.102.227 | grep "user:" | cut -f2 -d"[" | cut -f1 -d"]"
```

---

## NBTScan

```bash
nbtscan -v 192.168.102.227
nmblookup -A 192.168.102.227
```
