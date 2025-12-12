# Quick Reference Guide - Issue #2

**GitHub Issue**: Provision Azure Infrastructure for ZavaStorefront Web Application (Dev Environment) #2

---

## 🚀 Deploy in 3 Steps

```bash
# Step 1: Navigate to project
cd c:\Users\ruchidalal\ZavaLabFork

# Step 2: Deploy infrastructure and application
azd up

# Step 3: Get application URL
az containerapp show --name aca-duidxq2srj2z --resource-group rg-dev \
  --query properties.configuration.ingress.fqdn
```

Then visit: `https://{FQDN}/`

---

## 📋 What Was Delivered

### Infrastructure (Bicep)
- ✅ 8 Bicep module files
- ✅ Subscription-scoped deployment
- ✅ Automated resource group creation
- ✅ 5 Azure resources provisioned

### Docker
- ✅ Multi-stage Dockerfile (.NET 6.0)
- ✅ docker-compose for local development
- ✅ Optimized .dockerignore
- ✅ Comprehensive Docker guide

### CI/CD
- ✅ GitHub Actions workflow
- ✅ Automated build and deploy
- ✅ Docker push to Azure Container Registry
- ✅ Container App update

### Documentation
- ✅ 2,170+ lines across 6 guides
- ✅ Architecture diagrams
- ✅ Step-by-step instructions
- ✅ Troubleshooting guide

---

## 🏗️ Azure Resources

| Resource | Name | Purpose |
|----------|------|---------|
| Resource Group | `rg-dev` | Container for all resources |
| Container App | `aca-{token}` | Run .NET application |
| Container Env | `aze-{token}` | Manage containers |
| Registry | `acr{token}` | Store Docker images |
| Log Analytics | `law-{token}` | Monitor and log |
| Managed Identity | `uami-{token}` | Secure ACR access |

---

## 🔧 Configuration

### GitHub Secrets (Required for CI/CD)
```
AZURE_SUBSCRIPTION_ID          = f95d461a-e712-4c78-89bf-41079cc7ccea
AZURE_CLIENT_ID                = {from service principal}
AZURE_TENANT_ID                = {from Azure}
AZURE_CONTAINER_REGISTRY_NAME  = acrduidxq2srj2z
AZURE_RESOURCE_GROUP           = rg-dev
RESOURCE_TOKEN                 = duidxq2srj2z
```

### Environment (.azure/dev/.env)
```
AZURE_ENV_NAME=dev
AZURE_LOCATION=westus3
AZURE_SUBSCRIPTION_ID=f95d461a-e712-4c78-89bf-41079cc7ccea
AZURE_RESOURCE_GROUP=rg-dev
```

---

## 📚 Documentation Map

| Document | Purpose | Read Time |
|----------|---------|-----------|
| **ISSUE_2_COMPLETE.md** | Executive summary and quick start | 10 min |
| **INFRASTRUCTURE_PLAN.md** | Detailed architecture and deployment | 20 min |
| **infra/README.md** | Bicep files and modules explained | 15 min |
| **src/DOCKER.md** | Docker configuration guide | 15 min |
| **.github/workflows/README.md** | CI/CD setup instructions | 10 min |
| **VERIFICATION_REPORT.md** | Completion verification | 5 min |

---

## 🎯 Key Features

### Deployment
- Subscription-scoped provisioning
- Automatic resource group creation
- Infrastructure as Code (Bicep)
- AZD-compatible setup

### Security
- HTTPS-only access
- No admin keys stored
- Managed identity authentication
- Private container registry

### Scalability
- Auto-scaling (1-3 replicas)
- 0.5 CPU, 1Gi memory per replica
- Serverless architecture
- Pay-as-you-go pricing

### Monitoring
- Log Analytics integration
- 30-day log retention
- Application metrics captured
- Easy KQL queries

---

## 💰 Estimated Costs

| Service | Tier | Cost/Month |
|---------|------|-----------|
| Container Apps | Consumption | $15-30 |
| Container Registry | Basic | $5-10 |
| Log Analytics | PerGB2018 | $10-15 |
| **Total** | | **$30-55** |

---

## 🐛 Troubleshooting

### Container app won't start
```bash
# Check logs
az containerapp logs show --name aca-duidxq2srj2z --resource-group rg-dev

# Verify image in registry
az acr repository list --name acrduidxq2srj2z
```

