FROM php:8.1-apache

# 安装系统依赖（精简且无冲突）
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 安装并更新Composer到最新版本（避免旧版本解析依赖失败）
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer self-update

# 提取PHP源码并安装扩展
RUN docker-php-source extract
RUN set -x && docker-php-ext-install -j1 pdo_pgsql
RUN set -x && docker-php-ext-install -j1 pgsql
RUN set -x && docker-php-ext-install -j1 mbstring
RUN set -x && docker-php-ext-install -j1 intl
RUN set -x && docker-php-ext-install -j1 simplexml xml xmlwriter
RUN docker-php-source delete

# 启用扩展并验证（新增：检查扩展是否正确安装）
RUN docker-php-ext-enable pdo_pgsql pgsql mbstring intl \
    && php -m | grep -E 'pdo_pgsql|pgsql|mbstring|intl'

# 配置Apache
RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 复制源码并提前设置权限（确保Composer有写入权限）
COPY . /var/www/html/
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html

# 安装MediaWiki依赖（增加-vvv输出详细日志，方便定位错误）
RUN composer install --no-dev -vvv

CMD ["apache2-foreground"]
