param(
    [Parameter(Mandatory=$true)]
    [string]$Message
)

Set-Location $PSScriptRoot\..

Write-Host "Preparando despliegue..." -ForegroundColor Cyan

git add -A
git commit -m $Message

if ($LASTEXITCODE -ne 0) {
    Write-Host "No hay cambios para commitear o error en commit." -ForegroundColor Yellow
    exit 0
}

Write-Host "Haciendo push a origin main..." -ForegroundColor Cyan
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "Push exitoso. Dokploy iniciara el despliegue automaticamente." -ForegroundColor Green
} else {
    Write-Host "Error al hacer push." -ForegroundColor Red
    exit 1
}
