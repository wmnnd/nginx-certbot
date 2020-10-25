FROM nginx:1.15-alpine

RUN apk add --no-cache \
      curl \
      bash \
      openssl \
&&  mkdir -p /etc/nginx/letsencrypt \
&&  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "/etc/nginx/letsencrypt/options-ssl-nginx.conf" \
&&  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "/etc/nginx/letsencrypt/ssl-dhparams.pem" \
&&  chown -R nginx /etc/nginx/letsencrypt \
&&  rm -rf /var/cache/apk/* \
           /tmp/* \
           /var/tmp/*

COPY ./scripts/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
