# syntax=docker/dockerfile:1

############################
# Etapa 1: build / deps
############################
FROM node:18.15.0-alpine AS builder

WORKDIR /app

# Herramientas necesarias para compilar el módulo nativo sqlite3
RUN apk add --no-cache python3 make g++

# Instalar dependencias usando el lockfile (build reproducible)
COPY package.json package-lock.json ./
RUN npm ci

# Copiar el código fuente
COPY . .

# Dejar solo las dependencias de producción (sqlite3 ya quedó compilado)
RUN npm prune --omit=dev


############################
# Etapa 2: runtime
############################
FROM node:18.15.0-alpine AS runtime

# Metadatos de la imagen
LABEL org.opencontainers.image.title="demo-devops-nodejs" \
      org.opencontainers.image.description="API REST de usuarios - Prueba técnica DevOps Devsu" \
      org.opencontainers.image.source="https://github.com/gpleyton/gpleyton_devsu"

ENV NODE_ENV=production \
    PORT=8000

WORKDIR /app

# wget (incluido en busybox) se usa para el HEALTHCHECK
# Copiamos dependencias ya instaladas/compiladas y el código, con dueño non-root
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node . .

# Ejecutar como usuario sin privilegios (requisito del enunciado)
USER node

EXPOSE 8000

# Verificación de salud apuntando al endpoint de liveness
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/api/health || exit 1

CMD ["node", "index.js"]
