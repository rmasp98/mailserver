FROM alpine:latest

EXPOSE 25 465 587
VOLUME ["/ssl", "/dovecot"]

RUN apk update && apk add postfix postfix-mysql --no-cache

# Remove all postfix configuration files except dynamicmaps and postfix-files
RUN rm -rf $(find /etc/postfix/* | grep -v "postfix-files\|dynamicmaps.cf")

ADD *.cf /etc/postfix/

ADD entry-point.sh .
RUN chmod 700 /entry-point.sh

ENTRYPOINT ["/entry-point.sh"]
CMD ["/usr/sbin/postfix", "start-fg"]
