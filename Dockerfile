FROM debian:buster

EXPOSE 25 143 587

# TODO
# Setting TRUSTED_NETWORKS="127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 172.17.0.0/16" exposes relay access since docker remote IP address might be broken

ENV MAILNAME=mydummymailname.com \
    HOSTNAME=mailserver \
    TRUSTED_NETWORKS="127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128" \
    DKIM_ENABLED=false \
    SERVICE_AVAILABLE_DIR=/etc/service \
    SERVICE_ENABLED_DIR=/service \
    REPLACE_VARS='$MAILNAME,$HOSTNAME,$TRUSTED_NETWORKS,DKIM_ENABLED,$SERVICE_AVAILABLE_DIR,$SERVICE_ENABLED_DIR' \
    DEBIAN_FRONTEND=noninteractive \
    CERT_LOCATION=/etc/ssl/private/fullchain.pem \
    CERT_KEY_LOCATION=/etc/ssl/private/privkey.pem

# Basics
RUN echo $MAILNAME >/etc/mailname \
  && echo $HOSTNAME >/etc/hostname \
# Refresh the system
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends --no-install-suggests ca-certificates \
  && update-ca-certificates \
# Prepare user and group
  && groupadd -g 9000 vmail \
  && useradd -u 9000 -g vmail -s /usr/bin/nologin -d /mail -m vmail \
# Install things
  && apt-get install -y --no-install-recommends --no-install-suggests \
# Install runit and basic tools
      runit cron rsyslog procps gettext-base \
# Install postfix
      postfix \
# Install dovecot
      dovecot-core dovecot-imapd dovecot-managesieved dovecot-sieve \
# Install opendkim
      opendkim opendkim-tools \
# Spamassasin
      spamassassin spamc \
# Create services
  && mkdir -p $SERVICE_AVAILABLE_DIR \
  && mkdir -p $SERVICE_ENABLED_DIR \
# Cron service
  && mkdir -p $SERVICE_AVAILABLE_DIR/cron \
  && echo "#!/bin/bash\nexec cron -f" >$SERVICE_AVAILABLE_DIR/cron/run \
  && chmod a+x $SERVICE_AVAILABLE_DIR/cron/run \
# Rsyslogd
  && mkdir -p $SERVICE_AVAILABLE_DIR/rsyslog \
  && echo "#!/bin/bash\nexec rsyslogd -n" >$SERVICE_AVAILABLE_DIR/rsyslog/run \
  && chmod a+x $SERVICE_AVAILABLE_DIR/rsyslog/run \
# Dovecot service
  && mkdir -p $SERVICE_AVAILABLE_DIR/dovecot \
  && echo "#!/bin/bash\nexec dovecot -F" >$SERVICE_AVAILABLE_DIR/dovecot/run \
  && chmod a+x $SERVICE_AVAILABLE_DIR/dovecot/run \
# Postfix service
  && mkdir -p $SERVICE_AVAILABLE_DIR/postfix \
  && echo "#!/bin/bash\n/usr/lib/postfix/configure-instance.sh postfix\nexec /usr/lib/postfix/sbin/master" >$SERVICE_AVAILABLE_DIR/postfix/run \
  && chmod a+x $SERVICE_AVAILABLE_DIR/postfix/run \
# Spamassasin service
  && mkdir -p $SERVICE_AVAILABLE_DIR/spamassassin \
  && echo "#!/bin/bash\nexec spamd --max-children 5" >$SERVICE_AVAILABLE_DIR/spamassassin/run \
  && chmod a+x $SERVICE_AVAILABLE_DIR/spamassassin/run \
# OPENDKIM service (DISABLED BY DEFAULT)
  && mkdir -p $SERVICE_AVAILABLE_DIR/opendkim \
  && echo "#!/bin/bash\nexec opendkim -x /etc/opendkim.conf -f" >$SERVICE_AVAILABLE_DIR/opendkim/run \
  && chmod a+x $SERVICE_AVAILABLE_DIR/opendkim/run \
# Emable services
  && ln -s $SERVICE_AVAILABLE_DIR/cron $SERVICE_ENABLED_DIR/ \
  && ln -s $SERVICE_AVAILABLE_DIR/rsyslog $SERVICE_ENABLED_DIR/ \
  && ln -s $SERVICE_AVAILABLE_DIR/postfix $SERVICE_ENABLED_DIR/ \
  && ln -s $SERVICE_AVAILABLE_DIR/dovecot $SERVICE_ENABLED_DIR/ \
  && ln -s $SERVICE_AVAILABLE_DIR/spamassassin $SERVICE_ENABLED_DIR/ \
# Prepare files for replacements (config files point to this folders)
  && cp /etc/ssl/certs/ssl-cert-snakeoil.pem $CERT_LOCATION \
  && cp /etc/ssl/private/ssl-cert-snakeoil.key $CERT_KEY_LOCATION

# Copy configs - some will be changed later
COPY src/postfix/main.cf \
     src/postfix/main.cf-open-dkim \
     src/postfix/master.cf \
     src/postfix/virtual_domains \
     src/postfix/virtual_aliases \
     src/postfix/virtual_boxes \
       /etc/postfix/
COPY src/dovecot/dovecot.conf \
     src/dovecot/users \
       /etc/dovecot/
COPY src/spamassassin/spamassassin \
       /etc/default/
COPY src/spamassassin/local.cf \
       /etc/spamassassin/
COPY src/opendkim/opendkim.conf /etc/opendkim.conf
COPY src/entry.sh /entry.sh

# Start
CMD ["/entry.sh"]
