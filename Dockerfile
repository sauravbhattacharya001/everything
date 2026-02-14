# =============================================================================
# Multi-stage Dockerfile for the Everything App (Flutter Web)
# =============================================================================
# Stage 1: Build the Flutter web app
# Stage 2: Serve with nginx (lightweight, production-ready)
# =============================================================================

# ---------------------------------------------------------------------------
# Build stage
# ---------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:3.22.0 AS build

WORKDIR /app

# Copy dependency files first for better layer caching
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies (allow missing pubspec.lock for fresh builds)
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Build the Flutter web app with release optimizations
# Using CanvasKit renderer for full fidelity; switch to --web-renderer html
# for smaller bundle size if preferred
RUN flutter build web --release --web-renderer canvaskit

# ---------------------------------------------------------------------------
# Production stage
# ---------------------------------------------------------------------------
FROM nginx:1.29-alpine AS production

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy the built web app from the build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Custom nginx config for Flutter SPA routing
RUN cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression for Flutter web assets
    gzip on;
    gzip_types text/plain text/css application/json application/javascript
               text/xml application/xml application/xml+rss text/javascript
               application/wasm;
    gzip_min_length 256;
    gzip_vary on;

    # Long cache for hashed assets (fonts, canvaskit, etc.)
    location ~* \.(js|css|wasm|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Flutter SPA: route all non-file requests to index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
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

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
