#!/bin/bash

echo $MAILNAME >/etc/mailname
echo $HOSTNAME >/etc/hostname

chown dovecot:dovecot /etc/dovecot/users

envsubst $REPLACE_VARS </etc/postfix/main.cf >/tmp/tmp.conf && mv /tmp/tmp.conf /etc/postfix/main.cf
envsubst $REPLACE_VARS </etc/spamassassin/local.cf >/tmp/tmp.conf && mv /tmp/tmp.conf /etc/spamassassin/local.cf

exec runsvdir /service
