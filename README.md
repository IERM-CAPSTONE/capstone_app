# Capstone App - NestJS Monorepo

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                           Client                                 │
└─────────────────────────────┬───────────────────────────────────┘
                              │ HTTP Request
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       app_api (Port 3000)                        │
│  • REST API endpoints                                            │
│  • Authentication                                                 │
│  • Push jobs to Redis Queue (Producer)                           │
└─────────────────────────────┬───────────────────────────────────┘
                              │ BullMQ (Redis)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   app_background (Port 3001)                     │
│  • Process background jobs (Consumer)                            │
│  • Handle async tasks                                            │
│  • Update database with results                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
capstone_app/
├── apps/
│   ├── app_api/                    # API Server (Producer)
│   │   └── src/
│   │       ├── main.ts
│   │       └── app_api.module.ts
│   │
│   └── app_background/             # Background Worker (Consumer)
│       └── src/
│           ├── main.ts
│           └── app_background.module.ts
│
├── libs/
│   └── queue/                      # Shared Queue Library (@app/queue)
│       └── src/
│           ├── index.ts
│           ├── queue.module.ts
│           ├── queue.constants.ts
│           └── interfaces/
│
├── docker-compose.yml              # Redis setup
├── package.json
└── nest-cli.json
```

## 🚀 Getting Started

### 1. Prerequisites

- Node.js 18+
- Docker & Docker Compose
- npm

### 2. Install Dependencies

```bash
npm install
```

### 3. Start Redis

```bash
# Start Redis in background
docker-compose up -d redis

# (Optional) Start Redis Commander for debugging
docker-compose up -d redis-commander
# Access at http://localhost:8081
```

### 4. Start Applications

```bash
# Terminal 1: Start API Server
npm run start:dev:api

# Terminal 2: Start Background Worker
npm run start:dev:background
```

## 🔄 Queue Flow

```
1. Client sends request to app_api
2. app_api creates job and adds to Redis queue
3. app_api returns response immediately (async)
4. app_background picks up job from queue
5. app_background processes job
6. Client can poll for status or receive webhook/websocket notification
```

## 📦 Available Queues

| Queue | Description |
|-------|-------------|
| `notification` | Push notifications, in-app notifications |
| `email` | Email sending jobs |

## 📦 Scripts

| Script | Description |
|--------|-------------|
| `npm run start:dev:api` | Start API in development mode |
| `npm run start:dev:background` | Start Background Worker in development mode |
| `npm run build:api` | Build API for production |
| `npm run build:background` | Build Background Worker for production |
| `npm run start:prod:api` | Start API in production mode |
| `npm run start:prod:background` | Start Background Worker in production mode |

## 🐳 Production Deployment

```bash
# Build both apps
npm run build:api
npm run build:background

# Run with PM2 or Docker
node dist/apps/app_api/main.js
node dist/apps/app_background/main.js
```

## 🔗 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_HOST` | localhost | Redis host |
| `REDIS_PORT` | 6379 | Redis port |
| `REDIS_PASSWORD` | (empty) | Redis password |
| `API_PORT` | 3000 | API server port |
| `BACKGROUND_PORT` | 3001 | Background worker port |
