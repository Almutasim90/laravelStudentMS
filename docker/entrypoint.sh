#!/bin/sh
set -e

echo "──────────────────────────────────────────"
echo "  Student Management System — Booting..."
echo "──────────────────────────────────────────"

# Ensure .env exists (copy from .env.production if present)
if [ ! -f /var/www/html/.env ]; then
    if [ -f /var/www/html/.env.production ]; then
        cp /var/www/html/.env.production /var/www/html/.env
        echo "[✓] .env created from .env.production"
    else
        echo "[!] WARNING: No .env file found. Set environment variables manually."
    fi
fi

# Ensure SQLite file exists
mkdir -p /var/www/html/database
if [ ! -f /var/www/html/database/database.sqlite ]; then
    touch /var/www/html/database/database.sqlite
    echo "[✓] SQLite database file created"
fi

# Fix permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/database
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
chmod 664 /var/www/html/database/database.sqlite
echo "[✓] Permissions set"

cd /var/www/html

# Generate app key if not set
if [ -z "$(grep '^APP_KEY=base64:' .env 2>/dev/null)" ]; then
    php artisan key:generate --force
    echo "[✓] App key generated"
fi

# Run migrations
php artisan migrate --force
echo "[✓] Migrations complete"

# Cache config, routes, views for production performance
php artisan config:cache
php artisan route:cache
php artisan view:cache
echo "[✓] Caches warmed"

# Create storage symlink
php artisan storage:link --force 2>/dev/null || true
echo "[✓] Storage linked"

echo "──────────────────────────────────────────"
echo "  Booted — starting Supervisor"
echo "──────────────────────────────────────────"

# Start Supervisor (manages nginx + php-fpm + queue)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
