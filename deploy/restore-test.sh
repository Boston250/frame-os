#!/bin/sh
set -eu
: "${BACKUP_FILE:?BACKUP_FILE is required}"
: "${RESTORE_DATABASE_URL:?RESTORE_DATABASE_URL is required}"
gzip -cd "$BACKUP_FILE" > /tmp/frame-restore.dump
pg_restore --clean --if-exists --no-owner --dbname="$RESTORE_DATABASE_URL" /tmp/frame-restore.dump
psql "$RESTORE_DATABASE_URL" -v ON_ERROR_STOP=1 -c "SELECT count(*) FROM schema_migrations;"
