#!/bin/bash
# LDAP + NFS Setup Verification Script
# Author: Rohan Kumbhar
# Usage: sudo ./verify.sh

set -e

LDAP_BASE="dc=example,dc=com"
USERS_OU="ou=Users,$LDAP_BASE"
GROUPS_OU="ou=Groups,$LDAP_BASE"
GUEST_DIR="/home/guests"
NFS_ALLOWED_NET="192.168.183.0/24"

echo "=== LDAP + NFS Verification Script ==="
echo

# 1️⃣ Check slapd service
echo "1️⃣ Checking slapd service..."
if systemctl is-active --quiet slapd; then
    echo "✅ slapd is running"
else
    echo "❌ slapd is NOT running"
fi
echo

# 2️⃣ Check LDAP ports
echo "2️⃣ Checking LDAP ports..."
LDAP_PORTS=$(ss -lt | grep ldap || true)
if [[ $LDAP_PORTS == *"ldap"* ]]; then
    echo "✅ LDAP ports listening"
else
    echo "❌ LDAP ports NOT listening"
fi
echo "$LDAP_PORTS"
echo

# 3️⃣ LDAP search test
echo "3️⃣ Checking LDAP entries..."
USERS_COUNT=$(ldapsearch -x -LLL -b "$USERS_OU" dn 2>/dev/null | grep "^dn:" | wc -l)
GROUPS_COUNT=$(ldapsearch -x -LLL -b "$GROUPS_OU" dn 2>/dev/null | grep "^dn:" | wc -l)

if [ "$USERS_COUNT" -gt 0 ]; then
    echo "✅ Users OU has $USERS_COUNT entries"
else
    echo "❌ Users OU is empty"
fi

if [ "$GROUPS_COUNT" -gt 0 ]; then
    echo "✅ Groups OU has $GROUPS_COUNT entries"
else
    echo "❌ Groups OU is empty"
fi
echo

# 4️⃣ Check guest users locally
echo "4️⃣ Checking local guest users..."
for i in {1..5}; do
    if id ldapuser$i &>/dev/null; then
        echo "✅ ldapuser$i exists"
    else
        echo "❌ ldapuser$i NOT found"
    fi
done
echo

# 5️⃣ Check NFS exports
echo "5️⃣ Checking NFS exports..."
EXPORTS=$(showmount -e | grep "$GUEST_DIR" || true)
if [[ $EXPORTS == *"$GUEST_DIR"* ]]; then
    echo "✅ NFS export exists for $GUEST_DIR"
    echo "$EXPORTS"
else
    echo "❌ NFS export NOT found for $GUEST_DIR"
fi
echo

# 6️⃣ Check firewall rules
echo "6️⃣ Checking firewall rules..."
FIREWALL_SERVICES=$(firewall-cmd --list-services)
for svc in ldap ldaps nfs rpc-bind mountd; do
    if [[ $FIREWALL_SERVICES == *"$svc"* ]]; then
        echo "✅ $svc service open in firewall"
    else
        echo "❌ $svc service NOT open in firewall"
    fi
done
echo

# 7️⃣ Check LDAP logs for errors (last 20 lines)
echo "7️⃣ Checking last 20 lines of LDAP log..."
if [ -f /var/log/ldap.log ]; then
    tail -20 /var/log/ldap.log
else
    echo "⚠️ LDAP log file /var/log/ldap.log not found"
fi

echo
echo "✅ Verification Completed!"

