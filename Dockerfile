ARG NODE_VERSION=22

# Stage 1: Dependencies
FROM node:${NODE_VERSION}-alpine AS deps

RUN apk add --no-cache libc6-compat openssl

WORKDIR /app

# Copy package files
COPY .npmrc package.json package-lock.json* yarn.lock* pnpm-lock.yaml* ./

# Copy Prisma schema folder
COPY prisma ./prisma

# Install dependencies based on the preferred package manager
RUN \
    if [ -f yarn.lock ]; then \
    yarn --frozen-lockfile; \
    elif [ -f package-lock.json ]; then \
    npm ci; \
    elif [ -f pnpm-lock.yaml ]; then \
    corepack enable pnpm && pnpm i --frozen-lockfile; \
    else \
    echo "Lockfile not found." && exit 1; \
    fi

# Stage 2: Build
FROM node:${NODE_VERSION}-alpine AS builder

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Set environment variables for build
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Dummy environment variables for build time (required by next.config.mjs validation)
ARG NEXT_PUBLIC_BASE_URL=https://papermark.capybaara.com
ARG NEXT_PUBLIC_WEBHOOK_BASE_HOST=https://papermark.capybaara.com
ENV NEXTAUTH_URL=https://papermark.capybaara.com
ARG NEXT_PUBLIC_APP_BASE_HOST=papermark.capybaara.com
ARG NEXT_PUBLIC_WEBHOOK_BASE_HOST=https://papermark.capybaara.com
ARG NEXT_PUBLIC_MARKETING_URL=https://papermark.capybaara.com
ARG NEXT_PUBLIC_HANKO_TENANT_ID=d8ca4ded-6e8a-40ca-95e3-a476fbe3a946
ARG NEXT_PUBLIC_UPLOAD_TRANSPORT=s3
ENV POSTGRES_PRISMA_URL=postgresql://dummy:dummy@localhost:5432/dummy
ENV OPENAI_API_KEY=dummy
ENV UPSTASH_REDIS_REST_URL=https://dummy.upstash.io
ENV UPSTASH_REDIS_REST_TOKEN=dummy
ENV UPSTASH_REDIS_REST_LOCKER_URL=https://dummy.upstash.io
ENV UPSTASH_REDIS_REST_LOCKER_TOKEN=dummy
ENV HANKO_API_KEY=dummy
ENV SLACK_CLIENT_ID=dummy
ENV SLACK_CLIENT_SECRET=dummy
ENV QSTASH_URL=https://dummy.upstash.io
ENV QSTASH_TOKEN=dummy
ENV QSTASH_CURRENT_SIGNING_KEY=dummy
ENV QSTASH_NEXT_SIGNING_KEY=dummy


# Generate Prisma Client
RUN npx prisma generate

# Build the application
RUN \
    if [ -f yarn.lock ]; then \
    yarn build; \
    elif [ -f package-lock.json ]; then \
    npm run build; \
    elif [ -f pnpm-lock.yaml ]; then \
    corepack enable pnpm && pnpm build; \
    else \
    echo "Lockfile not found." && exit 1; \
    fi

# Stage 3: Production Runtime
FROM node:${NODE_VERSION}-alpine AS runner

WORKDIR /app

# Create non-root user for running the app
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY .npmrc ./

# Install runtime dependencies
RUN apk add --no-cache \
    libc6-compat \
    openssl \
    curl \
    bash

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Copy built application
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# Copy Prisma schema for migrations
COPY --from=builder /app/prisma ./prisma

# Install prisma CLI for migrations (matching project version)
RUN npm install prisma@6.5.0


# Copy startup script
COPY --chown=nextjs:nodejs entrypoint.sh ./entrypoint.sh
RUN dos2unix ./entrypoint.sh || sed -i 's/\r$//' ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

# Set proper permissions
RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

ENTRYPOINT ["./entrypoint.sh"]
