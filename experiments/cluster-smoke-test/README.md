# Cluster smoke-test experiment

After deployment into kind/minikube:

```bash
kubectl get pods -n demo-app
kubectl get svc -n demo-app
kubectl get networkpolicy -n demo-app
./scripts/smoke-test.sh
```

Expected result: api-gateway returns `/health` and `/api/status`.
