# grcSmart – Infraestructura y DevOps

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Inicializar el monorepo grcSmart con Git, Docker Compose (dev + prod) y scripts PowerShell.

**Architecture:** Monorepo con `/backend` (Go), `/frontend` (Vue 3/Quasar), `/scripts` (PS1). Dev: Postgres + ChromaDB + Backend en Docker, Frontend fuera. Prod: todos los servicios en Docker incluyendo Nginx para el Frontend.

**Tech Stack:** Git, Docker Compose v2, PostgreSQL 15, ChromaDB 0.4.x, Nginx alpine, PowerShell 7.

---

## Estructura de archivos

```
grcSmart/
├── .gitignore
├── docker-compose.yml          # Producción (Dokploy)
├── docker-compose.dev.yml      # Desarrollo local
├── backend/                    # (placeholder vacío – se completa en Plan B)
│   └── .gitkeep
├── frontend/                   # (placeholder vacío – se completa en Plan C)
│   └── .gitkeep
└── scripts/
    ├── start-dev.ps1
    ├── stop.ps1
    ├── rebuild-backend.ps1
    └── deploy.ps1
```

---

## Task 1: Git init + .gitignore + remote

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Inicializar Git**

```bash
cd /c/Users/Gaston/Desktop/eden/grcSmart
git init
git remote add origin https://github.com/JulioGastonPita/grcSmart.git
```

Expected: `Initialized empty Git repository in .../grcSmart/.git/`

- [ ] **Step 2: Crear .gitignore**

Crear el archivo `/c/Users/Gaston/Desktop/eden/grcSmart/.gitignore` con este contenido exacto:

```gitignore
# Environment
.env
.env.local
.env.*.local

# Go
backend/bin/
backend/*.exe
backend/tmp/

# Uploads (archivos físicos de producción/dev)
uploads/
backend/uploads/

# Node / Quasar
frontend/node_modules/
frontend/dist/
frontend/.quasar/

# IDE
.vscode/
.idea/
*.swp

# Docker
*.log

# OS
.DS_Store
Thumbs.db
```

- [ ] **Step 3: Crear directorios base con placeholders**

```bash
mkdir -p backend frontend scripts
touch backend/.gitkeep frontend/.gitkeep
```

- [ ] **Step 4: Commit inicial**

```bash
git add .gitignore backend/.gitkeep frontend/.gitkeep
git commit -m "chore: init monorepo structure"
```

---

## Task 2: docker-compose.dev.yml (Desarrollo local)

**Files:**
- Create: `docker-compose.dev.yml`

Los servicios de desarrollo son: PostgreSQL, ChromaDB y Backend Go.
El Frontend corre fuera de Docker (`npm run dev` / `quasar dev`).

- [ ] **Step 1: Crear docker-compose.dev.yml**

```yaml
version: "3.9"

services:
  postgres:
    image: postgres:15-alpine
    container_name: grcsmart_postgres_dev
    restart: unless-stopped
    environment:
      POSTGRES_USER: grcsmart
      POSTGRES_PASSWORD: grcsmart_pass
      POSTGRES_DB: grcsmart_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U grcsmart -d grcsmart_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  chromadb:
    image: chromadb/chroma:0.4.24
    container_name: grcsmart_chroma_dev
    restart: unless-stopped
    ports:
      - "8001:8000"
    volumes:
      - chroma_dev_data:/chroma/chroma
    environment:
      ALLOW_RESET: "true"
      ANONYMIZED_TELEMETRY: "false"

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: grcsmart_backend_dev
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: grcsmart
      DB_PASSWORD: grcsmart_pass
      DB_NAME: grcsmart_db
      CHROMA_URL: http://chromadb:8000
      UPLOADS_DIR: /uploads
      GIN_MODE: debug
    volumes:
      - uploads_dev_data:/uploads
    depends_on:
      postgres:
        condition: service_healthy
      chromadb:
        condition: service_started

volumes:
  postgres_dev_data:
  chroma_dev_data:
  uploads_dev_data:
```

- [ ] **Step 2: Verificar sintaxis**

```bash
docker compose -f docker-compose.dev.yml config --quiet
```

Expected: Sin output (sin errores de sintaxis).

- [ ] **Step 3: Commit**

