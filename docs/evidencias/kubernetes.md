# Evidencias de despliegue en Kubernetes (minikube)

Generado durante la validación local. Clúster: minikube (driver docker).

## kubectl get all -n devsu
```
NAME                                           READY   STATUS    RESTARTS   AGE
pod/demo-demo-devops-nodejs-7db5fd75f4-4zcqt   1/1     Running   0          5m19s
pod/demo-demo-devops-nodejs-7db5fd75f4-9qggw   1/1     Running   0          5m3s

NAME                              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/demo-demo-devops-nodejs   ClusterIP   10.103.133.85   <none>        80/TCP    5m19s

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/demo-demo-devops-nodejs   2/2     2            2           5m19s

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/demo-demo-devops-nodejs-7db5fd75f4   2         2         2       5m19s

NAME                                                          REFERENCE                            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/demo-demo-devops-nodejs   Deployment/demo-demo-devops-nodejs   cpu: 2%/70%   2         5         2          5m19s
```

## Recursos de configuración e ingress
```
NAME                                       DATA   AGE
configmap/demo-demo-devops-nodejs-config   2      5m19s
configmap/kube-root-ca.crt                 1      5m19s

NAME                                    TYPE                 DATA   AGE
secret/demo-demo-devops-nodejs-secret   Opaque               2      5m19s
secret/sh.helm.release.v1.demo.v1       helm.sh/release.v1   1      5m19s

NAME                                                CLASS   HOSTS               ADDRESS        PORTS   AGE
ingress.networking.k8s.io/demo-demo-devops-nodejs   nginx   demo-devops.local   192.168.49.2   80      5m18s

NAME                                                          REFERENCE                            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/demo-demo-devops-nodejs   Deployment/demo-demo-devops-nodejs   cpu: 2%/70%   2         5         2          5m19s
```

## Detalle del HPA (escalamiento horizontal)
```
Name:                                                  demo-demo-devops-nodejs
Namespace:                                             devsu
Labels:                                                app.kubernetes.io/instance=demo
                                                       app.kubernetes.io/managed-by=Helm
                                                       app.kubernetes.io/name=demo-devops-nodejs
                                                       helm.sh/chart=demo-devops-nodejs-0.1.0
Annotations:                                           meta.helm.sh/release-name: demo
                                                       meta.helm.sh/release-namespace: devsu
CreationTimestamp:                                     Fri, 29 May 2026 11:42:00 -0400
Reference:                                             Deployment/demo-demo-devops-nodejs
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  2% (1m) / 70%
Min replicas:                                          2
Max replicas:                                          5
Behavior:
  Scale Up:
    Stabilization Window: 0 seconds
    Select Policy: Max
    Policies:
      - Type: Pods     Value: 4    Period: 15 seconds
      - Type: Percent  Value: 100  Period: 15 seconds
  Scale Down:
    Stabilization Window: 120 seconds
    Select Policy: Max
    Policies:
```

## Verificación non-root y healthcheck del pod
```
Pod: demo-demo-devops-nodejs-7db5fd75f4-4zcqt
runAsUser: 1000
readOnlyRootFilesystem: true
```
