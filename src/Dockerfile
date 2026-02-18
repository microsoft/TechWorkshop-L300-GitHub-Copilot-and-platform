# Multi-stage Dockerfile for ZavaStorefront ASP.NET Core 6.0 application

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app

# Copy csproj and restore dependencies
COPY *.csproj ./
RUN dotnet restore

# Copy everything else and build
COPY . ./
RUN dotnet publish -c Release -o out

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS runtime
WORKDIR /app

# Copy build artifacts from build stage
COPY --from=build /app/out .

# Expose port 80 for the application
EXPOSE 80

# Set environment variables
ENV ASPNETCORE_URLS=http://+:80

# Run the application
ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
