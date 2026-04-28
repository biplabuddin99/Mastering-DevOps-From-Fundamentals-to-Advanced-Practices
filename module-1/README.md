# Docker + ngrok Demo

A simple Node.js Express application demonstrating Docker containerization and ngrok tunneling.

## Prerequisites

- Node.js 18+ (for local development)
- Docker
- ngrok

## Quick Start
### 1. Build the Docker Image

```bash
docker build -t docker-ngrok-demo .
```

### 2. Run the Container

```bash
docker run -p 3000:3000 docker-ngrok-demo:latest
```

Or run in detached mode:
```bash
docker run -d -p 3000:3000 --name my-app docker-ngrok-demo:latest
```

### 3. Set up ngrok

Configure your ngrok auth token (one-time setup):
```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN_HERE
```

### 4. Expose with ngrok

```bash
ngrok http 3000
```

## Available Endpoints

- `GET /` - Returns a greeting message
- `GET /health` - Health check endpoint
- `POST /echo` - Echoes back JSON data

## Testing the App

```bash
# Test the root endpoint
curl http://localhost:3000

# Test health check
curl http://localhost:3000/health

# Test echo endpoint
curl -X POST http://localhost:3000/echo -H "Content-Type: application/json" -d '{"message":"Hello"}'
```

## Running Locally (without Docker)

```bash
npm install
npm start
```

## Docker Commands Reference

```bash
# View running containers
docker ps

# View logs
docker logs my-app

# Follow logs in real-time
docker logs -f my-app

# Stop the container
docker stop my-app

# Start the container
docker start my-app

# Remove the container
docker rm my-app
```

## ngrok Web Interface

After starting ngrok, visit http://localhost:4040 to inspect HTTP requests in real-time.

## License

MIT
