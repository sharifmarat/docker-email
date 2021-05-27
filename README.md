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
Certificates are optional. To use automatically generated remove `-v parameters`.
```
docker run -d \
    -p 25:25 \
    -p 143:143 \
    -p 587:587 \
    -v /etc/letsencrypt/live/example.com/fullchain.pem:/etc/ssl/private/fullchain.pem \
    -v /etc/letsencrypt/live/example.com/privkey.pem:/etc/ssl/private/privkey.pem \
    postfix-dovecot
```

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

# TODO:
* Bind virtual users and aliases
* Manage users/passwords with scripts
* Spamassassin
* DKIM
