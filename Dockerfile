# Multi-stage build for 9Router v2 - Hugging Face Spaces optimized
# Stage 1: Build backend
FROM node:20-slim AS backend-builder

WORKDIR /build

# Copy root and backend files
COPY package.json package-lock.json ./
COPY backend ./backend

# Install dependencies
RUN npm ci

# Build backend
WORKDIR /build/backend
RUN npm run build

# Stage 2: Build frontend
FROM node:20-slim AS frontend-builder

WORKDIR /build

# Copy root and frontend files
COPY package.json package-lock.json ./
COPY frontend ./frontend

# Install dependencies
RUN npm ci

# Build frontend
WORKDIR /build/frontend
RUN npm run build

# Stage 3: Runtime
FROM node:20-slim

# Install Python for automation features (optional)
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    chromium \
    chromium-driver \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy backend dist and dependencies from builder
COPY --from=backend-builder /build/backend/dist ./backend/dist
COPY --from=backend-builder /build/backend/package.json ./backend/
COPY --from=backend-builder /build/node_modules ./node_modules

# Copy frontend dist
COPY --from=frontend-builder /build/frontend/dist ./frontend/dist

# Copy root package files
COPY package.json ./

# Install only production dependencies
WORKDIR /app/backend
RUN npm ci --omit=dev

WORKDIR /app

# Create data directory for SQLite
RUN mkdir -p /app/data

# Expose ports
EXPOSE 3000 3001

# Set environment variables for Hugging Face Spaces
ENV NODE_ENV=production
ENV PORT=3000
ENV REQUIRE_LOGIN=true
ENV JWT_SECRET=${JWT_SECRET:-change-me-in-production}
ENV ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/api/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start backend with frontend serving
CMD ["node", "backend/dist/server.js"]
