#!/bin/sh
set -eu

: "${DATABASE_URL:?DATABASE_URL is required}"
: "${DATABASE_MIGRATION_URL:?DATABASE_MIGRATION_URL is required}"
: "${SESSION_SECRET:?SESSION_SECRET is required}"

echo "FRAME OS: applying database migrations"
npm run db:migrate
echo "FRAME OS: database migrations complete"

if [ "${FRAME_RUN_INITIAL_SEED:-false}" = "true" ]; then
  : "${FRAME_BOOTSTRAP_PASSWORD:?FRAME_BOOTSTRAP_PASSWORD is required for the initial seed}"
  echo "FRAME OS: creating initial administrator"
  npm run db:seed
  echo "FRAME OS: initial administrator ready"
fi

echo "FRAME OS: starting API, worker and web application"
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

echo "FRAME OS: starting public web gateway on port 10000"
nginx -g 'daemon off;'
