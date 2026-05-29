# Demo DevOps NodeJS — Prueba Técnica DevOps (Devsu)

API REST de usuarios (Node.js + Express) **dockerizada**, con **pipeline CI/CD**, desplegada en **Kubernetes** (local con minikube y en la nube con **GKE**), infraestructura como código con **Terraform** y **HTTPS** con certificado válido de Let's Encrypt.

| | |
|---|---|
| 🌐 **Endpoint público (HTTPS)** | `https://<IP-ESTÁTICA>.sslip.io/api/users` (ver nota) |
| 📦 **Repositorio** | https://github.com/gpleyton/gpleyton_devsu |
| ⚙️ **Pipeline (GitHub Actions)** | https://github.com/gpleyton/gpleyton_devsu/actions |
| 🐳 **Imagen (GHCR)** | https://github.com/gpleyton/gpleyton_devsu/pkgs/container/gpleyton_devsu |
| 🔍 **Análisis (SonarCloud)** | https://sonarcloud.io/project/overview?id=gpleyton_devsu |

> ⚠️ El endpoint público corre en GKE y puede estar destruido para evitar costos. Se recrea con un solo comando (`./scripts/deploy-gke.sh`) y, gracias a la **IP estática** reservada por Terraform, la URL es estable entre destrucciones/recreaciones. Tras el despliegue, la URL exacta se muestra en consola. Evidencias en [`docs/evidencias/`](docs/evidencias/).

---

