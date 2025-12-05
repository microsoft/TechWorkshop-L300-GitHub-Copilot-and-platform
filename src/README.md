# Zava Storefront - ASP.NET Core MVC

A simple e-commerce storefront application built with .NET 6 ASP.NET MVC.

## Features

- **Product Listing**: Browse a catalog of 8 sample products with images, descriptions, and prices
- **Shopping Cart**: Add products to cart with session-based storage
- **Cart Management**: View cart, update quantities, remove items
- **Checkout**: Simple checkout process that clears cart and shows success message
- **Responsive Design**: Mobile-friendly layout using Bootstrap 5

## Technology Stack

- .NET 6
- ASP.NET Core MVC
- Bootstrap 5
- Bootstrap Icons
- Session-based state management (no database)

## Project Structure

```
ZavaStorefront/
├── Controllers/
│   ├── HomeController.cs      # Products listing and add to cart
│   └── CartController.cs       # Cart operations and checkout
├── Models/
│   ├── Product.cs              # Product model
│   └── CartItem.cs             # Cart item model
├── Services/
│   ├── ProductService.cs       # Static product data
│   └── CartService.cs          # Session-based cart management
├── Views/
│   ├── Home/
│   │   └── Index.cshtml        # Products listing page
│   ├── Cart/
│   │   ├── Index.cshtml        # Shopping cart page
│   │   └── CheckoutSuccess.cshtml  # Checkout success page
│   └── Shared/
│       └── _Layout.cshtml      # Main layout with cart icon
└── wwwroot/
    ├── css/
    │   └── site.css            # Custom styles
    └── images/
        └── products/           # Product images directory
```

## How to Run

1. Navigate to the project directory:
   ```bash
   cd ZavaStorefront
   ```

2. Run the application:
   ```bash
   dotnet run
   ```

3. Open your browser and navigate to:
   ```
   https://localhost:5001
   ```

## Product Images

The application includes 8 sample products. Product images are referenced from:
- `/wwwroot/images/products/`

If images are not found, the application automatically falls back to placeholder images from placeholder.com.

To add custom product images, place JPG files in `wwwroot/images/products/` with these names:
- headphones.jpg
- smartwatch.jpg
- speaker.jpg
- charger.jpg
- usb-hub.jpg
- keyboard.jpg
- mouse.jpg
- webcam.jpg

## Sample Products

1. Wireless Bluetooth Headphones - $89.99
2. Smart Fitness Watch - $199.99
3. Portable Bluetooth Speaker - $49.99
4. Wireless Charging Pad - $29.99
5. USB-C Hub Adapter - $39.99
6. Mechanical Gaming Keyboard - $119.99
7. Ergonomic Wireless Mouse - $34.99
8. HD Webcam - $69.99

## Application Flow

1. **Landing Page**: Displays all products in a responsive grid
2. **Add to Cart**: Click "Buy" button to add products to cart
3. **View Cart**: Click cart icon (top right) to view cart contents
4. **Update Cart**: Modify quantities or remove items
5. **Checkout**: Click "Checkout" button to complete purchase
6. **Success**: View confirmation and return to products

## Session Management

- Cart data is stored in session
- Session timeout: 30 minutes
- No data persistence (cart clears when session expires)
- Cart is cleared after successful checkout

## Logging

The application includes structured logging for:
- Product page loads
- Adding products to cart
- Cart operations (update, remove)
- Checkout process

Logs are written to console during development.

---

## Azure Deployment

This application is configured for deployment to Azure using Azure Developer CLI (azd) and Bicep infrastructure as code.

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- Azure subscription with appropriate permissions

### Architecture

The infrastructure deploys the following resources in `westus3`:

| Resource | Purpose | SKU |
|----------|---------|-----|
| Azure Container Registry | Container image storage | Basic |
| App Service Plan | Linux hosting for containers | B1 |
| Web App for Containers | Application hosting | - |
| Application Insights | Application monitoring | - |
| Log Analytics Workspace | Centralized logging | PerGB2018 |
| Key Vault | Secrets management (AI Foundry) | Standard |
| Storage Account | AI Foundry data storage | Standard_LRS |
| AI Foundry (ML Workspace) | GPT-4 and Phi model access | Basic |

### Deployment Workflow

#### Option 1: Using Azure Developer CLI (Recommended)

```bash
# Login to Azure
azd auth login

# Initialize environment (first time only)
azd init

# Provision infrastructure and deploy application
azd up
```

#### Option 2: Manual Bicep Deployment

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-zavastore-dev-westus3 --location westus3

# Deploy infrastructure
az deployment group create \
  --resource-group rg-zavastore-dev-westus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam

# Build and push container image (no local Docker required)
az acr build \
  --registry <acr-name> \
  --image zavastorefront:latest \
  ./src
```

#### Option 3: GitHub Actions CI/CD

The repository includes a GitHub Actions workflow (`.github/workflows/deploy.yml`) that:
1. Builds container images using ACR Tasks (cloud-based, no local Docker)
2. Deploys to Azure Web App for Containers
3. Supports manual infrastructure provisioning via workflow dispatch

**Required Secrets:**
- `AZURE_CLIENT_ID` - Service principal client ID
- `AZURE_TENANT_ID` - Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID

### Security Features

- **Managed Identity**: Web App uses system-assigned managed identity
- **RBAC-based ACR Access**: AcrPull role assignment (no passwords)
- **HTTPS Only**: Enforced for all web traffic
- **TLS 1.2 Minimum**: Modern encryption standards
- **Key Vault RBAC**: Role-based access control for secrets

### Estimated Monthly Costs (Dev Environment)

| Resource | Estimated Cost |
|----------|---------------|
| ACR Basic | ~$5/month |
| App Service B1 | ~$13/month |
| Application Insights | ~$2-5/month |
| Log Analytics | ~$2-5/month |
| Key Vault | ~$0.03/10k ops |
| Storage Account | ~$2/month |
| AI Foundry | Pay-per-use |

**Total**: ~$25-35/month (excluding AI usage)

### Cleanup

```bash
# Using azd
azd down

# Or manually
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```
