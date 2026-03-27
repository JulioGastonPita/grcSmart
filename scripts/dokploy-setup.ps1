# ==============================================================
# dokploy-setup.ps1
# Crea el proyecto grcSmart en Dokploy via API y dispara
# el primer deploy del docker-compose.yml del repositorio.
#
# La API key se lee automaticamente de .env.local (raiz del repo).
# Uso:
#   .\scripts\dokploy-setup.ps1
#   .\scripts\dokploy-setup.ps1 -Deploy
# ==============================================================

param(
    [string]$ApiKey = "",
    [string]$DokployUrl = "http://dokploy.edensa.com.ar:3000",
    [string]$ProjectName = "grcSmart",
    [string]$ProjectDescription = "RAG para consulta de politicas y procedimientos",
    [string]$GitRepoUrl = "https://github.com/JulioGastonPita/grcSmart.git",
    [string]$GitBranch = "main",
    [string]$ComposeFile = "docker-compose.yml",
    [string]$DbPassword = "CAMBIAR_EN_PRODUCCION",
    [string]$ViteApiBaseUrl = "http://dokploy.edensa.com.ar",
    [switch]$Deploy
)

# --- Cargar .env.local si existe ------------------------------
$envLocalPath = Join-Path $PSScriptRoot "..\.env.local"
if (Test-Path $envLocalPath) {
    Get-Content $envLocalPath | ForEach-Object {
        if ($_ -match "^\s*([^#=][^=]*)=(.*)$") {
            $k = $matches[1].Trim()
            $v = $matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($k, $v, "Process")
        }
    }
}

if ($ApiKey -eq "") { $ApiKey = [System.Environment]::GetEnvironmentVariable("DOKPLOY_API_KEY", "Process") }
$envUrl2 = [System.Environment]::GetEnvironmentVariable("DOKPLOY_URL", "Process")
if ($envUrl2 -ne "") { $DokployUrl = $envUrl2 }

# --- Validaciones ---------------------------------------------
if ($ApiKey -eq "") {
    Write-Host "ERROR: Se requiere una API key de Dokploy." -ForegroundColor Red
    Write-Host "Agrega DOKPLOY_API_KEY=tu_key en el archivo .env.local" -ForegroundColor Yellow
    exit 1
}

$BaseUrl = $DokployUrl.TrimEnd("/") + "/api"
$Headers = @{
    "x-api-key"    = $ApiKey
    "Content-Type" = "application/json"
}

# --- Helper de llamadas a la API ------------------------------
function Invoke-Dokploy {
    param(
        [string]$Endpoint,
        [string]$Method = "POST",
        [hashtable]$Body = @{}
    )
    $url = "$BaseUrl/$Endpoint"
    try {
        if ($Method -eq "GET") {
            return Invoke-RestMethod -Uri $url -Method GET -Headers $Headers -ErrorAction Stop
        }
        else {
            $json = $Body | ConvertTo-Json -Depth 10
            return Invoke-RestMethod -Uri $url -Method POST -Headers $Headers -Body $json -ErrorAction Stop
        }
    }
    catch {
        $code = $_.Exception.Response.StatusCode.value__
        $msg  = $_.ErrorDetails.Message
        Write-Host "  ERROR $code en $Endpoint" -ForegroundColor Red
        if ($msg) { Write-Host "  $msg" -ForegroundColor Red }
        throw $_
    }
}

function Step { param([string]$Msg); Write-Host ""; Write-Host ">>> $Msg" -ForegroundColor Cyan }

# --- PASO 1: Detectar servidor --------------------------------
Step "Detectando servidor..."
$serverId = $null
try {
    $servers = Invoke-Dokploy -Endpoint "server.all" -Method "GET"
    if ($servers -and $servers.Count -gt 0) {
        $serverId = $servers[0].serverId
        Write-Host "  Servidor remoto: $($servers[0].name) (ID: $serverId)" -ForegroundColor Green
    }
    else {
        Write-Host "  Sin servidores remotos - usando servidor local." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  Sin servidores remotos - usando servidor local." -ForegroundColor Yellow
}

# --- PASO 2: Crear proyecto (incluye environment por defecto) ---
Step "Creando proyecto '$ProjectName'..."
$response      = Invoke-Dokploy -Endpoint "project.create" -Body @{ name = $ProjectName; description = $ProjectDescription }
$projectId     = $response.project.projectId
$environmentId = $response.environment.environmentId
Write-Host "  Proyecto creado     (ID: $projectId)" -ForegroundColor Green
Write-Host "  Environment default (ID: $environmentId)" -ForegroundColor Green

# --- PASO 4: Crear compose service ---------------------------
Step "Creando servicio Docker Compose..."
$composeBody = @{ name = $ProjectName; environmentId = $environmentId }
if ($serverId) { $composeBody["serverId"] = $serverId }
$compose   = Invoke-Dokploy -Endpoint "compose.create" -Body $composeBody
$composeId = $compose.composeId
Write-Host "  Compose service creado (ID: $composeId)" -ForegroundColor Green

# --- PASO 5: Configurar repositorio Git ----------------------
Step "Configurando repositorio Git..."
$envVars = "DB_USER=grcsmart`nDB_PASSWORD=$DbPassword`nDB_NAME=grcsmart_db`nVITE_API_BASE_URL=$ViteApiBaseUrl"

Invoke-Dokploy -Endpoint "compose.update" -Body @{
    composeId    = $composeId
    sourceType   = "git"
    customGitUrl = $GitRepoUrl
    branch       = $GitBranch
    composePath  = $ComposeFile
    env          = $envVars
} | Out-Null

Write-Host "  Repositorio: $GitRepoUrl ($GitBranch)" -ForegroundColor Green
Write-Host "  Compose file: $ComposeFile" -ForegroundColor Green

# --- PASO 6: Deploy (opcional) -------------------------------
if ($Deploy) {
    Step "Disparando primer deploy..."
    Invoke-Dokploy -Endpoint "compose.deploy" -Body @{ composeId = $composeId } | Out-Null
    Write-Host "  Deploy encolado. Revisa el estado en Dokploy UI." -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "Setup completo. Para deployar ejecuta:" -ForegroundColor Yellow
    Write-Host "  .\scripts\dokploy-setup.ps1 -Deploy" -ForegroundColor White
}

# --- Guardar IDs en .env.local para uso posterior ------------
$envLocalPath2 = Join-Path $PSScriptRoot "..\.env.local"
$envContent    = Get-Content $envLocalPath2 -ErrorAction SilentlyContinue
# Eliminar entradas previas de IDs de Dokploy
$envContent = $envContent | Where-Object { $_ -notmatch "^DOKPLOY_(COMPOSE|PROJECT|ENVIRONMENT|SERVER)_ID=" }
$envContent += "DOKPLOY_COMPOSE_ID=$composeId"
$envContent += "DOKPLOY_PROJECT_ID=$projectId"
$envContent += "DOKPLOY_ENVIRONMENT_ID=$environmentId"
Set-Content -Path $envLocalPath2 -Value $envContent
Write-Host "  IDs guardados en .env.local" -ForegroundColor Green

# --- Resumen -------------------------------------------------
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " grcSmart configurado en Dokploy" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Proyecto ID   : $projectId"
Write-Host "  Environment ID: $environmentId"
Write-Host "  Compose ID    : $composeId"
Write-Host "  Servidor ID   : $serverId"
Write-Host "  UI Dokploy    : $DokployUrl"
Write-Host ""
Write-Host "RECORDATORIO: cambia DB_PASSWORD en .env.local antes de deployar." -ForegroundColor Yellow
