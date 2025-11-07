# 最新版MediaWiki（带Apache）
FROM mediawiki:latest

# 分步安装PostgreSQL驱动（无语法坑）
RUN apt-get update
RUN apt-get install -y --no-install-recommends libpq-dev
RUN docker-php-ext-install pdo_pgsql
RUN rm -rf /var/lib/apt/lists/*

# 配置Apache重写
RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf
RUN echo '    AllowOverride All' >> /etc/apache2/apache2.conf
RUN echo '</Directory>' >> /etc/apache2/apache2.conf
COPY LocalSettings.php /var/www/html/
RUN chown www-data:www-data /var/www/html/LocalSettings.php
RUN chmod 644 /var/www/html/LocalSettings.php
CMD ["apache2-foreground"]
