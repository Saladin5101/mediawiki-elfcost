FROM php:8.2-apache

# 1. 安装所有必要系统库（含最基础的C编译库）
RUN apt-get update && apt-get install -y \
    build-essential \
    libc6-dev \
    libpq-dev \
    libicu-dev \
    icu-devtools \
    libxml2-dev \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. 强制获取PHP源码（关键！确保编译扩展时有完整源码）
RUN docker-php-source extract

# 3. 分步安装扩展（带最详细日志输出）
RUN set -x \
    && docker-php-ext-install -v pdo

RUN set -x \
    && docker-php-ext-install -v pdo_pgsql

RUN set -x \
    && docker-php-ext-install -v pgsql

RUN set -x \
    && docker-php-ext-install -v mbstring

RUN set -x \
    && docker-php-ext-install -v simplexml xml xmlwriter

RUN set -x \
    && docker-php-ext-install -v intl

# 4. 清理PHP源码（可选，减小镜像体积）
RUN docker-php-source delete

# 5. 启用扩展
RUN docker-php-ext-enable pdo pdo_pgsql pgsql mbstring simplexml xml xmlwriter intl

# 6. 配置Apache
RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 7. 复制文件并修复权限
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

CMD ["apache2-foreground"]
