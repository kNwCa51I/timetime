# 04 Service-Specific Enumeration

---

## FTP (port 21)

```bash
# Nmap scripts
sudo nmap -sV -p 21 192.168.102.227 --script "ftp* and not brute" -oN ftp-nmap.txt

# Anonymous login (always try first)
ftp anonymous@192.168.102.227 21
lftp -p 21 -u anonymous, ftp://192.168.102.227

# Better connection using domain name
ftp anonymous@hostname

# Default creds to try
# anonymous:anonymous
# admin:admin
# ftp:ftp
# guest:guest

# Recursive download
wget -q -m ftp://anonymous:anonymous@192.168.102.227:21 -P FTP-Dump

# SSL FTP
openssl s_client -connect 192.168.102.227:21 -starttls ftp

# Checklist:
# - Anonymous login?
# - Version in searchsploit?
# - Hints in directory (interesting filenames)?
# - Can we upload? If so, does it surface on web?
# - Does it point to web directory?
```

---

## SSH (port 22)

```bash
# Version check
nmap --script ssh-brute -p22 192.168.102.227 -oN sshBrute.nmap

# Key-based auth (check for keys on other boxes)
ssh -i id_rsa USERNAME@192.168.102.227

# If key found elsewhere
chmod 600 id_rsa
ssh -i id_rsa -o StrictHostKeyChecking=no USERNAME@192.168.102.227 -p 22

# Heartbleed check
nmap -p 22 --script ssl-heartbleed 192.168.102.227
```

---

## SMTP (port 25/587/465)

```bash
# Connect
telnet 192.168.102.227 25

# Session flow
EHLO attacker.com
VRFY username          # verify if user exists
EXPN mailinglist       # expand mailing list
MAIL FROM:<spoof@attacker.com>
RCPT TO:<target@localhost>
DATA
Subject: Test
Body.
.
QUIT

# User enumeration
smtp-user-enum -M VRFY -U /usr/share/seclists/Usernames/Names/names.txt -t 192.168.102.227
smtp-user-enum -M RCPT -U /usr/share/seclists/Usernames/Names/names.txt -t 192.168.102.227

# Open relay test
HELO test.com
MAIL FROM:<you@external.com>
RCPT TO:<other@external.com>   # If accepted = open relay

# Send file/payload
swaks --to victim@target.com --from you@spoof.com \
  --server 192.168.102.227 --attach payload.ods --data "Here is the doc"

# After shell — check local mail
cat /var/mail/*
cat /var/spool/mail/*
```

---

## DNS (port 53)

```bash
# Normal query
nslookup 192.168.102.227

# MX records
dig bossingit.biz MX

# NS records
dig bossingit.biz NS

# Zone transfer (all records!)
dig axfr @NAMESERVER bossingit.biz
dnsrecon -d bossingit.biz -a --name_server NAMESERVER

# Subnet DNS servers
nmap -sU -p53 NETWORK/24

# Subdomain brute force
dnsmap bossingit.biz
```

---

## TFTP (port 69 UDP)

```bash
# Enum with nmap
nmap -n -Pn -sU -p69 -sV --script tftp-enum 192.168.102.227

# Download found files
tftp 192.168.102.227 -c get backup.cfg
tftp 192.168.102.227 -c get sip.cfg
```

---

## NFS / RPC (port 111)

```bash
# Useful nmap scripts
nmap -p 111 --script rpc-info,nfs-ls,nfs-showmount,nfs-statfs 192.168.102.227

# Show mounts
showmount -e 192.168.102.227

# Mount share
mkdir /mnt/nfs
mount -t nfs 192.168.102.227:/share /mnt/nfs -nolock

# Check for no_root_squash
cat /etc/exports
```

---

## SNMP (port 161 UDP) — Don't Skip This

```bash
# Nmap brute community strings
sudo nmap -sU -p 161 --script snmp-brute 192.168.102.227
sudo nmap -sU -p 161 192.168.102.227 --script "snmp* and not brute" -oN snmp-scripts-udp-161-nmap.txt

# Hydra community string brute
hydra -P /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings.txt \
  snmp://192.168.102.227/

# Walk with public
snmpwalk -v 1 -c public 192.168.102.227 NET-SNMP-EXTEND-MIB::nsExtendObjects
snmpwalk -v2c -c public 192.168.102.227 | grep -i "password\|pass\|user\|login"
snmp-check 192.168.102.227

# Vendor-specific / enterprise OIDs (gave passwords on Frankfurt)
snmpwalk -v2c -c public 192.168.102.227 1.3.6.1.4.1 | tee snmpWalk.OUT

# Useful OIDs
# 1.3.6.1.2.1.25.1.6.0   System Processes
# 1.3.6.1.2.1.25.4.2.1.2 Running Programs
# 1.3.6.1.4.1.77.1.2.25  User Accounts
# 1.3.6.1.2.1.6.13.1.3   TCP Local Ports
```

---

## IMAP (port 143/993)

```bash
# Connect
telnet 192.168.102.227 143

# Manual session
a1 LOGIN USERNAME PASSWORD
a2 LIST "" "*"
a3 SELECT INBOX
a4 FETCH 1:* (BODY[HEADER.FIELDS (SUBJECT)])  # Subject lines
a5 FETCH 1 BODY[]                              # Full email 1
a6 FETCH 1:4 (BODY[HEADER.FIELDS (SUBJECT)] BODY[TEXT])  # Subjects+bodies 1-4
```

---

## POP3 (port 110/995)

```bash
# Connect
telnet 192.168.102.227 110

# Session
USER username
PASS password
LIST              # list messages
RETR 1            # get message 1
TOP 1 5           # headers + first 5 lines
STAT              # count + size
QUIT
```

---

## LDAP Functional Level Cheatsheet

From root DSE output:
```
Value  Windows Version     Notes
7      Server 2019+        Modern — no LM hashing, may restrict NTLM
6      Server 2016
5      Server 2012 R2
4      Server 2008 R2
3      Server 2008
2      Server 2003         Legacy — check for older attack paths
```

SASL Mechanisms in LDAP:
```
GSSAPI     → Kerberos auth (use with kinit for password-less enum)
GSS-SPNEGO → Kerberos + NTLM fallback (modern AD SSO)
DIGEST-MD5 → Legacy, weak
EXTERNAL   → Certificate-based
```

---

## Password Brute Force Wordlist Priority

```bash
# Try these BEFORE rockyou.txt
/usr/share/seclists/Passwords/corporate_passwords.txt
/usr/share/seclists/Passwords/xato-net-10-million-passwords-1000.txt
/usr/share/seclists/Passwords/cirt-default-passwords.txt
/usr/share/seclists/Passwords/Common-Credentials/100k-most-used-passwords-NCSC.txt
/usr/share/seclists/Passwords/Common-Credentials/common-passwords-win.txt
/usr/share/seclists/Passwords/darkweb2017-top1000.txt
/usr/share/wordlists/metasploit/unix_passwords.txt

# Then
/usr/share/wordlists/rockyou.txt

# Custom delta between lists
comm -23 <(sort -u new_list.txt) \
  <(cat old1.txt old2.txt | sort -u) > delta.txt
```
