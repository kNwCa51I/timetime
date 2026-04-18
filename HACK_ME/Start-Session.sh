#!/usr/bin/env bash
# Start-Session.sh — Bootstrap a new target box within the active project
#
# Usage:
#   bash Start-Session.sh <IP>
#
# Requires:
#   newproj to have been run first (sets ~/.pentest_env and ~/.current_project)
#
# What it does:
#   1) Validates active project from ~/.pentest_env
#   2) Asks for sudo and keeps it alive
#   3) Launches top-5000 TCP scan in a new terminal immediately
#   4) Prompts for box metadata while scan runs
#   5) Creates box working directory + subdirs + seeded wordlists
#   6) Copies and substitutes stage templates into box notes dir
#   7) Writes box-level vars to ~/.pentest_env (IP, DOMAIN, BOX_DIR, OS)
#   8) Waits for top-5000 scan, moves report into box dir
#   9) Launches full TCP scan in a new terminal
#  10) Launches AutoRecon in a new terminal (optional)
#  11) Prints UDP command for manual use
#
# Master terminal stays as orchestrator throughout — never blocks on scans

set -euo pipefail

# ── Paths ──────────────────────────────────────────────────────────────────
PENTEST_ENV_FILE="$HOME/.pentest_env"
CURRENT_PROJECT_FILE="$HOME/.current_project"
CURRENT_BOX_FILE="$HOME/.current_workdir"
TEMPLATE_DIR="$HOME/OSCP/CTFs/utils/PentestTemplates"
CTF_ROOT_DIR="$HOME/OSCP/CTFs"
NOTES_ROOT="$HOME/OSCP/CTFs/ctf_NOTES_obs"

# ── AutoRecon tuning ────────────────────────────────────────────────────────
DIRBUSTER_WORDLIST="/usr/share/wordlists/dirb/common.txt"
DIRBUSTER_THREADS=100
DIRBUSTER_RECURSIVE=true
AUTORECON_HEARTBEAT=30
AUTORECON_NMAP_APPEND="--min-rate 500 --max-retries 4"

# ── Helpers ─────────────────────────────────────────────────────────────────
log()    { printf '  %s\n' "$*"; }
info()   { printf '\n\033[1;34m[*]\033[0m %s\n' "$*"; }
ok()     { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn()   { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
err()    { printf '\033[1;31m[-]\033[0m %s\n' "$*"; }
banner() { printf '\n\033[1;35m══════════════════════════════════════════\033[0m\n\033[1;35m  %s\033[0m\n\033[1;35m══════════════════════════════════════════\033[0m\n' "$*"; }

confirm() {
    local response
    read -r -p "    $1 (Enter/y = yes, anything else = no): " response
    [[ -z "$response" || "$response" =~ ^[Yy]$ ]]
}

confirm_no() {
    local response
    read -r -p "    $1 (y = yes, Enter = no): " response
    [[ "$response" =~ ^[Yy]$ ]]
}

usage() {
    echo "Usage: $0 <IP_ADDRESS>"
    exit 1
}

# ── Args ────────────────────────────────────────────────────────────────────
[[ $# -eq 1 ]] || usage
IP="$1"

# ── Validate active project ─────────────────────────────────────────────────
banner "New Box Session"

if [[ ! -f "$PENTEST_ENV_FILE" ]]; then
    err "No active project found. Run: newproj"
    exit 1
fi

source "$PENTEST_ENV_FILE" 2>/dev/null || true

if [[ -z "${PENTEST_PROJECT_DIR:-}" || ! -d "${PENTEST_PROJECT_DIR}" ]]; then
    err "Project directory not set or does not exist. Run: newproj"
    exit 1
fi

info "Active project: ${PENTEST_PROJECT_NAME} [${PENTEST_LAB}]"
log "  Directory : $PENTEST_PROJECT_DIR"
echo ""

# ── Get local IP ─────────────────────────────────────────────────────────────
LOCAL_IP="$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true)"
if [[ -z "$LOCAL_IP" ]]; then
    warn "Could not detect tun0 IP — VPN may not be up."
    LOCAL_IP="LOCAL_IP"
fi

# ── Sudo keepalive ───────────────────────────────────────────────────────────
if ! sudo -v; then
    err "sudo authentication failed."
    exit 1
fi

while true; do sudo -n true; sleep 60; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

LAST_BG_PID=""

# ── Terminal launcher ────────────────────────────────────────────────────────
launch_terminal_script() {
    local script_path="$1"
    local title="${2:-Pentest Terminal}"

    for emulator in gnome-terminal xfce4-terminal konsole x-terminal-emulator; do
        if command -v "$emulator" >/dev/null 2>&1; then
            case "$emulator" in
                gnome-terminal)
                    gnome-terminal --title="$title" -- bash -lc "bash '$script_path'; exec bash" >/dev/null 2>&1 &
                    ;;
                xfce4-terminal)
                    xfce4-terminal --title="$title" --hold --command="bash -lc \"bash '$script_path'; exec bash\"" >/dev/null 2>&1 &
                    ;;
                konsole)
                    konsole --title "$title" -e bash -lc "bash '$script_path'; exec bash" >/dev/null 2>&1 &
                    ;;
                x-terminal-emulator)
                    x-terminal-emulator -e bash -lc "bash '$script_path'; exec bash" >/dev/null 2>&1 &
                    ;;
            esac
            return 0
        fi
    done

    err "No terminal emulator found — cannot launch: $title"
    return 1
}

