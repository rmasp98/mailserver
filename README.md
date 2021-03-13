DO NOT USE!!! This is still a work in progress

This is an attempt at a full mailserver stack that is a little less resource intensive than mailcow. It is based on postfix and dovecot with a mariadb backend

Features:
 - OpenDKIM, SPF and greylisting (you need to add the txt fields to DNS)
 - Let's Encrpyt certificates with auto renewal
 - Multiple domain hosting
 - Automatic user aliasing (e.g. user-facebook@example.com will go to user@example.com mailbox)
 - Spam filter using rspamd (also learns from emails added and removed from spam folder)
 - Roundcube web mail to get access to mail in the browser
 - Server side filters manageable by users through managesieve protocol
 - Capacity to sink other mail boxes into your mailboxes here

TODO:
 - virtual folders (apparenty called mailboxes)
   - All mail
   - Archive
   - Important
 - API to manage mailserver (convert bash script). 
   - Probably need client as well
   - This could allow us to move root DB password off server
   - make this gRPC could be fun
   - github.com/docker/cli/cli/compose has go code for parsing compose file
   - Probably split client and server off to different repo
   - Learn how to do go binary only container
 - Harden docker images
   - Dovecot and postfix can chroot
   - Stop everything running as root

