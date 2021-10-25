#!/bin/sh

config_file="/var/mbsync/sync.conf"

# If file exists then command still running
if [ ! -f ${config_file} ]; then

    touch ${config_file}
    trap "rm -f ${config_file}" 0

    mysql -u dovecot -p${DB_PASS} -h mariadb -D mailserver -N \
    -e "SELECT (select email from users where id=user_id), username, password, host, ssl_type, mappings FROM mailsync" | \
      while read -r email username password host ssl_type mappings; do
        user=$(echo ${email} | cut -d'@' -f 1)
        domain=$(echo ${email} | cut -d'@' -f 2)

        cat << EOF >> ${config_file}
IMAPStore           "${username}-${host}"
Host                "${host}"
User                "${username}"
Pass                "${password}"
SSLType             "${ssl_type}"

IMAPStore           "${email}"
Host                127.0.0.1
User                "${email}*postmaster@master"
Pass                "$(cat /var/mbsync/postmaster-pass)"
SSLType             IMAPS
CertificateFile     /ssl/fullchain.pem

EOF

        if [ "${mappings}" = "" ]; then
            cat << EOF >> ${config_file}
Channel             "${username}-${host}"
Master              ":${username}-${host}:"
Slave               ":${email}:"
Create              Slave
Expunge             Slave
Sync                Pull
Pattern             *

EOF
        else

            IFS=","
            for mapping in ${mappings}; do
                source_mb=$(echo ${mapping} | cut -d'=' -f 1)
                destination_mb=$(echo ${mapping} | cut -d'=' -f 2)
                cat << EOF >> ${config_file}
Channel             "${username}-${host}-${source_mb}"
Master              ":${username}-${host}:${source_mb}"
Slave               ":${email}:${destination_mb}"
Create              Slave
Expunge             Slave
Sync                Pull

EOF
            done
        fi
    done

    mbsync -c ${config_file} --all --pull --create
fi
