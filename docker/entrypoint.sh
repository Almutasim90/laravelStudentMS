#!/bin/sh
# ═══════════════════════════════════════════════════════════════
#  Entrypoint for Coolify deployment
#
#  Coolify injects all environment variables at container runtime.
#  This script writes them to a .env file so Laravel can read them,
#  then bootstraps the app before handing off to Supervisor.
# ═══════════════════════════════════════════════════════════════
set -e

cd /var/www/html

echo "╔══════════════════════════════════════════╗"
echo "║  Student Management System — Starting    ║"
echo "╚══════════════════════════════════════════╝"

# ── Step 1: Write .env from environment variables ──────────────
# Coolify passes all env vars at runtime — write them to .env
# so Laravel's config system can read them.
echo "▶ Writing .env from environment..."
cat > /var/www/html/.env <<EOF
APP_NAME="${APP_NAME:-Student Management System}"
APP_ENV="${APP_ENV:-production}"
APP_KEY="${APP_KEY:-}"
APP_DEBUG="${APP_DEBUG:-false}"
APP_URL="${APP_URL:-https://sms.almutasim.site}"

APP_LOCALE=en
APP_FALLBACK_LOCALE=en

LOG_CHANNEL=stack
LOG_STACK=single
LOG_LEVEL="${LOG_LEVEL:-error}"

DB_CONNECTION=sqlite
DB_DATABASE=/var/www/html/database/database.sqlite

SESSION_DRIVER=file
SESSION_LIFETIME=120
SESSION_ENCRYPT=false

CACHE_STORE=file
QUEUE_CONNECTION=database
FILESYSTEM_DISK=local

BROADCAST_CONNECTION=log

MAIL_MAILER="${MAIL_MAILER:-log}"
MAIL_FROM_ADDRESS="${MAIL_FROM_ADDRESS:-noreply@almutasim.site}"
MAIL_FROM_NAME="${APP_NAME:-Student Management System}"

BCRYPT_ROUNDS=12
EOF
echo "  [✓] .env written"

# ── Step 2: Ensure SQLite file exists ──────────────────────────
mkdir -p /var/www/html/database
if [ ! -f /var/www/html/database/database.sqlite ]; then
    touch /var/www/html/database/database.sqlite
    echo "  [✓] SQLite database file created"
fi

# ── Step 3: Ensure storage directories exist ───────────────────
mkdir -p storage/framework/cache/data \
         storage/framework/sessions \
         storage/framework/views \
         storage/logs \
         bootstrap/cache

# ── Step 4: Fix permissions ────────────────────────────────────
chown -R www-data:www-data /var/www/html
chmod -R 775 storage bootstrap/cache
chmod 664 database/database.sqlite
chmod 775 database
echo "  [✓] Permissions set"

# ── Step 5: Generate APP_KEY if not provided ───────────────────
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "" ]; then
    echo "  ⚠ APP_KEY not set — generating one now..."
    php artisan key:generate --force
    echo "  [✓] APP_KEY generated"
    echo "  !! IMPORTANT: Copy this key to Coolify ENV vars to persist it !!"
else
    echo "  [✓] APP_KEY present"
fi

# ── Step 6: Run database migrations ───────────────────────────
echo "▶ Running migrations..."
php artisan migrate --force
echo "  [✓] Migrations complete"

# ── Step 7: Cache config/routes/views for performance ─────────
echo "▶ Warming caches..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
echo "  [✓] Caches warmed"

# ── Step 8: Storage symlink ────────────────────────────────────
php artisan storage:link --force 2>/dev/null || true
echo "  [✓] Storage symlink ready"

echo "╔══════════════════════════════════════════╗"
echo "║  Boot complete — launching Supervisor    ║"
echo "╚══════════════════════════════════════════╝"

# Hand off to Supervisor (nginx + php-fpm + queue worker)
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
