#!/bin/bash

set -e

echo "[Entrypoint] Initializing Nginx with TLS 1.3"

# ============================================
# Variables
# ============================================
DOMAIN="${DOMAIN_NAME:-localhost}"
CERT_DIR="/etc/nginx/ssl"
CERT_FILE="${CERT_DIR}/${DOMAIN}.crt"
KEY_FILE="${CERT_DIR}/${DOMAIN}.key"

# ============================================
# Function: Configure timezone
# ============================================
setup_timezone() {
    if [ -n "$TZ" ] && [ -f "/usr/share/zoneinfo/$TZ" ]; then
        echo "[Entrypoint] Configuring timezone: $TZ"
        ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
        echo "$TZ" > /etc/timezone
        echo ""
    fi
}

# ============================================
# Function: Create required directories
# ============================================
setup_directories() {
    echo "[Entrypoint] Checking required directories..."

    local DIRS=(
        "/var/cache/nginx/client_temp"
        "/var/cache/nginx/proxy_temp"
        "/var/cache/nginx/fastcgi_temp"
        "/var/cache/nginx/uwsgi_temp"
        "/var/cache/nginx/scgi_temp"
        "/var/log/nginx"
        "/usr/share/nginx/html"
        "/var/run"
        "$CERT_DIR"
    )

    for DIR in "${DIRS[@]}"; do
        mkdir -p "$DIR" 2>/dev/null || true
        chown -R nginx:nginx "$DIR" 2>/dev/null || true
    done

    touch /var/run/nginx.pid 2>/dev/null || true
    chown nginx:nginx /var/run/nginx.pid 2>/dev/null || true
    echo "[Entrypoint] Directories checked"
    echo ""
}

# ============================================
# Function: Process Nginx configuration
# ============================================
process_config() {
    echo "[Entrypoint] Processing Nginx configuration..."

    local CONFIG_TEMPLATE="/etc/nginx/conf.d/default.conf.template"
    local CONFIG_DEST="/etc/nginx/conf.d/default.conf"

    if [ -f "$CONFIG_TEMPLATE" ]; then
        echo "[Entrypoint] Using $CONFIG_TEMPLATE file"
        sed "s@\${DOMAIN_NAME}@${DOMAIN}@g" "$CONFIG_TEMPLATE" > "$CONFIG_DEST"
    elif [ -f "$CONFIG_DEST" ]; then
        echo "¨Process existing config file"
        cp "$CONFIG_DEST" "${CONFIG_DEST}.backup"
        sed "s@\${DOMAIN_NAME}@${DOMAIN}@g" "${CONFIG_DEST}.backup" > "$CONFIG_DEST"
        rm -f "${CONFIG_DEST}.backup"
    fi

    echo "[Entrypoint] Nginx configuration for $DOMAIN processed"
}

# ============================================
# Function: Configure SSL/TLS certificates
# ============================================
setup_certificates() {
    echo "[Entrypoint] Configuring SSL/TLS certificates..."

    local NEED_CERTS=false

    if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
        echo "[Entrypoint] Certificates not found."
        NEED_CERTS=true
    elif ! openssl x509 -checkend 0 -noout -in "$CERT_FILE" 2>/dev/null; then
        echo "[Entrypoint] Certificates expired"
        NEED_CERTS=true
    fi

    if [ "$NEED_CERTS" = "true" ]; then
        echo ""
        /usr/local/bin/generate-certs.sh "$DOMAIN" "$CERT_DIR"
        echo ""
    else
        echo "[Entrypoint] Found valid certificates"
        openssl x509 -in "$CERT_FILE" -noout -subject -dates 2>/dev/null | sed 's/^/   /'
    fi

    if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
        echo "[Entrypoint] ERROR: Certificates could not be created"
        exit 1
    fi

    chmod 600 "$KEY_FILE" 2>/dev/null || true
    chmod 644 "$CERT_FILE" 2>/dev/null || true

}

# ============================================
# Function: Test configuration
# ============================================
test_config() {
    echo "[Entrypoint] Testing Nginx configuration..."

    if nginx -t 2>&1 | sed 's/^/   /'; then
        echo "[Entrypoint] Valid configuration"
        return 0
    else
        echo "[Entrypoint] ERROR: Bad configuration"
        echo "[Entrypoint] Current configuration:"
        cat /etc/nginx/conf.d/default.conf 2>/dev/null | sed 's/^/   /' || echo "   (not found)"
        return 1
    fi
}

# ============================================
# Function: Show info
# ============================================
show_info() {
    echo "=========================================="
    echo " Nginx configured correctly"
    echo "=========================================="
    echo ""
    echo "  Server information:"
    echo "   Domain: $DOMAIN"
    echo "   TLS Protocol: TLSv1.3"
    echo "   Nginx: $(nginx -v 2>&1 | cut -d'/' -f2)"
    echo "   Alpine: $(cat /etc/alpine-release 2>/dev/null || echo 'N/A')"
    echo "   OpenSSL: $(openssl version | cut -d' ' -f2)"
    echo ""
    echo "  Available endpoints:"
    echo "   HTTPS: https://$DOMAIN (puerto 443)"
    echo "   Health: https://$DOMAIN/healthz"
    echo "   Documentation: https://$DOMAIN/docs/"
    echo "   Adminer: https://$DOMAIN/adminer/"

    echo ""
    echo "  SSL certificates:"
    echo "   Path: $CERT_DIR"
    echo "   Certificate: ${DOMAIN}.crt"
    echo "   Private key: ${DOMAIN}.key"
    echo ""
    echo "=========================================="
    echo " Starting Nginx..."
    echo "=========================================="
    echo ""
}

# ============================================
# MAIN
# ============================================
main() {
    show_env
    setup_timezone
    setup_directories
    process_config
    setup_certificates

    if ! test_config; then
        echo "[Entrypoint] ABORT: Invalid config"
        exit 1
    fi

    show_info
    exec "$@"
}

main "$@"
