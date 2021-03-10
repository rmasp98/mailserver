require ["vnd.dovecot.pipe", "copy", "imapsieve"];

pipe :copy "rspamd-curl.sh" ["spam"];
