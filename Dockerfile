# 使用MediaWiki官方1.46.1版本镜像（标签存在且稳定）
FROM mediawiki:1.46.1

# 补充PostgreSQL驱动（官方镜像默认不含，必须安装）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \  # PostgreSQL扩展依赖库
    && docker-php-ext-install pdo_pgsql \  # 安装pgsql驱动
    && rm -rf /var/lib/apt/lists/*  # 清理缓存

# 配置Apache支持Rewrite（MediaWiki需要）
RUN a2enmod rewrite \
    && echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

# 启动服务
CMD ["apache2-foreground"]
