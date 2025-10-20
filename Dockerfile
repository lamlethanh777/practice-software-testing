# Multi-stage Dockerfile for Practice Software Testing
# Combines Angular UI + Laravel API + Nginx in a single image

# Stage 1: Build Angular UI
FROM node:20.19-alpine AS ui-builder

WORKDIR /app

# Copy UI package files
COPY sprint5/UI/package*.json ./
RUN npm install --legacy-peer-deps --force

# Copy UI source and build
COPY sprint5/UI/ ./
RUN npm run build -- --configuration production

# Stage 2: Setup PHP/Laravel
FROM php:8.3-fpm-alpine AS api-base

# Install dependencies
RUN apk add --no-cache \
    mysql-client \
    msmtp \
    perl \
    wget \
    procps \
    shadow \
    libzip \
    libpng \
    libjpeg-turbo \
    libwebp \
    freetype \
    icu \
    nginx \
    supervisor \
    netcat-openbsd \
    bash

# Install PHP extensions
RUN apk add --no-cache --virtual build-essentials \
    icu-dev icu-libs zlib-dev g++ make automake autoconf libffi-dev libzip-dev \
    libpng-dev libwebp-dev libjpeg-turbo-dev freetype-dev && \
    docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-configure ffi --with-ffi && \
    docker-php-ext-install gd && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install ffi && \
    docker-php-ext-install intl && \
    docker-php-ext-install opcache && \
    docker-php-ext-install exif && \
    docker-php-ext-install zip && \
    apk del build-essentials && rm -rf /usr/src/php*

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Stage 3: Final production image
FROM api-base AS production

WORKDIR /var/www

# Copy PHP configuration
COPY _docker/opcache.ini /usr/local/etc/php/conf.d/
COPY _docker/php-ini-overrides.ini /usr/local/etc/php/conf.d/

# Copy Laravel API
COPY sprint5/API/ ./

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader --ignore-platform-req=ext-ffi

# Set permissions
RUN chown -R www-data:www-data /var/www && \
    chmod -R 755 /var/www && \
    chmod -R 777 /var/www/storage /var/www/bootstrap/cache

# Copy built Angular UI to public directory
RUN mkdir -p /var/www/public/ui
COPY --from=ui-builder /app/dist/ /var/www/public/ui/

# Copy Nginx configuration
COPY nginx-single.conf /etc/nginx/http.d/default.conf

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy startup script
COPY start-single.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose port
EXPOSE 8080

# Start services using supervisor
CMD ["/usr/local/bin/start.sh"]
