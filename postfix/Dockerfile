FROM alpine:latest

EXPOSE 25
EXPOSE 465
EXPOSE 587

VOLUME /ssl
VOLUME /dovecot

RUN apk update && apk add postfix postfix-mysql --no-cache

RUN rm -rf $(find /etc/postfix/* | grep -v "postfix-files\|dynamicmaps.cf")

ADD *.cf /etc/postfix/
ADD entrypoint.sh .

CMD ["/bin/sh", "entrypoint.sh"]
