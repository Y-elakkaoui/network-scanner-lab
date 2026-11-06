# Same Apache major version as the original lab (2.4.58 on Ubuntu 24.04).
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends apache2 \
    && a2enmod headers \
    && rm -f /var/www/html/index.html
CMD ["apache2ctl", "-D", "FOREGROUND"]
