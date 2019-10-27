#!/bin/bash
set -e

domains=(example.com www.example.com) # Specify domains here or use the -d argument
data_path="./data/certbot" # Specify data path here or use the --data-path argument
email="" # Specify email here or use the --email argument
staging=0 # Set to 1 here or use the --staging argument
rsa_key_size=4096

print_help() {
  echo "Usage: `basename $0` [-d DOMAIN] [--staging] [-f COMPOSE_FILE] [--data-path PATH]"
  echo ""
  echo "You can either modify `basename $0` directly or use the following options to adjust its behavior."
  echo ""
  echo "Options:"
  echo "-h, --help:          Print this help."
  echo "-d, --domain DOMAIN: Request certificates for the given DOMAIN. Can be used multiple times (e.g. -d example.com -d www.example.com)."
  echo "-f, --file PATH:     If given, use specified docker-compose configuration file."
  echo "-m, --email EMAIL:   If given, use EMAIL to registert Let's Encrypt account"
  echo "--staging:           Use Let's Encrypt in Staging Mode"
  echo "--data-path:         Set path for storing certificate data"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      print_help
      exit
      ;;
    -d|--domain)
      if [ "${domains[0]}" == "example.com" ]; then domains=(); fi
      domains+=("$2")
      shift; shift
      ;;
    --staging)
      staging=1
      shift;
      ;;
    -f|--file)
      compose_file="$2"
      shift; shift
      ;;
    -m|--email)
      email="$2"
      shift; shift
      ;;
    --data-path)
      data_path="$2"
      shift; shift
      ;;
    *)
      echo "Unknown argument: $1"
      exit
      ;;
  esac
done

# Make sure at least one domain has been configured
if [ "${domains[0]}" == "example.com" ] || [ "${domains[0]}" == "" ]; then
  echo "Error: You must specify at least one domain."
  exit 1
fi

# Set compose_file_arg if requested
if [ "$compose_file" != "" ]; then
  compose_file_arg="-f $compose_file"
else
  compose_file_arg=""
fi

# Ask for confirmation before replacing existing certificates
if [ -d "$data_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

# Download TLS parameters
if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  mkdir -p "$data_path/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
  echo
fi

# Create dummy certificate
echo "### Creating dummy certificate for $domains ..."
path="/etc/letsencrypt/live/all"
mkdir -p "$data_path/conf/live/all"
docker-compose ${compose_file_arg} run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:1024 -days 1 \
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot
echo

# Start nginx
echo "### Starting nginx ..."
docker-compose ${compose_file_arg} up --force-recreate --no-deps -d nginx
echo

# Delete dummy certificate
echo "### Deleting dummy certificate for $domains ..."
docker-compose ${compose_file_arg} run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/all && \
  rm -Rf /etc/letsencrypt/archive/all && \
  rm -Rf /etc/letsencrypt/renewal/all.conf" certbot
echo


echo "### Requesting Let's Encrypt certificate for $domains ..."
# Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

# Enable staging mode if requested
if [ $staging != "0" ]; then staging_arg="--staging"; fi

docker-compose ${compose_file_arg} run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    ${staging_arg} \
    ${email_arg} \
    ${domain_args} \
    --cert-name all \
    --rsa-key-size ${rsa_key_size} \
    --agree-tos \
    --force-renewal" certbot
echo

# Reload nginx
echo "### Reloading nginx ..."
docker-compose ${compose_file_arg} exec nginx nginx -s reload
