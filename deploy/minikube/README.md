# minikube deployment

```bash
minikube start
kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f -
./scripts/build-local.sh
helm upgrade --install demo ./chart -n demo-app -f ./chart/values-dev.yaml
kubectl get all -n demo-app
```

For local images with minikube, either build inside minikube docker environment or use a registry.
