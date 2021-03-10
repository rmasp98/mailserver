#!/bin/sh

if [ ! -d "/var/lib/mysql/mailserver" ]; then
    apk add --no-cache mysql-client gettext
    mysql_install_db --user=mysql --ldata=/var/lib/mysql
    mysqld_safe --user=mysql --skip-networking=0 --skip-bind-address &
    sleep 5 # wait for process to start up
    cat db-setup.sql | envsubst | mysql
    killall -9 mysqld_safe mariadbd
    apk del mysql-client gettext
fi
unset DB_ROOT_PASS DB_POSTFIX_PASS DB_DOVECOT_PASS DB_ROUNDCUBE_PASS POSTMASTER_PASS
rm db-setup.sql

mysqld_safe --user=mysql --skip-networking=0 --skip-bind-address
