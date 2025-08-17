#!/bin/bash
# Server-run LDAP setup on Node1 (foreground, output server वर दिसेल)
# Author: Rohan

NODE1="node1.example.com"
SCRIPT_NAME="ldap_client_remote.sh"
REMOTE_LOG="/tmp/ldap_setup.log"

# --------------------------
# Generate remote script on server
# --------------------------
cat <<'EOF_REMOTE' > /tmp/$SCRIPT_NAME
#!/bin/bash

LDAP_DOMAIN="content.example.com"
LDAP_BASE="dc=example,dc=com"
LDAP_BIND_DN="cn=manager,dc=example,dc=com"
LDAP_PASSWORD="redhat"
HOMEDIR_PARENT="/home/guests"
TEMP_REPO="/etc/yum.repos.d/rhel.repo"
LOG_FILE="/tmp/ldap_setup.log"

echo "$(date) - Script started" > $LOG_FILE

# Step 0: Create temporary yum repo
cat > $TEMP_REPO <<EOF
[BaseOS]
name=BaseOS
baseurl=http://content.example.com/rhel9/BaseOS
enabled=1
gpgcheck=0

[AppStream]
name=AppStream
baseurl=http://content.example.com/rhel9/AppStream
enabled=1
gpgcheck=0
EOF
echo "$(date) - Temporary yum repo created." >> $LOG_FILE

# Step 1: Auto-detect LDAP server IP
LDAP_SERVER_IP=$(getent hosts $LDAP_DOMAIN | awk '{print $1}')
if [ -z "$LDAP_SERVER_IP" ]; then
    echo "$(date) - Error: Could not detect LDAP server IP" >> $LOG_FILE
    rm -f $TEMP_REPO
    exit 1
fi
echo "$(date) - Detected LDAP server IP: $LDAP_SERVER_IP" >> $LOG_FILE

# Step 2: Install packages
echo "$(date) - Installing required packages..." >> $LOG_FILE
dnf install -y sssd realmd oddjob oddjob-mkhomedir nfs-utils &>> $LOG_FILE

# Step 3: Configure authselect
echo "$(date) - Configuring authselect..." >> $LOG_FILE
authselect select sssd with-mkhomedir --force &>> $LOG_FILE

# Step 4: Create sssd.conf
cat > /etc/sssd/sssd.conf <<EOF_SSSD
[sssd]
services = nss, pam
config_file_version = 2
domains = LDAP

[domain/LDAP]
id_provider = ldap
auth_provider = ldap
chpass_provider = ldap
ldap_uri = ldap://$LDAP_SERVER_IP
ldap_search_base = $LDAP_BASE
ldap_default_bind_dn = $LDAP_BIND_DN
ldap_default_authtok = $LDAP_PASSWORD
ldap_tls_reqcert = allow
override_homedir = $HOMEDIR_PARENT/%u
enumerate = true
EOF_SSSD

chmod 600 /etc/sssd/sssd.conf
systemctl restart sssd &>> $LOG_FILE

# Step 5: Cleanup temporary repo
rm -f $TEMP_REPO
echo "$(date) - Temporary yum repo deleted." >> $LOG_FILE

echo "$(date) - LDAP client setup completed." >> $LOG_FILE
EOF_REMOTE

# --------------------------
# Copy script to Node1
# --------------------------
scp /tmp/$SCRIPT_NAME $NODE1:/tmp/

# --------------------------
# Run remotely in foreground (server sees output)
# --------------------------
ssh -t $NODE1 "bash /tmp/$SCRIPT_NAME; tail -f /tmp/ldap_setup.log"
