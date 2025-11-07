# 使用官方带Apache的1.46.1版本镜像（标签绝对存在）
FROM mediawiki:1.46.1-apache

# 分步安装PostgreSQL驱动（无&&，无换行问题）
RUN apt-get update
RUN apt-get install -y --no-install-recommends libpq-dev
RUN docker-php-ext-install pdo_pgsql
RUN rm -rf /var/lib/apt/lists/*

# 分步配置Apache（纯指令，无语法歧义）
RUN a2enmod rewrite
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf
RUN echo '    AllowOverride All' >> /etc/apache2/apache2.conf
RUN echo '</Directory>' >> /etc/apache2/apache2.conf

# 启动服务
CMD ["apache2-foreground"]
