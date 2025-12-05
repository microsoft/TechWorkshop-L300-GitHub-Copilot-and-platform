# =========================================================================
# Dockerfile for ZavaStorefront .NET 6 Application
# Multi-stage build for optimized production container
# =========================================================================

# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copy project files and restore dependencies
COPY ["ZavaStorefront.csproj", "."]
RUN dotnet restore "ZavaStorefront.csproj"

# Copy remaining source code
COPY . .

# Build and publish the application
RUN dotnet build "ZavaStorefront.csproj" -c Release -o /app/build
RUN dotnet publish "ZavaStorefront.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS runtime
WORKDIR /app

# Copy published application
COPY --from=build /app/publish .

# Expose port 8080 (Azure App Service default)
EXPOSE 8080

# Set environment variables
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Start the application
ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
