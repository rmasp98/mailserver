FROM alpine:latest

VOLUME /ssl

RUN apk update &&  apk add certbot py3-pip dcron --no-cache && pip install certbot-dns-digitalocean

ADD entry-point.sh /
RUN chmod 700 /entry-point.sh

ENTRYPOINT ["/entry-point.sh"]
CMD ["/usr/sbin/crond", "-f"]
