FROM php:8.1-apache

# 安装必要依赖（新增libonig-dev，mbstring的核心依赖）
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev 
    && rm -rf /var/lib/apt/lists/*

# 提取PHP源码
RUN docker-php-source extract

# 安装扩展（顺序不变，确保依赖正确）
RUN set -x && docker-php-ext-install -j1 pdo_pgsql
RUN set -x && docker-php-ext-install -j1 pgsql
RUN set -x && docker-php-ext-install -j1 mbstring  # 现在有了libonig-dev，可正常编译
RUN set -x && docker-php-ext-install -j1 intl
RUN set -x && docker-php-ext-install -j1 simplexml xml xmlwriter

# 清理源码
RUN docker-php-source delete

# 启用扩展
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
