#!/bin/bash -ue

# Generate new password
doveadm pw -s SHA512-CRYPT -p "XXX"


# Re-encrypt
doveadm -o plugin/mail_crypt_private_password={dovecot encrypt scheme}password-hash-from-mysql mailbox cryptokey generate -u -f john@example.org -RU.


user="$1"

read -s -p "Old password:" pass_old
echo ""
read -s -p "New password:" pass_new1
echo ""
read -s -p "Type new password again:" pass_new2
echo ""

if [ "$pass_new1" != "$pass_new2" ]; then
  echo "New passwords do not match" >&2
  exit 1
fi

doveadm mailbox cryptokey password -u "$user" -n "$pass_new1" -o "$pass_old"

echo "Generating crypt password:"
doveadm pw -s SHA512-CRYPT -p "$pass_new1"
echo "Update your users file with this"

# TODO TODO TODO
# Create a new user - automatically it does not work with the password :(
#doveadm -o plugin/mail_crypt_private_password=desired_password mailbox cryptokey generate -u <USER> -UR

# Create DKIM record
#sudo opendkim-genkey -b 2048 -d your-domain.com -D /etc/opendkim/keys/your-domain.com -s default -v
#sudo chown opendkim:opendkim /etc/opendkim/keys/your-domain.com/default.private

# TEST DKIM record
#opendkim-testkey -d <DOMAIN> -s mail -vvv
