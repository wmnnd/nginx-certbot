#!/bin/sh

domain="example.org"
rsa_key_size=4096
data_path="/etc/letsencrypt"

echo "### Creating dummy certificate for $domain ..."
path="/etc/letsencrypt/live/$domain"
mkdir -p "$path"

openssl req -x509 -nodes -newkey rsa:1024 -days 1 \
  -keyout "$path/privkey.pem" \
  -out "$path/fullchain.pem" \
  -subj '/CN=localhost'

exec "$@"
