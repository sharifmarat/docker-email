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

