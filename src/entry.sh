#!/bin/bash

echo $MAILNAME >/etc/mailname
echo $HOSTNAME >/etc/hostname

chown dovecot:dovecot /etc/dovecot/users

envsubst $REPLACE_VARS </etc/postfix/main.cf >/tmp/tmp.conf && mv /tmp/tmp.conf /etc/postfix/main.cf
envsubst $REPLACE_VARS </etc/spamassassin/local.cf >/tmp/tmp.conf && mv /tmp/tmp.conf /etc/spamassassin/local.cf
envsubst $REPLACE_VARS </etc/dovecot/dovecot.conf >/tmp/tmp.conf && mv /tmp/tmp.conf /etc/dovecot/dovecot.conf

# if opendkim enabled
if [ "$DKIM_ENABLED" = "true" ]; then
  # Append openDKIM config to postfix
  cat /etc/postfix/main.cf-open-dkim >>/etc/postfix/main.cf

  # Change permissions of private keys
  find /etc/opendkim -iname "mail.private" -exec chown opendkim:opendkim {} \;

  # enable opendkim service
  ln -s $SERVICE_AVAILABLE_DIR/opendkim $SERVICE_ENABLED_DIR/
fi

exec runsvdir /service
