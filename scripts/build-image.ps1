param()

$ErrorActionPreference = 'Stop'

if (-not $env:ACR_NAME) {
    throw 'ACR_NAME is not set. Run `azd up` after infrastructure outputs are available.'
}

if (-not $env:AZURE_ENV_NAME) {
    throw 'AZURE_ENV_NAME is not set. Ensure azd environment is initialized.'
}

if (-not $env:AZURE_WEB_APP_NAME) {
    throw 'AZURE_WEB_APP_NAME is not set. Ensure bicep output is exported by azd.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $repoRoot 'src'
$imageRepository = 'zavastorefront'
$imageTag = $env:AZURE_ENV_NAME

Write-Host "Building image in ACR '$($env:ACR_NAME)' with tag '$imageTag'..."
az acr build --registry $env:ACR_NAME --image "$imageRepository`:$imageTag" $sourcePath

Write-Host "Applying container config to web app '$($env:AZURE_WEB_APP_NAME)'..."
az webapp config container set `
    --name $env:AZURE_WEB_APP_NAME `
    --resource-group "rg-$($env:AZURE_ENV_NAME)" `
    --container-image-name "$($env:ACR_LOGIN_SERVER)/$imageRepository`:$imageTag"

Write-Host 'Image build and web app container configuration completed.'
