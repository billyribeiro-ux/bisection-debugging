composer install --no-dev --no-interaction --prefer-dist 2>&1 || exit 125
./vendor/bin/phpunit
