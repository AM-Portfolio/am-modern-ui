# AM Modern UI - Docker Deployment

This directory contains the complete AM Modern UI monorepo with Docker support.

## 🚀 Quick Start

### Option 1: Build and Run All Services

```bash
# Build and start all containers
docker-compose up -d --build

# View logs
docker-compose logs -f
```

### Option 2: Run Specific Service

```bash
# Main app only
docker-compose up -d am-app

# Market UI only
docker-compose up -d market-ui
```

## 📊 Service Ports

| Service | Port | Description |
|---------|------|-------------|
| **AM App (Main)** | 9000 | Main application shell |
| Market UI | 9002 | Market data standalone app |
| Portfolio UI | 9005 | Portfolio management app |
| Trade UI | 9006 | Trade management app |

## 🌐 Access URLs

After starting the services:

- **Main App**: http://localhost:9000
- **Market UI**: http://localhost:9002
- **Portfolio UI**: http://localhost:9005
- **Trade UI**: http://localhost:9006

## ⚙️ Configuration

### Environment Variables

Create a `.env` file (use `.env.example` as template):

```bash
cp .env.example .env
```

Edit `.env` with your API endpoints:

```env
API_BASE_URL=https://your-api-url.com/api
AUTH_BASE_URL=https://your-api-url.com/api/auth
MARKET_API_URL=https://your-api-url.com/api/market
PORTFOLIO_API_URL=https://your-api-url.com/api/portfolio
TRADE_API_URL=https://your-api-url.com/api/trade
```

## 🛠️ Docker Commands

### Build

```bash
# Build all images
docker-compose build

# Build specific service
docker-compose build am-app
```

### Run

```bash
# Start all services (detached)
docker-compose up -d

# Start with build
docker-compose up -d --build

# Start and view logs
docker-compose up
```

### Stop

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### Logs

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f am-app
docker-compose logs -f market-ui
```

### Restart

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart am-app
```

## 📁 Project Structure

```
am_modern_ui/
├── am_app/                   # Main application shell
│   ├── Dockerfile
│   └── nginx.conf
├── am_market_ui/
│   └── live/                 # Standalone market app
│       └── Dockerfile
├── am_portfolio_ui/
│   └── live/                 # Standalone portfolio app
│       └── Dockerfile
├── am_trade_ui/
│   └── live/                 # Standalone trade app
│       └── Dockerfile
├── docker-compose.yml        # Multi-service orchestration
├── .env.example             # Environment template
└── README.md                # This file
```

## 🔧 Development

### Local Development (without Docker)

```bash
# Run main app
cd am_app
flutter run -d chrome

# Run market UI
cd am_market_ui/live
flutter run -d chrome

# Run portfolio UI
cd am_portfolio_ui/live
flutter run -d chrome
```

### Build for Production

```bash
# Build web app
flutter build web --release --web-renderer canvaskit
```

## 🐛 Troubleshooting

### Port Already in Use

If you get "port already in use" error:

```bash
# Find process using port 9000
lsof -ti:9000 | xargs kill -9

# Or change port in docker-compose.yml
ports:
  - "9001:80"  # Changed from 9000 to 9001
```

### Container Won't Start

```bash
# View container logs
docker-compose logs am-app

# Remove and rebuild
docker-compose down
docker-compose up -d --build
```

### Clean Restart

```bash
# Stop all containers
docker-compose down -v

# Remove all images
docker rmi $(docker images -q 'am_modern_ui*')

# Rebuild from scratch
docker-compose up -d --build
```

## 📝 Notes

- **Build Time**: Initial build may take 10-15 minutes (Flutter download + compile)
- **Image Size**: Each app image is ~500MB-800MB
- **Resource Requirements**: Minimum 4GB RAM, 10GB disk space
- **Web Renderer**: Using CanvasKit for better performance

## 🔐 Security

- All apps run as non-root in containers
- Nginx serves static files with security headers
- Environment variables for API configuration
- No sensitive data in images

## 📚 Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Architecture Documentation](./ARCHITECTURE.md)

---

**Version**: 1.0.0  
**Last Updated**: January 5, 2026  
**Maintained By**: AM Portfolio Team
