FROM alpine:latest

EXPOSE 3306/tcp
VOLUME ["var/lib/mysql"]

RUN apk update && apk add mysql --no-cache

ADD db-setup.sql /

ADD entry-point.sh /
RUN chmod 700 /entry-point.sh

ENTRYPOINT ["/entry-point.sh"]
CMD ["mysqld_safe", "--user=mysql", "--skip-networking=0", "--skip-bind-address"]
