#!/bin/bash

cat << EOF > /etc/postfix/vdomains.cf
user = postfix
password = ${DB_PASS}
hosts = mariadb
dbname = mailserver
query = SELECT 1 FROM domains WHERE domain='%s'
EOF

cat << EOF > /etc/postfix/vmailbox-maps.cf
user = postfix
password = ${DB_PASS}
hosts = mariadb
dbname = mailserver
query = SELECT 1 FROM users WHERE email='%s'
EOF

cat << EOF > /etc/postfix/valias-maps.cf
user = postfix
password = ${DB_PASS}
hosts = mariadb
dbname = mailserver
require_result_set = no
query = CALL GetEmailFromAlias('%s')
EOF

unset DB_PASS

syslogd
postgrey -u /var/spool/postfix/postgrey.sock -d
postfix start-fg
