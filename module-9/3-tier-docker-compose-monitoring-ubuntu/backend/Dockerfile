# =============================================================================
# Backend Dockerfile — Multi-Stage Build
# =============================================================================
# Stage 1 (builder) : Installs Node.js dependencies with full toolchain
# Stage 2 (runtime) : Copies only compiled output into a clean minimal image
#
# The multi-stage pattern ensures the final production image does NOT contain:
#   - npm cache (~200 MB on a typical project)
#   - devDependencies (test frameworks, linters, type definitions)
#   - Any intermediate build artefacts or temporary files
#
# This reduces the final image size and eliminates attack surface from packages
# that have no runtime role.
# =============================================================================

# ── Stage 1: builder ──────────────────────────────────────────────────────────
# node:18-alpine is chosen over node:18-bullseye (Debian) for:
#   - ~170 MB smaller base image (~50 MB vs ~200 MB uncompressed)
#   - Significantly fewer pre-installed packages = smaller CVE surface
#   - Consistent base with the production stage (same OS, same tooling)
FROM node:18-alpine AS builder

WORKDIR /app

# Copy only the package manifests before copying source code.
# Docker builds each instruction as a cached layer. The expensive `npm install`
# layer is only invalidated when package.json or package-lock.json changes —
# not on every application source file change. This dramatically speeds up
# iterative builds during development and in CI pipelines.
COPY package*.json ./

# Install only production dependencies (excludes devDependencies such as
# Jest, ESLint, and TypeScript type packages). This reduces the amount of
# code that gets copied into the final image.
RUN npm install --only=production

# Copy application source after installing dependencies.
# Layer order matters: source changes are far more frequent than dependency
# changes, so keeping source copy after npm install maximises cache reuse.
COPY . .


# ── Stage 2: runtime ──────────────────────────────────────────────────────────
# Start from a clean node:18-alpine base. The builder stage's npm cache,
# intermediate files, and any environment secrets are left behind entirely.
# Only the /app directory is carried forward via COPY --from=builder.
FROM node:18-alpine

WORKDIR /app

# wget is required by the HEALTHCHECK instruction below (and by the Compose
# healthcheck in docker-compose.yml). It is not included in alpine by default.
#
# pm2 is installed globally as the in-container process manager.
# pm2-runtime (used in CMD) is PM2's Docker-optimised launcher: it stays
# in the foreground as PID 1, forwards OS signals to the Node process,
# streams logs to stdout/stderr, and restarts the process on crash.
RUN apk add --no-cache wget \
  && npm install -g pm2

# Create a non-root system user and group.
# Running as root inside a container provides root-equivalent access on the
# host if the container runtime is ever compromised. A dedicated system user
# (UID 1001, no shell, no home directory) limits the blast radius.
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy the full /app tree from the builder stage (node_modules + source).
# --chown transfers ownership atomically during the copy so the nodejs user
# can read and execute all files without a separate chmod step at runtime.
COPY --from=builder --chown=nodejs:nodejs /app .

# Drop privileges. All subsequent instructions and the CMD run as nodejs (UID 1001).
# The nodejs user has no write access outside /app and no login shell.
USER nodejs

# EXPOSE is metadata only — it does not publish the port to the host.
# It documents the application's listen port and enables service-to-service
# DNS resolution in Docker Compose networks.
EXPOSE 3000

# Fallback health check for non-Compose deployments (e.g. plain `docker run`).
# When a healthcheck is also defined in docker-compose.yml, Compose's version
# takes precedence over this Dockerfile HEALTHCHECK instruction.
# start_period: 40s allows time for PM2 startup and the pg connection pool warm-up.
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# pm2-runtime is PM2's container-native entry point. It:
#   1. Reads ecosystem.config.js for the process name, script path, and env vars
#   2. Stays in the foreground as PID 1 — required for Docker signal handling
#   3. Forwards SIGTERM (from `docker stop`) gracefully to the Node.js process
#   4. Restarts the Node.js process on crash before Docker would notice the failure
#   5. Writes logs to /proc/1/fd/1+2 (captured by Docker's json-file driver)
#
# Using `node src/server.js` directly would bypass all of the above.
CMD ["pm2-runtime", "ecosystem.config.js"]
