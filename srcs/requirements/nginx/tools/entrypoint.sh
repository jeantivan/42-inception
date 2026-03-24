#!/bin/bash
# entrypoint.sh - Versión corregida

set -e

echo ""
echo "=========================================="
echo "🚀 Iniciando Nginx con TLS 1.3"
echo "=========================================="
echo ""

# ============================================
# Variables
# ============================================
DOMAIN="${DOMAIN_NAME:-localhost}"
CERT_DIR="/etc/nginx/ssl"
CERT_FILE="${CERT_DIR}/${DOMAIN}.crt"
KEY_FILE="${CERT_DIR}/${DOMAIN}.key"

# ============================================
# Función: Mostrar variables de entorno
# ============================================
show_env() {
    echo "📋 Configuración del entorno:"
    echo "   DOMAIN_NAME: ${DOMAIN}"
    echo "   TZ: ${TZ:-UTC}"
    echo ""
}

# ============================================
# Función: Configurar timezone
# ============================================
setup_timezone() {
    if [ -n "$TZ" ] && [ -f "/usr/share/zoneinfo/$TZ" ]; then
        echo "🌍 Configurando timezone: $TZ"
        ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
        echo "$TZ" > /etc/timezone
        echo ""
    fi
}

# ============================================
# Función: Crear directorios necesarios
# ============================================
setup_directories() {
    echo "📁 Verificando directorios necesarios..."

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
    done

    touch /var/run/nginx.pid 2>/dev/null || true
    echo "   ✅ Directorios verificados"
    echo ""
}

# ============================================
# Función: Procesar configuración
# ============================================
process_config() {
    echo "🔧 Procesando configuración de Nginx..."

    local CONFIG_TEMPLATE="/etc/nginx/conf.d/default.conf.template"
    local CONFIG_DEST="/etc/nginx/conf.d/default.conf"

    # Si existe template, usarlo
    if [ -f "$CONFIG_TEMPLATE" ]; then
        echo "   📝 Usando template de configuración"
        sed "s/\${DOMAIN_NAME}/${DOMAIN}/g" "$CONFIG_TEMPLATE" > "$CONFIG_DEST"
    # Si no hay template pero sí configuración copiada en build
    elif [ -f "$CONFIG_DEST" ]; then
        echo "   📝 Procesando configuración existente"
        # Crear backup temporal
        cp "$CONFIG_DEST" "${CONFIG_DEST}.backup"
        # Reemplazar variables
        sed "s/\${DOMAIN_NAME}/${DOMAIN}/g" "${CONFIG_DEST}.backup" > "$CONFIG_DEST"
        # Limpiar backup
        rm -f "${CONFIG_DEST}.backup"
    fi

    echo "   ✅ Configuración procesada"
    echo "   ✅ Dominio configurado: $DOMAIN"
    echo ""
}

# ============================================
# Función: Configurar certificados
# ============================================
setup_certificates() {
    echo "🔐 Configurando certificados SSL/TLS..."

    local NEED_CERTS=false

    if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
        echo "   ⚠️  Certificados no encontrados"
        NEED_CERTS=true
    elif ! openssl x509 -checkend 0 -noout -in "$CERT_FILE" 2>/dev/null; then
        echo "   ⚠️  Certificados expirados"
        NEED_CERTS=true
    fi

    if [ "$NEED_CERTS" = "true" ]; then
        echo ""
        /usr/local/bin/generate-certs.sh "$DOMAIN" "$CERT_DIR"
        echo ""
    else
        echo "   ✅ Certificados válidos encontrados"
        openssl x509 -in "$CERT_FILE" -noout -subject -dates 2>/dev/null | sed 's/^/   /'
    fi

    if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
        echo ""
        echo "   ❌ ERROR: No se pudieron crear los certificados"
        exit 1
    fi

    chmod 600 "$KEY_FILE" 2>/dev/null || true
    chmod 644 "$CERT_FILE" 2>/dev/null || true

    echo ""
}

# ============================================
# Función: Verificar configuración
# ============================================
test_config() {
    echo "🔍 Verificando configuración de Nginx..."
    echo ""

    if nginx -t 2>&1 | sed 's/^/   /'; then
        echo ""
        echo "   ✅ Configuración válida"
        echo ""
        return 0
    else
        echo ""
        echo "   ❌ Error en la configuración"
        echo ""
        echo "Configuración actual:"
        cat /etc/nginx/conf.d/default.conf 2>/dev/null | sed 's/^/   /' || echo "   (no encontrada)"
        echo ""
        return 1
    fi
}

# ============================================
# Función: Mostrar información
# ============================================
show_info() {
    echo "=========================================="
    echo "✅ Nginx configurado correctamente"
    echo "=========================================="
    echo ""
    echo "🌐 Información del servidor:"
    echo "   Dominio: $DOMAIN"
    echo "   Protocolo TLS: TLSv1.3"
    echo "   Nginx: $(nginx -v 2>&1 | cut -d'/' -f2)"
    echo "   Alpine: $(cat /etc/alpine-release 2>/dev/null || echo 'N/A')"
    echo "   OpenSSL: $(openssl version | cut -d' ' -f2)"
    echo ""
    echo "📍 Endpoints disponibles:"
    echo "   HTTPS: https://$DOMAIN (puerto 443)"
    echo "   Health: https://$DOMAIN/healthz"
    echo ""
    echo "🔐 Certificados SSL:"
    echo "   Ubicación: $CERT_DIR"
    echo "   Certificado: ${DOMAIN}.crt"
    echo "   Clave privada: ${DOMAIN}.key"
    echo ""
    echo "=========================================="
    echo "🚀 Iniciando Nginx..."
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
        echo "❌ ABORTANDO: Configuración inválida"
        exit 1
    fi

    show_info

    # Ejecutar Nginx
    exec "$@"
}

# Ejecutar
main "$@"
