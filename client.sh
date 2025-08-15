#!/bin/bash
# RHEL 9 LDAP Client Setup Script (without NFS autofs) with LDAP server IP auto-detect

# Variables
LDAP_DOMAIN="content.example.com"
LDAP_BASE="dc=example,dc=com"
LDAP_BIND_DN="cn=manager,$LDAP_BASE"
LDAP_PASSWORD="redhat"
HOMEDIR_PARENT="/home/guests"

# Step 0: Auto-detect LDAP server IP
LDAP_SERVER_IP=$(getent hosts $LDAP_DOMAIN | awk '{print $1}')
if [ -z "$LDAP_SERVER_IP" ]; then
    echo "Error: Could not detect LDAP server IP for $LDAP_DOMAIN"
    exit 1
fi

echo "Detected LDAP server IP: $LDAP_SERVER_IP"

# Step 1: Install required packages
dnf install -y sssd realmd oddjob oddjob-mkhomedir nfs-utils

# Step 2: Configure authselect
authselect select sssd with-mkhomedir --force

# Step 3: Create /etc/sssd/sssd.conf
cat > /etc/sssd/sssd.conf <<EOF
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
EOF

# Step 4: Set permissions and restart SSSD
chmod 600 /etc/sssd/sssd.conf
systemctl restart sssd

# Step 5: Test LDAP setup
echo "LDAP client setup completed. Test with: id <ldap_user> and su - <ldap_user>"
