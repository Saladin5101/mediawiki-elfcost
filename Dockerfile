FROM php:8.1-apache

# 修复换行符：每个包后用\结尾（无多余空格），确保属于同一RUN指令
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    libmagic1 \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 安装Composer并配置国内镜像
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer self-update \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# 安装PHP扩展（含fileinfo）
RUN docker-php-source extract \
    && docker-php-ext-install -j1 pdo_pgsql \
    && docker-php-ext-install -j1 pgsql \
    && docker-php-ext-install -j1 mbstring \
    && docker-php-ext-install -j1 intl \
    && docker-php-ext-install -j1 simplexml xml xmlwriter \
    && docker-php-ext-install -j1 fileinfo \
    && docker-php-source delete

# 验证扩展
RUN echo "验证PHP扩展：" \
    && php -m | grep -E 'pdo_pgsql|pgsql|mbstring|intl|simplexml|xml|xmlwriter|fileinfo' \
    || (echo "缺少必需扩展！" && exit 1)

# 配置Apache
RUN a2enmod rewrite \
    && echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 复制源码并设置权限
COPY . /var/www/html/
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html \
    && mkdir -p /root/.composer \
    && chown -R www-data:www-data /root/.composer

# 直接安装依赖（移除validate，用www-data用户执行避免权限问题）
USER www-data  # 切换到Apache运行用户，避免权限冲突
RUN composer install --no-dev -vvv

# 切回root用户执行后续命令（可选，不影响）
USER root

CMD ["apache2-foreground"]
