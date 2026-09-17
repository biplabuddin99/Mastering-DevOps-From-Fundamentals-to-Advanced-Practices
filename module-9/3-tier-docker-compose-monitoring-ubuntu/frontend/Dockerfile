# =============================================================================
# Frontend Dockerfile — Multi-Stage Build
# =============================================================================
# Stage 1 (builder) : Node.js + Vite compiles the React SPA into static assets
# Stage 2 (runtime) : Nginx serves the compiled assets and proxies /api + /health
#
# The separation means the final image ships ONLY Nginx + compiled HTML/JS/CSS.
# The Node.js runtime (~170 MB), node_modules, and all source code are left behind
# in the builder stage and never reach production. This produces a ~25 MB image
# compared to ~400 MB if Node.js were kept in the final stage.
# =============================================================================

# ── Stage 1: builder ──────────────────────────────────────────────────────────
# node:18-alpine matches the backend base for consistency and for the same
# reasons: smaller image, fewer pre-installed packages, smaller CVE surface.
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package manifests before source to maximise Docker layer cache reuse.
# The npm install layer is only invalidated when dependencies change —
# not on every React source file edit. Critical for CI pipeline speed.
COPY package*.json ./

# --legacy-peer-deps is required because some React 18 ecosystem packages
# (e.g. older chart.js wrappers) declare peer dependency ranges that do not
# formally include React 18. This flag installs them anyway (npm 6 behaviour),
# trading strict peer resolution for compatibility.
RUN npm install --legacy-peer-deps

# Copy all source files. Vite reads vite.config.js, src/, public/, index.html.
COPY . .

# `npm run build` invokes `vite build`, which:
#   1. Bundles and tree-shakes all JS/JSX/CSS modules
#   2. Applies PostCSS transforms if configured
#   3. Hashes asset filenames for cache-busting (e.g. main.a1b2c3.js)
#   4. Outputs the production bundle to dist/
RUN npm run build


# ── Stage 2: runtime ──────────────────────────────────────────────────────────
# nginx:alpine (~25 MB) vs nginx:latest/nginx:stable-debian (~140 MB).
# Alpine is used for the same reasons as the backend: smaller image, fewer CVEs.
FROM nginx:alpine

# wget is used for the HEALTHCHECK instruction. curl is not installed in nginx:alpine.
RUN apk add --no-cache wget

# Copy ONLY the compiled dist/ directory from the builder stage.
# No Node.js runtime, no node_modules, no source files reach this image.
COPY --from=builder /app/dist /usr/share/nginx/html

# Replace Nginx's default site configuration with the application-specific config.
# The custom nginx.conf handles:
#   - SPA routing fallback: try_files → index.html for all client-side routes
#   - /api/* reverse proxy to the backend service (same Docker network)
#   - /health proxy to backend (enables host-level health checks via port 80)
#   - Long-lived caching headers for hashed static assets (JS, CSS, images)
#   - Security headers: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
#   - Proper 5xx error handling (returns 502 instead of masking upstream errors
#     as 200 OK with the SPA HTML body — which breaks monitoring health checks)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Fallback health check for non-Compose deployments.
# The Compose healthcheck in docker-compose.yml takes precedence over this.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# `daemon off;` keeps Nginx in the foreground as PID 1.
# Nginx's default behaviour is to fork a master process to the background,
# which would cause the container to exit immediately (PID 1 exits = container exits).
# Running in the foreground also ensures SIGTERM from `docker stop` reaches Nginx
# directly and triggers a graceful connection drain before shutdown.
CMD ["nginx", "-g", "daemon off;"]
