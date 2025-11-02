# 基于官方PHP 8.2 + Apache镜像（MediaWiki 1.44.2推荐版本）
FROM php:8.2-apache

# 第一步：安装系统依赖（解决libpq-fe.h缺失、扩展编译等问题）
RUN apt-get update && apt-get install -y \
    libpq-dev \                  # PostgreSQL客户端开发库（核心，解决libpq-fe.h缺失）
    libicu-dev \                 # 国际化扩展（MediaWiki多语言支持必需）
    libxml2-dev \                # XML处理扩展依赖
    wget \                       # 用于后续可能的文件下载
    unzip \                      # 解压工具
    && rm -rf /var/lib/apt/lists/*  # 清理缓存，减小镜像体积

# 第二步：安装MediaWiki必需的PHP扩展
RUN docker-php-ext-install \
    pdo \                # 数据库连接基础
    pdo_pgsql \          # PostgreSQL PDO驱动（核心数据库支持）
    pgsql \              # PostgreSQL原生驱动
    mbstring \           # 多字节字符串处理（中文等字符支持）
    xml \                # XML解析（配置文件、扩展依赖）
    intl \               # 国际化（日期、语言格式处理）
    && docker-php-ext-enable \
    pdo_pgsql pgsql mbstring xml intl  # 启用扩展

# 第三步：配置Apache（支持URL重写、适配MediaWiki）
RUN a2enmod rewrite  # 启用重写模块（MediaWiki的友好URL必需）
# 修改Apache配置，允许.htaccess文件生效（MediaWiki的URL重写依赖）
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 第四步：复制仓库中的MediaWiki文件到Apache根目录（/var/www/html是Apache默认目录）
COPY . /var/www/html/

# 第五步：修复文件权限（避免Apache读写文件时出现权限错误）
RUN chown -R www-data:www-data /var/www/html \  # 给Apache用户（www-data）所有权
    && chmod -R 755 /var/www/html                # 开放读写执行权限（安全范围内）

# 第六步：启动命令（用Apache前台运行模式，适配Render容器环境）
CMD ["apache2-foreground"]
