#!/bin/sh
set -e

PG_USER="${POSTGRES_USER:-${COMMON:-outline}}"
PG_PASS="${POSTGRES_PASSWORD:-${COMMON:-outline}}"
PG_DB="${POSTGRES_DB:-${COMMON:-outline}}"

# named-volume mount comes up root-owned; reclaim it for postgres
chown -R postgres:postgres "$PGDATA" /run/postgresql
chmod 700 "$PGDATA"

# ---- Postgres ----
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "==> initdb in $PGDATA"
  su-exec postgres initdb -D "$PGDATA" --username="$PG_USER" \
    --auth-local=trust --auth-host=md5 >/dev/null
  echo "listen_addresses = '*'"        >> "$PGDATA/postgresql.conf"
  echo "host all all 0.0.0.0/0 md5"    >> "$PGDATA/pg_hba.conf"
fi

echo "==> starting postgres on :5432"
su-exec postgres pg_ctl -D "$PGDATA" -l "$PGDATA/postgres.log" -w start

# ensure password is set (md5 auth needs it for host connections)
su-exec postgres psql -U "$PG_USER" -d postgres -c \
  "ALTER ROLE \"$PG_USER\" WITH LOGIN PASSWORD '$PG_PASS';" >/dev/null

# create db idempotently
su-exec postgres psql -U "$PG_USER" -d postgres -tAc \
  "SELECT 1 FROM pg_database WHERE datname='$PG_DB'" | grep -q 1 || \
  su-exec postgres createdb -U "$PG_USER" -O "$PG_USER" "$PG_DB"

# ---- Redis ----
echo "==> starting redis on :6379"
redis-server --daemonize yes --bind 0.0.0.0 --port 6379 \
  --logfile "" --protected-mode no

# ---- OIDC mock (foreground) ----
echo "==> starting bun OIDC mock on :${PORT_OIDC:-8080}"
exec bun server.js