# ── Sudo job in new terminal with live log stream ────────────────────────────
start_sudo_job_with_terminal() {
    local label="$1"
    local cmd="$2"
    local log_file="$3"
    local done_file="$4"
    local status_file="$5"

    local job_script viewer_script
    job_script="$(mktemp /tmp/session-job.XXXXXX.sh)"
    viewer_script="$(mktemp /tmp/session-view.XXXXXX.sh)"

    cat > "$job_script" <<JOBEOF
#!/usr/bin/env bash
$cmd
status=\$?
printf '%s\n' "\$status" > "$status_file"
touch "$done_file"
exit "\$status"
JOBEOF
    chmod +x "$job_script"

    : > "$log_file"
    nohup sudo -n script -qefc "bash '$job_script'" /dev/null > "$log_file" 2>&1 &
    LAST_BG_PID=$!

    cat > "$viewer_script" <<VIEWEOF
#!/usr/bin/env bash
echo ""
echo "  ┌─────────────────────────────────────────┐"
echo "  │  Stage : $label"
echo "  │  Log   : $log_file"
echo "  └─────────────────────────────────────────┘"
echo ""

touch "$log_file"
tail -n +1 -f "$log_file" &
TAIL_PID=\$!

while [[ ! -f "$done_file" ]]; do
    sleep 2
done

kill "\$TAIL_PID" 2>/dev/null || true
wait "\$TAIL_PID" 2>/dev/null || true

echo ""
status=\$(cat "$status_file" 2>/dev/null || echo "unknown")
echo "  [+] $label finished — exit code: \$status"
echo ""
exec bash
VIEWEOF
    chmod +x "$viewer_script"

    if launch_terminal_script "$viewer_script" "$label"; then
        ok "Launched terminal: $label"
        return 0
    fi

    warn "Could not open terminal for: $label"
    warn "Job still running in background. Log: $log_file"
    return 1
}

wait_for_job() {
    local done_file="$1"
    local status_file="$2"
    local label="$3"

    info "Waiting for: $label"
    while [[ ! -f "$done_file" ]]; do
        sleep 5
        printf '.'
    done
    echo ""

    local status="1"
    [[ -f "$status_file" ]] && status="$(<"$status_file")"

    if [[ "$status" != "0" ]]; then
        warn "$label finished with exit code: $status"
        return "$status"
    fi

    ok "$label complete."
    return 0
}

# ── Extract open ports from gnmap ────────────────────────────────────────────
extract_open_ports() {
    local gnmap="$1"
    awk -F'Ports: ' '
        /Ports: /{
            n=split($2, a, ",");
            for(i=1;i<=n;i++){
                gsub(/^[ \t]+|[ \t]+$/, "", a[i]);
                if(a[i] ~ /open\/tcp/){
                    split(a[i], b, "/");
                    gsub(/[^0-9]/, "", b[1]);
                    if(b[1] != "") print b[1];
                }
            }
        }' "$gnmap" | sort -n | uniq | paste -sd, -
}

# ── App launchers ────────────────────────────────────────────────────────────
open_vscode() {
    local dir="$1"
    for bin in code code-oss code-insiders; do
        if command -v "$bin" >/dev/null 2>&1; then
            "$bin" --new-window "$dir" >/dev/null 2>&1 &
            ok "VS Code opening: $dir"
            return
        fi
    done
    warn "VS Code not found."
}

