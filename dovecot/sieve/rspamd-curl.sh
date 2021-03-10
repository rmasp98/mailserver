#!/bin/sh

if [ "$1" != "ham" ] && [ "$1" != "spam" ]; then
    >&2 echo "Action: $1 is not supported"
    exit 1;
fi

read password < controller_password

RESULT=$(/usr/bin/curl -s -H "Password: ${password}" --data-binary -d @- http://rspamd:11334/learn$1)
STATUS=$?
if [ ${STATUS} -eq 0 ]; then
    echo "Uploaded"
else
    >&2 echo "Failed with error code ${STATUS}"
fi
