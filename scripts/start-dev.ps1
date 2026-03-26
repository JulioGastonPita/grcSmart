# Levanta los servicios de desarrollo (Postgres + ChromaDB + Backend)
# El Frontend debe correrse por separado con: cd frontend && quasar dev

Write-Host "Iniciando servicios de desarrollo..." -ForegroundColor Cyan
Set-Location $PSScriptRoot\..
docker compose -f docker-compose.dev.yml up -d --build

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Servicios levantados:" -ForegroundColor Green
    Write-Host "  Backend: http://localhost:8080" -ForegroundColor Green
    Write-Host "  ChromaDB: http://localhost:8001" -ForegroundColor Green
    Write-Host "  PostgreSQL: localhost:5432" -ForegroundColor Green
    Write-Host ""
    Write-Host "Para el Frontend, ejecuta en otra terminal:" -ForegroundColor Yellow
    Write-Host "  cd frontend && quasar dev" -ForegroundColor Yellow
} else {
    Write-Host "Error al levantar los servicios." -ForegroundColor Red
    exit 1
}
