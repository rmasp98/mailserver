#!/bin/sh --

ROOT="/var/lib/rspamd/dkim"
mkdir ${ROOT}

if [ -n "${CONTROLLER_PASS}" ]; then
    echo "password = \"$(rspamadm -e -p ${CONTROLLER_PASS}\")" > /etc/rspamd/local.d/worker-controller.inc
    echo "bind_socket = \"*:11334\"" > /etc/rspamd/local.d/worker-controller.inc
fi

apk add mysql-client --no-cache
mysql -u postfix -p${DB_PASS} -h mariadb -D mailserver -N -e "SELECT domain, selector, dkim_key FROM domains" \
        | while read -r domain selector dkim_key; do
    if [ "${domain}" != "localhost" ]; then
	    echo -e ${dkim_key} >> ${ROOT}/${domain}.${selector}.key
        chmod 440 ${ROOT}/${domain}.${selector}.key
    fi
done
apk del mysql-client

chown -R rspamd:rspamd ${ROOT}

redis-server /etc/redis.conf &
rspamd -u rspamd -g rspamd -f