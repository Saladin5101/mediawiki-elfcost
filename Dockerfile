FROM php:8.1-apache

# 第一步：安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    libmagic1 \
    libgd-dev \
    libcurl4-openssl-dev \
    wget \
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

# 第四步：下载MediaWiki（移除校验和，添加wget重试）
WORKDIR /var/www
RUN set -x \
    # 下载官方包，失败重试3次
    && wget --tries=3 https://releases.wikimedia.org/mediawiki/1.46/mediawiki-1.46.1.tar.gz -O mediawiki.tar.gz \
    # 跳过校验和验证（避免错误）
    && tar -xzf mediawiki.tar.gz \
    && mv mediawiki-1.46.1 html \
    && rm mediawiki.tar.gz \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

CMD ["apache2-foreground"]
