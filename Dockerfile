FROM php:8.2-apache

# 1. 安装所有系统依赖（确保扩展编译的基础库完整）
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. 分步安装PHP扩展（每步单独执行，方便定位错误）
# 安装pdo
RUN docker-php-ext-install -v pdo
# 安装pdo_pgsql
RUN docker-php-ext-install -v pdo_pgsql
# 安装pgsql
RUN docker-php-ext-install -v pgsql
# 安装mbstring
RUN docker-php-ext-install -v mbstring
# 安装xml相关扩展（用更具体的xml扩展名）
RUN docker-php-ext-install -v simplexml xml xmlwriter
# 安装intl
RUN docker-php-ext-install -v intl

# 3. 启用扩展（合并为一条命令）
RUN docker-php-ext-enable pdo pdo_pgsql pgsql mbstring simplexml xml xmlwriter intl

# 4. 配置Apache
RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 5. 复制文件并修复权限
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

CMD ["apache2-foreground"]
