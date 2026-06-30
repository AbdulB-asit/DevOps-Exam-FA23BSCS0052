# =========================================================================
# STAGE 1: Compilation, Dependency Resolution & Artifact Preparation
# =========================================================================
FROM node:20-alpine AS builder

WORKDIR /src

# Leverage caching layers for node modules to accelerate iterative builds
COPY package*.json ./
RUN npm install

# Build minified frontend static bundle using the Vite compiler configuration
COPY . .
RUN npm run build

# Strip devDependencies and purge developer artifacts to shrink build context
RUN npm prune --production && \
    find node_modules/ -type f -name "*.md" -o -name "*.map" -o -name "*.ts" -delete && \
    npm cache clean --force

# =========================================================================
# STAGE 2: Hardened, Non-Root Runtime Execution Layer (Minimal Footprint)
# =========================================================================
FROM alpine:3.20 AS runtime

WORKDIR /app

# Provision minimum engine dependencies and instantiate low-privilege system identities
RUN apk add --no-cache nodejs && \
    addgroup -g 1000 node && \
    adduser -u 1000 -G node -s /bin/sh -D node && \
    mkdir -p /app/logs && \
    chown -R node:node /app

# Port compiled modules, the entrypoint script, and distribution maps safely
COPY --chown=node:node --from=builder /src/node_modules ./node_modules
COPY --chown=node:node --from=builder /src/package*.json ./
COPY --chown=node:node --from=builder /src/index.js ./
COPY --chown=node:node --from=builder /src/dist ./dist

ENV NODE_ENV=production
USER node
EXPOSE 5000

CMD ["node", "index.js"]