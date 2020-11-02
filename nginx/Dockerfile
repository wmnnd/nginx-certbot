FROM nginx:1.19-alpine

RUN set -x \
&&  apk add --no-cache \
      apache2-utils \
      curl \
      bash \
      netcat-openbsd \
      openssl \
&&  mkdir -p /etc/nginx/letsencrypt \
&&  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "/etc/nginx/letsencrypt/options-ssl-nginx.conf" \
&&  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "/etc/nginx/letsencrypt/ssl-dhparams.pem" \
&&  chown -R nginx /etc/nginx/letsencrypt \
&&  rm -rf /var/cache/apk/* \
           /tmp/* \
           /var/tmp/*

RUN curl -s https://raw.githubusercontent.com/nginxinc/docker-nginx/master/mainline/alpine/docker-entrypoint.sh > "/nginx-entrypoint.sh" \
&&  chmod +x /nginx-entrypoint.sh
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
