FROM mediawiki:1.46.1

# 单独更新包索引
RUN apt-get update

# 单独安装PostgreSQL依赖库
RUN apt-get install -y --no-install-recommends libpq-dev

# 单独安装pgsql扩展
RUN docker-php-ext-install pdo_pgsql

# 单独清理缓存
RUN rm -rf /var/lib/apt/lists/*

# 单独启用Apache重写模块
RUN a2enmod rewrite

# 单独配置Apache目录权限（分多行echo，不用&&）
RUN echo '<Directory "/var/www/html">' >> /etc/apache2/apache2.conf
RUN echo '    AllowOverride All' >> /etc/apache2/apache2.conf
RUN echo '</Directory>' >> /etc/apache2/apache2.conf

# 启动命令
CMD ["apache2-foreground"]
