# Scripts

## create-self-signed-ca.sh

Creates a self-signed Certificate Authority (CA) and server certificate for a specified domain.

### Usage

```bash
./scripts/create-self-signed-ca.sh <domain>
```

Example:
```bash
./scripts/create-self-signed-ca.sh example.com
```

### Output

The script generates certificates in `secrets/<domain>/`:

- `ca.key` - CA private key (4096-bit RSA)
- `ca.crt` - CA certificate (valid for 10 years)
- `server.key` - Server private key (4096-bit RSA)
- `server.crt` - Server certificate (valid for 1 year)

The server certificate includes:
- The specified domain as CN
- Subject Alternative Names (SAN) for the domain and wildcard subdomain

### Kubernetes Integration

To create a TLS secret from the generated certificates:

```bash
kubectl create secret tls <domain>-tls --cert=secrets/<domain>/server.crt --key=secrets/<domain>/server.key
```