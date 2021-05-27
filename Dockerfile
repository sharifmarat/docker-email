FROM debian-buster-base

ARG MAILNAME=example.com

EXPOSE 25 143 587

ENV DEBIAN_FRONTEND=noninteractive \
    SERVICE_AVAILABLE_DIR=/etc/service \
    SERVICE_ENABLED_DIR=/service \
    CERT_LOCATION=/etc/ssl/private/fullchain.pem \
    CERT_KEY_LOCATION=/etc/ssl/private/privkey.pem

# Basics
RUN echo $MAILNAME >/etc/mailname \
# Refresh the system
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends --no-install-suggests ca-certificates \
  && update-ca-certificates \
# Prepare user and group
  && groupadd -g 9000 vmail \
  && useradd -u 9000 -g vmail -s /usr/bin/nologin -d /mail -m vmail \
# TODO: certificates
# Install things
  && apt-get install -y --no-install-recommends --no-install-suggests \
# Install runit
      runit \
# Install postfix
      postfix \
# Install dovecot
      dovecot-core dovecot-imapd dovecot-managesieved dovecot-sieve \
# Install opendkim
      opendkim opendkim-tools \
# Spamassasin
      spamassassin \
# Ngingx
# Roundcube
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
COPY src/postfix/main.cf /etc/postfix/
COPY src/postfix/master.cf /etc/postfix/
COPY src/postfix/virtual_domains /etc/postfix/
COPY src/postfix/virtual_aliases /etc/postfix/
COPY src/postfix/virtual_boxes /etc/postfix/
COPY src/dovecot/local.conf /etc/dovecot/
COPY src/dovecot/users /etc/dovecot/

# Apply arguments

# Build hashes
RUN postmap /etc/postfix/virtual_aliases \
 && postmap /etc/postfix/virtual_boxes

# Start
CMD ["/bin/runsvdir", "/service"]
