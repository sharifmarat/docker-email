Docker images based on debian which contains:
* postfix with virtual users (file based)
* dovecot for imap, auth and filtering
* spamassassin (in progress)
* scripts to manage users (in progress)
* runit as init to supervise services

# Building
```
docker build --rm -t postfix-dovecot --build-arg MAILNAME=example.com .
```

# Running
Start with self-signed certificates:
```
docker run -d \
    -p 25:25 \
    -p 143:143 \
    -p 587:587 \
    postfix-dovecot
```

Start with your existing certificates:
```
docker run -d \
    -p 25:25 \
    -p 143:143 \
    -p 587:587 \
    -v /etc/letsencrypt/live/example.com/fullchain.pem:/etc/ssl/private/fullchain.pem:ro \
    -v /etc/letsencrypt/live/example.com/privkey.pem:/etc/ssl/private/privkey.pem:ro \
    postfix-dovecot
```

Start with mounted folder for mail storage:
```
mkdir /my-mail
chown 9000:9000 /my-mail  # It is kind of hack. 9000 is vmail uid&gid in docker. Is there a better way?
docker run -d \
    -p 25:25 \
    -p 143:143 \
    -p 587:587 \
    -v /etc/letsencrypt/live/example.com/fullchain.pem:/etc/ssl/private/fullchain.pem:ro \
    -v /etc/letsencrypt/live/example.com/privkey.pem:/etc/ssl/private/privkey.pem:ro \
    -v /my-mail:/mail \
    postfix-dovecot
```

Start with mounted virtual user configuration and dovecot auth:
```
docker run -d \
    -p 25:25 \
    -p 143:143 \
    -p 587:587 \
    -v /etc/letsencrypt/live/example.com/fullchain.pem:/etc/ssl/private/fullchain.pem:ro \
    -v /etc/letsencrypt/live/example.com/privkey.pem:/etc/ssl/private/privkey.pem:ro \
    -v /my-mail:/mail \
    -v /my-users:/etc/dovecot/users \
    -v /my-virtual_domains:/etc/postfix/virtual_domains \
    -v /my-virtual_accounts:/etc/postfix/virtual_boxes \
    -v /my-virtual_aliases:/etc/postfix/virtual_aliases \
    postfix-dovecot
```
See on how to adjust configuration with scripts below.

# Adding roundcube on top of that
You can add roundcube:
```
docker run -d \
    -e ROUNDCUBEMAIL_DEFAULT_HOST=tls://example.com \
    -e ROUNDCUBEMAIL_SMTP_SERVER=tls://example.com \
    -e ROUNDCUBEMAIL_PLUGINS=archive,zipdownload,managesieve \
    -p 8000:80 \
    roundcube/roundcubemail
```

# Example of nginx reverse proxy config
```
location /my-mail/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host            $host;
        proxy_set_header X-Forwarded-For $remote_addr;
}
```

# Restarting a service or reloading config
```
docker exec $(docker ps -q --filter ancestor=postfix-dovecot) sv restart dovecot
docker exec $(docker ps -q --filter ancestor=postfix-dovecot) sv restart postfix
docker exec $(docker ps -q --filter ancestor=postfix-dovecot) postfix reload
```

# Stopping the container
```
docker stop $(docker ps -q --filter ancestor=postfix-dovecot)
docker rmi $(docker ps -a -q --filter ancestor=postfix-dovecot)
```

# Adding/Removing users

# Details on implementation

## Spamassassin

# TODO:
* Manage users/passwords with scripts
* DKIM
