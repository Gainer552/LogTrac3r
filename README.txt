# LogTrac3r

**LogTrac3r** is a fast, portable Linux DFIR triage tool. Drop `logtrac3r.sh` on a machine (USB-friendly), run one command, and get a timestamped folder of artifacts plus a single **CSV index** for quick analyst review.

---

## Features
- Collects high-value artifacts: systemd journal, kernel `dmesg`, auth/login history, per-service logs, package logs, audit logs (if enabled), cron, web/server logs, network snapshots, temp file listings, host info.
- Writes **`forensic_summary.csv`** with headers: `category,item,path`.
- Optional **account switch** prompt to run as another user (useful for user history capture).
- Works from **noexec** mounts (run via `bash`).

---

## Requirements
- Linux with systemd/journald.
- Tools: `bash`, `find`, `tar`; optional `ss`, `lsof`, `ausearch`.
- **Root recommended** for full coverage; non-root will miss protected paths.

---

## Quick Start

```bash
# Make executable (optional if running via bash):
chmod +x logtrac3r.sh

# Run (preferred): full coverage as root
sudo bash ./logtrac3r.sh

# Specify output dir and a journal time filter
sudo bash ./logtrac3r.sh /tmp/forensic-$(date +%s) "1 hour ago"

# Running from a USB (noexec-safe)
sudo bash /media/$USER/<USB_LABEL>/logtrac3r.sh /tmp/forensic-$(date +%s)
```

You’ll be asked:
- `Switch account before collecting logs? [y/N]`
- If **y**, provide the username (you’ll be prompted by `su` for that user’s password).

> Tip: For complete system access, answer **N** (stay root).

---

## Output (example)

```
forensic-<timestamp>/
├─ forensic_summary.csv          # CSV index (category,item,path)
├─ journal/ , journal.txt , journal_err.txt
├─ dmesg.txt
├─ sshd.txt , logind.txt , wtmp_last.txt , btmp_lastb.txt , lastlog.txt
├─ svc_<service>.txt             # per-service logs (sshd, docker, nginx, etc.)
├─ pacman.log / dpkg.log / apt-history.log (if present)
├─ audit/ , ausearch_recent.txt  (if auditd present)
├─ crontab_<user>.txt , cron.daily.tgz , cron.hourly.tgz , cron.d.tgz
├─ nginx_logs.tgz / httpd_logs.tgz (if present)
├─ networkmanager.txt , ss.txt , lsof.txt
├─ tmp_recent.txt , vartmp_recent.txt
├─ systemd_units.txt , systemd_enabled.txt
├─ uname.txt , os-release.txt
└─ collector.info
```

CSV schema: `category,item,path`.

---

## Troubleshooting
- **Permission denied (CSV) after switching users**  
  The output dir may be root-owned. Use a path the target user can write to (e.g., their home), or don’t switch.
- **USB won’t execute**  
  Use `sudo bash /path/to/logtrac3r.sh …` (noexec-safe).
- **Missing artifacts**  
  Run as root and choose **N** for switching.

---

## File
- Program name: **LogTrac3r**  
- Script file: **`logtrac3r.sh`**

---

## Legal Disclaimer
This software is provided **“as is”** without warranty of any kind, express or implied, including but not limited to merchantability, fitness for a particular purpose, and non-infringement. You are solely responsible for ensuring you have proper **authorization** to access, collect, store, or transfer data from any system where this tool is run. Use may be subject to laws, regulations, contracts, and organizational policies. The authors and contributors shall **not be liable** for any claims, damages, data loss, legal consequences, or other liability arising from or related to use of this software. **For lawful DFIR and educational purposes only.**
