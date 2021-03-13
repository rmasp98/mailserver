#!/bin/sh

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
query = SELECT 1 FROM users WHERE email='%s' and enabled=true
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

if [[ ${PRODUCTION} == 0 ]]; then
    # Disables all recieving security so we can test
    cp /etc/postfix/main-test.cf /etc/postfix/main.cf
fi

chmod -R o-rwx /etc/postfix

syslogd -O -

# Run CMD
exec "$@"
