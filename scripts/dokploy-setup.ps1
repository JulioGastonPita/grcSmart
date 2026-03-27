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

# --- PASO 2: Crear proyecto -----------------------------------
Step "Creando proyecto '$ProjectName'..."
$project = Invoke-Dokploy -Endpoint "project.create" -Body @{ name = $ProjectName; description = $ProjectDescription }

# Debug: mostrar respuesta cruda
Write-Host "  Respuesta raw proyecto:" -ForegroundColor DarkGray
Write-Host ($project | ConvertTo-Json -Depth 5) -ForegroundColor DarkGray

# tRPC puede envolver la respuesta en result.data
if ($project.result) { $project = $project.result.data }

$projectId = $project.projectId
Write-Host "  Proyecto creado (ID: $projectId)" -ForegroundColor Green

# --- PASO 3: Obtener environment por defecto -----------------
Step "Obteniendo environment del proyecto..."
$inputJson    = (@{ projectId = $projectId } | ConvertTo-Json -Compress)
$encodedInput = [System.Uri]::EscapeDataString($inputJson)
$envApiUrl    = "$BaseUrl/environment.byProjectId?input=$encodedInput"
Write-Host "  URL: $envApiUrl" -ForegroundColor DarkGray

try {
    $environments = Invoke-RestMethod -Uri $envApiUrl -Method GET -Headers $Headers
    Write-Host "  Respuesta raw environments:" -ForegroundColor DarkGray
    Write-Host ($environments | ConvertTo-Json -Depth 5) -ForegroundColor DarkGray
    if ($environments.result) { $environments = $environments.result.data }
}
catch {
    Write-Host "  Error al obtener environments: $($_.ErrorDetails.Message)" -ForegroundColor Red
    Write-Host "  Intentando endpoint alternativo project.one..." -ForegroundColor Yellow
    $inputJson2    = (@{ projectId = $projectId } | ConvertTo-Json -Compress)
    $encodedInput2 = [System.Uri]::EscapeDataString($inputJson2)
    $proj = Invoke-RestMethod -Uri "$BaseUrl/project.one?input=$encodedInput2" -Method GET -Headers $Headers
    Write-Host ($proj | ConvertTo-Json -Depth 8) -ForegroundColor DarkGray
    exit 1
}

if (-not $environments -or $environments.Count -eq 0) {
    Write-Host "No se encontro environment en el proyecto." -ForegroundColor Red
    exit 1
}
$environmentId = $environments[0].environmentId
Write-Host "  Environment: $($environments[0].name) (ID: $environmentId)" -ForegroundColor Green

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
