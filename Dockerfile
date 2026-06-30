# ==========================================
# STAGE 1: Build Frontend & Production Modules
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package configurations and install ALL dependencies
COPY package*.json ./
RUN npm install

# Copy source files and compile the Vite frontend build
COPY . .
RUN npm run build

# Prune devDependencies cleanly before moving to the final stage
RUN npm prune --production && npm cache clean --force

# ==========================================
# STAGE 2: Ultra-minimal Runtime Environment
# ==========================================
# Official Google Distroless Node 20 runtime image (~40MB base)
FROM gcr.io/distroless/nodejs20-debian12 AS runner

WORKDIR /app

# Copy the lightweight, pruned production node_modules from Stage 1
COPY --from=builder /app/node_modules ./node_modules

# Copy application manifest files
COPY --from=builder /app/package*.json ./

# Copy the backend server entry point
COPY --from=builder /app/index.js ./

# Copy the compiled static frontend files from Stage 1
COPY --from=builder /app/dist ./dist

# Set production environment flags
ENV NODE_ENV=production

# Expose the application port
EXPOSE 5000

# Run the node binary directly on index.js (Distroless requires array syntax)
CMD ["index.js"]