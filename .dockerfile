# ═══════════════════════════════════════════════════════════════
#  Student Management System — Coolify Dockerfile
#  Deployed to: sms.almutasim.site
#
#  Coolify will:
#    - Build this image from your GitHub repo
#    - Inject environment variables (APP_KEY, APP_URL, etc.)
#    - Handle SSL + domain routing automatically
#    - Map port 80 of this container to your domain
# ═══════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────
# Stage 1 — Build frontend assets with Node 20
# ───────────────────────────────────────────────────────────────
FROM node:20-alpine AS node-builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --no-audit --no-fund

COPY resources/    resources/
COPY vite.config.js .
COPY tailwind.config.js .
COPY postcss.config.js .

RUN npm run build

# ───────────────────────────────────────────────────────────────
# Stage 2 — PHP 8.2 FPM + Nginx (single container for Coolify)
# ───────────────────────────────────────────────────────────────
FROM php:8.2-fpm-alpine

LABEL maintainer="sms.almutasim.site"
LABEL org.opencontainers.image.source="https://github.com/Almutasim90/laravelStudentMS"

# ── System packages ────────────────────────────────────────────
RUN apk add --no-cache \
        nginx \
        supervisor \
        sqlite \
        sqlite-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        zip \
        unzip \
        curl \
        bash \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_sqlite \
        gd \
        opcache \
        pcntl \
        bcmath

# ── Composer ───────────────────────────────────────────────────
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# ── PHP production config ──────────────────────────────────────
RUN { \
        echo "upload_max_filesize=50M"; \
        echo "post_max_size=50M"; \
        echo "max_execution_time=300"; \
        echo "memory_limit=256M"; \
        echo "date.timezone=UTC"; \
        echo "expose_php=Off"; \
    } > /usr/local/etc/php/conf.d/custom.ini

# OPcache tuned for production
RUN { \
        echo "opcache.enable=1"; \
        echo "opcache.memory_consumption=256"; \
        echo "opcache.interned_strings_buffer=16"; \
        echo "opcache.max_accelerated_files=20000"; \
        echo "opcache.revalidate_freq=0"; \
        echo "opcache.validate_timestamps=0"; \
        echo "opcache.save_comments=1"; \
    } > /usr/local/etc/php/conf.d/opcache.ini

# ── Nginx config ───────────────────────────────────────────────
# NOTE: No server_name — Coolify's reverse proxy handles domain/SSL.
#       This Nginx only serves on port 80 inside the container.
RUN mkdir -p /run/nginx
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf

# ── Supervisor (manages nginx + php-fpm) ──────────────────────
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ── Application ────────────────────────────────────────────────
WORKDIR /var/www/html

# Install PHP deps with layer caching
COPY composer.json composer.lock ./
RUN composer install \
        --no-dev \
        --optimize-autoloader \
        --no-interaction \
        --no-scripts \
        --prefer-dist

# Copy full application source
COPY . .

# Copy compiled frontend assets from Stage 1
COPY --from=node-builder /app/public/build ./public/build

# ── Storage & database bootstrap ──────────────────────────────
RUN mkdir -p \
        database \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache \
    && touch database/database.sqlite \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache \
    && chmod 664 database/database.sqlite \
    && chmod 775 database

# ── Entrypoint ─────────────────────────────────────────────────
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Coolify maps this port to your domain
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
