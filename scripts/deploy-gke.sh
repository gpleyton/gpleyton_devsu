#!/usr/bin/env bash
# Deploy the application to GKE with a stable public HTTPS endpoint.
#
# Prereqs: gcloud (authenticated), kubectl, helm, docker. The Terraform stack
# (cluster + static IP + Artifact Registry) must already be applied:
#   cd terraform && terraform apply
#
# Usage (from the repo root):
#   ./scripts/deploy-gke.sh
#
# The public endpoint will be https://<static-ip-with-dashes>.sslip.io/api/users
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Reading Terraform outputs"
pushd terraform >/dev/null
STATIC_IP="$(terraform output -raw ingress_static_ip)"
CLUSTER="$(terraform output -raw cluster_name)"
ZONE="$(terraform output -raw cluster_location)"
AR_REPO="$(terraform output -raw artifact_registry_repository)"
PROJECT="$(gcloud config get-value project 2>/dev/null)"
popd >/dev/null

HOST="${STATIC_IP//./-}.sslip.io"
IMAGE="${AR_REPO}/demo-devops-nodejs"

echo "    Static IP : ${STATIC_IP}"
echo "    Host      : ${HOST}"
echo "    Image     : ${IMAGE}"

echo "==> Connecting kubectl to the cluster"
gcloud container clusters get-credentials "${CLUSTER}" --zone "${ZONE}" --project "${PROJECT}"

echo "==> Building and pushing the image (linux/amd64)"
gcloud auth configure-docker "$(echo "${AR_REPO}" | cut -d/ -f1)" --quiet
docker buildx build --platform linux/amd64 -t "${IMAGE}:latest" --push .

echo "==> Installing ingress-nginx (with the static IP)"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.loadBalancerIP="${STATIC_IP}" \
  --set controller.admissionWebhooks.enabled=false \
  --wait --timeout 300s

echo "==> Installing cert-manager"
helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set crds.enabled=true \
  --wait --timeout 300s

echo "==> Applying the Let's Encrypt ClusterIssuer"
kubectl apply -f k8s/tls/clusterissuer.yaml

echo "==> Deploying the application with Helm"
helm upgrade --install demo helm/demo-devops-nodejs \
  -n devsu --create-namespace \
  -f helm/demo-devops-nodejs/values-gke.yaml \
  --set image.repository="${IMAGE}" \
  --set ingress.host="${HOST}" \
  --wait --timeout 240s

echo
echo "==> Done. Public endpoint:"
echo "    https://${HOST}/api/users"
