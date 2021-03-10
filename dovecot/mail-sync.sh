#!/bin/sh

mysql -u dovecot -p${DB_PASS} -h mariadb -D mailserver -N \
  -e "SELECT (select email from users where id=user_id), username, password, host, port, flags FROM mailsync" | \
  while read -r email username password host port flags; do
    passfile1=/var/imapsync/${email}
    echo ${password} > ${passfile1}
    trap "rm -f ${passfile1}" 0

    eval imapsync --host1 ${host} --user1 ${username} --passfile1 ${passfile1} \
             --host2 127.0.0.1 --user2 "${email}*postmaster@master" --passfile2 /var/imapsync/postmaster-pass \
             ${flags}
done

