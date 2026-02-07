#!/bin/bash

set -e

DOMAIN="${1:-localhost}"
CERT_DIR="${2:-/etc/nginx/ssl}"
DAYS="${3:-365}"

echo "=========================================="
echo "🔐 Generating self-signed TLS certificates"
echo "    Domain: ${DOMAIN}"
echo "    Certificate Directory: ${CERT_DIR}"
echo "    Validity: ${DAYS} days"
echo "=========================================="


# Create certificate directory if it doesn't exist
mkdir -p "${CERT_DIR}"

# Output file paths
KEY_FILE="${CERT_DIR}/${DOMAIN}.key"
CERT_FILE="${CERT_DIR}/${DOMAIN}.crt"
CSR_FILE="${CERT_DIR}/${DOMAIN}.csr"

# Generate private key RSA 2048 bits
echo "🔑 Generating private key..."
openssl genrsa -out "${KEY_FILE}" 2048 2>/dev/null

# Generate self-signed certificate with SAN
echo "📄 Generating self-signed certificate..."
openssl req -new -x509 -key "${KEY_FILE}" -out "${CERT_FILE}" -days "${DAYS}" -subj "/C=ES/ST=Murcia/L=Murcia/O=Development/CN=${DOMAIN}" -addext "subjectAltName=DNS:${DOMAIN},DNS:*.${DOMAIN},DNS:localhost,IP:127.0.0.1" 2>/dev/null

# Set file permissions
chmod 600 "${KEY_FILE}" 2>/dev/null || true
chmod 644 "${CERT_FILE}" 2>/dev/null || true

# Verify the generated certificate
echo ""
echo "=========================================="
echo " ✅ Certificate generated successfully!"
echo "    Certificate Path: ${CERT_FILE}"
echo "    Key Path: ${KEY_FILE}"
echo ""
echo " Certificate Details:"
openssl x509 -in "${CERT_FILE}" -noout -subject -dates
echo "=========================================="



