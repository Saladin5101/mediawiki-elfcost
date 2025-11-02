FROM php:8.1-apache

# 第一步：安装系统依赖（新增Composer所需的php-cli、curl等）
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    php-cli \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 第二步：安装Composer（PHP的依赖管理工具）
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 第三步：提取PHP源码（供扩展编译）
RUN docker-php-source extract

# 第四步：安装MediaWiki必需的PHP扩展
RUN set -x && docker-php-ext-install -j1 pdo_pgsql
RUN set -x && docker-php-ext-install -j1 pgsql
RUN set -x && docker-php-ext-install -j1 mbstring
RUN set -x && docker-php-ext-install -j1 intl
RUN set -x && docker-php-ext-install -j1 simplexml xml xmlwriter

# 第五步：清理PHP源码
RUN docker-php-source delete

# 第六步：启用手动安装的扩展
RUN docker-php-ext-enable pdo_pgsql pgsql mbstring intl

# 第七步：配置Apache
RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 第八步：复制MediaWiki源码到Apache目录
COPY . /var/www/html/

# 第九步：用Composer安装MediaWiki的外部依赖（核心步骤！）
WORKDIR /var/www/html  # 切换到MediaWiki根目录
RUN composer install --no-dev  # --no-dev：只安装生产环境依赖，减小体积
RUN chown -R www-data:www-data /var/www/html  # 修复依赖目录的权限

CMD ["apache2-foreground"]
