#!/bin/sh --

DB_USER="root"
DB_HOST="mariadb"
DB_NAME="mailserver"

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: create_domains.sh <domain> <selector> <password>"
    exit
fi

DOMAIN=$1
SELECTOR=$2
PASSWORD=$3

opendkim-genkey -b 2048 -d ${DOMAIN} -D / -s ${SELECTOR}

mysql -u ${DB_USER} --password=${DB_PASS} -h ${DB_HOST} ${DB_NAME} \
        -e "CALL CreateDomain('${DOMAIN}', '${SELECTOR}', '$(cat /${SELECTOR}.private)', '${PASSWORD}')"

cat /${SELECTOR}.txt
