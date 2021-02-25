FROM alpine:latest

RUN apk update &&  apk add certbot py3-pip dcron --no-cache && pip install certbot-dns-digitalocean

ADD entry-point.sh /

CMD ["/bin/sh", "/entry-point.sh"]
