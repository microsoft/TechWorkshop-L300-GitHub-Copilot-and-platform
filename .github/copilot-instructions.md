# Copilot Instructions

## Project Overview

This repository has two parts:

1. **Zava Storefront** (`src/`) — An ASP.NET Core 6.0 MVC e-commerce demo app.
2. **Lab documentation** (`docs/`, `index.md`) — A Jekyll site (just-the-docs theme) deployed to GitHub Pages.

Azure infrastructure is defined in `infra/` using Bicep. The app deploys to Azure App Service as a Docker container via Azure Developer CLI (`azd`).

## Build and Run

```bash
# .NET app
cd src
dotnet build
dotnet run

# Docker
docker build -t zava-storefront ./src
docker run -p 8080:8080 zava-storefront

# Jekyll docs
bundle install
bundle exec jekyll serve

# Azure deployment
azd up          # provision infra + deploy app
azd provision   # infra only
```

## Architecture

### Storefront App (`src/`)

ASP.NET Core 6.0 MVC using the minimal hosting model (`Program.cs`, no `Startup.cs`). Convention-based routing: `{controller=Home}/{action=Index}/{id?}`.

- **No database.** `ProductService` holds a static in-memory `List<Product>` (singleton). `CartService` serializes cart state to ASP.NET session as JSON via `IHttpContextAccessor` (scoped). Session expires after 30 minutes.
- **HomeController** handles product listing and add-to-cart. **CartController** handles cart CRUD and checkout.
- Views are Razor `.cshtml` with a shared layout in `Views/Shared/`.

### Infrastructure (`infra/`)

Subscription-scoped Bicep deployment with modules for: Container Registry, App Service (Linux B1), Log Analytics + Application Insights, Azure AI Services (Foundry), and a managed identity with ACR pull role. Outputs are wired as `azd` environment variables.

## Conventions

### C# / .NET

- Constructor injection for all dependencies. `ProductService` is singleton; `CartService` is scoped.
- Structured logging via `ILogger<T>` on controller actions.
- Cart session key: `"ShoppingCart"`.

### Documentation (`docs/`)

- Exercises are numbered directories (`NN_exercise_name/`) with step files (`NN_MM.md`).
- Each doc file requires Jekyll front matter: `title`, `layout: default`, `nav_order`, `parent`.
- External links use `{:target="_blank"}`. Collapsible sections use `<details>` tags.
- Images are stored in `media/` and referenced via relative paths.
- Callout types (configured in `_config.yml`): `highlight`, `important`, `new`, `note`, `warning`.

### CI/CD

- `.github/workflows/jekyll-gh-pages.yml` builds and deploys the docs site on push to `main`.
- App deployment is handled separately via `azd` with Docker (multi-stage build, port 8080).
