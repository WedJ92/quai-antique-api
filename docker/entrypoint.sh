#!/bin/sh
# Lancé à chaque démarrage du conteneur de l'API
set -e

# Crée ou met à jour les tables (user, restaurant, picture...)
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration

# Vide le cache et redonne les droits à Apache
php bin/console cache:clear
chown -R www-data:www-data var

# Démarre Apache au premier plan (le conteneur vit tant qu'Apache tourne)
exec apache2-foreground
