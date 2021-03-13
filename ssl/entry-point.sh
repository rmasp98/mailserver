#!/bin/sh --

if [ ${PRODUCTION} == 1 ]; then
    cat << EOF > /secret.txt
dns_digitalocean_token = ${DO_TOKEN}
EOF
    
    MAIN_DOMAIN=$(echo ${SERVER_DOMAINS} | cut -d',' -f1)
    
    # If DO_TOKEN is set and certificates do not already exist get new certificates
    if [ ! -z ${DO_TOKEN} ] && [ ! -d /etc/letsencrypt/live/${MAIN_DOMAIN} ]; then
        certbot certonly \
            -n \
            --dns-digitalocean \
            --dns-digitalocean-credentials /secret.txt \
            --expand -d ${SERVER_DOMAINS} \
            --agree-tos -m ${EMAIL}
    fi
    
    # make sure there is a copy of the certs in /ssl
    cp /etc/letsencrypt/live/${MAIN_DOMAIN}/* /ssl
    
    # Creates cronjob to renew certificates every two months
    echo -e "0\t1\t1\t*/2\t*\tcertbot renew && cp /etc/letsencrypt/live/${MAIN_DOMAIN}/* /ssl" >> /etc/crontabs/root
else
    if [ ! -f "/ssl/fullchain.pem" ]; then
        apk add openssl
        cat << EOF > cert.conf
$(cat /etc/ssl/openssl.cnf)
[SAN]
subjectAltName=DNS:dovecot,DNS:postfix,DNS:roundcube
EOF
        openssl req  -nodes -new -x509 \
            -subj "/C=US/ST=CA/O=Acme, Inc./CN=example.com"  \
            -keyout /ssl/privkey.pem -out /ssl/fullchain.pem \
            -reqexts SAN -extensions SAN -config cert.conf
    fi
fi

# Run CMD
"$@"
