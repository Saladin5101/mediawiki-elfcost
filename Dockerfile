# 使用MediaWiki官方1.46.1版本镜像
FROM mediawiki:1.46.1

# 补充PostgreSQL驱动（修复换行符，确保命令连续）
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \  # 行尾加反斜杠，连接下一行命令
    && docker-php-ext-install pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

# 配置Apache支持Rewrite
RUN a2enmod rewrite \
    && echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf \
    && echo '    AllowOverride All' >> /etc/apache2/apache2.conf \
    && echo '</Directory>' >> /etc/apache2/apache2.conf

CMD ["apache2-foreground"]
