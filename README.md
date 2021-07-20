# Boilerplate for nginx with Let’s Encrypt on docker-compose

> This repository is accompanied by a [step-by-step guide on how to
set up nginx and Let’s Encrypt with Docker](https://medium.com/@pentacent/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71).

`init-letsencrypt.sh` fetches and ensures the renewal of a Let’s
Encrypt certificate for one or multiple domains in a docker-compose
setup with nginx.
This is useful when you need to set up nginx as a reverse proxy for an
application.

## Installation
1. [Install docker-compose](https://docs.docker.com/compose/install/#install-compose).

2. Clone this repository: `git clone https://github.com/wmnnd/nginx-certbot.git .`

3. Modify configuration:
- Create a .env file and add domains and email addresses using the env variables defined below 
- NGINX_DOMAIN_LIST - [REQUIRED] the list of domains for nginx (also used by letsencrypt); each domain name should be separated by a space; the first domain name will be taken as the primary domain unless NGINX_PRIMARY_DOMAIN env variable is also provided; defaults to "example.org www.example.org"
- NGINX_PRIMARY_DOMAIN - [OPTIONAL] the primary domain name to use for certificate registration; defaults to "example.org"
- NGINX_PROXY_PASS - [REQUIRED] the url to route all incoming requests on ports 80, 443; for example "http://localhost:8080" to forward all incoming to localhost:8080; defaults to "http://example.org"
- LETSENCRYPT_EMAIL - [OPTIONAL] the email id to use for LetsEncrypt registration; defaults to ""
- LETSENCRYPT_STAGING - [OPTIONAL] Set to 1 if you're testing your setup to avoid hitting request limits; defaults to 0

4. Run the init script:

        ./init-letsencrypt.sh

5. Run the server:

        docker-compose up

## Got questions?
Feel free to post questions in the comment section of the [accompanying guide](https://medium.com/@pentacent/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71)

## License
All code in this repository is licensed under the terms of the `MIT License`. For further information please refer to the `LICENSE` file.
