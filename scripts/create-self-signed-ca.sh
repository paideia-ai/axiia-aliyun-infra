#!/bin/bash

# Check if domain argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 example.com"
    exit 1
fi

DOMAIN=$1
OUTPUT_DIR="./secrets/${DOMAIN}"
CA_KEY="${OUTPUT_DIR}/ca.key"
CA_CERT="${OUTPUT_DIR}/ca.crt"
SERVER_KEY="${OUTPUT_DIR}/server.key"
SERVER_CSR="${OUTPUT_DIR}/server.csr"
SERVER_CERT="${OUTPUT_DIR}/server.crt"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Creating self-signed CA for domain: $DOMAIN"

# Generate CA private key
echo "Generating CA private key..."
openssl genrsa -out "$CA_KEY" 4096

# Generate CA certificate
echo "Generating CA certificate..."
openssl req -new -x509 -days 3650 -key "$CA_KEY" -out "$CA_CERT" \
    -subj "/C=CN/ST=Zhejiang/L=Hangzhou/O=Self-Signed CA/CN=Self-Signed Root CA"

# Generate server private key
echo "Generating server private key..."
openssl genrsa -out "$SERVER_KEY" 4096

# Generate certificate signing request
echo "Generating certificate signing request..."
openssl req -new -key "$SERVER_KEY" -out "$SERVER_CSR" \
    -subj "/C=CN/ST=Zhejiang/L=Hangzhou/O=Self-Signed/CN=$DOMAIN"

# Create extensions file for SAN
cat > "${OUTPUT_DIR}/v3.ext" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
EOF

# Sign the certificate with the CA
echo "Signing server certificate with CA..."
openssl x509 -req -in "$SERVER_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" \
    -CAcreateserial -out "$SERVER_CERT" -days 365 \
    -extfile "${OUTPUT_DIR}/v3.ext"

# Clean up temporary files
rm -f "$SERVER_CSR" "${OUTPUT_DIR}/v3.ext" "${OUTPUT_DIR}/ca.srl"

echo ""
echo "Certificate generation complete!"
echo "Files created in $OUTPUT_DIR:"
echo "  - ca.key: CA private key"
echo "  - ca.crt: CA certificate (add to trusted roots)"
echo "  - server.key: Server private key"
echo "  - server.crt: Server certificate"
echo ""
echo "To create a Kubernetes TLS secret:"
echo "kubectl create secret tls ${DOMAIN//./-}-tls --cert=$SERVER_CERT --key=$SERVER_KEY"