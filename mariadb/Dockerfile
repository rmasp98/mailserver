FROM alpine:latest

RUN apk update && apk add mysql --no-cache

ADD entry-point.sh /
ADD db-setup.sql /

CMD ["/bin/sh", "/entry-point.sh"]
