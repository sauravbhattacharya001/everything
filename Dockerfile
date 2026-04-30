# =============================================================================
# Multi-stage Dockerfile for the Everything App (Flutter Web)
# =============================================================================
# Stage 1: Build the Flutter web app
# Stage 2: Compress assets with Brotli/Gzip for static delivery
# Stage 3: Serve with nginx (lightweight, production-ready)
# =============================================================================

# ---------------------------------------------------------------------------
# Build stage
# ---------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:3.41.6 AS build

ARG WEB_RENDERER=canvaskit
ARG FLUTTER_BUILD_ARGS=""

WORKDIR /app

# Copy dependency files first for better layer caching
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies (allow missing pubspec.lock for fresh builds)
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Build the Flutter web app with release optimizations
RUN flutter build web --release --web-renderer ${WEB_RENDERER} ${FLUTTER_BUILD_ARGS}

# ---------------------------------------------------------------------------
# Compression stage — pre-compress static assets for nginx gzip_static
# ---------------------------------------------------------------------------
FROM alpine:3.21 AS compress

RUN apk add --no-cache brotli gzip findutils

COPY --from=build /app/build/web /assets

# Pre-compress JS, CSS, WASM, HTML, JSON, SVG with Brotli (quality 11) & Gzip
RUN find /assets -type f \( \
      -name '*.js' -o -name '*.css' -o -name '*.wasm' \
      -o -name '*.html' -o -name '*.json' -o -name '*.svg' \
      -o -name '*.txt' -o -name '*.xml' -o -name '*.map' \
    \) -exec sh -c 'brotli -q 11 -o "$1.br" "$1" && gzip -9 -k "$1"' _ {} \;

# ---------------------------------------------------------------------------
# Production stage
# ---------------------------------------------------------------------------
FROM nginx:1.29-alpine AS production

LABEL org.opencontainers.image.source="https://github.com/sauravbhattacharya001/everything"
LABEL org.opencontainers.image.description="Everything App — Flutter web productivity suite"
LABEL org.opencontainers.image.licenses="MIT"

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy pre-compressed assets from the compression stage
COPY --from=compress /assets /usr/share/nginx/html

# Custom nginx config for Flutter SPA routing with Brotli/Gzip static serving
RUN cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    # ---------- Compression (dynamic fallback for non-precompressed) ----------
    gzip on;
    gzip_types text/plain text/css application/json application/javascript
               text/xml application/xml application/xml+rss text/javascript
               application/wasm image/svg+xml;
    gzip_min_length 256;
    gzip_vary on;
    gzip_static on;

    # ---------- Long cache for hashed / immutable assets ----------
    location ~* \.(js|css|wasm|png|jpg|jpeg|gif|ico|svg|woff2?|ttf|otf)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # ---------- Short cache for service worker & manifest ----------
    location ~* (flutter_service_worker\.js|manifest\.json|version\.json)$ {
        expires 1h;
        add_header Cache-Control "public, must-revalidate";
        try_files $uri =404;
    }

    # ---------- SPA fallback ----------
    location / {
        try_files $uri $uri/ /index.html;
    }

    # ---------- Security headers ----------
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
}
EOF

# Run as non-root user for security
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
