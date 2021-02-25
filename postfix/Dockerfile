FROM alpine:latest

RUN apk update && apk add postfix postfix-mysql postfix-policyd-spf-perl postgrey fail2ban --no-cache

RUN adduser -S -H -D -s /sbin/nologin policyd-spf 

ADD fail2ban/ /etc/
ADD *.cf /etc/postfix/
ADD entrypoint.sh .

CMD ["/bin/sh", "entrypoint.sh"]
