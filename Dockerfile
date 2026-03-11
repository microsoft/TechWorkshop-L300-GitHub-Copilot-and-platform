FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copy the project file
COPY ["src/ZavaStorefront.csproj", "src/"]

# Restore dependencies
RUN dotnet restore "src/ZavaStorefront.csproj"

# Copy the full source code
COPY . .

# Build the application
RUN dotnet build "src/ZavaStorefront.csproj" -c Release -o /app/build

# Publish the application
FROM build AS publish
RUN dotnet publish "src/ZavaStorefront.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS runtime
WORKDIR /app
COPY --from=publish /app/publish .

# Expose port 8080 for Azure App Service
EXPOSE 8080

# Set environment variables for Azure App Service compatibility
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