open_obsidian() {
    if command -v obsidian >/dev/null 2>&1; then
        obsidian "$NOTES_ROOT" >/dev/null 2>&1 &
        ok "Obsidian opening."
    elif command -v flatpak >/dev/null 2>&1 && flatpak list 2>/dev/null | grep -qi obsidian; then
        flatpak run md.obsidian.Obsidian "$NOTES_ROOT" >/dev/null 2>&1 &
        ok "Obsidian opening via flatpak."
    else
        warn "Obsidian not found."
    fi
}

open_burpsuite() {
    for bin in burpsuite burpsuite-community; do
        if command -v "$bin" >/dev/null 2>&1; then
            "$bin" >/dev/null 2>&1 &
            ok "Burp Suite opening."
            return
        fi
    done
    warn "Burp Suite not found."
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — Launch top-5000 scan immediately in new terminal
# ══════════════════════════════════════════════════════════════════════════════

STAMP="$(date +%Y%m%d-%H%M%S)"
BOOTSTRAP_BASE="/tmp/nmap-bootstrap-${IP//./_}-${STAMP}"
BOOTSTRAP_TMP_OUT="${BOOTSTRAP_BASE}.nmap"
BOOTSTRAP_LOG="${BOOTSTRAP_BASE}.log"
BOOTSTRAP_DONE="${BOOTSTRAP_BASE}.done"
BOOTSTRAP_STATUS="${BOOTSTRAP_BASE}.status"

BOOTSTRAP_CMD="nmap -vv -sS -sV -sC --top-ports 5000 -oN \"$BOOTSTRAP_TMP_OUT\" \"$IP\""

info "Launching top-5000 TCP scan in new terminal..."
log "  Command: $BOOTSTRAP_CMD"

start_sudo_job_with_terminal \
    "Nmap Top-5000 — $IP" \
    "$BOOTSTRAP_CMD" \
    "$BOOTSTRAP_LOG" \
    "$BOOTSTRAP_DONE" \
    "$BOOTSTRAP_STATUS"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — Box metadata (while scan runs)
# ══════════════════════════════════════════════════════════════════════════════

info "Box metadata (scan is running in background)..."
echo ""

read -r -p "    Box name: " BOXNAME
if [[ -z "$BOXNAME" ]]; then
    err "Box name cannot be empty."
    exit 1
fi

echo ""
echo "    OS type:"
echo "    1) Windows"
echo "    2) Linux"
echo "    3) Unknown"
read -r -p "    Choice [1-3]: " os_choice
case "$os_choice" in
    1) OS_TYPE="Windows"; OS_PREFIX="W" ;;
    2) OS_TYPE="Linux";   OS_PREFIX="L" ;;
    3) OS_TYPE="Unknown"; OS_PREFIX="U" ;;
    *) OS_TYPE="Unknown"; OS_PREFIX="U" ;;
esac

echo ""
read -r -p "    Domain name (leave blank if none): " DOMAIN_INPUT
DOMAIN="${DOMAIN_INPUT:-}"

# ── Directory names ──────────────────────────────────────────────────────────
IP_LAST="${IP##*.}"
BOX_DIRNAME="${BOXNAME}-${OS_PREFIX}-${PENTEST_LAB}-${IP_LAST}"
BOX_WORK_DIR="${PENTEST_PROJECT_DIR}/${BOX_DIRNAME}"
BOX_NOTES_DIR="${NOTES_ROOT}/${BOX_DIRNAME}"
BOOTSTRAP_FINAL_OUT="${BOX_WORK_DIR}/nmap_0_top5000.nmap"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — Create directories and seed files
# ══════════════════════════════════════════════════════════════════════════════

info "Creating box working directory..."

mkdir -p "$BOX_WORK_DIR"/{enum,foothold,loot,privesc,scans,loot/hashes,loot/creds}
mkdir -p "$BOX_NOTES_DIR"

# Seeded wordlists
for word in "$BOXNAME" admin administrator root test guest; do
    echo "$word" >> "$BOX_WORK_DIR/users.txt"
    echo "$word" >> "$BOX_WORK_DIR/passwords.txt"
done
[[ -n "$DOMAIN" ]] && echo "$DOMAIN" >> "$BOX_WORK_DIR/passwords.txt"
echo "$BOXNAME" > "$BOX_WORK_DIR/ContextWordlist.txt"
echo "placeholder" > "$BOX_WORK_DIR/foo.txt"

