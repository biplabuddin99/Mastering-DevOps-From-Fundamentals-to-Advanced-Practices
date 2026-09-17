/**
 * PM2 Ecosystem Configuration
 *
 * Used by `pm2-runtime ecosystem.config.js` (the Docker CMD in backend/Dockerfile).
 * pm2-runtime is PM2's container-native launcher: it stays in the foreground as
 * PID 1, forwards OS signals to the Node.js process, and restarts it on crash —
 * all without needing a separate init system inside the container.
 */
module.exports = {
  apps: [{
    name: 'bmi-backend',
    script: './src/server.js',

    // cwd must match the Docker WORKDIR (/app).
    // PM2 resolves `script` relative to `cwd`. If this pointed to a host path
    // (e.g. /home/ubuntu/project/backend) the container would fail to start
    // because that path does not exist inside the image.
    cwd: '/app',

    // instances: 1 — single Node.js process.
    // The container already provides one process per container replica.
    // Multi-instance clustering here would require coordinating the pg connection
    // pool across workers and provides no benefit at this deployment scale.
    instances: 1,

    // autorestart: true — PM2 restarts the Node.js process if it crashes
    // without Docker restarting the entire container. PM2's restart is faster
    // than a full container lifecycle (no image pull, no health-check delay).
    autorestart: true,

    // watch: false — NEVER enable file watching in production.
    // It causes restarts in response to log file writes, volume-mounted config
    // changes, and any other filesystem events — extremely disruptive in prod.
    watch: false,

    // Restart the process if resident set size exceeds 500 MB.
    // This provides a clean recovery from memory leaks before the container's
    // hard memory limit (1 GB in docker-compose.prod.yml) triggers an OOM kill.
    // A PM2-managed restart is graceful; an OOM kill is not.
    max_memory_restart: '500M',

    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },

    // Route all PM2 process output to Docker's logging driver by writing to
    // the file descriptors of container PID 1 (/proc/1/fd/1 = stdout, /proc/1/fd/2 = stderr).
    // Without this, PM2 would write logs to a file inside the container that is
    // completely invisible to `docker logs`, Promtail, and Loki.
    error_file: '/proc/1/fd/2',  // PM2 stderr → Docker stderr → json-file driver → Loki
    out_file: '/proc/1/fd/1',    // PM2 stdout → Docker stdout → json-file driver → Loki

    // Set to /dev/null because all output is already routed to stdout/stderr above.
    // A combined log_file here would be a redundant copy wasting container disk space.
    log_file: '/dev/null',

    // Prepend an ISO-8601 timestamp to every log line emitted by PM2 itself.
    // Promtail uses these timestamps for log ordering in Loki; Loki uses them
    // for time-range query filtering in Grafana.
    time: true,
    merge_logs: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
