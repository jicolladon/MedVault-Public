# ─────────────────────────────────────────────────────────────
# MedVault Sharing Web — Multi-stage Docker build
#   Stage 1: Build Angular app with Node.js
#   Stage 2: Serve with nginx
# ─────────────────────────────────────────────────────────────
FROM node:22-alpine AS build
WORKDIR /app

# Install dependencies first for better layer caching
COPY src/apps/web/medvault-sharing/package.json src/apps/web/medvault-sharing/package-lock.json* ./
RUN npm ci --ignore-scripts

# Copy source and build
COPY src/apps/web/medvault-sharing/ ./
RUN npx ng build --configuration production

# ─── Production image ───────────────────────────────────────
FROM nginx:1.27-alpine AS runtime
COPY devops/docker/nginx-sharing.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/medvault-sharing/browser /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
