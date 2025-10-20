#!/bin/sh
set -e

echo "🚀 Starting Practice Software Testing Application..."

cd /var/www

# Wait for database to be ready if DATABASE_URL is set
if [ ! -z "$DATABASE_URL" ]; then
    echo "⏳ Waiting for database to be ready..."
    
    # Extract DB host and port from DATABASE_URL (mysql://user:pass@host:port/db)
    DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')
    DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    
    if [ -z "$DB_PORT" ]; then
        DB_PORT=3306
    fi
    
    echo "Database host: $DB_HOST:$DB_PORT"
    
    # Wait for database
    for i in $(seq 1 30); do
        if nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; then
            echo "✅ Database is ready!"
            break
        fi
        echo "Waiting for database... ($i/30)"
        sleep 2
    done
fi

# Generate application key if not set
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "base64:YOUR_APP_KEY_HERE" ]; then
    echo "🔑 Generating application key..."
    php artisan key:generate --force
fi

# Run database migrations
echo "📊 Running database migrations..."
php artisan migrate --force

# Seed database if SEED_DATABASE is set
if [ "$SEED_DATABASE" = "true" ]; then
    echo "🌱 Seeding database..."
    php artisan db:seed --force
fi

# Clear and cache config
echo "🔧 Optimizing application..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Create necessary directories
mkdir -p /var/log/supervisor
mkdir -p /var/www/storage/logs

# Set permissions
chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

echo "✨ Application is ready!"

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
