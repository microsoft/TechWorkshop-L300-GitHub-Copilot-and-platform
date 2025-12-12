# Docker Configuration Guide

## Overview
This directory contains Docker configuration files for building and running the ZavaStorefront application as a container.

## Files

### Dockerfile
Multi-stage Dockerfile for building and packaging the .NET 6.0 ASP.NET MVC application.

**Build Stages:**
1. **Build Stage**: Compiles the application using .NET 6.0 SDK
2. **Publish Stage**: Creates optimized release package
3. **Runtime Stage**: Runs the application using .NET 6.0 runtime

**Key Features:**
- Minimizes final image size (runtime-only base image)
- Fast builds with layer caching
- Security: Uses official Microsoft base images
- Port: 8080 (HTTP)

### .dockerignore
Specifies files and directories to exclude from Docker build context.

**Excluded Items:**
- Solution files (`.sln`) - Prevents MSBuild confusion
- Build artifacts (`bin/`, `obj/`)
- Version control (`.git/`)
- IDE files (`.vscode/`, `.vs/`, `.idea/`, `*.user`)
- Cache directories (`.cache/`, `node_modules/`)
- Other metadata files

**Benefits:**
- Reduces build context size
- Faster Docker build performance
- Cleaner final image

### docker-compose.yml
Local development configuration for running the application in Docker.

**Services:**
- **zava-app**: ZavaStorefront application container
  - Port: 8080
  - Environment: Development
  - Auto-restart: Yes

**Optional:**
- SQL Server service (commented out) - Uncomment when database integration needed

## Building Locally

### Prerequisites
- Docker Desktop installed and running
- Located in `src/` directory

### Build Docker Image
```bash
# Navigate to src directory
cd src

# Build image with tag
docker build -t zava-storefront:latest .

# Or with specific version
docker build -t zava-storefront:1.0.0 .
```

### Run Container Directly
```bash
# Run with default settings
docker run -p 8080:8080 zava-storefront:latest

# Run with custom environment
docker run -p 8080:8080 \
  -e ASPNETCORE_ENVIRONMENT=Development \
  zava-storefront:latest

# Run in detached mode
docker run -d -p 8080:8080 --name zava zava-storefront:latest
```

### Using docker-compose
```bash
# Build and start services
docker-compose up --build

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f zava-app

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## Access Application
- **Local URL**: http://localhost:8080
- **Health Check**: http://localhost:8080/Health (if implemented)

## Environment Variables

### Development
```
ASPNETCORE_ENVIRONMENT=Development
ASPNETCORE_URLS=http://+:8080
```

### Production (Azure)
```
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=https://+:443
```

## Image Details

### Base Images
- **Build**: `mcr.microsoft.com/dotnet/sdk:6.0`
- **Runtime**: `mcr.microsoft.com/dotnet/aspnet:6.0`

### Image Size
- Final image: ~200-250 MB (typical for .NET 6.0 ASP.NET)
- Build image: ~2 GB (temporary, used only during build)

### Security Considerations
- Uses official Microsoft base images (regularly patched)
- Non-root user recommended for production
- No credentials stored in image
- Uses read-only root filesystem where possible

## Troubleshooting

### Port Already in Use
```bash
# Check what's using port 8080
netstat -ano | findstr :8080  # Windows
lsof -i :8080                  # Mac/Linux

# Use different port
docker run -p 8081:8080 zava-storefront:latest
```

### Container Exits Immediately
```bash
# Check logs
docker logs <container-id>

# Run interactively
docker run -it zava-storefront:latest /bin/bash
```

### Image Size Issues
```bash
# Prune unused images
docker image prune

# Remove specific image
docker rmi zava-storefront:latest
```

## Integration with Azure

### Push to Azure Container Registry
```bash
# Login to ACR
az acr login --name <acr-name>

# Tag image
docker tag zava-storefront:latest <acr-name>.azurecr.io/zava-storefront:latest

# Push to registry
docker push <acr-name>.azurecr.io/zava-storefront:latest
```

### Deploy to Container Apps
```bash
# Update container app with new image
az containerapp update \
  --name <app-name> \
  --resource-group <rg-name> \
  --image <acr-name>.azurecr.io/zava-storefront:latest
```

## CI/CD Integration

### GitHub Actions
The CI/CD pipeline in `.github/workflows/build-deploy.yml` automatically:
1. Builds Docker image
2. Pushes to Azure Container Registry
3. Updates Container App deployment

Trigger: Push to `main` branch or manual workflow dispatch

## Best Practices

✅ **Do:**
- Use specific base image versions (not `latest`)
- Exclude unnecessary files in `.dockerignore`
- Keep images as small as possible
- Use multi-stage builds for smaller final images
- Scan images for vulnerabilities regularly
- Use managed identities for registry authentication

❌ **Don't:**
- Run containers as root user
- Store secrets in images
- Use `latest` tag in production
- Include unnecessary build tools in runtime image
- Skip base image updates

## References

- [Docker Documentation](https://docs.docker.com/)
- [.NET Docker Images](https://hub.docker.com/_/microsoft-dotnet)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Security](https://docs.docker.com/engine/security/)
