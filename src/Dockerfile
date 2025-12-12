# Build stage
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# When building in ACR with context set to ./src, copy directly
COPY ZavaStorefront.csproj ./
RUN dotnet restore "ZavaStorefront.csproj"

COPY . .
RUN dotnet build "ZavaStorefront.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "ZavaStorefront.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY --from=publish /app/publish .

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
