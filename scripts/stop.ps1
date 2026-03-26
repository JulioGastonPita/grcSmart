param(
    [switch]$Dev,
    [switch]$Prod
)

Set-Location $PSScriptRoot\..

if ($Dev) {
    Write-Host "Deteniendo servicios de desarrollo..." -ForegroundColor Yellow
    docker compose -f docker-compose.dev.yml down
} elseif ($Prod) {
    Write-Host "Deteniendo servicios de produccion..." -ForegroundColor Yellow
    docker compose down
} else {
    Write-Host "Deteniendo todos los servicios (dev)..." -ForegroundColor Yellow
    docker compose -f docker-compose.dev.yml down
}

Write-Host "Servicios detenidos." -ForegroundColor Green
