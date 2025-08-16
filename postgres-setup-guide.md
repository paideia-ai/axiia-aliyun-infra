# PostgreSQL Database Setup for Non-Postgres User

## Initial Setup (as postgres superuser)

### 1. Generate a secure password
```bash
openssl rand -base64 32
```

### 2. Create user and database
```bash
psql -U postgres
```

```sql
-- Create the application user
CREATE USER axiia_app WITH PASSWORD 'your_generated_password_here';

-- Create database with the app user as owner
CREATE DATABASE axiia OWNER axiia_app;

-- Connect to the new database
\c axiia

-- Grant permissions on public schema (required for PostgreSQL 15+)
GRANT ALL ON SCHEMA public TO axiia_app;
GRANT CREATE ON SCHEMA public TO axiia_app;

-- Optional: Make axiia_app the owner of public schema
ALTER SCHEMA public OWNER TO axiia_app;
```

### 3. One-liner alternative
```bash
psql -U postgres -c "CREATE USER axiia_app WITH PASSWORD 'password';" && \
psql -U postgres -c "CREATE DATABASE axiia OWNER axiia_app;" && \
psql -U postgres -d axiia -c "GRANT ALL ON SCHEMA public TO axiia_app;" && \
psql -U postgres -d axiia -c "GRANT CREATE ON SCHEMA public TO axiia_app;"
```

## Database Migration (Dump and Restore)

### Dump from source database
```bash
# Create compressed dump without ownership/permission info
pg_dump "postgresql://username:password@source-host:5432/source_db" \
  --no-owner --no-acl -Fc -f axiia.dump
```

### Restore to target database
```bash
# Restore using the application user (not postgres)
pg_restore -d "postgresql://axiia_app:password@target-host:5432/axiia" \
  --no-owner --no-acl axiia.dump
```

### Direct migration (one-liner)
```bash
pg_dump "postgresql://user:pass@source:5432/source_db" --no-owner --no-acl | \
  psql "postgresql://axiia_app:pass@target:5432/axiia"
```

## Common Issues and Solutions

### Issue: "permission denied for schema public"
This happens in PostgreSQL 15+ because the public schema no longer grants CREATE permission by default.

**Solution:**
```sql
-- As postgres user
\c axiia
GRANT CREATE ON SCHEMA public TO axiia_app;
-- Or make them the owner
ALTER SCHEMA public OWNER TO axiia_app;
```

### Issue: Missing schemas in dump
If the dump references schemas that don't exist in the target:

**Option 1:** Create missing schemas first
```bash
psql "postgresql://postgres:password@host:5432/axiia" \
  -c "CREATE SCHEMA IF NOT EXISTS schema_name;"
psql "postgresql://postgres:password@host:5432/axiia" \
  -c "GRANT ALL ON SCHEMA schema_name TO axiia_app;"
```

**Option 2:** Filter out unwanted schemas
```bash
pg_restore -l axiia.dump > contents.list
grep -v "SCHEMA.*unwanted_schema" contents.list > filtered.list
pg_restore -d "postgresql://axiia_app:password@host:5432/axiia" \
  --no-owner --no-acl --use-list=filtered.list axiia.dump
```

## Key Points

1. **Database ownership ≠ Schema ownership**: Being database owner doesn't automatically grant permissions on existing schemas
2. **PostgreSQL 15+ changes**: Public schema requires explicit CREATE permission
3. **Use `--no-owner --no-acl`**: Prevents permission conflicts during restore
4. **Restore as app user**: Use the application user for restore, not postgres superuser
5. **Connection string format**: `postgresql://user:password@host:port/database`

## Verification Commands

```sql
-- Check database owner
\l axiia

-- Check schema permissions
\c axiia
\dn+ public

-- Check user privileges
\du axiia_app
```