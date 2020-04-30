#!/bin/bash

# Ensure the primary LDAP DC is resolvable by adding it to /etc/hosts
/bin/cat <<EOM >>/etc/hosts
$(jetpack config adauth.ldapUriIp)   $(jetpack config adauth.ldapUri)
EOM

# Install and config SSSD
yum install sssd-ldap sssd-tools oddjob-mkhomedir -y
authconfig --enablesssd --enablesssdauth --disablesmartcard --enablemkhomedir --disablefingerprint --updateall

# Copy the Cyclecloud provided sssd.conf to /etc/sssd and set permissions
cp $CYCLECLOUD_SPEC_PATH/files/sssd.conf /etc/sssd/sssd.conf
chown root:root /etc/sssd/sssd.conf
chmod 600 /etc/sssd/sssd.conf

# Replace the stock LDAP URI with Cycle provided value
sed -i "s|host1.testdomain.com|$(jetpack config adauth.ldapUri)|g" /etc/sssd/sssd.conf 

# Conditionally remove or set the LDAP backup DC
if [ $(jetpack config adauth.ldapBackupUri) == "None" ]; then
  sed -i '/ldap_backup_uri/d' /etc/sssd/sssd.conf  
else
  sed -i "s|host2.testdomain.com|$(jetpack config adauth.ldapBackupUri)|g" /etc/sssd/sssd.conf
  /bin/cat <<EOM >>/etc/hosts
  $(jetpack config adauth.ldapBackupUriIp)   $(jetpack config adauth.ldapBackupUri)
EOM
fi

# Conditionally set CA cert directory
if [ $(jetpack config adauth.ldapCaCertDir) == "None" ]; then
  sed -i '/ldap_tls_cacertdir/d' /etc/sssd/sssd.conf  
else
  sed -i "s|/etc/openldap/certs|$(jetpack config adauth.ldapCaCertDir)|g" /etc/sssd/sssd.conf
fi

# Replace stock values in sssd.conf with Cycle provided values
sed -i "s|testdomain.com|$(jetpack config adauth.ldapDomain)|g" /etc/sssd/sssd.conf 
sed -i "s|ou=usr,dc=testdomain,dc=com|$(jetpack config adauth.ldapUserSearchBase)|g" /etc/sssd/sssd.conf
sed -i "s|ou=groups,dc=testdomain,dc=com|$(jetpack config adauth.ldapGroupSearchBase)|g" /etc/sssd/sssd.conf
sed -i "s|8675309|$(jetpack config adauth.ldapOverrideGid)|g" /etc/sssd/sssd.conf
sed -i "s|memberOf=cn=HPC_Admins_G,ou=HPC,ou=Groups,dc=testdomain,dc=com|$(jetpack config adauth.ldapAccessFilter)|g" /etc/sssd/sssd.conf
sed -i "s|adauth.ldapUser|$(jetpack config adauth.ldapUser)|g" /etc/sssd/sssd.conf 
sed -i "s|adauth.ldapPassword|$(jetpack config adauth.ldapPassword)|g" /etc/sssd/sssd.conf 

# Restart SSSD
systemctl stop sssd
systemctl start sssd

# Enable SSH Password Authentication
sed -i 's|PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config
systemctl stop sshd
systemctl start sshd
