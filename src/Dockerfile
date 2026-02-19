FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

COPY ["ZavaStorefront.csproj", "./"]
RUN dotnet restore "./ZavaStorefront.csproj"

COPY . .
RUN dotnet publish "./ZavaStorefront.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80

ENTRYPOINT ["dotnet", "ZavaStorefront.dll"]
