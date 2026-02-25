# Build stage
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /source

COPY src/*.csproj ./src/
RUN dotnet restore ./src/ZavaStorefront.csproj

COPY src/ ./src/
RUN dotnet publish ./src/ZavaStorefront.csproj -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS runtime
WORKDIR /app
EXPOSE 80
EXPOSE 443

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:80
ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
