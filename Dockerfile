# 用PHP 8.1稳定版
FROM php:8.1-apache

# 1. 安装最精简的必要依赖（只保留编译必需的）
RUN apt-get update && apt-get install -y \
    build-essential \
    libc6-dev \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. 提取PHP源码（供扩展编译使用）
RUN docker-php-source extract

# 3. 直接用docker-php-ext-install安装扩展（内部会自动调用make）
RUN set -x && docker-php-ext-install -j1 -v pdo

RUN set -x && docker-php-ext-install -j1 -v pdo_pgsql

RUN set -x && docker-php-ext-install -j1 -v pgsql

RUN set -x && docker-php-ext-install -j1 -v mbstring

RUN set -x && docker-php-ext-install -j1 -v simplexml xml xmlwriter

RUN set -x && docker-php-ext-install -j1 -v intl

# 4. 清理源码
RUN docker-php-source delete

# 5. 启用扩展
RUN docker-php-ext-enable pdo pdo_pgsql pgsql mbstring simplexml xml xmlwriter intl

# 6. 配置Apache（仅保留必需项）
RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 7. 复制文件并修复权限
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html

CMD ["apache2-foreground"]
