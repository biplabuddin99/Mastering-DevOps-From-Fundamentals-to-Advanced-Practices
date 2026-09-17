const { Pool } = require('pg');

// PostgreSQL connection pool configuration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 2000, // Return error after 2 seconds if can't connect
});

// Handle pool errors — log but do not exit; PM2 will restart if the process becomes unhealthy
pool.on('error', (err, client) => {
  console.error('Unexpected error on idle PostgreSQL client:', err);
});

// Test connection on startup
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('ERROR: Database connection failed:', err.message);
    // Exit so PM2 / Docker restart policy can recover the process
    process.exit(1);
  } else {
    console.log('SUCCESS: Database connected successfully at:', res.rows[0].now);
  }
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool
};
