DO NOT USE!!! This is still a work in progress

This is an attempt at a full mailserver stack that is a little less resource intensive than mailcow. It is based on postfix and dovecot with a mariadb backend

Features:
 - OpenDKIM and SPF configured (you need to add the txt fields to DNS)
 - Let's Encrpyt certificates with auto renewal
 - Multiple domain hosting
 - Automatic user aliasing (e.g. user-facebook@example.com will go to user@example.com mailbox)

TODO:
 - Spam filter and AV
 - roundcube or other webmail
 - virtual folders (apparenty called mailboxes)
   - All mail
   - Archive
   - Important
 - API to manage mailserver (convert bash script). 
   - Probably need client as well
   - This could allow us to move root DB password off server
   - make this gRPC could be fun
 - Pull emails from other mailboxes
   - Primarily gmail but could look into general one too

