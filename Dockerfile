# ===== Image de l'API Symfony Quai Antique =====
# PHP 8.2 + serveur Apache intégré
FROM php:8.2-apache

# 1. Outils système nécessaires aux extensions PHP et à Composer
RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip libicu-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Extensions PHP demandées par l'API (MySQL, intl, zip)
RUN docker-php-ext-install pdo_mysql intl zip opcache

# 3. Composer, récupéré depuis son image officielle
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 4. Apache : le site est dans public/ et toutes les routes passent par index.php
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && printf '<Directory /var/www/html/public>\n    AllowOverride None\n    FallbackResource /index.php\n</Directory>\n' \
       > /etc/apache2/conf-available/symfony.conf \
    && a2enconf symfony

WORKDIR /var/www/html

# 5. Installe les bibliothèques PHP (équivalent de npm install)
COPY composer.json composer.lock symfony.lock ./
RUN composer install --no-interaction --no-scripts --prefer-dist

# 6. Copie le code de l'API, puis termine l'installation
COPY . .
RUN composer run-script auto-scripts --no-interaction \
    && chown -R www-data:www-data var

# 7. Script lancé au démarrage du conteneur (migrations puis Apache)
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
# (sed retire les fins de ligne Windows qui casseraient le script)
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80
ENTRYPOINT ["entrypoint.sh"]
