FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libicu-dev \
    icu-devtools \
    libxml2-dev \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN gcc --version && make --version

RUN docker-php-ext-install -v pdo
RUN docker-php-ext-install -v pdo_pgsql
RUN docker-php-ext-install -v pgsql
RUN docker-php-ext-install -v mbstring
RUN docker-php-ext-install -v simplexml xml xmlwriter
RUN docker-php-ext-install -v intl

RUN docker-php-ext-enable pdo pdo_pgsql pgsql mbstring simplexml xml xmlwriter intl

RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

CMD ["apache2-foreground"]