```bash
git add docker-compose.dev.yml
git commit -m "chore: add docker-compose.dev.yml for local development"
```

---

## Task 3: docker-compose.yml (Producción Dokploy)

**Files:**
- Create: `docker-compose.yml`

En producción se añade el servicio `frontend` que usa un Dockerfile multi-stage (se crea en Plan C).

- [ ] **Step 1: Crear docker-compose.yml**

```yaml
version: "3.9"

services:
  postgres:
    image: postgres:15-alpine
    container_name: grcsmart_postgres
    restart: always
    environment:
      POSTGRES_USER: ${DB_USER:-grcsmart}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-change_me_in_production}
      POSTGRES_DB: ${DB_NAME:-grcsmart_db}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-grcsmart} -d ${DB_NAME:-grcsmart_db}"]
      interval: 10s
      timeout: 5s
      retries: 5

  chromadb:
    image: chromadb/chroma:0.4.24
    container_name: grcsmart_chroma
    restart: always
    volumes:
      - chroma_data:/chroma/chroma
    environment:
      ANONYMIZED_TELEMETRY: "false"

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: grcsmart_backend
    restart: always
    ports:
      - "8080:8080"
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: ${DB_USER:-grcsmart}
      DB_PASSWORD: ${DB_PASSWORD:-change_me_in_production}
      DB_NAME: ${DB_NAME:-grcsmart_db}
      CHROMA_URL: http://chromadb:8000
      UPLOADS_DIR: /uploads
      GIN_MODE: release
    volumes:
      - uploads_data:/uploads
    depends_on:
      postgres:
        condition: service_healthy
      chromadb:
        condition: service_started

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        VITE_API_BASE_URL: ${VITE_API_BASE_URL:-http://localhost:8080}
    container_name: grcsmart_frontend
    restart: always
    ports:
      - "80:80"
    depends_on:
      - backend

volumes:
  postgres_data:
  chroma_data:
  uploads_data:
```

- [ ] **Step 2: Verificar sintaxis**

```bash
docker compose -f docker-compose.yml config --quiet
```

Expected: Sin output (sin errores de sintaxis).

- [ ] **Step 3: Commit**

```bash
git add docker-compose.yml
git commit -m "chore: add docker-compose.yml for production (Dokploy)"
```

---

## Task 4: Scripts PowerShell

**Files:**
- Create: `scripts/start-dev.ps1`
- Create: `scripts/stop.ps1`
- Create: `scripts/rebuild-backend.ps1`
- Create: `scripts/deploy.ps1`

- [ ] **Step 1: Crear scripts/start-dev.ps1**

```powershell
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
```

- [ ] **Step 2: Crear scripts/stop.ps1**

```powershell
# Detiene todos los servicios (dev o prod)

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
```

- [ ] **Step 3: Crear scripts/rebuild-backend.ps1**

```powershell
# Reconstruye solo el servicio backend sin tocar los demas servicios

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
```

- [ ] **Step 4: Crear scripts/deploy.ps1**

```powershell
# Dispara el despliegue en Dokploy via git push origin main

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
```

- [ ] **Step 5: Commit de los scripts**

```bash
git add scripts/
git commit -m "chore: add PowerShell dev/deploy scripts"
```

---

## Task 5: Push inicial al repositorio remoto

- [ ] **Step 1: Verificar remote**

```bash
git remote -v
```

Expected:
```
origin  https://github.com/JulioGastonPita/grcSmart.git (fetch)
origin  https://github.com/JulioGastonPita/grcSmart.git (push)
```

- [ ] **Step 2: Push a main**

```bash
git push -u origin main
```

Expected: Todos los commits subidos a GitHub. Dokploy detectará el webhook si está configurado.

---

## Verificación final

Tras completar todos los tasks, la estructura debe verse así:

```
grcSmart/
├── .gitignore                  ✓
├── docker-compose.yml          ✓
├── docker-compose.dev.yml      ✓
├── backend/.gitkeep            ✓
├── frontend/.gitkeep           ✓
└── scripts/
    ├── start-dev.ps1           ✓
    ├── stop.ps1                ✓
    ├── rebuild-backend.ps1     ✓
    └── deploy.ps1              ✓
```

**Siguiente paso:** Ejecutar Plan B (`2026-03-26-backend.md`) para construir la API Go.
