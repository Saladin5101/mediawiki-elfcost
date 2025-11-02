# 基础镜像：PHP 8.1 + Apache（稳定兼容MediaWiki 1.46）
FROM php:8.1-apache

# 第一步：安装所有系统依赖（对应PHP扩展的底层库）
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 编译工具
    build-essential \
    # PostgreSQL扩展依赖
    libpq-dev \
    # intl扩展依赖
    libicu-dev \
    # mbstring扩展依赖
    libonig-dev \
    # XML相关扩展依赖
    libxml2-dev \
    # fileinfo扩展依赖（处理文件类型）
    libmagic1 \
    # gd扩展依赖（图片处理）
    libgd-dev \
    # curl扩展依赖（网络请求）
    libcurl4-openssl-dev \
    # Composer所需工具
    curl \
    git \
    # 清理缓存（减小镜像体积）
    && rm -rf /var/lib/apt/lists/*

# 第二步：安装PHP扩展（MediaWiki 1.46必需）
RUN docker-php-source extract \
    # 数据库相关
    && docker-php-ext-install -j1 pdo_pgsql pgsql \
    # 文本处理
    && docker-php-ext-install -j1 mbstring \
    # 国际化
    && docker-php-ext-install -j1 intl \
    # XML处理
    && docker-php-ext-install -j1 simplexml xml xmlwriter \
    # 文件处理
    && docker-php-ext-install -j1 fileinfo \
    # 图片处理
    && docker-php-ext-install -j1 gd \
    # 网络请求
    && docker-php-ext-install -j1 curl \
    # 清理源码
    && docker-php-source delete

# 第三步：安装并配置Composer（依赖管理工具）
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer self-update \
    # 配置镜像源（解决网络下载问题）
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# 第四步：配置Apache（支持Rewrite和目录权限）
RUN a2enmod rewrite \
    && echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 第五步：复制MediaWiki源码并设置权限
COPY . /var/www/html/
WORKDIR /var/www/html
# 开放权限（避免Composer写入失败）
RUN chmod -R 777 /var/www/html \
    && mkdir -p /root/.composer \
    && chmod -R 777 /root/.composer

# 第六步：安装MediaWiki依赖（跳过插件和脚本，避免权限冲突）
RUN rm -rf composer.lock  # 删除锁定文件，让Composer重新计算依赖
RUN composer clear-cache  # 彻底清理旧缓存
# 增加超时时间+优先下载压缩包，避免网络超时
RUN composer install --no-dev -vvv --no-plugins --no-scripts --prefer-dist --timeout=300
# 启动Apache
CMD ["apache2-foreground"]
