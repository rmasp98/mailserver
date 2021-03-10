#!/bin/sh

cat << EOF > /etc/dovecot/dovecot-sql.conf.ext
driver = mysql
connect = host=mariadb dbname=mailserver user=dovecot password=${DB_PASS}
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email as user, password FROM users WHERE email='%u' and enabled = true;
user_query = SELECT concat('*:storage=', quota, 'M') AS quota_rule FROM users WHERE email='%u';
EOF

cat << EOF > /etc/dovecot/dovecot-sql-master.conf.ext
driver = mysql
connect = host=mariadb dbname=mailserver user=dovecot password=${DB_PASS}
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email as user, password FROM users WHERE email='%u' and '%u'='postmaster@master';
EOF

mkdir -p /var/mail/sieve/global

# Creates password file for rspamd controller
echo ${CONTROLLER_PASS} > /var/mail/sieve/global/controller_password
chmod 400 /var/mail/sieve/global/controller_password
unset CONTROLLER_PASS

# Copy default sieve files to main sieve directory
cp /etc/dovecot/sieve/* /var/mail/sieve/global/
chmod 500 /var/mail/sieve/global/rspamd-curl.sh
chown vmail:vmail -R /var/mail

# Create cron job to retrieve mail from other servers
echo -e "*/15\t*\t*\t*\t*\t/var/imapsync/mail-sync.sh" > /etc/crontabs/imapsync

# Save postmaster password to file for imapsync 
echo ${POSTMASTER_PASS} > /var/imapsync/postmaster-pass
chmod -R go-rwx /var/imapsync
chmod  u+x /var/imapsync/mail-sync.sh
chown -R imapsync /var/imapsync

# This monitors for changes to certificates and reloads dovecot
find /ssl | entr dovecot reload &
crond -L /dev/stdout -b
/usr/sbin/dovecot -F
