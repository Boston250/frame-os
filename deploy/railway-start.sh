#!/bin/sh
set -eu

: "${PORT:?Railway PORT is required}"
: "${DATABASE_URL:?DATABASE_URL is required}"
: "${DATABASE_MIGRATION_URL:?DATABASE_MIGRATION_URL is required}"
: "${SESSION_SECRET:?SESSION_SECRET is required}"

echo "FRAME OS: applying database migrations"
npm run db:migrate

if [ "${FRAME_RUN_INITIAL_SEED:-false}" = "true" ]; then
  : "${FRAME_BOOTSTRAP_PASSWORD:?FRAME_BOOTSTRAP_PASSWORD is required for initial setup}"
  echo "FRAME OS: creating initial administrator"
  npm run db:seed
fi

envsubst '${PORT}' < /etc/nginx/templates/frame-os.conf.template > /etc/nginx/http.d/default.conf

npm run api &
api_pid=$!
npm run worker &
worker_pid=$!
npm run start &
app_pid=$!

cleanup() {
  kill "$api_pid" "$worker_pid" "$app_pid" 2>/dev/null || true
}
trap cleanup INT TERM EXIT

echo "FRAME OS: public gateway starting on Railway port ${PORT}"
nginx -g 'daemon off;'
