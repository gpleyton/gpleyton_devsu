# syntax=docker/dockerfile:1

############################
# Stage 1: build / deps
############################
FROM node:18.15.0-alpine AS builder

WORKDIR /app

# Build tools required to compile the native sqlite3 module
RUN apk add --no-cache python3 make g++

# Install dependencies from the lockfile (reproducible build)
COPY package.json package-lock.json ./
RUN npm ci

# Copy the source code
COPY . .

# Keep only production dependencies (sqlite3 is already compiled)
RUN npm prune --omit=dev


############################
# Stage 2: runtime
############################
FROM node:18.15.0-alpine AS runtime

LABEL org.opencontainers.image.title="demo-devops-nodejs" \
      org.opencontainers.image.description="Users REST API - Devsu DevOps technical test" \
      org.opencontainers.image.source="https://github.com/gpleyton/gpleyton_devsu"

ENV NODE_ENV=production \
    PORT=8000

WORKDIR /app

# Copy already installed/compiled dependencies and the source, owned by a non-root user.
# wget (bundled in busybox) is used for the HEALTHCHECK.
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node . .

# Run as an unprivileged user
USER node

EXPOSE 8000

# Health check against the liveness endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/api/health || exit 1

CMD ["node", "index.js"]
