#!/bin/sh --

# TODO: check if already populated
DB_USER="root"
DB_HOST="mariadb"
DB_NAME="mailserver"

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: create_user.sh <username> <password> <domain>"
    exit
fi

USER=$1
PASSWORD=$2
DOMAIN=$3

mysql -u ${DB_USER} --password=${DB_PASS} -h ${DB_HOST} ${DB_NAME} \
        -e "CALL CreateUser('${USER}', '${PASSWORD}', '${DOMAIN}')"
