FROM alpine:latest

RUN apk update && apk add dovecot dovecot-pop3d dovecot-lmtpd dovecot-mysql entr --no-cache

RUN addgroup -S -g 5000 vmail && adduser -S -h /var/mail -D -u 5000 -s /sbin/nologin -G vmail vmail
RUN adduser -S -H -D -u 100 -s /sbin/nologin postfix

COPY conf.d /etc/dovecot/conf.d/
COPY dovecot.conf /etc/dovecot/

ADD entry-point.sh /

CMD ["/bin/sh", "/entry-point.sh"]
