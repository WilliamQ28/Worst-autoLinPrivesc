#!/bin/bash

echo "=============================="
echo "[*] Kernel Exploitability Check"
echo "=============================="

KERNEL=$(uname -r)
echo "[*] Kernel: $KERNEL"
echo ""

# -------------------------
# CVE-2022-2586 / 32250
# -------------------------
echo "[+] Checking nf_tables UAF (CVE-2022-2586 / 32250)..."

# Check for vulnerable kernel versions
ver_major=$(echo "$KERNEL" | cut -d. -f1)
ver_minor=$(echo "$KERNEL" | cut -d. -f2)
ver_patch=$(echo "$KERNEL" | cut -d. -f3 | cut -d- -f1)

nft_kernel_ok=false

if [ "$ver_major" -eq 5 ] && [ "$ver_minor" -eq 15 ] && [ "$ver_patch" -ge 0 ]; then
    nft_kernel_ok=true
elif [ "$ver_major" -eq 5 ] && [ "$ver_minor" -eq 12 ] && [ "$ver_patch" -ge 13 ]; then
    nft_kernel_ok=true
fi

if $nft_kernel_ok; then
    echo "[+] Kernel version matches known vulnerable ranges"
else
    echo "[-] Kernel version not in vulnerable ranges for nftables UAF"
fi

# Check for nf_tables module
if lsmod | grep -q nf_tables; then
    echo "[+] nf_tables module is loaded"
else
    echo "[-] nf_tables module not loaded"
fi

# Check user namespace support
if [ "$(sysctl -n kernel.unprivileged_userns_clone 2>/dev/null)" = "1" ]; then
    echo "[+] unprivileged_userns_clone is enabled"
else
    echo "[-] unprivileged_userns_clone is disabled"
fi

echo ""

# -------------------------
# CVE-2021-22555
# -------------------------
echo "[+] Checking Netfilter Heap Overflow (CVE-2021-22555)..."

if echo "$KERNEL" | grep -q '^5\.8\.0-'; then
    echo "[+] Kernel 5.8.0-* matches known vulnerable range"
else
    echo "[-] Kernel not in 5.8.0 range"
fi

if lsmod | grep -q ip_tables; then
    echo "[+] ip_tables module is loaded"
else
    echo "[-] ip_tables module not loaded"
fi

if [ "$(sysctl -n kernel.unprivileged_userns_clone 2>/dev/null)" = "1" ]; then
    echo "[+] unprivileged_userns_clone is enabled"
else
    echo "[-] unprivileged_userns_clone is disabled"
fi

echo ""
echo "=============================="
echo "[*] Analysis complete"
echo "=============================="
