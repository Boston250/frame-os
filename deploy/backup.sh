#!/bin/sh
set -eu
: "${DATABASE_URL:?DATABASE_URL is required}"
: "${BACKUP_DESTINATION:?BACKUP_DESTINATION is required}"
backup_database_url="${DATABASE_MIGRATION_URL:-$DATABASE_URL}"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
file="/tmp/frame-os-${stamp}.dump"
pg_dump --format=custom --no-owner --dbname="$backup_database_url" --file="$file"
gzip "$file"
sha256sum "${file}.gz" > "${file}.gz.sha256"
mkdir -p "$BACKUP_DESTINATION"
mv "${file}.gz" "${file}.gz.sha256" "$BACKUP_DESTINATION/"
find "$BACKUP_DESTINATION" -name 'frame-os-*.dump.gz' -mtime +30 -delete
