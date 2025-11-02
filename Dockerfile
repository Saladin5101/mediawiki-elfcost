# 基于 PHP 8.2 + Apache 镜像（MediaWiki 推荐版本）
FROM php:8.2-apache

# 安装 MediaWiki 必需的 PHP 扩展（PostgreSQL 支持、字符编码等）
RUN docker-php-ext-install pdo pdo_pgsql pgsql mbstring xml intl

# 启用 Apache 重写模块（MediaWiki 的 URL 美化需要）
RUN a2enmod rewrite

# 复制仓库里的 MediaWiki 文件到 Apache 根目录（/var/www/html）
COPY . /var/www/html/

# 给 Apache 权限访问文件（避免读写错误）
RUN chown -R www-data:www-data /var/www/html

# 启动命令（用 Apache 自带的前台启动方式，适配 Render）
CMD ["apache2-foreground"]
