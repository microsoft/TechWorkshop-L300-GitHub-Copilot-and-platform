# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Restore dependencies first (layer caching)
COPY ["ZavaStorefront.csproj", "."]
RUN dotnet restore "ZavaStorefront.csproj"

# Copy remaining source and publish
COPY . .
RUN dotnet publish "ZavaStorefront.csproj" \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS final
WORKDIR /app

# Non-root user for security
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid appgroup --shell /bin/false appuser

COPY --from=build --chown=appuser:appgroup /app/publish .

USER appuser
EXPOSE 80

ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
