#!/bin/bash

if ! [ -x "$(command -v docker-compose)" ]; then
echo 'Error: docker-compose is not installed.' >&2
exit 1
fi

domains=(mydomain.com)
rsa_key_size=4096
data_path="./data/certbot"
email="mymail@mail.com" # Adding a valid address is strongly recommended
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits
subscribe_to_eff=1 # Set to 1 if you provided an e-mail address and want to subscribe to EFF mailings

if [ -d "$data_path" ]; then
read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
	exit
fi
fi

echo "### Creating dummy certificate for $domains ..."
path="/etc/letsencrypt/live/$domains"
mkdir -p "$data_path/conf/live/$domains"

docker-compose run --rm --entrypoint "\
openssl req -x509 -nodes -newkey rsa:2048 -days 1\
-keyout '$path/privkey.pem' \
-out '$path/fullchain.pem' \
-subj '/CN=localhost'" certbot
docker ps
echo

echo "### Starting nginx ..."
docker-compose up --force-recreate -d nginx
echo

echo "### Deleting dummy certificate for $domains ..."
docker-compose run --rm --entrypoint "\
rm -Rf /etc/letsencrypt/live/$domains && \
rm -Rf /etc/letsencrypt/archive/$domains && \
rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
echo

echo "### Requesting Let's Encrypt certificate for $domains ..."
#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
	domain_args="$domain_args -d $domain"
done
echo "domain args ..."
echo $domain_args

# Select appropriate email arg
case "$email" in
"") email_arg="--register-unsafely-without-email" ;;
*)  email_arg="--email $email"
		if [ $subscribe_to_eff == "1" ]; then
			subscribe_arg="--eff-email";
		else
			subscribe_arg="--no-eff-email";
		fi
;;
esac

# Enable staging mode if needed
if [ $staging != "0" ]; then 
staging_arg="--staging"; 
fi

docker-compose run --rm --entrypoint "certbot certonly -a webroot -v --debug-challenges -w /var/www/certbot $staging_arg $email_arg $domain_args $subscribe_arg --rsa-key-size $rsa_key_size --agree-tos --force-renewal" certbot
echo
echo "### Reloading nginx ..."
docker-compose exec nginx nginx -s reload
