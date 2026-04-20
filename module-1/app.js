const express = require('express');
const app = express();
const port = 3000;

app.use(express.json());

// Serve a simple favicon response
app.get('/favicon.ico', (req, res) => {
  res.status(204).end(); // No Content
});

// Or serve an actual favicon file
// app.get('/favicon.ico', (req, res) => {
//   res.sendFile(__dirname + '/favicon.ico');
// });

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Docker + ngrok!',
    timestamp: new Date().toISOString(),
    service: 'Demo App'
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.post('/echo', (req, res) => {
  res.json({
    received: req.body,
    echo: true,
    timestamp: new Date().toISOString()
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Demo app running on http://0.0.0.0:${port}`);
});