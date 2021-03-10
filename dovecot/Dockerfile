FROM alpine:latest

EXPOSE 143
EXPOSE 993
EXPOSE 4190

VOLUME /ssl
VOLUME /postfix
VOLUME /var/mail

RUN apk update && apk add dovecot dovecot-lmtpd dovecot-mysql dovecot-pigeonhole-plugin \
    entr curl dcron mysql-client imapsync --no-cache

# Postfix created for permissions on dovecot sockets
RUN addgroup -S -g 5000 vmail && \
    adduser -S -h /var/mail -D -u 5000 -s /sbin/nologin -G vmail vmail && \
    adduser -S -H -D -u 100 -s /sbin/nologin postfix && \
    adduser -h /var/imapsync -s /sbin/nologin -S -D imapsync 

# Remove all unecessary config files
RUN rm -rf /etc/dovecot/*

ADD dovecot.conf /etc/dovecot/
ADD mail-sync.sh /var/imapsync/
ADD sieve /etc/dovecot/sieve
ADD entry-point.sh /

CMD ["/bin/sh", "/entry-point.sh"]
