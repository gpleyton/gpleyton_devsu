# Infraestructura como Código (Terraform · GCP)

Módulo de Terraform que aprovisiona la infraestructura necesaria para ejecutar
la aplicación en **Google Cloud Platform**:

- **APIs habilitadas:** Kubernetes Engine, Artifact Registry, Compute Engine.
- **Artifact Registry:** repositorio Docker para las imágenes de la app.
- **GKE:** cluster zonal + node pool gestionado (2 nodos `e2-small` por defecto).

> ⚠️ **IMPORTANTE — Costos.** Este código está **escrito pero NO aplicado**.
> Crear un cluster de GKE y nodos genera **costos reales** en tu cuenta de GCP.
> Aplícalo solo cuando lo necesites y ejecuta `terraform destroy` al terminar.

## Requisitos previos

1. [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
2. [gcloud CLI](https://cloud.google.com/sdk/docs/install) autenticado:
   ```bash
   gcloud auth application-default login
   ```
3. Un proyecto de GCP con facturación habilitada.

## Uso

```bash
cd terraform

# 1. Configurar variables
cp terraform.tfvars.example terraform.tfvars
#   editar terraform.tfvars y poner tu project_id

# 2. Inicializar
terraform init

# 3. Revisar el plan
terraform plan

# 4. Aplicar (CREA RECURSOS QUE CUESTAN DINERO)
terraform apply

# 5. Conectar kubectl al cluster (usa el output)
$(terraform output -raw kubectl_connect_command)

# 6. Destruir todo al terminar
terraform destroy
```

## Despliegue de la app tras crear el cluster

Una vez conectado `kubectl` al cluster de GKE:

```bash
# Etiquetar y subir la imagen al Artifact Registry creado
REPO=$(terraform output -raw artifact_registry_repository)
docker tag ghcr.io/gpleyton/gpleyton_devsu:latest $REPO/demo-devops-nodejs:latest
gcloud auth configure-docker us-central1-docker.pkg.dev
docker push $REPO/demo-devops-nodejs:latest

# Desplegar con Helm apuntando a esa imagen
helm upgrade --install demo ../helm/demo-devops-nodejs -n devsu --create-namespace \
  --set image.repository=$REPO/demo-devops-nodejs \
  --set image.tag=latest
```

## Variables principales

| Variable | Descripción | Default |
|---|---|---|
| `project_id` | ID del proyecto de GCP (obligatorio) | — |
| `region` | Región de GCP | `us-central1` |
| `zone` | Zona del cluster (zonal = más barato) | `us-central1-a` |
| `cluster_name` | Nombre del cluster GKE | `demo-devops-cluster` |
| `node_count` | Nodos del pool | `2` |
| `machine_type` | Tipo de máquina | `e2-small` |
| `artifact_repo_id` | ID del repo Docker | `demo-devops-nodejs` |

## Outputs

| Output | Descripción |
|---|---|
| `cluster_name` | Nombre del cluster |
| `cluster_endpoint` | Endpoint del API server (sensible) |
| `artifact_registry_repository` | Ruta del repo Docker |
| `kubectl_connect_command` | Comando para conectar kubectl |
