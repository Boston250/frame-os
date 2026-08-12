#!/bin/sh
set -eu

: "${DATABASE_URL:?DATABASE_URL is required}"
: "${DATABASE_MIGRATION_URL:?DATABASE_MIGRATION_URL is required}"
: "${SESSION_SECRET:?SESSION_SECRET is required}"

npm run db:migrate

if [ "${FRAME_RUN_INITIAL_SEED:-false}" = "true" ]; then
  : "${FRAME_BOOTSTRAP_PASSWORD:?FRAME_BOOTSTRAP_PASSWORD is required for the initial seed}"
  npm run db:seed
fi

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

nginx -g 'daemon off;'
