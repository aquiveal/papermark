#!/bin/bash
set -e

if [ -n "$POSTGRES_PRISMA_URL" ]; then
    npx prisma migrate deploy
fi

exec node server.js