### Deployment fails
```bash
# Check resource group
az group show --name rg-dev

# View deployment errors
az deployment group list --resource-group rg-dev
```

### Can't access application
```bash
# Get FQDN
az containerapp show --name aca-duidxq2srj2z --resource-group rg-dev \
  --query properties.configuration.ingress.fqdn

# Check Container App status
az containerapp show --name aca-duidxq2srj2z --resource-group rg-dev
```

---

## 📂 Important Files

**Bicep Infrastructure**
- `infra/main.bicep` - Main orchestration
- `infra/modules/` - Infrastructure modules

**Docker Configuration**
- `src/Dockerfile` - Container image build
- `src/docker-compose.yml` - Local development

**CI/CD Pipeline**
- `.github/workflows/build-deploy.yml` - GitHub Actions

**Configuration**
- `azure.yaml` - AZD configuration
- `.azure/dev/.env` - Environment variables
- `infra/main.parameters.json` - Template parameters

---

## ✅ Verification Checklist

Before deployment:
- [ ] Azure subscription ID configured
- [ ] Azure Developer CLI installed
- [ ] Docker installed
- [ ] GitHub Secrets configured (if using CI/CD)
- [ ] Read INFRASTRUCTURE_PLAN.md

After deployment:
- [ ] Check Azure Portal for resources
- [ ] Access application via FQDN
- [ ] Verify logs in Log Analytics
- [ ] Test CI/CD by pushing to main branch

---

## 🔗 Useful Commands

### Deploy
```bash
azd provision              # Deploy infrastructure only
azd deploy                 # Build and deploy app only
azd up                     # Deploy both
azd down                   # Delete all resources
azd provision --preview    # Preview changes
```

### Container App
```bash
# Get FQDN
az containerapp show --name aca-duidxq2srj2z --resource-group rg-dev \
  --query properties.configuration.ingress.fqdn

# View logs
az containerapp logs show --name aca-duidxq2srj2z --resource-group rg-dev

# Update image
az containerapp update --name aca-duidxq2srj2z --resource-group rg-dev \
  --image {registry}.azurecr.io/image:tag
```

### Container Registry
```bash
# List repositories
az acr repository list --name acrduidxq2srj2z

# List images in repository
az acr repository show-tags --registry acrduidxq2srj2z \
  --repository zava-storefront

# Build and push image
az acr build --registry acrduidxq2srj2z \
  --image zava-storefront:latest \
  -f src/Dockerfile ./src
```

### Local Docker
```bash
# Build locally
cd src
docker build -t zava-storefront:latest .

# Run locally
docker run -p 8080:8080 zava-storefront:latest

# Using compose
docker-compose up --build
docker-compose down
```

---

## 📖 Documentation Index

### Getting Started
1. **ISSUE_2_COMPLETE.md** - Start here for overview
2. **INFRASTRUCTURE_PLAN.md** - Deep dive into architecture

### Technical Reference
3. **infra/README.md** - Bicep files documentation
4. **src/DOCKER.md** - Docker configuration
5. **.github/workflows/README.md** - CI/CD setup

### Verification
6. **VERIFICATION_REPORT.md** - Completion checklist
7. **ISSUE_2_REQUIREMENTS.md** - Detailed requirements

---

## 🎓 Learning Resources

- [Azure Container Apps Docs](https://learn.microsoft.com/azure/container-apps/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Docker Documentation](https://docs.docker.com/)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [GitHub Actions](https://docs.github.com/actions)

---

## 📞 Support

### For deployment issues
→ See **INFRASTRUCTURE_PLAN.md** Troubleshooting section

### For Docker issues
→ See **src/DOCKER.md** Troubleshooting section

### For CI/CD issues
→ See **.github/workflows/README.md** and GitHub Actions logs

### For general questions
→ See **ISSUE_2_REQUIREMENTS.md** Requirements section

---

## 🎉 Status

✅ **ISSUE #2 COMPLETE**

All requirements delivered:
- Infrastructure as Code (Bicep)
- Docker configuration
- CI/CD pipeline
- Comprehensive documentation

**Ready to deploy with**: `azd up`

---

*Last Updated: December 12, 2025*
*Issue: Provision Azure Infrastructure for ZavaStorefront Web Application (Dev Environment) #2*
