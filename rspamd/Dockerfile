FROM alpine:latest

RUN apk update && apk add rspamd rspamd-proxy rspamd-controller redis --no-cache

ADD rspamd/local.d/* /etc/rspamd/local.d/
ADD entry-point.sh /

CMD ["/bin/sh", "entry-point.sh"]
