# ============================================================
# dokploy-setup.ps1
# Crea el proyecto grcSmart en Dokploy via API y dispara
# el primer deploy del docker-compose.yml del repositorio.
#
# IMPORTANTE: Nunca hardcodees tu API key. Pásala como
# parámetro o usa la variable de entorno DOKPLOY_API_KEY.
#
# Uso:
#   .\scripts\dokploy-setup.ps1 -ApiKey "TU_KEY"
#   .\scripts\dokploy-setup.ps1   # usa $env:DOKPLOY_API_KEY
# ============================================================

param(
    [string]$ApiKey = $env:DOKPLOY_API_KEY,
    [string]$DokployUrl = "http://dokploy.edensa.com.ar:3000",
    [string]$ProjectName = "grcSmart",
    [string]$ProjectDescription = "RAG para consulta de políticas y procedimientos",
    [string]$GitRepoUrl = "https://github.com/JulioGastonPita/grcSmart.git",
    [string]$GitBranch = "main",
    [string]$ComposeFile = "docker-compose.yml",

    # Variables de entorno para producción (editar antes de ejecutar)
    [string]$DbPassword = "CAMBIAR_EN_PRODUCCION",
    [string]$ViteApiBaseUrl = "http://dokploy.edensa.com.ar:8080",

    [switch]$Deploy   # Agrega este flag para disparar el deploy al final
)

# ─── Validaciones ─────────────────────────────────────────
if (-not $ApiKey) {
    Write-Host "ERROR: Se requiere una API key de Dokploy." -ForegroundColor Red
    Write-Host "Usa: .\dokploy-setup.ps1 -ApiKey 'tu_key'" -ForegroundColor Yellow
    Write-Host "O define la variable de entorno: `$env:DOKPLOY_API_KEY = 'tu_key'" -ForegroundColor Yellow
    exit 1
}

$BaseUrl = $DokployUrl.TrimEnd("/") + "/api"
$Headers = @{
    "x-api-key"    = $ApiKey
    "Content-Type" = "application/json"
}

# ─── Helpers ──────────────────────────────────────────────
function Invoke-Dokploy {
    param(
        [string]$Endpoint,
        [string]$Method = "POST",
        [hashtable]$Body = @{}
    )
    $url = "$BaseUrl/$Endpoint"
    try {
        if ($Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $url -Method GET -Headers $Headers -ErrorAction Stop
        } else {
            $json = $Body | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Uri $url -Method POST -Headers $Headers -Body $json -ErrorAction Stop
        }
        return $response
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorBody  = $_.ErrorDetails.Message
        Write-Host "  ERROR $statusCode en $Endpoint" -ForegroundColor Red
        if ($errorBody) { Write-Host "  $errorBody" -ForegroundColor Red }
        throw $_
    }
}

function Step {
    param([string]$Msg)
    Write-Host ""
    Write-Host ">>> $Msg" -ForegroundColor Cyan
}

# ─── PASO 1: Listar servidores para obtener serverId ─────
Step "Obteniendo lista de servidores..."
$servers = Invoke-Dokploy -Endpoint "server.all" -Method "GET"

if (-not $servers -or $servers.Count -eq 0) {
    Write-Host "No se encontraron servidores en Dokploy." -ForegroundColor Red
    Write-Host "Asegúrate de tener al menos un servidor configurado." -ForegroundColor Yellow
    exit 1
}

$server   = $servers[0]
$serverId = $server.serverId
Write-Host "  Servidor: $($server.name) (ID: $serverId)" -ForegroundColor Green

# ─── PASO 2: Crear proyecto ───────────────────────────────
Step "Creando proyecto '$ProjectName'..."
$project = Invoke-Dokploy -Endpoint "project.create" -Body @{
    name        = $ProjectName
    description = $ProjectDescription
}
$projectId = $project.projectId
Write-Host "  Proyecto creado (ID: $projectId)" -ForegroundColor Green

# ─── PASO 3: Obtener environment por defecto ──────────────
Step "Obteniendo environment del proyecto..."

# Dokploy crea un environment "Production" por defecto al crear el proyecto.
# Lo buscamos via byProjectId.
$envUrl = "$BaseUrl/environment.byProjectId?input=" + [System.Uri]::EscapeDataString(
    ((@{ projectId = $projectId }) | ConvertTo-Json -Compress)
)
$environments = Invoke-RestMethod -Uri $envUrl -Method GET -Headers $Headers

if (-not $environments -or $environments.Count -eq 0) {
    Write-Host "No se encontró environment en el proyecto." -ForegroundColor Red
    exit 1
}

$environment   = $environments[0]
$environmentId = $environment.environmentId
Write-Host "  Environment: $($environment.name) (ID: $environmentId)" -ForegroundColor Green

# ─── PASO 4: Crear compose service ────────────────────────
Step "Creando servicio Docker Compose..."
$compose = Invoke-Dokploy -Endpoint "compose.create" -Body @{
    name          = $ProjectName
    environmentId = $environmentId
    serverId      = $serverId
}
$composeId = $compose.composeId
Write-Host "  Compose service creado (ID: $composeId)" -ForegroundColor Green

# ─── PASO 5: Configurar repositorio Git ───────────────────
Step "Configurando repositorio Git..."

# Variables de entorno del docker-compose (formato KEY=VALUE separado por \n)
$envVars = @"
DB_USER=grcsmart
DB_PASSWORD=$DbPassword
DB_NAME=grcsmart_db
VITE_API_BASE_URL=$ViteApiBaseUrl
"@

Invoke-Dokploy -Endpoint "compose.update" -Body @{
    composeId    = $composeId
    sourceType   = "git"
    customGitUrl = $GitRepoUrl
    branch       = $GitBranch
    composePath  = $ComposeFile
    env          = $envVars
} | Out-Null

Write-Host "  Repositorio configurado: $GitRepoUrl ($GitBranch)" -ForegroundColor Green
Write-Host "  Compose file: $ComposeFile" -ForegroundColor Green

# ─── PASO 6: Deploy (opcional) ────────────────────────────
if ($Deploy) {
    Step "Disparando primer deploy..."
    Invoke-Dokploy -Endpoint "compose.deploy" -Body @{
        composeId = $composeId
    } | Out-Null
    Write-Host "  Deploy encolado. Revisa el estado en Dokploy UI." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Setup completado. Para disparar el deploy ejecuta:" -ForegroundColor Yellow
    Write-Host "  .\scripts\dokploy-setup.ps1 -ApiKey `$env:DOKPLOY_API_KEY -Deploy" -ForegroundColor White
    Write-Host "  O haz click en 'Deploy' desde la UI de Dokploy." -ForegroundColor White
}

# ─── Resumen ──────────────────────────────────────────────
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " grcSmart configurado en Dokploy" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Proyecto ID   : $projectId"
Write-Host "  Environment ID: $environmentId"
Write-Host "  Compose ID    : $composeId"
Write-Host "  Servidor ID   : $serverId"
Write-Host ""
Write-Host "  UI Dokploy: $DokployUrl"
Write-Host ""
Write-Host "RECORDATORIO: Cambia DB_PASSWORD antes de" -ForegroundColor Yellow
Write-Host "ejecutar en produccion." -ForegroundColor Yellow
