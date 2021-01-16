#!/usr/bin/env bash
# vim:sw=2:ts=2:et

set -ueo pipefail
# DEBUG
# set -x

# convert space-delimited string from the ENV to array
domains=(${domains:-example.org})

domain=${domains[0]}

data_path="/etc/letsencrypt"
path="$data_path/live/$domain"

rsa_key_size=${rsa_key_size:-4096}

trap exit TERM

echo "### Let's nginx bootstrap"
sleep 10s

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

if [ ! -f "$path/privkey.pem" ]; then
  echo "### Requesting Let's Encrypt certificate for $domains ..."

  # join $domains to -d args
  domain_args=""
  for domain in "${domains[@]}"; do
    domain_args="$domain_args -d $domain"
  done

  # Enable staging mode if needed
  if [ $staging != "0" ]; then
    staging_arg="--staging"
  else
    staging_arg=""
  fi

  certbot certonly \
    --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal

    echo "### Reloading nginx ..."
    curl --fail --silent --user ${nginx_api_user}:${nginx_api_password} http://nginx/nginx/reload
fi

while :; do
  certbot renew \
    --webroot -w /var/www/certbot \
    $email_arg \
    --rsa-key-size $rsa_key_size \
    --agree-tos

  curl --fail --silent --user ${nginx_api_user}:${nginx_api_password} http://nginx/nginx/reload
  sleep 12h & wait ${!}
done
