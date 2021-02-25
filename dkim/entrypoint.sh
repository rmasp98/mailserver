#!/bin/sh --

ROOT="/etc/opendkim"
SIGN="${ROOT}/signing.table"
KEY="${ROOT}/key.table"

if [ ! -d "/run/opendkim" ]; then
    mkdir /run/opendkim
fi

cat << EOF > ${ROOT}/trusted.hosts
127.0.0.1
localhost
postfix
EOF

mysql -u postfix -p${DB_PASS} -h mariadb -D mailserver -N -e "SELECT domain, selector, dkim_key FROM domains" \
        | while read -r domain selector dkim_key; do
    mkdir -p ${ROOT}/keys/${domain}
	echo "*@${domain}    ${selector}._domainkey.${domain}" >> ${SIGN}
	echo "${selector}._domainkey.${domain}    ${domain}:${selector}:${ROOT}/keys/${domain}/${selector}.private" >> ${KEY}
	echo -e ${dkim_key} >> ${ROOT}/keys/${domain}/${selector}.private
    chmod 440 ${ROOT}/keys/${domain}/${selector}.private

    echo "*.${domain}" >> ${ROOT}/trusted.hosts
done

chown -R opendkim:opendkim ${ROOT}
chown opendkim:opendkim /run/opendkim

syslogd
opendkim -f
