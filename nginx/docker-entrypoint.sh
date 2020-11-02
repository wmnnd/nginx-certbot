#!/usr/bin/env bash
# vim:sw=2:ts=2:et

set -ueo pipefail
# DEBUG
# set -x

# convert space-delimited string from the ENV to array
domains=(${domains:-example.org})
domain="${domains[0]}"
export nginx_domain="${domain}"

data_path="/etc/letsencrypt"
path="$data_path/live/$domain"

rsa_key_size=${rsa_key_size:-4096}

wait_certbot(){
  (
    echo "### Waiting for certbot container"

    retries="${1:-180}"

    set +e
    until ping -c 1 certbot > /dev/null 2>&1 || [ "$retries" -eq 0 ]; do
      : $((retries--))
      echo "### certbot is not up yet!"
      sleep 1s
    done
    set -e

    [ "${retries}" -ne 0 ] || (echo "### certbot service did not get up"; exit 1)

    echo "### Removing self-signed SSL from $path"
    rm -rf "$path"
  ) &
}

if [ ! -f "$path/privkey.pem" ]; then
  sleep 5
  echo "### Creating dummy certificate for $domain ..."

  mkdir -p "$path"

  openssl req -x509 -nodes -newkey rsa:1024 -days 1 \
    -keyout "$path/privkey.pem" \
    -out "$path/fullchain.pem" \
    -subj '/CN=localhost'

  wait_certbot
fi

# API service that reloads nginx on request
htpasswd -bc /tmp/.htpasswd "${nginx_api_user}" "${nginx_api_password}" > /dev/null 2>&1
(
  while true
  do
    { echo -e "HTTP/1.1 200 OK\n\nNGINX reload requested at: $(date)"; nginx -s reload & } | nc -l -p 9000 -q 1
  done
) &

# original entrypoint for nginx
exec /nginx-entrypoint.sh "$@"
