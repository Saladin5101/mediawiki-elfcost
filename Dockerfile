FROM php:8.1-apache

# 安装必要依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# 提取PHP源码（供其他扩展编译）
RUN docker-php-source extract

# 只安装非内置的扩展（pdo已内置，无需安装）
RUN set -x && docker-php-ext-install -j1 -v pdo_pgsql  # PostgreSQL的PDO驱动（非内置）
RUN set -x && docker-php-ext-install -j1 -v pgsql      # PostgreSQL原生驱动（非内置）
RUN set -x && docker-php-ext-install -j1 -v mbstring   # 多字节字符串（部分环境需手动装）
RUN set -x && docker-php-ext-install -j1 -v intl       # 国际化扩展（非内置）
RUN set -x && docker-php-ext-install -j1 -v simplexml xml xmlwriter  # XML相关扩展

# 清理源码
RUN docker-php-source delete

# 启用所有扩展（包括内置的pdo）
RUN docker-php-ext-enable pdo pdo_pgsql pgsql mbstring intl simplexml xml xmlwriter

# 配置Apache
RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 复制文件并修复权限
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html

CMD ["apache2-foreground"]
