# 换用PHP 8.1（比8.2更稳定，MediaWiki 1.44.2完全兼容）
FROM php:8.1-apache

# 1. 安装所有底层依赖（包含pkg-config处理库依赖）
RUN apt-get update && apt-get install -y \
    build-essential \
    libc6-dev \
    pkg-config \
    libpq-dev \
    libicu-dev \
    icu-devtools \
    libxml2-dev \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. 提取PHP源码并确保权限
RUN docker-php-source extract \
    && chmod -R 777 /usr/src/php

# 3. 单线程编译pdo（避免多线程资源冲突，关键！）
RUN set -x \
    && make -j1 \
    && docker-php-ext-install -j1 -v pdo

# 4. 继续单线程安装其他扩展
RUN set -x \
    && docker-php-ext-install -j1 -v pdo_pgsql

RUN set -x \
    && docker-php-ext-install -j1 -v pgsql

RUN set -x \
    && docker-php-ext-install -j1 -v mbstring

RUN set -x \
    && docker-php-ext-install -j1 -v simplexml xml xmlwriter

RUN set -x \
    && docker-php-ext-install -j1 -v intl

# 5. 清理源码
RUN docker-php-source delete

# 6. 启用扩展
RUN docker-php-ext-enable pdo pdo_pgsql pgsql mbstring simplexml xml xmlwriter intl

# 7. 配置Apache
RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 8. 复制文件并修复权限
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

CMD ["apache2-foreground"]
