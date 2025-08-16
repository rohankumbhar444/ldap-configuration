#!/bin/bash
# full_check_debug.sh - Automated EXAM check on 2 nodes with proper TMARKS capture
# Author: Rohan Kumbhar
# Total Marks: 300, Passing: 210

NODE1="node1.example.com"
NODE2="node2.example.com"

PASS=210

echo "=== EXAM CHECK START ==="
echo ""

# --- Node1 Checks ---
check_node1() {
ssh "$NODE1" bash <<'ENDSSH'
TMARKS=0
echo "=== Checking Node1: Q1–Q15 ==="

# Q1 Network + Hostname
ip addr show | grep "192.168.183.154" &>/dev/null
hostnamectl status | grep "content.example.com" &>/dev/null
[[ $? -eq 0 ]] && TMARKS=$((TMARKS+15)) && echo "Q1 OK (15)" || echo "Q1 FAIL"

# Q2 YUM repos
grep "BaseOS" /etc/yum.repos.d/*.repo &>/dev/null
grep "AppStream" /etc/yum.repos.d/*.repo &>/dev/null
[[ $? -eq 0 ]] && TMARKS=$((TMARKS+10)) && echo "Q2 OK (10)" || echo "Q2 FAIL"

# Q3 SELinux + Webserver
ss -tulpn | grep ":82" &>/dev/null
systemctl is-active httpd &>/dev/null
[[ $? -eq 0 ]] && TMARKS=$((TMARKS+15)) && echo "Q3 OK (15)" || echo "Q3 FAIL"

# (Add Q4–Q15 similarly...)

# Finally print only TMARKS number for outer capture
echo $TMARKS
ENDSSH
}

# --- Node2 Checks ---
check_node2() {
ssh "$NODE2" bash <<'ENDSSH'
TMARKS=0
echo "=== Checking Node2: Q16–Q23 ==="

# Q16 Root password
echo "trootnet" | sudo -S -l &>/dev/null
[[ $? -eq 0 ]] && TMARKS=$((TMARKS+10)) && echo "Q16 OK (10)" || echo "Q16 FAIL"

# Q17 YUM repos
grep "BaseOS" /etc/yum.repos.d/*.repo &>/dev/null
grep "AppStream" /etc/yum.repos.d/*.repo &>/dev/null
[[ $? -eq 0 ]] && TMARKS=$((TMARKS+10)) && echo "Q17 OK (10)" || echo "Q17 FAIL"

# Q18 LV resize
if lvs myvg/mylv &>/dev/null; then
  SIZE=$(lvs --noheadings -o LV_SIZE --units M --nosuffix myvg/mylv | awk '{print int($1)}')
  [[ $SIZE -ge 290 && $SIZE -le 330 ]] && TMARKS=$((TMARKS+15)) && echo "Q18 OK (15)" || echo "Q18 FAIL"
else
  echo "Q18 FAIL: myvg/mylv not found"
fi

# Q19 Swap 512MB
swapon --show | grep "512M" &>/dev/null
[[ $? -eq 0 ]] && TMARKS=$((TMARKS+10)) && echo "Q19 OK (10)" || echo "Q19 FAIL"

# Q20 LV wshare mounted
mount | grep "/mnt/wshare" &>/dev/null
[[ $? -eq 0 ]] && TMARKS=$((TMARKS+10)) && echo "Q20 OK (10)" || echo "Q20 FAIL"

# Q21 Tuned profile
if command -v tuned-adm &>/dev/null; then
  tuned-adm active | grep recommended &>/dev/null
  [[ $? -eq 0 ]] && TMARKS=$((TMARKS+5)) && echo "Q21 OK (5)" || echo "Q21 FAIL"
else
  echo "Q21 FAIL: tuned-adm not installed"
fi

# Q22 sudo sysadmin
if id natasha &>/dev/null; then
  sudo -l -U natasha | grep "NOPASSWD" &>/dev/null
  [[ $? -eq 0 ]] && TMARKS=$((TMARKS+5)) && echo "Q22 OK (5)" || echo "Q22 FAIL"
else
  echo "Q22 FAIL: user natasha not found"
fi

# Q23 Password expiry
if id natasha &>/dev/null; then
  EXPIRE=$(chage -l natasha | grep "Maximum" | awk '{print $NF}')
  [[ $EXPIRE -eq 30 ]] && TMARKS=$((TMARKS+5)) && echo "Q23 OK (5)" || echo "Q23 FAIL"
else
  echo "Q23 FAIL: user natasha not found"
fi

# Finally print only TMARKS number for outer capture
echo $TMARKS
ENDSSH
}

# --- Run Checks ---
echo "Running Node1 checks..."
N1_MARKS=$(check_node1)
N1_MARKS=$(echo "$N1_MARKS" | tail -1)   # only the number

echo "Running Node2 checks..."
N2_MARKS=$(check_node2)
N2_MARKS=$(echo "$N2_MARKS" | tail -1)   # only the number

TOTAL=$((N1_MARKS + N2_MARKS))
echo ""
echo "=== FINAL RESULT ==="
echo "Total Marks: $TOTAL / 300"
if [[ $TOTAL -ge $PASS ]]; then
    echo "Result: PASS ✅"
else
    echo "Result: FAIL ❌"
fi
