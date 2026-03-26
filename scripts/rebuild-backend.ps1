Write-Host "Reconstruyendo backend..." -ForegroundColor Cyan
Set-Location $PSScriptRoot\..
docker compose -f docker-compose.dev.yml up -d --build --no-deps backend

if ($LASTEXITCODE -eq 0) {
    Write-Host "Backend reconstruido y reiniciado." -ForegroundColor Green
    Write-Host "Logs: docker compose -f docker-compose.dev.yml logs -f backend" -ForegroundColor Gray
} else {
    Write-Host "Error al reconstruir el backend." -ForegroundColor Red
    exit 1
}