## Tabla de contenido
- [La aplicación](#la-aplicación)
- [Arquitectura](#arquitectura)
- [Flujo CI/CD](#flujo-cicd)
- [Cómo ejecutar](#cómo-ejecutar)
  - [Local](#1-local-nodejs)
  - [Docker](#2-docker)
  - [Kubernetes (minikube)](#3-kubernetes-minikube)
  - [Despliegue en GKE](#despliegue-en-gke-google-cloud)
  - [Terraform (IaC)](#infraestructura-como-código-terraform)
- [Pipeline CI/CD](#pipeline-cicd-detalle)
- [Probar la API](#probar-la-api)
- [Decisiones técnicas](#decisiones-técnicas)
- [Requisitos del ejercicio](#requisitos-del-ejercicio)
- [Estructura del repositorio](#estructura-del-repositorio)

---

## La aplicación

API REST sencilla de gestión de usuarios. Un usuario tiene `id` (autogenerado), `dni` (único) y `name`.

| Método | Ruta | Descripción | Respuestas |
|---|---|---|---|
| `GET` | `/api/users` | Lista todos los usuarios | `200` |
| `GET` | `/api/users/:id` | Obtiene un usuario | `200` / `404` si no existe |
| `POST` | `/api/users` | Crea un usuario (`dni`, `name`) | `201` / `400` si dni duplicado o datos inválidos |
| `GET` | `/api/health` | Liveness probe (proceso vivo) | `200` `{"status":"UP"}` |
| `GET` | `/api/health/ready` | Readiness probe (BD disponible) | `200` / `503` |

**Stack:** Node.js 18 · Express · Sequelize · SQLite · Yup (validación) · Jest (tests).

---

## Arquitectura

Arquitectura del despliegue en Kubernetes (aplica a minikube y a GKE):

```mermaid
flowchart TD
    user([Cliente / Internet])

    subgraph cluster["Cluster Kubernetes (namespace devsu)"]
        ing["Ingress (nginx)<br/>TLS / HTTPS"]
        svc["Service ClusterIP<br/>puerto 80"]
        subgraph dep["Deployment (2 réplicas)"]
            p1["Pod app<br/>non-root - :8000<br/>SQLite propio"]
            p2["Pod app<br/>non-root - :8000<br/>SQLite propio"]
        end
        hpa["HorizontalPodAutoscaler<br/>min 2 / máx 5 - CPU 70%"]
        cm["ConfigMap<br/>PORT, DATABASE_NAME"]
        sec["Secret<br/>credenciales BD"]
        cert["cert-manager<br/>(Let's Encrypt)"]
    end

    user -->|HTTPS 443| ing
    ing --> svc
    svc --> p1
    svc --> p2
    hpa -. escala .-> dep
    cm -. env .-> dep
    sec -. env .-> dep
    cert -. emite cert TLS .-> ing
```

**Probes:** liveness → `/api/health`, readiness → `/api/health/ready`.
**Seguridad del pod:** usuario non-root, `readOnlyRootFilesystem`, capabilities `drop: ALL`, volumen efímero para la BD.

---

## Flujo CI/CD

```mermaid
flowchart LR
    dev["git push / PR a main"] --> bt

    subgraph gha["GitHub Actions"]
        bt["Build + Lint<br/>+ Tests + Coverage"]
        sonar["SonarCloud<br/>análisis estático"]
        docker["Docker build<br/>+ Trivy scan<br/>+ Push a GHCR"]
        deploy["Deploy a Kubernetes<br/>(cluster kind efímero)<br/>+ smoke test"]
    end

    bt --> sonar
    bt --> docker
    docker --> deploy

    docker -->|imagen| ghcr[("GHCR")]
    sonar -->|métricas| sc[("SonarCloud")]
```

---

## Cómo ejecutar

### 1. Local (Node.js)
Requiere Node.js 18.

```bash
cp .env.example .env
npm install
npm test           # tests unitarios
npm run test:coverage
npm start          # http://localhost:8000/api/users
```

### 2. Docker
```bash
docker compose up --build
# o manualmente:
docker build -t demo-devops-nodejs:local .
docker run -p 8000:8000 demo-devops-nodejs:local
```
Imagen **multi-stage** sobre `node:18-alpine`, usuario **non-root** y `HEALTHCHECK` a `/api/health`.

### 3. Kubernetes (minikube)
```bash
minikube start
minikube addons enable ingress
minikube addons enable metrics-server
minikube image load demo-devops-nodejs:local

# Opción A: manifiestos planos
kubectl apply -f k8s/

# Opción B: Helm (recomendado)
helm upgrade --install demo helm/demo-devops-nodejs -n devsu --create-namespace \
  --set image.repository=demo-devops-nodejs --set image.tag=local --set image.pullPolicy=Never
```

### Despliegue en GKE (Google Cloud)
1. Crear la infraestructura con [Terraform](#infraestructura-como-código-terraform) (crea el cluster, el Artifact Registry y una **IP estática** para el endpoint).
2. Desplegar la aplicación con el script incluido:
   ```bash
   ./scripts/deploy-gke.sh
   ```
   El script: conecta `kubectl`, construye y publica la imagen, instala **ingress-nginx** (con la IP estática), **cert-manager**, aplica el `ClusterIssuer` de Let's Encrypt y despliega la app con Helm. El host del Ingress usa `sslip.io` sobre la IP estática, así que la **URL es estable** entre recreaciones. Al terminar, imprime la URL pública (`https://<IP>.sslip.io/api/users`). Evidencias en [`docs/evidencias/gke.md`](docs/evidencias/gke.md).

### Infraestructura como Código (Terraform)
Aprovisiona en GCP: APIs, **Artifact Registry** y un cluster **GKE**. Detalle en [`terraform/README.md`](terraform/README.md).

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # poner tu project_id
terraform init
terraform apply      # ⚠️ crea recursos que cuestan dinero
terraform destroy    # al terminar, para dejar de pagar
```

---

## Pipeline CI/CD (detalle)

Definido como código en [`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml). Se ejecuta en cada push/PR a `main`:

| Job | Pasos |
|---|---|
| **build-test** | `npm ci` → ESLint → tests unitarios → **code coverage** (lcov) |
| **sonarcloud** | Análisis estático de código (SonarCloud) usando el reporte de cobertura |
| **docker** | Build de imagen → **escaneo de vulnerabilidades (Trivy)** → push a **GHCR** (`sha` + `latest`) |
| **deploy** | Crea un cluster **kind** efímero → despliega con Helm (2 réplicas) → **smoke test** de los endpoints |

El despliegue a Kubernetes se valida en un cluster `kind` dentro del runner (100% reproducible en la nube, sin infraestructura propia).

---

## Probar la API

Reemplaza `HOST` por la URL que imprime el script de despliegue (`https://<IP>.sslip.io`) o por `http://localhost:8000` en local.

```bash
# Salud
curl $HOST/api/health

# Crear usuario
curl -X POST $HOST/api/users \
  -H 'Content-Type: application/json' \
  -d '{"dni":"1234567890","name":"Juan Perez"}'

# Listar
curl $HOST/api/users
```

También puedes importar la colección de **Postman** en [`docs/api/`](docs/api/) o usar el archivo `requests.http` con la extensión REST Client de VS Code.

---

## Decisiones técnicas

- **Imagen Docker multi-stage + non-root + healthcheck:** imagen liviana (`node:18-alpine`), build reproducible con lockfile, ejecución como usuario `node`, `readOnlyRootFilesystem` y `HEALTHCHECK` — buenas prácticas de seguridad y producción.
- **Helm chart además de manifiestos planos:** los manifiestos en `k8s/` son fáciles de revisar; el chart en `helm/` parametriza el despliegue (imagen, recursos, TLS, HPA) y se reutiliza en CI, minikube y GKE.
- **HTTPS con ingress-nginx + cert-manager + Let's Encrypt + sslip.io:** certificado válido y gratuito sin necesidad de comprar dominio. `sslip.io` resuelve la IP a un hostname (las CA no emiten certificados para IPs).
- **GHCR como registry:** integrado al repositorio público, sin cuentas externas (usa el `GITHUB_TOKEN`).
- **Validación del deploy con kind en CI:** demuestra el despliegue a Kubernetes de forma reproducible sin depender de un cluster propio.
- **Base de datos SQLite por réplica (limitación consciente):** la app base usa SQLite en fichero local y recrea el esquema al iniciar (`sync force`). Con 2 réplicas, **cada pod tiene su propia BD**, por lo que un `POST` y un `GET` pueden caer en réplicas distintas y devolver datos distintos. Es **aceptable para esta prueba** (no se pide BD persistente/compartida). **En producción** se usaría una base de datos externa gestionada (Cloud SQL / PostgreSQL) compartida entre réplicas, y se quitaría el `sync force`.
- **Mono-repo:** el enunciado pide un único repositorio; se mantiene la infraestructura (k8s, helm, terraform) en carpetas separadas y limpias, de modo que migrar a repos separados (app vs infra) sería trivial en un escenario real.

---

## Requisitos del ejercicio

| Requerimiento | Estado | Dónde |
|---|---|---|
| Dockerizar (env vars, run user, port, healthcheck) | ✅ | `Dockerfile`, `docker-compose.yml` |
| Pipeline: Code Build | ✅ | job `build-test` |
| Pipeline: Unit Tests | ✅ | job `build-test` |
| Pipeline: Static Code Analysis | ✅ | job `sonarcloud` |
| Pipeline: Code Coverage | ✅ | job `build-test` (lcov) |
| Pipeline: Build & Push imagen | ✅ | job `docker` → GHCR |
| Pipeline: Vulnerability scan (opcional) | ✅ | Trivy en job `docker` |
| Desplegar en Kubernetes | ✅ | minikube + GKE |
| ≥ 2 réplicas + escalamiento horizontal (HPA) | ✅ | `k8s/deployment.yaml`, `k8s/hpa.yaml` |
| ConfigMap, Secret, Ingress | ✅ | `k8s/` |
| Deploy de K8s en el pipeline | ✅ | job `deploy` (kind) |
| Documentación + diagramas | ✅ | este README |
| **Extra:** IaC en proveedor público | ✅ | `terraform/` (GCP) |
| **Extra:** entorno público accesible | ✅ | GKE + HTTPS |
| **Extra:** DNS / certificado TLS | ✅ | sslip.io + Let's Encrypt |

> **Requisitos no cumplidos:** ninguno de los obligatorios. Única limitación conocida (documentada arriba): la BD SQLite no es compartida entre réplicas, por diseño de la app base.

---

## Estructura del repositorio

```
.
├── index.js, users/, shared/      # Aplicación Node.js (Express)
├── Dockerfile, docker-compose.yml # Contenedor
├── .github/workflows/ci-cd.yml    # Pipeline CI/CD
├── sonar-project.properties       # Config SonarCloud
├── k8s/                           # Manifiestos Kubernetes
│   ├── namespace, configmap, secret, deployment, service, ingress, hpa
│   └── tls/clusterissuer.yaml     # Let's Encrypt (cert-manager)
├── helm/demo-devops-nodejs/       # Helm chart (incl. values-gke.yaml)
├── terraform/                     # IaC para GCP (GKE + Artifact Registry)
└── docs/
    ├── api/                       # Colección Postman + requests.http
    └── evidencias/                # Evidencias de despliegue (minikube, GKE)
```

---

## Licencia
Aplicación base: Copyright © 2023 Devsu. Trabajo de DevOps para prueba técnica.
