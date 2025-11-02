FROM php:8.1-apache

# 关键调整：移除多余的php-cli（镜像已自带），添加--no-install-recommends减少依赖冲突
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 安装Composer（无需php-cli，镜像已自带PHP命令）
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 提取PHP源码
RUN docker-php-source extract

# 安装扩展
RUN set -x && docker-php-ext-install -j1 pdo_pgsql
RUN set -x && docker-php-ext-install -j1 pgsql
RUN set -x && docker-php-ext-install -j1 mbstring
RUN set -x && docker-php-ext-install -j1 intl
RUN set -x && docker-php-ext-install -j1 simplexml xml xmlwriter

# 清理源码
RUN docker-php-source delete

# 启用扩展
RUN docker-php-ext-enable pdo_pgsql pgsql mbstring intl

# 配置Apache
RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 复制源码并安装MediaWiki依赖
COPY . /var/www/html/
WORKDIR /var/www/html
RUN composer install --no-dev  # 安装生产环境依赖
RUN chown -R www-data:www-data /var/www/html

CMD ["apache2-foreground"]
