#!/usr/bin/env bash
set -Eeuo pipefail; IFS=$'\n\t'
OUT="${1:-./forensic-$(date +%Y%m%dT%H%M%S)}"; SINCE="${2:-}"; mkdir -p "$OUT"
csv(){ printf '%s,%s,%s\n' "$1" "$2" "$3" >>"$OUT/forensic_summary.csv"; }
printf 'category,item,path\n' >"$OUT/forensic_summary.csv"

read -rp "Switch account before collecting logs? [y/N]: " a
if [[ ${a,,} =~ ^y ]]; then
  read -rp "Username to switch to: " USR; echo "su will prompt for $USR's password..."
  exec su - "$USR" -c "bash -lc 'OUT=\"$OUT\";SINCE=\"\$SINCE\"
csv(){ printf '\''%s,%s,%s\n'\'' \"\$1\" \"\$2\" \"\$3\" >>\"\$OUT/forensic_summary.csv\"; }; [ -s \"\$OUT/forensic_summary.csv\" ]||printf '\''category,item,path\n'\''>\"\$OUT/forensic_summary.csv\"
mkdir -p \"\$OUT\"
# System & Kernel
[ -d /var/log/journal ]&&cp -a /var/log/journal \"\$OUT/\" 2>/dev/null||: ; csv \"System & Kernel\" \"/var/log/journal/\" \"\$OUT/journal/\" 
journalctl --no-pager \${SINCE:+--since \"\$SINCE\"} >\"\$OUT/journal.txt\" 2>&1||: ; csv \"System & Kernel\" \"journalctl (all)\" \"\$OUT/journal.txt\"
journalctl -p err..alert \${SINCE:+--since \"\$SINCE\"} >\"\$OUT/journal_err.txt\" 2>&1||: ; csv \"System & Kernel\" \"journalctl (err..alert)\" \"\$OUT/journal_err.txt\"
dmesg --ctime >\"\$OUT/dmesg.txt\" 2>&1||: ; csv \"System & Kernel\" \"dmesg\" \"\$OUT/dmesg.txt\"
# Auth & Users
journalctl --no-pager _COMM=sshd \${SINCE:+--since \"\$SINCE\"} >\"\$OUT/sshd.txt\" 2>&1||: ; csv \"Auth & Users\" \"journalctl _COMM=sshd\" \"\$OUT/sshd.txt\"
journalctl -u systemd-logind \${SINCE:+--since \"\$SINCE\"} >\"\$OUT/logind.txt\" 2>&1||: ; csv \"Auth & Users\" \"systemd-logind\" \"\$OUT/logind.txt\"
last -w -f /var/log/wtmp >\"\$OUT/wtmp_last.txt\" 2>&1||: ; csv \"Auth & Users\" \"/var/log/wtmp (last)\" \"\$OUT/wtmp_last.txt\"
lastb -f /var/log/btmp >\"\$OUT/btmp_lastb.txt\" 2>&1||: ; csv \"Auth & Users\" \"/var/log/btmp (lastb)\" \"\$OUT/btmp_lastb.txt\"
lastlog >\"\$OUT/lastlog.txt\" 2>&1||: ; csv \"Auth & Users\" \"lastlog\" \"\$OUT/lastlog.txt\"
(for h in .bash_history .zsh_history .local/share/fish/history; do [ -f \"\$HOME/\$h\" ]&&cp \"\$HOME/\$h\" \"\$OUT/\$(whoami)_\${h//\//_}\"; done) 2>/dev/null||:
csv \"Auth & Users\" \"$(whoami) shell histories\" \"\$OUT/\$(whoami)_*history*\"
# System & Services
systemctl list-unit-files --state=enabled >\"\$OUT/systemd_enabled.txt\" 2>&1||: ; csv \"System & Services\" \"enabled units\" \"\$OUT/systemd_enabled.txt\"
for s in sshd nginx apache2 httpd docker NetworkManager systemd-resolved ssh cron rsyslog; do journalctl -u \"\$s\" \${SINCE:+--since \"\$SINCE\"} >\"\$OUT/svc_\$s.txt\" 2>&1||: ; csv \"System & Services\" \"journalctl -u \$s\" \"\$OUT/svc_\$s.txt\"; done
journalctl --no-pager -p err..alert \${SINCE:+--since \"\$SINCE\"} >\"\$OUT/errors.txt\" 2>&1||: ; csv \"System & Services\" \"errors (err..alert)\" \"\$OUT/errors.txt\"
# Packages
[ -f /var/log/pacman.log ]&&cp /var/log/pacman.log \"\$OUT/\"; [ -f /var/log/dpkg.log ]&&cp /var/log/dpkg.log \"\$OUT/\"; [ -f /var/log/apt/history.log ]&&cp /var/log/apt/history.log \"\$OUT/apt-history.log\"
[ -f \"\$OUT/pacman.log\" ]&&csv \"Packages\" \"pacman.log\" \"\$OUT/pacman.log\"
[ -f \"\$OUT/dpkg.log\" ]&&csv \"Packages\" \"dpkg.log\" \"\$OUT/dpkg.log\"
[ -f \"\$OUT/apt-history.log\" ]&&csv \"Packages\" \"apt history.log\" \"\$OUT/apt-history.log\"
# Audit
[ -d /var/log/audit ]&&{ cp -a /var/log/audit \"\$OUT/\" 2>/dev/null||:; csv \"Security & Audit\" \"/var/log/audit/\" \"\$OUT/audit/\"; }
ausearch --start recent >\"\$OUT/ausearch_recent.txt\" 2>/dev/null||: ; [ -s \"\$OUT/ausearch_recent.txt\" ]&&csv \"Security & Audit\" \"ausearch recent\" \"\$OUT/ausearch_recent.txt\"
# Scheduled
crontab -l >\"\$OUT/crontab_$(whoami).txt\" 2>&1||: ; csv \"Scheduled Tasks\" \"crontab ($(whoami))\" \"\$OUT/crontab_$(whoami).txt\"
for d in /etc/cron.daily /etc/cron.hourly /etc/cron.d; do [ -d \"\$d\" ]&&{ tar -czf \"\$OUT/\$(basename \$d).tgz\" -C \"\$(dirname \$d)\" \"\$(basename \$d)\" 2>/dev/null||:; csv \"Scheduled Tasks\" \"\$d\" \"\$OUT/\$(basename \$d).tgz\"; }; done
# Web/Network
[ -d /var/log/nginx ]&&{ tar -czf \"\$OUT/nginx_logs.tgz\" -C /var/log nginx 2>/dev/null||:; csv \"Web/Network\" \"/var/log/nginx\" \"\$OUT/nginx_logs.tgz\"; }
[ -d /var/log/httpd ]&&{ tar -czf \"\$OUT/httpd_logs.tgz\" -C /var/log httpd 2>/dev/null||:; csv \"Web/Network\" \"/var/log/httpd\" \"\$OUT/httpd_logs.tgz\"; }
journalctl -u NetworkManager \${SINCE:+--since \"\$SINCE\"} >\"\$OUT/networkmanager.txt\" 2>&1||: ; csv \"Web/Network\" \"NetworkManager\" \"\$OUT/networkmanager.txt\"
(ss -tunap >\"\$OUT/ss.txt\" 2>/dev/null||:; [ -s \"\$OUT/ss.txt\" ]&&csv \"Web/Network\" \"ss -tunap\" \"\$OUT/ss.txt\")
(lsof -Pn >\"\$OUT/lsof.txt\" 2>/dev/null||:; [ -s \"\$OUT/lsof.txt\" ]&&csv \"Web/Network\" \"lsof -Pn\" \"\$OUT/lsof.txt\")
# Other Useful
find /tmp -maxdepth 2 -type f -printf '\''%T@ %p %s\n'\''|sort -nr|head -n500 >\"\$OUT/tmp_recent.txt\" 2>&1||: ; csv \"Other Useful\" \"tmp recent files\" \"\$OUT/tmp_recent.txt\"
find /var/tmp -maxdepth 2 -type f -printf '\''%T@ %p %s\n'\''|sort -nr|head -n500 >\"\$OUT/vartmp_recent.txt\" 2>&1||: ; csv \"Other Useful\" \"var/tmp recent files\" \"\$OUT/vartmp_recent.txt\"
systemctl list-units --all >\"\$OUT/systemd_units.txt\" 2>&1||: ; csv \"Other Useful\" \"all units\" \"\$OUT/systemd_units.txt\"
uname -a >\"\$OUT/uname.txt\"; csv \"Host Info\" \"uname\" \"\$OUT/uname.txt\"
cat /etc/os-release >\"\$OUT/os-release.txt\" 2>/dev/null||: ; csv \"Host Info\" \"/etc/os-release\" \"\$OUT/os-release.txt\"
echo \"collected-by=\$(whoami)\" >\"\$OUT/collector.info\"; csv \"Meta\" \"collector\" \"\$OUT/collector.info\"
echo \"Done. Output: \$OUT\"'"; exit; fi

# ===== current-user (no switch) =====
# System & Kernel
[ -d /var/log/journal ]&&cp -a /var/log/journal "$OUT/" 2>/dev/null||: ; csv "System & Kernel" "/var/log/journal/" "$OUT/journal/"
journalctl --no-pager ${SINCE:+--since "$SINCE"} >"$OUT/journal.txt" 2>&1||: ; csv "System & Kernel" "journalctl (all)" "$OUT/journal.txt"
journalctl -p err..alert ${SINCE:+--since "$SINCE"} >"$OUT/journal_err.txt" 2>&1||: ; csv "System & Kernel" "journalctl (err..alert)" "$OUT/journal_err.txt"
dmesg --ctime >"$OUT/dmesg.txt" 2>&1||: ; csv "System & Kernel" "dmesg" "$OUT/dmesg.txt"
# Auth & Users
journalctl --no-pager _COMM=sshd ${SINCE:+--since "$SINCE"} >"$OUT/sshd.txt" 2>&1||: ; csv "Auth & Users" "journalctl _COMM=sshd" "$OUT/sshd.txt"
journalctl -u systemd-logind ${SINCE:+--since "$SINCE"} >"$OUT/logind.txt" 2>&1||: ; csv "Auth & Users" "systemd-logind" "$OUT/logind.txt"
last -w -f /var/log/wtmp >"$OUT/wtmp_last.txt" 2>&1||: ; csv "Auth & Users" "/var/log/wtmp (last)" "$OUT/wtmp_last.txt"
lastb -f /var/log/btmp >"$OUT/btmp_lastb.txt" 2>&1||: ; csv "Auth & Users" "/var/log/btmp (lastb)" "$OUT/btmp_lastb.txt"
lastlog >"$OUT/lastlog.txt" 2>&1||: ; csv "Auth & Users" "lastlog" "$OUT/lastlog.txt"
for u in $(awk -F: '$3>=1000{print $1}' /etc/passwd); do h=$(getent passwd "$u"|cut -d: -f6); for f in .bash_history .zsh_history .local/share/fish/history; do [ -f "$h/$f" ]&&cp "$h/$f" "$OUT/${u}_${f//\//_}" 2>/dev/null||:; done; [ -d "$h/.ssh" ]&&ls -la "$h/.ssh" >"$OUT/${u}_ssh_list.txt" 2>/dev/null||:; done
csv "Auth & Users" "users' histories & ssh listings" "$OUT/*history*"
# System & Services
systemctl list-unit-files --state=enabled >"$OUT/systemd_enabled.txt" 2>&1||: ; csv "System & Services" "enabled units" "$OUT/systemd_enabled.txt"
for s in sshd nginx apache2 httpd docker NetworkManager systemd-resolved ssh cron rsyslog; do journalctl -u "$s" ${SINCE:+--since "$SINCE"} >"$OUT/svc_$s.txt" 2>&1||: ; csv "System & Services" "journalctl -u $s" "$OUT/svc_$s.txt"; done
journalctl --no-pager -p err..alert ${SINCE:+--since "$SINCE"} >"$OUT/errors.txt" 2>&1||: ; csv "System & Services" "errors (err..alert)" "$OUT/errors.txt"
# Packages
[ -f /var/log/pacman.log ]&&{ cp /var/log/pacman.log "$OUT/"; csv "Packages" "pacman.log" "$OUT/pacman.log"; }
[ -f /var/log/dpkg.log ]&&{ cp /var/log/dpkg.log "$OUT/"; csv "Packages" "dpkg.log" "$OUT/dpkg.log"; }
[ -f /var/log/apt/history.log ]&&{ cp /var/log/apt/history.log "$OUT/apt-history.log"; csv "Packages" "apt history.log" "$OUT/apt-history.log"; }
# Audit
[ -d /var/log/audit ]&&{ cp -a /var/log/audit "$OUT/" 2>/dev/null||:; csv "Security & Audit" "/var/log/audit/" "$OUT/audit/"; }
ausearch --start recent >"$OUT/ausearch_recent.txt" 2>/dev/null||: ; [ -s "$OUT/ausearch_recent.txt" ]&&csv "Security & Audit" "ausearch recent" "$OUT/ausearch_recent.txt"
# Scheduled
crontab -l >"$OUT/crontab_root.txt" 2>&1||: ; csv "Scheduled Tasks" "crontab (root)" "$OUT/crontab_root.txt"
for d in /etc/cron.daily /etc/cron.hourly /etc/cron.d; do [ -d "$d" ]&&{ tar -czf "$OUT/$(basename $d).tgz" -C "$(dirname $d)" "$(basename $d)" 2>/dev/null||:; csv "Scheduled Tasks" "$d" "$OUT/$(basename $d).tgz"; }; done
# Web/Network
[ -d /var/log/nginx ]&&{ tar -czf "$OUT/nginx_logs.tgz" -C /var/log nginx 2>/dev/null||:; csv "Web/Network" "/var/log/nginx" "$OUT/nginx_logs.tgz"; }
[ -d /var/log/httpd ]&&{ tar -czf "$OUT/httpd_logs.tgz" -C /var/log httpd 2>/dev/null||:; csv "Web/Network" "/var/log/httpd" "$OUT/httpd_logs.tgz"; }
journalctl -u NetworkManager ${SINCE:+--since "$SINCE"} >"$OUT/networkmanager.txt" 2>&1||: ; csv "Web/Network" "NetworkManager" "$OUT/networkmanager.txt"
(ss -tunap >"$OUT/ss.txt" 2>/dev/null||:; [ -s "$OUT/ss.txt" ]&&csv "Web/Network" "ss -tunap" "$OUT/ss.txt")
(lsof -Pn >"$OUT/lsof.txt" 2>/dev/null||:; [ -s "$OUT/lsof.txt" ]&&csv "Web/Network" "lsof -Pn" "$OUT/lsof.txt")
# Other Useful
find /tmp -maxdepth 2 -type f -printf '%T@ %p %s\n'|sort -nr|head -n500 >"$OUT/tmp_recent.txt" 2>&1||: ; csv "Other Useful" "tmp recent files" "$OUT/tmp_recent.txt"
find /var/tmp -maxdepth 2 -type f -printf '%T@ %p %s\n'|sort -nr|head -n500 >"$OUT/vartmp_recent.txt" 2>&1||: ; csv "Other Useful" "var/tmp recent files" "$OUT/vartmp_recent.txt"
systemctl list-units --all >"$OUT/systemd_units.txt" 2>&1||: ; csv "Other Useful" "all units" "$OUT/systemd_units.txt"
uname -a >"$OUT/uname.txt"; csv "Host Info" "uname" "$OUT/uname.txt"
cat /etc/os-release >"$OUT/os-release.txt" 2>/dev/null||: ; csv "Host Info" "/etc/os-release" "$OUT/os-release.txt"
echo "collected-by=$(whoami)" >"$OUT/collector.info"; csv "Meta" "collector" "$OUT/collector.info"
echo "Done. Output: $OUT  |  CSV: $OUT/forensic_summary.csv"
