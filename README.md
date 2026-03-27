# grcSmart

Sistema RAG (Retrieval-Augmented Generation) para consulta de políticas y procedimientos corporativos en formato PDF.

## Descripción

grcSmart permite subir documentos PDF, indexarlos automáticamente en una base vectorial y consultarlos mediante lenguaje natural a través de una interfaz tipo chat. Utiliza la API de Gemini para embeddings y generación de respuestas.

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Backend | Go 1.22 + Gin + GORM |
| Frontend | Vue 3 + Quasar Framework v2 + Pinia |
| Base de datos relacional | PostgreSQL 15 |
| Base de datos vectorial | ChromaDB 0.4 |
| LLM / Embeddings | Google Gemini API |
| Infraestructura | Docker Compose + Dokploy |

## Estructura del repositorio

```
grcSmart/
├── backend/                    # API REST en Go
│   ├── cmd/server/main.go
│   ├── internal/
│   │   ├── api/                # Handlers HTTP y router Gin
│   │   ├── config/             # Variables de entorno
│   │   ├── domain/             # Modelos GORM
│   │   ├── infrastructure/     # PostgreSQL, ChromaDB, Gemini, Storage
│   │   └── service/            # Lógica de negocio (RAG, documentos)
│   └── Dockerfile
├── frontend/                   # SPA Vue 3 + Quasar
│   ├── src/
│   │   ├── boot/               # Axios
│   │   ├── layouts/            # MainLayout con sidebar
│   │   ├── pages/              # Chat, Upload, Documents, Settings
│   │   └── stores/             # Pinia (chat, documents, settings)
│   └── Dockerfile
├── scripts/                    # PowerShell
│   ├── start-dev.ps1           # Levanta entorno de desarrollo
│   ├── stop.ps1                # Detiene servicios
│   ├── rebuild-backend.ps1     # Reconstruye solo el backend
│   ├── deploy.ps1              # git push a main
│   ├── dokploy-setup.ps1       # Crea el proyecto en Dokploy via API
│   └── redeploy.ps1            # Dispara redeploy en Dokploy
├── docker-compose.yml          # Producción (Dokploy)
├── docker-compose.dev.yml      # Desarrollo local
└── .env.local                  # Credenciales locales (no commiteado)
```

## Requisitos previos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Go 1.22+](https://go.dev/dl/)
- [Node.js 20+](https://nodejs.org/)
- [Quasar CLI](https://quasar.dev/start/quasar-cli): `npm install -g @quasar/cli`
- API Key de [Google Gemini](https://aistudio.google.com/)

## Configuración inicial

Crear el archivo `.env.local` en la raíz del proyecto (nunca se sube al repositorio):

```env
DOKPLOY_API_KEY=tu_api_key_de_dokploy
DOKPLOY_URL=http://dokploy.edensa.com.ar:3000
DOKPLOY_COMPOSE_ID=        # se completa automáticamente con dokploy-setup.ps1
DOKPLOY_PROJECT_ID=        # se completa automáticamente con dokploy-setup.ps1
DOKPLOY_ENVIRONMENT_ID=    # se completa automáticamente con dokploy-setup.ps1
```

## Desarrollo local

```powershell
# 1. Levantar PostgreSQL + ChromaDB + Backend en Docker
.\scripts\start-dev.ps1

# 2. En otra terminal, levantar el Frontend
cd frontend
quasar dev
```

Servicios disponibles:
- Frontend: http://localhost:9000
- Backend API: http://localhost:8080
- ChromaDB: http://localhost:8001
- PostgreSQL: localhost:5432

```powershell
# Detener todos los servicios
.\scripts\stop.ps1

# Reconstruir solo el backend (sin reiniciar DB ni ChromaDB)
.\scripts\rebuild-backend.ps1
```

## API Endpoints

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/health` | Estado del servidor |
| GET | `/api/settings` | Obtener configuración activa |
| PUT | `/api/settings` | Guardar API Key y modelo |
| GET | `/api/documents` | Listar documentos subidos |
| POST | `/api/documents` | Subir y vectorizar un PDF |
| DELETE | `/api/documents/:id` | Eliminar PDF y sus vectores |
| POST | `/api/chat` | Consulta RAG |

## Primer uso

1. Abrir el frontend en http://localhost:9000
2. Ir a **Configuración** → ingresar la API Key de Gemini → Guardar
3. Ir a **Subir Archivos** → subir uno o más PDFs de políticas
4. Ir a **Chat** → hacer preguntas sobre el contenido

## Despliegue en producción (Dokploy)

### Primera vez

```powershell
# Crea el proyecto en Dokploy y guarda los IDs en .env.local
.\scripts\dokploy-setup.ps1

# Con deploy inmediato
.\scripts\dokploy-setup.ps1 -Deploy
```

### Actualizaciones posteriores

```powershell
# Solo redeploy (el código ya está en main)
.\scripts\redeploy.ps1

# Commit + push + redeploy en un comando
.\scripts\redeploy.ps1 -PushFirst -Message "feat: descripcion del cambio"
```

### Variables de entorno en producción

Editar en `dokploy-setup.ps1` o directamente en la UI de Dokploy:

| Variable | Descripción |
|---|---|
| `DB_USER` | Usuario de PostgreSQL |
| `DB_PASSWORD` | Contraseña de PostgreSQL |
| `DB_NAME` | Nombre de la base de datos |
| `VITE_API_BASE_URL` | URL pública del backend |

## Tests

```bash
cd backend
go test ./... -v
```

Tests unitarios incluidos:
- `config`: carga de variables de entorno
- `storage`: guardar y eliminar archivos
- `service`: chunking de texto y extracción de PDF

## Arquitectura RAG

```
PDF subido
    ↓
Extracción de texto (ledongthuc/pdf)
    ↓
Chunking recursivo (1000 chars, 200 overlap)
    ↓
Embeddings via Gemini (text-embedding-004)
    ↓
Almacenamiento en ChromaDB
    ↓
[Consulta del usuario]
    ↓
Embedding de la pregunta
    ↓
Búsqueda semántica en ChromaDB (top 5)
    ↓
Prompt con contexto → Gemini LLM
    ↓
Respuesta al usuario
```
