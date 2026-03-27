# ==============================================================
# redeploy.ps1
# Dispara un redeploy del compose service de grcSmart en Dokploy.
# Lee los IDs y credenciales desde .env.local (raiz del repo).
#
# Uso:
#   .\scripts\redeploy.ps1
#   .\scripts\redeploy.ps1 -Message "fix: actualizo configuracion"
# ==============================================================

param(
    [string]$ApiKey     = "",
    [string]$DokployUrl = "http://dokploy.edensa.com.ar:3000",
    [string]$ComposeId  = "",
    [string]$Message    = "",
    [switch]$PushFirst   # Si se pasa, hace git push antes del redeploy
)

# --- Cargar .env.local ----------------------------------------
$envLocalPath = Join-Path $PSScriptRoot "..\.env.local"
if (Test-Path $envLocalPath) {
    Get-Content $envLocalPath | ForEach-Object {
        if ($_ -match "^\s*([^#=][^=]*)=(.*)$") {
            [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), "Process")
        }
    }
}

if ($ApiKey    -eq "") { $ApiKey    = [System.Environment]::GetEnvironmentVariable("DOKPLOY_API_KEY",    "Process") }
if ($ComposeId -eq "") { $ComposeId = [System.Environment]::GetEnvironmentVariable("DOKPLOY_COMPOSE_ID", "Process") }
$envUrl = [System.Environment]::GetEnvironmentVariable("DOKPLOY_URL", "Process")
if ($envUrl -ne "") { $DokployUrl = $envUrl }

# --- Validaciones ---------------------------------------------
if ($ApiKey -eq "") {
    Write-Host "ERROR: DOKPLOY_API_KEY no encontrada en .env.local" -ForegroundColor Red
    exit 1
}
if ($ComposeId -eq "") {
    Write-Host "ERROR: DOKPLOY_COMPOSE_ID no encontrada en .env.local" -ForegroundColor Red
    Write-Host "Ejecuta primero: .\scripts\dokploy-setup.ps1" -ForegroundColor Yellow
    exit 1
}

$BaseUrl = $DokployUrl.TrimEnd("/") + "/api"
$Headers = @{
    "x-api-key"    = $ApiKey
    "Content-Type" = "application/json"
}

# --- Git push opcional ----------------------------------------
if ($PushFirst) {
    Write-Host ""
    Write-Host ">>> Haciendo git push..." -ForegroundColor Cyan
    Set-Location (Join-Path $PSScriptRoot "..")
    if ($Message -ne "") {
        git add -A
        git commit -m $Message
    }
    git push origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error en git push." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Push exitoso." -ForegroundColor Green
}

# --- Redeploy -------------------------------------------------
Write-Host ""
Write-Host ">>> Disparando redeploy en Dokploy..." -ForegroundColor Cyan
Write-Host "  Compose ID: $ComposeId"

try {
    $body = @{ composeId = $ComposeId } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/compose.redeploy" -Method POST -Headers $Headers -Body $body -ErrorAction Stop | Out-Null
    Write-Host "  Redeploy encolado correctamente." -ForegroundColor Green
    Write-Host "  Revisa el estado en: $DokployUrl" -ForegroundColor White
}
catch {
    $code = $_.Exception.Response.StatusCode.value__
    $msg  = $_.ErrorDetails.Message
    Write-Host "  ERROR $code al hacer redeploy." -ForegroundColor Red
    if ($msg) { Write-Host "  $msg" -ForegroundColor Red }
    exit 1
}
