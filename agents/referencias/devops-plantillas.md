# Referencias extendidas — devops

Plantillas completas movidas desde `04-Agentes/devops.md` para mantener el
agente liviano. El agente `devops` remite acá cuando hace falta el detalle.

## Docker & Docker Compose

### PHP-FPM + nginx + PostgreSQL + Redis (patrón base)

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    restart: unless-stopped
    volumes:
      - .:/var/www/html
      - /var/www/html/vendor      # excluir vendor del bind mount
      - /var/www/html/node_modules
    environment:
      - APP_ENV=production
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks: [app-network]

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - .:/var/www/html
      - ./docker/nginx/conf.d:/etc/nginx/conf.d
      - ./docker/nginx/ssl:/etc/nginx/ssl   # certs Let's Encrypt
    depends_on: [app]
    networks: [app-network]

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_DATABASE}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USERNAME} -d ${DB_DATABASE}"]
      interval: 10s
      retries: 5
    networks: [app-network]

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
    networks: [app-network]

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

### Dockerfile multi-stage para Laravel

```dockerfile
# ── base ──────────────────────────────────────────────────
FROM php:8.3-fpm-alpine AS base

RUN apk add --no-cache \
    postgresql-dev \
    libzip-dev \
    oniguruma-dev \
    && docker-php-ext-install pdo pdo_pgsql zip bcmath opcache

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# ── dependencies ──────────────────────────────────────────
FROM base AS dependencies

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

COPY . .
RUN composer dump-autoload --optimize --no-dev

# ── production ────────────────────────────────────────────
FROM base AS production

COPY --from=dependencies /var/www/html /var/www/html

# Permisos correctos — nunca root en runtime
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

USER www-data

# OPcache para producción
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

EXPOSE 9000
CMD ["php-fpm"]
```

### opcache.ini para producción
```ini
[opcache]
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0   ; 0 en prod — 1 en dev
opcache.revalidate_freq=0
opcache.fast_shutdown=1
```


## nginx

### Virtual host Laravel + PHP-FPM

```nginx
# docker/nginx/conf.d/app.conf
server {
    listen 80;
    server_name tu-dominio.com www.tu-dominio.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tu-dominio.com www.tu-dominio.com;

    root /var/www/html/public;
    index index.php;

    # SSL — certs generados con Certbot en el host
    ssl_certificate     /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_min_length 1000;

    # Headers de seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Laravel — todo pasa por index.php
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP-FPM upstream
    location ~ \.php$ {
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    # Bloquear acceso a archivos sensibles
    location ~ /\.(env|git|htaccess) { deny all; }
    location ~ \.(log|yml|yaml|json|lock)$ { deny all; }

    # Assets estáticos — cache largo
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```


## GitHub Actions — CI/CD para Laravel

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: secret
          POSTGRES_DB: testing
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports: ["5432:5432"]

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: pdo, pdo_pgsql, zip, bcmath

      - name: Cache Composer
        uses: actions/cache@v4
        with:
          path: vendor
          key: composer-${{ hashFiles('composer.lock') }}

      - name: Install dependencies
        run: composer install --no-interaction --prefer-dist --optimize-autoloader

      - name: Copy .env
        run: cp .env.example .env && php artisan key:generate

      - name: Configure test DB
        run: |
          echo "DB_CONNECTION=pgsql" >> .env
          echo "DB_HOST=127.0.0.1" >> .env
          echo "DB_PORT=5432" >> .env
          echo "DB_DATABASE=testing" >> .env
          echo "DB_USERNAME=postgres" >> .env
          echo "DB_PASSWORD=secret" >> .env

      - name: Run migrations
        run: php artisan migrate --force

      - name: Run tests
        run: php artisan test --parallel

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          script: |
            set -e
            cd /var/www/tu-app

            # Pull y actualizar
            git pull origin main
            docker compose exec -T app composer install --no-dev --optimize-autoloader
            docker compose exec -T app php artisan migrate --force
            docker compose exec -T app php artisan config:cache
            docker compose exec -T app php artisan route:cache
            docker compose exec -T app php artisan view:cache

            # Restart PHP-FPM (no nginx — zero downtime)
            docker compose restart app

            # Smoke test
            curl -fsS https://tu-dominio.com/health || (echo "Health check failed" && exit 1)
```


## Scripts de servidor

### deploy.sh — deploy manual desde el servidor

```bash
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/var/www/tu-app"
BRANCH="${1:-main}"

echo "→ Deploy de rama: $BRANCH"
cd "$APP_DIR"

git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

docker compose exec -T app composer install --no-dev --optimize-autoloader --quiet
docker compose exec -T app php artisan migrate --force
docker compose exec -T app php artisan optimize

docker compose restart app
echo "✔ Deploy completado"
```

### backup-db.sh — backup de PostgreSQL

```bash
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/backups/postgres"
DATE=$(date +%Y-%m-%d_%H%M)
mkdir -p "$BACKUP_DIR"

docker compose exec -T db pg_dump \
  -U "${DB_USERNAME}" \
  "${DB_DATABASE}" \
  | gzip > "$BACKUP_DIR/${DB_DATABASE}_${DATE}.sql.gz"

# Retener solo los últimos 7 días
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
echo "✔ Backup: $BACKUP_DIR/${DB_DATABASE}_${DATE}.sql.gz"
```


## Hardening básico de servidor Linux

Checklist al configurar un servidor nuevo:

```bash
# 1. Actualizar sistema
apt update && apt upgrade -y

# 2. Crear usuario deploy (nunca trabajar como root)
adduser deploy
usermod -aG sudo deploy
# Copiar authorized_keys del root al nuevo usuario
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy

# 3. Deshabilitar root SSH y password auth
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload sshd

# 4. Firewall
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# 5. Fail2ban para SSH
apt install -y fail2ban
systemctl enable --now fail2ban
```

### .env en el servidor — nunca en el repo

```bash
# En el servidor, el .env vive FUERA del directorio del repo o sin tracking
# Crear en primera instalación:
cp .env.example .env
nano .env   # editar valores reales
# Permisos estrictos
chmod 640 .env
chown deploy:www-data .env
```
