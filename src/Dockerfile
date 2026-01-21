# Build stage
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["ZavaStorefront.csproj", "./"]
RUN dotnet restore "ZavaStorefront.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "ZavaStorefront.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "ZavaStorefront.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS final
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Copy published output
COPY --from=publish /app/publish .

# Set environment variables
ENV ASPNETCORE_URLS=http://+:80
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
