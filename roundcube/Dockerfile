FROM alpine:latest

ARG ROUNDCUBE_URL="https://github.com/roundcube/roundcubemail/releases/download/1.4.11/roundcubemail-1.4.11-complete.tar.gz"

EXPOSE 443

VOLUME /ssl

# Need to install nginx
RUN set -ex; \
    apk update && \
    apk add php7-fpm composer php7-gd php7-ctype php7-dom php7-ldap php7-xml php7-session\
            php7-pdo php7-fileinfo php7-intl php7-exif php7-imagick php7-pdo_mysql nginx --no-cache; \
    wget -O roundcubemail.tar.gz $ROUNDCUBE_URL; \
    mkdir -p /var/www/html; \
    tar zxvf roundcubemail.tar.gz -C /var/www/html --strip-components=1 --no-same-owner; \
    cd /var/www/html && composer install --no-dev && bin/updatecss.sh --dir skins/elastic; \
    rm -rf roundcubemail.tar.gz /var/www/html/installer; \
    mkdir -p /run/nginx;
    
ADD config.inc.php /var/www/html/config
ADD nginx.conf /etc/nginx/

ADD entry-point.sh /
RUN chmod u+x /entry-point.sh

WORKDIR /var/www/html
ENTRYPOINT ["/entry-point.sh"]
CMD ["/usr/sbin/php-fpm7", "-F"]
