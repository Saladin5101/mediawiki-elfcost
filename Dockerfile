# 直接基于MediaWiki官方1.46版本镜像（已包含所有依赖）
FROM mediawiki:1.46

# 安装PostgreSQL驱动（官方镜像默认不含，补充上）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && docker-php-ext-install pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

# 配置Apache（允许Rewrite和目录权限）
RUN a2enmod rewrite \
    && echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 启动服务
CMD ["apache2-foreground"]
