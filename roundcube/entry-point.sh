#!/bin/sh

if ! grep -q "OPTIONAL_COMPLETED" /var/www/html/config/config.inc.php; then
    PLUGINS=$(echo "${PLUGINS}" | sed -E "s/[, ]+/', '/g")
    cat << EOF >> /var/www/html/config/config.inc.php
// OPTIONAL_COMPLETED
\$config['db_dsnw'] = 'mysql://roundcube:${DB_PASS}@mariadb/roundcube';
\$config['default_host'] = 'ssl://${IMAP_SERVER}';
\$config['smtp_server'] = 'tls://${SMTP_SERVER}';
\$config['product_name'] = '${NAME}';
\$config['skin'] = '${SKIN}';
\$config['plugins'] = array('${PLUGINS}');
\$config['managesieve_host'] = '${IMAP_SERVER}';
\$config['password_db_dsn'] = 'mysql://roundcube:${DB_PASS}@mariadb/mailserver';

EOF
fi

if [ ${PRODUCTION} = 0 ] && ! grep -q "TESTING_COMPLETED" /var/www/html/config/config.inc.php; then
    cat << EOF >> /var/www/html/config/config.inc.php
// TESTING_COMPLETED
\$config['imap_conn_options'] = array(
   'ssl' => array('verify_peer' => false, 'verify_peer_name' => false),
);
\$config['smtp_conn_options'] = array(
   'ssl' => array('verify_peer' => false, 'verify_peer_name' => false),
);
\$config['managesieve_conn_options'] = array(
   'ssl' => array('verify_peer' => false, 'verify_peer_name' => false),
);
EOF
fi

chown nginx:nginx -R /var/www/html/

# Sleep to wait for mariadb to initialise
sleep 15
bin/initdb.sh --dir=$PWD/SQL --create || bin/updatedb.sh --dir=$PWD/SQL --package=roundcube || echo "Failed to initialize database. Please run $PWD/bin/initdb.sh and $PWD/bin/updatedb.sh manually."

nginx

exec "$@"
