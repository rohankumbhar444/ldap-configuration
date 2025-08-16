#!/bin/bash
# ==========================================================
# Distributed Exam Lab Setup Script (via root SSH)
# Author: Rohan Kumbhar
# Purpose: Setup Q3, Q10, Q11, Test Files on node1 and Q18 on node2
# ==========================================================

NODE1="node1"
NODE2="node2"
USER="root"

echo "=== MASTER: Starting Distributed Exam Lab Setup ==="

# -----------------------------
# NODE1 Setup: Q3, Q10, Q11, Test Files
# -----------------------------
ssh $USER@$NODE1 'bash -s' <<'EOF'
echo "=== NODE1: Exam Lab Setup Started ==="

# Q3: SELinux Debug Lab
echo "=== Q3: SELinux Debug Lab Setup ==="
dnf install -y httpd policycoreutils-python-utils firewalld

mkdir -p /var/www/html
cat > /var/www/html/index.html <<EOT
<h1>Welcome to Apache Server</h1>
<h2>Your answer is right</h2>
<h3>Best of Luck</h3>
EOT

sed -i 's/^Listen 80/Listen 82/' /etc/httpd/conf/httpd.conf
semanage port -d -t http_port_t -p tcp 82 2>/dev/null
systemctl enable --now firewalld
firewall-cmd --permanent --remove-port=82/tcp
firewall-cmd --reload
systemctl stop httpd
systemctl disable httpd
setenforce 1
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

echo "Q3 Setup Complete. Student Hints:"
echo "1. Allow Apache on port 82 in SELinux"
echo "2. Open firewall for port 82"
echo "3. Start and enable Apache"
echo "4. Verify /var/www/html content"
echo "------------------------------------------------"

# Q11: 'ich' Words Lab
echo "=== Q11: Words Lab Setup ==="
WORDS_FILE="/usr/share/dict/words"
mkdir -p /usr/share/dict

cat > $WORDS_FILE <<EOT
sandwich
rich
switch
pitch
stitch
glitch
niche
lich
bitch
witch
itchy
kitchen
mitch
dichotomy
richter
fichu
radich
trichome
richness
unethical
apple
banana
orange
grape
technology
network
linux
server
student
teacher
EOT

chmod 644 $WORDS_FILE
rm -f /root/lines

echo "Q11 Setup Complete. Student Tasks:"
echo "1. Search for 'ich' in $WORDS_FILE"
echo "2. Save results to /root/lines"
echo "------------------------------------------------"

# Test Files Creation
echo "=== Creating Test Files ==="
DIR="/usr/local/testfile"
mkdir -p $DIR

for i in {1..10}; do
    dd if=/dev/urandom of=$DIR/file_gt30k_$i bs=1K count=$((RANDOM % 20 + 31)) status=none
done

for i in {1..10}; do
    dd if=/dev/urandom of=$DIR/file_lt30k_$i bs=1K count=$((RANDOM % 29 + 1)) status=none
done

for i in {1..10}; do
    dd if=/dev/urandom of=$DIR/file_lt50k_$i bs=1K count=$((RANDOM % 19 + 31)) status=none
done

for i in {1..10}; do
    dd if=/dev/urandom of=$DIR/file_gt50k_$i bs=1K count=$((RANDOM % 50 + 51)) status=none
done

echo "Test Files Created:"
ls -lh $DIR
echo "------------------------------------------------"

# Q10: Wait for 'harry' and Setup
echo "=== Q10: Waiting for user 'harry' ==="
MAX_WAIT=300
WAIT_INTERVAL=5
ELAPSED=0

while (( ELAPSED < MAX_WAIT )); do
    if id harry &>/dev/null; then
        echo "User 'harry' found. Setting up Q10..."
        mkdir -p /home/harry/testfiles
        chown -R harry:harry /home/harry/testfiles

        touch /home/harry/testfiles/file1 /home/harry/testfiles/file2
        chown harry:harry /home/harry/testfiles/file1 /home/harry/testfiles/file2

        cp /bin/ping /home/harry/testfiles/ping_suid
        cp /usr/bin/passwd /home/harry/testfiles/passwd_suid
        chown harry:harry /home/harry/testfiles/ping_suid /home/harry/testfiles/passwd_suid
        chmod u+s /home/harry/testfiles/ping_suid /home/harry/testfiles/passwd_suid

        echo "Q10 Setup Complete. Student Tasks:"
        echo "1. Find SUID files owned by harry"
        echo "2. Copy them to /root/harry-files"
        break
    fi
    sleep $WAIT_INTERVAL
    (( ELAPSED += WAIT_INTERVAL ))
done

if (( ELAPSED >= MAX_WAIT )); then
    echo "Timeout waiting for user 'harry'. Skipping Q10 setup."
fi

echo "=== NODE1 Setup Finished ==="
EOF

# -----------------------------
# NODE2 Setup: Q18
# -----------------------------
ssh $USER@$NODE2 'bash -s' <<'EOF'
echo "=== NODE2: Q18 Logical Volume Setup ==="

dd if=/dev/zero of=/root/lvm_disk.img bs=1M count=500
losetup -fP /root/lvm_disk.img
LOOPDEV=$(losetup -j /root/lvm_disk.img | cut -d: -f1)
echo "Loop device: $LOOPDEV"

pvcreate $LOOPDEV
vgcreate myvg $LOOPDEV
lvcreate -n mylv -L 250M myvg

mkfs.xfs /dev/myvg/mylv
mkdir -p /mnt/mylv
mount /dev/myvg/mylv /mnt/mylv

UUID=$(blkid -s UUID -o value /dev/myvg/mylv)
echo "UUID=$UUID /mnt/mylv xfs defaults 0 0" >> /etc/fstab

echo "Q18 Setup Done. Student Task:"
echo "Resize 'mylv' to 290MB–330MB after reboot"
echo "=== NODE2 Setup Finished ==="
EOF

echo "=== MASTER: All Nodes Setup Complete ==="
