FROM alpine:latest

EXPOSE 11334
VOLUME ["/var/lib/redis"]

RUN apk update && apk add rspamd rspamd-proxy rspamd-controller redis mysql-client --no-cache

ADD --chown=rspamd:rspamd rspamd/local.d/* /etc/rspamd/local.d/

ADD entry-point.sh /
RUN chmod 700 /entry-point.sh

ENTRYPOINT ["/entry-point.sh"]
CMD ["/usr/sbin/rspamd", "-u", "rspamd", "-g", "rspamd", "-f"]
