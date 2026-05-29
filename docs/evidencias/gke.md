# Evidencias de despliegue en GKE (Google Cloud)

Proyecto GCP: devsu-demo-devops-gp | Cluster: demo-devops-cluster (us-central1-a)
Imagen: us-central1-docker.pkg.dev/devsu-demo-devops-gp/demo-devops-nodejs/demo-devops-nodejs:latest
URL pública (LoadBalancer): http://34.135.97.73

## Nodos
```
NAME                                                  STATUS   ROLES    AGE     VERSION               INTERNAL-IP   EXTERNAL-IP     OS-IMAGE                             KERNEL-VERSION   CONTAINER-RUNTIME
gke-demo-devops-clus-demo-devops-clus-d64fd575-kl2p   Ready    <none>   5m22s   v1.35.3-gke.1389000   10.128.0.4    34.68.121.191   Container-Optimized OS from Google   6.12.68+         containerd://2.1.5
```

## Recursos en namespace devsu
```
NAME                                           READY   STATUS    RESTARTS   AGE
pod/demo-demo-devops-nodejs-5c95bdf557-8zkvd   1/1     Running   0          2m32s
pod/demo-demo-devops-nodejs-5c95bdf557-kgs76   1/1     Running   0          2m48s

NAME                              TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)        AGE
service/demo-demo-devops-nodejs   LoadBalancer   34.118.225.251   34.135.97.73   80:32324/TCP   2m49s

NAME                                                          REFERENCE                            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/demo-demo-devops-nodejs   Deployment/demo-demo-devops-nodejs   cpu: 1%/70%   2         5         2          2m49s

NAME                                       DATA   AGE
configmap/demo-demo-devops-nodejs-config   2      2m49s
configmap/kube-root-ca.crt                 1      2m55s

NAME                                    TYPE                 DATA   AGE
secret/demo-demo-devops-nodejs-secret   Opaque               2      2m50s
secret/sh.helm.release.v1.demo.v1       helm.sh/release.v1   1      2m50s
```

## Prueba de la API pública
```
GET  /api/health     -> {"status":"UP"}
GET  /api/users      -> (balancea entre 2 réplicas con BD SQLite propia)
POST /api/users      -> 201 con el usuario creado
```

## Actualización: HTTPS con Ingress nginx + cert-manager + Let's Encrypt

URL pública HTTPS: https://34-41-108-49.sslip.io/api/users
Certificado: Let's Encrypt (válido), hostname vía sslip.io, redirección HTTP->HTTPS (308).

```
NAME                                                CLASS   HOSTS                   ADDRESS        PORTS     AGE
ingress.networking.k8s.io/demo-demo-devops-nodejs   nginx   34-41-108-49.sslip.io   34.41.108.49   80, 443   2m53s

NAME                                          READY   SECRET            AGE
certificate.cert-manager.io/demo-devops-tls   True    demo-devops-tls   2m52s

issuer: issuer=C=US, O=Let's Encrypt, CN=YR2
```
