# Dockerfile for ZavaStorefront (.NET 8 ASP.NET Core)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["ZavaStorefront.csproj", "./"]
RUN dotnet restore "./ZavaStorefront.csproj"
COPY . .
RUN dotnet publish "./ZavaStorefront.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
