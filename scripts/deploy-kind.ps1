param(
  [string]$Namespace = "demo-app"
)
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install demo ./chart -n $Namespace -f ./chart/values-dev.yaml
kubectl get pods,svc,networkpolicy -n $Namespace
