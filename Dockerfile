FROM php:8.1-apache

# 第一步：安装系统依赖（确保有curl）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    libmagic1 \
    libgd-dev \
    libcurl4-openssl-dev \
    curl \  # 用curl替代wget
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 第二步：安装PHP扩展
RUN docker-php-source extract \
    && docker-php-ext-install -j1 pdo_pgsql pgsql mbstring intl simplexml xml xmlwriter fileinfo gd curl \
    && docker-php-source delete

# 第三步：配置Apache
RUN a2enmod rewrite \
    && echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '    Require all granted' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 第四步：用curl下载MediaWiki（更稳定，支持重试和超时）
WORKDIR /var/www
RUN set -x \
    # 用curl下载，重试5次，超时30秒
    && curl -fL --retry 5 --retry-delay 10 --connect-timeout 30 \
       https://releases.wikimedia.org/mediawiki/1.46/mediawiki-1.46.1.tar.gz \
       -o mediawiki.tar.gz \
    # 解压并处理文件
    && tar -xzf mediawiki.tar.gz \
    && mv mediawiki-1.46.1 html \
    && rm mediawiki.tar.gz \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

CMD ["apache2-foreground"]
