# GitHub Actions Workflow for ZavaStorefront

This repository contains a GitHub Actions workflow to build and deploy the ZavaStorefront .NET application as a container to an Azure App Service.

## Prerequisites

1. **Azure App Service**: Ensure you have an Azure App Service already defined in the `infra` folder of this repository.
2. **GitHub Secrets**: Configure the following secrets in your GitHub repository:
   - `AZURE_CREDENTIALS`: Azure service principal credentials in JSON format. You can create a service principal and get the credentials using the Azure CLI:
     ```bash
     az ad sp create-for-rbac --name "myApp" --role contributor \
       --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
       --sdk-auth
     ```
     Copy the output JSON and save it as the `AZURE_CREDENTIALS` secret.
   - `AZURE_CONTAINER_REGISTRY_LOGIN_SERVER`: The login server URL of your Azure Container Registry (e.g., `myregistry.azurecr.io`).
   - `AZURE_CONTAINER_REGISTRY_USERNAME`: The username for your Azure Container Registry.
   - `AZURE_CONTAINER_REGISTRY_PASSWORD`: The password for your Azure Container Registry.
   - `AZURE_APP_NAME`: The name of your Azure App Service.

## Workflow Overview

The GitHub Actions workflow is triggered on every push to the `main` branch. It performs the following steps:

1. **Checkout Code**: Clones the repository.
2. **Azure Login**: Authenticates with Azure using the provided service principal credentials.
3. **Setup .NET**: Sets up the .NET environment for building the application.
4. **Build and Publish**: Builds and publishes the .NET application.
5. **Docker Login**: Logs in to the Azure Container Registry.
6. **Build and Push Docker Image**: Builds the Docker image and pushes it to the Azure Container Registry.
7. **Deploy to Azure App Service**: Deploys the container image to the Azure App Service.

## Notes

- Ensure that the `infra` folder contains the necessary Bicep templates for provisioning the Azure App Service.
- The workflow assumes that the Azure App Service and Azure Container Registry are already provisioned.
- For more details on configuring GitHub Actions workflows, refer to the [GitHub Actions documentation](https://docs.github.com/en/actions).

Feel free to modify the workflow file to suit your specific requirements.