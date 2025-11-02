FROM php:8.1-apache

# 1. 安装系统依赖（新增fileinfo扩展依赖libmagic1）
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    libmagic1 \  # fileinfo扩展依赖（MediaWiki处理文件需要）
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装并更新Composer，添加国内镜像（解决网络下载问题）
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer self-update \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/  # 国内镜像加速

# 3. 提取PHP源码，安装MediaWiki必需的所有扩展（新增fileinfo）
RUN docker-php-source extract \
    && docker-php-ext-install -j1 pdo_pgsql \
    && docker-php-ext-install -j1 pgsql \
    && docker-php-ext-install -j1 mbstring \
    && docker-php-ext-install -j1 intl \
    && docker-php-ext-install -j1 simplexml xml xmlwriter \
    && docker-php-ext-install -j1 fileinfo \  # 新增：处理文件类型检测（MediaWiki必需）
    && docker-php-source delete

# 4. 验证所有必需扩展是否加载（关键！缺失会导致Composer失败）
RUN echo "验证PHP扩展是否安装成功：" \
    && php -m | grep -E 'pdo_pgsql|pgsql|mbstring|intl|simplexml|xml|xmlwriter|fileinfo' \
    || (echo "缺少必需的PHP扩展！" && exit 1)

# 5. 配置Apache
RUN a2enmod rewrite \
    && echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 6. 复制源码，设置完整权限（包括Composer缓存目录）
COPY . /var/www/html/
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html \
    && mkdir -p /root/.composer \  # 创建Composer缓存目录
    && chown -R www-data:www-data /root/.composer  # 给缓存目录权限

# 7. 验证composer.json完整性，再安装依赖
RUN composer validate --no-check-publish  # 检查依赖文件是否有语法错误
RUN composer install --no-dev -vvv  # 详细日志输出

CMD ["apache2-foreground"]
