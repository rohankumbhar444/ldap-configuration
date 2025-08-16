#!/bin/bash
# ==========================================================
# Distributed Exam Lab Cleanup Script
# Author: Rohan Kumbhar
# Purpose: Clean Q3, Q10, Q11, Test Files from node1 and Q18 from node2
# ==========================================================

echo "=== COMPLETE EXAM LAB CLEANUP STARTED ==="

NODE1="node1"
NODE2="node2"

# -----------------------------
# Cleanup on node1
# -----------------------------
echo "=== Cleaning Q3, Q10, Q11, Test Files on $NODE1 ==="

ssh $NODE1 bash <<'EOF'
set -e

echo "--- Stopping and disabling Apache/firewalld ---"
systemctl stop httpd firewalld || true
systemctl disable httpd firewalld || true

echo "--- Removing Apache and related packages ---"
dnf remove -y httpd policycoreutils-python-utils firewalld || true

echo "--- Removing Apache content and config ---"
rm -rf /var/www/html
sed -i '/^Listen 82/d' /etc/httpd/conf/httpd.conf || true

echo "--- Resetting SELinux config ---"
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config || true
setenforce 0

echo "--- Removing semanage port rule ---"
semanage port -a -t http_port_t -p tcp 82 || true  # Re-adding default if needed

echo "--- Removing Q11 word file ---"
rm -f /usr/share/dict/words
rm -f /root/lines

echo "--- Removing test files ---"
rm -rf /usr/local/testfile

echo "--- Removing Q10 files for user 'harry' ---"
rm -rf /home/harry/testfiles

echo "Cleanup on node1 complete."
EOF

echo "------------------------------------------------"

# -----------------------------
# Cleanup on node2
# -----------------------------
echo "=== Cleaning Q18 Logical Volume on $NODE2 ==="

ssh $NODE2 bash <<'EOF'
set -e

echo "--- Unmounting and removing logical volume ---"
umount /mnt/mylv || true
lvremove -y /dev/myvg/mylv || true
vgremove -y myvg || true
pvremove -y /dev/loop* || true

echo "--- Removing loop device and image file ---"
losetup -D || true
rm -f /root/lvm_disk.img
rm -rf /mnt/mylv

echo "--- Removing fstab entry ---"
sed -i '/\/mnt\/mylv/d' /etc/fstab

echo "Cleanup on node2 complete."
EOF

echo "------------------------------------------------"
echo "=== COMPLETE EXAM LAB CLEANUP FINISHED ==="
~                                                         
