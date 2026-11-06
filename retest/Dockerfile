# Same Apache major version as the original lab (2.4.58 on Ubuntu 24.04).
FROM ubuntu:24.04
ARG CONF
RUN apt-get update && apt-get install -y --no-install-recommends apache2 \
    && a2enmod headers \
    && rm -f /var/www/html/index.html
COPY ${CONF} /etc/apache2/conf-available/security.conf
RUN apache2ctl configtest
CMD ["apache2ctl", "-D", "FOREGROUND"]
