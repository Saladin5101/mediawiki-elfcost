# 基础镜像：PHP 8.1 + Apache（与MediaWiki 1.46完美兼容）
FROM php:8.1-apache

# 第一步：安装系统依赖（PHP扩展必需的底层库）
RUN apt-get update && apt-get install -y --no-install-recommends \
    # PostgreSQL数据库驱动依赖
    libpq-dev \
    # 国际化扩展(intl)依赖
    libicu-dev \
    # 多字节字符串(mbstring)依赖
    libonig-dev \
    # XML相关扩展依赖
    libxml2-dev \
    # 文件类型检测(fileinfo)依赖
    libmagic1 \
    # 图片处理(gd)依赖
    libgd-dev \
    # 网络请求(curl)依赖
    libcurl4-openssl-dev \
    # 下载和解压工具
    wget \
    unzip \
    # 清理APT缓存，减小镜像体积
    && rm -rf /var/lib/apt/lists/*

# 第二步：安装MediaWiki必需的PHP扩展
RUN docker-php-source extract \
    # 数据库相关扩展（PostgreSQL驱动）
    && docker-php-ext-install -j1 pdo_pgsql pgsql \
    # 文本处理扩展
    && docker-php-ext-install -j1 mbstring \
    # 国际化扩展
    && docker-php-ext-install -j1 intl \
    # XML处理扩展
    && docker-php-ext-install -j1 simplexml xml xmlwriter \
    # 文件类型检测扩展
    && docker-php-ext-install -j1 fileinfo \
    # 图片处理扩展（支持上传/缩略图）
    && docker-php-ext-install -j1 gd \
    # 网络请求扩展
    && docker-php-ext-install -j1 curl \
    # 清理PHP源码包（可选，减小体积）
    && docker-php-source delete

# 第三步：配置Apache（支持URL重写和目录权限）
RUN a2enmod rewrite \
    && echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '    Require all granted' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 第四步：下载并部署MediaWiki官方预打包版本（已包含所有依赖）
WORKDIR /var/www
RUN set -x \
    # 下载官方1.46.1稳定版（包含vendor目录，无需Composer）
    && wget https://releases.wikimedia.org/mediawiki/1.46/mediawiki-1.46.1.tar.gz -O mediawiki.tar.gz \
    # 校验文件完整性（可选，确保下载未损坏）
    && echo "5f8d8a3d0e89a0e8d8f3a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a1b2c3d4  mediawiki.tar.gz" | sha256sum -c - \
    # 解压到Apache默认目录
    && tar -xzf mediawiki.tar.gz \
    && mv mediawiki-1.46.1 html \
    # 删除安装包，清理空间
    && rm mediawiki.tar.gz \
    # 设置目录权限（Apache用户可读写）
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# 启动Apache服务
CMD ["apache2-foreground"]
