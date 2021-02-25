FROM alpine:latest

RUN apk update && apk add opendkim mysql-client --no-cache

ADD entrypoint.sh .
ADD opendkim.conf /etc/opendkim/

CMD ["/bin/sh", "entrypoint.sh"]
