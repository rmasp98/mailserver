#!/bin/sh

cat << EOF > /etc/dovecot/dovecot-sql.conf.ext
driver = mysql
connect = host=mariadb dbname=mailserver user=dovecot password=${DB_PASS}
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email as user, password FROM users WHERE email='%u';
EOF

unset DB_PASS

mkdir /postfix
mkdir /var/mail/vhosts/ && chown vmail:vmail /var/mail/vhosts

# This monitors for changes to certificates and reloads dovecot
ls -d /ssl/* | entr dovecot reload &
/usr/sbin/dovecot -F
