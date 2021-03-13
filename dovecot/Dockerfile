FROM alpine:latest

EXPOSE 143/tcp 993/tcp 4190/tcp
VOLUME ["/ssl", "/postfix", "/var/mail"]

RUN apk update && apk add dovecot dovecot-lmtpd dovecot-mysql dovecot-pigeonhole-plugin \
    entr curl dcron mysql-client isync --no-cache

# Postfix created for permissions on dovecot sockets
RUN addgroup -S -g 5000 vmail && \
    adduser -S -h /var/mail -D -u 5000 -s /sbin/nologin -G vmail vmail && \
    adduser -S -H -D -u 100 -s /sbin/nologin postfix && \
    addgroup -S mbsync && \
    adduser -S -h /var/mbsync -D  -s /sbin/nologin -G mbsync mbsync

# Remove all unecessary config files
RUN rm -rf /etc/dovecot/*

ADD --chown=dovecot:dovecot dovecot.conf /etc/dovecot/
ADD --chown=dovecot:dovecot sieve /etc/dovecot/sieve
ADD --chown=mbsync:mbsync mail-sync.sh /var/mbsync/

ADD entry-point.sh /
RUN chmod u+x /entry-point.sh

ENTRYPOINT ["/entry-point.sh"]
CMD ["/usr/sbin/dovecot", "-F"]
