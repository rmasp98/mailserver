#!/bin/sh

# This will cause the container to completely restart if any point fails
# such as mariadb not being ready yet
set -e

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
   'ssl' => array('cafile' => '/ssl/fullchain.pem'),
);
\$config['smtp_conn_options'] = array(
   'ssl' => array('cafile' => '/ssl/fullchain.pem'),
);
\$config['managesieve_conn_options'] = array(
   'ssl' => array('cafile' => '/ssl/fullchain.pem'),
);
EOF
fi

chown nginx:nginx -R /var/www/html/

bin/initdb.sh --dir=$PWD/SQL --create || bin/updatedb.sh --dir=$PWD/SQL --package=roundcube

nginx

exec "$@"