ok "Working directory: $BOX_WORK_DIR"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — Copy and populate stage templates
# ══════════════════════════════════════════════════════════════════════════════

info "Copying stage templates..."

if [[ -d "$TEMPLATE_DIR" ]]; then
    for tmpl in "$TEMPLATE_DIR"/*.md; do
        [[ -f "$tmpl" ]] || continue
        dest="$BOX_NOTES_DIR/$(basename "$tmpl")"
        cp "$tmpl" "$dest"
        # Substitute placeholders
        sed -i \
            -e "s|IP_ADDRESS|${IP}|g" \
            -e "s|LOCAL_IP|${LOCAL_IP}|g" \
            -e "s|DOMAIN|${DOMAIN:-DOMAIN}|g" \
            -e "s|BOXNAME|${BOXNAME}|g" \
            -e "s|OS_TYPE|${OS_TYPE}|g" \
            -e "s|LAB_TYPE|${PENTEST_LAB}|g" \
            "$dest"
    done
    ok "Templates populated in: $BOX_NOTES_DIR"
else
    warn "Template directory not found: $TEMPLATE_DIR"
    warn "Skipping template copy — create templates at that path."
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — Write box-level env vars
# ══════════════════════════════════════════════════════════════════════════════

info "Writing box environment..."

# Backup before writing
ENV_BACKUP="${PENTEST_ENV_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
cp "$PENTEST_ENV_FILE" "$ENV_BACKUP"

# Update box-level vars in place using sed
sed -i \
    -e "s|^export PENTEST_BOX_NAME=.*|export PENTEST_BOX_NAME=\"${BOXNAME}\"|" \
    -e "s|^export PENTEST_BOX_DIR=.*|export PENTEST_BOX_DIR=\"${BOX_WORK_DIR}\"|" \
    -e "s|^export PENTEST_IP=.*|export PENTEST_IP=\"${IP}\"|" \
    -e "s|^export PENTEST_DOMAIN=.*|export PENTEST_DOMAIN=\"${DOMAIN:-}\"|" \
    -e "s|^export PENTEST_OS=.*|export PENTEST_OS=\"${OS_TYPE}\"|" \
    -e "s|^export PENTEST_LOCAL_IP=.*|export PENTEST_LOCAL_IP=\"${LOCAL_IP}\"|" \
    "$PENTEST_ENV_FILE"

# Write pointer files
echo "$BOX_WORK_DIR" > "$CURRENT_BOX_FILE"

# Source for current shell
source "$PENTEST_ENV_FILE"

ok "Environment updated — IP=$IP available in all new terminals."

# ══════════════════════════════════════════════════════════════════════════════
# STEP 6 — Open apps, cd to project dir
# ══════════════════════════════════════════════════════════════════════════════

open_vscode "$CTF_ROOT_DIR"
open_obsidian
open_burpsuite

info "Changing master terminal to project directory..."
cd "$PENTEST_PROJECT_DIR"
ok "Now in: $PENTEST_PROJECT_DIR"
log "  Run 'gobox' to jump to box dir at any time."

# ══════════════════════════════════════════════════════════════════════════════
# STEP 7 — Wait for top-5000 scan, move report
# ══════════════════════════════════════════════════════════════════════════════

wait_for_job "$BOOTSTRAP_DONE" "$BOOTSTRAP_STATUS" "Nmap Top-5000"

if [[ -f "$BOOTSTRAP_TMP_OUT" ]]; then
    sudo mv "$BOOTSTRAP_TMP_OUT" "$BOOTSTRAP_FINAL_OUT"
    sudo chown "$USER:$USER" "$BOOTSTRAP_FINAL_OUT" 2>/dev/null || true
    ok "Top-5000 report: $BOOTSTRAP_FINAL_OUT"
else
    warn "Top-5000 output not found at expected path: $BOOTSTRAP_TMP_OUT"
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 8 — Full TCP scan in new terminal
# ══════════════════════════════════════════════════════════════════════════════

NMAP_OUT="$BOX_WORK_DIR/scans/PortFull-Pn.nmap"
GNMAP_OUT="$BOX_WORK_DIR/scans/PortFull-Pn.gnmap"
NMAP_CMD="nmap -Pn -p- --min-rate 800 -vv -sC -sV -O --open -oN \"$NMAP_OUT\" -oG \"$GNMAP_OUT\" \"$IP\""

NMAP_LOG="/tmp/nmap-full-${IP//./_}-${STAMP}.log"
NMAP_DONE="/tmp/nmap-full-${IP//./_}-${STAMP}.done"
NMAP_STATUS="/tmp/nmap-full-${IP//./_}-${STAMP}.status"

info "Launching full TCP scan in new terminal..."
log "  Command: sudo $NMAP_CMD"

start_sudo_job_with_terminal \
    "Nmap Full TCP — $IP" \
    "$NMAP_CMD" \
    "$NMAP_LOG" \
    "$NMAP_DONE" \
    "$NMAP_STATUS"

# ══════════════════════════════════════════════════════════════════════════════
# STEP 9 — AutoRecon (optional, new terminal)
# ══════════════════════════════════════════════════════════════════════════════

AUTORECON_DIR="$BOX_WORK_DIR/scans/${IP}-autorecon"
mkdir -p "$AUTORECON_DIR"

# Build AutoRecon command using top-5000 open ports if available
OPEN_PORTS=""
if [[ -f "$BOOTSTRAP_FINAL_OUT" ]]; then
    # Create a temp gnmap-style parse from nmap output
    OPEN_PORTS=$(grep -oP '\d+/open' "$BOOTSTRAP_FINAL_OUT" 2>/dev/null \
        | cut -d/ -f1 | sort -n | uniq | paste -sd, - || true)
fi

AUTORECON_ARGS=(
    autorecon "$IP"
    --timeout 15
    -vv
)
[[ -n "$OPEN_PORTS" ]] && AUTORECON_ARGS+=(-p "$OPEN_PORTS")
AUTORECON_ARGS+=(
    --dirbuster.wordlist "$DIRBUSTER_WORDLIST"
    --dirbuster.threads "$DIRBUSTER_THREADS"
    --heartbeat "$AUTORECON_HEARTBEAT"
    "--nmap-append=${AUTORECON_NMAP_APPEND}"
)
$DIRBUSTER_RECURSIVE && AUTORECON_ARGS+=(--dirbuster.recursive)

AUTORECON_CMD="cd '${AUTORECON_DIR}' && $(printf '%q ' "${AUTORECON_ARGS[@]}")"
AUTORECON_CMD="${AUTORECON_CMD% }"

echo ""
info "AutoRecon command prepared:"
log "  $AUTORECON_CMD"
echo ""

if confirm_no "Launch AutoRecon in a new terminal now?"; then
    AR_LOG="$AUTORECON_DIR/autorecon-${STAMP}.log"
    AR_DONE="/tmp/autorecon-${IP//./_}-${STAMP}.done"
    AR_STATUS="/tmp/autorecon-${IP//./_}-${STAMP}.status"

    start_sudo_job_with_terminal \
        "AutoRecon — $IP" \
        "$AUTORECON_CMD" \
        "$AR_LOG" \
        "$AR_DONE" \
        "$AR_STATUS"
else
    warn "AutoRecon not started. Run when ready:"
    log "  sudo $AUTORECON_CMD"
fi

# ══════════════════════════════════════════════════════════════════════════════
# STEP 10 — UDP (manual)
# ══════════════════════════════════════════════════════════════════════════════

UDP_OUT="$BOX_WORK_DIR/scans/UDP-top1000.nmap"
UDP_CMD="sudo nmap -vv --top-ports=1000 -Pn -sU --open -oN \"$UDP_OUT\" \"$IP\""

# ══════════════════════════════════════════════════════════════════════════════
# STEP 11 — Summary
# ══════════════════════════════════════════════════════════════════════════════

banner "Session Ready — $BOXNAME ($IP)"
echo ""
log "  Project   : $PENTEST_PROJECT_NAME [$PENTEST_LAB]"
log "  Box       : $BOXNAME"
log "  IP        : $IP"
log "  OS        : $OS_TYPE"
[[ -n "$DOMAIN" ]] && log "  Domain    : $DOMAIN"
log "  Local IP  : $LOCAL_IP"
log "  Work dir  : $BOX_WORK_DIR"
log "  Notes dir : $BOX_NOTES_DIR"
echo ""
log "  \$PENTEST_IP is set — available in all new terminals."
echo ""
log "  UDP scan (run when ready):"
log "  $UDP_CMD"
echo ""
log "  Navigation:"
log "    gobox   → $BOX_WORK_DIR"
log "    goproj  → $PENTEST_PROJECT_DIR"
echo ""
