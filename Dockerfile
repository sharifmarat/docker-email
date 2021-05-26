FROM debian-buster-base

ARG MAILNAME=example.com

EXPOSE 25 143 587

ENV DEBIAN_FRONTEND=noninteractive \
    SERVICE_AVAILABLE_DIR=/etc/service \
    SERVICE_ENABLED_DIR=/service

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
  && echo "#!/bin/bash\nexec /usr/lib/postfix/sbin/master" >$SERVICE_AVAILABLE_DIR/postfix/run \
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
  && ln -s $SERVICE_AVAILABLE_DIR/spamassassin $SERVICE_ENABLED_DIR/

# Copy config
COPY src/postfix/main.cf /etc/postfix/
COPY src/postfix/virtual /etc/postfix/
COPY src/postfix/virtual_domains /etc/postfix/

# Build hashes
RUN postmap /etc/postfix/virtual

# Start
CMD ["/bin/runsvdir", "/service"]
