# VKR Meta-chart v3

This project contains a platform-style Helm metachart for multi-service configuration management.

The chart implements:

- hierarchical values model: `global -> defaults -> profiles -> services -> environment overrides`;
- JSON Schema validation through `values.schema.json`;
- Deployment, Service, Ingress, ConfigMap, Secret and HPA generation;
- internal service discovery from declared dependencies;
- NetworkPolicy generation derived from dependencies;
- centralized `podSecurityContext` and `securityContext`;
- Prometheus scrape annotations and optional ServiceMonitor;
- optional Istio Gateway, VirtualService and DestinationRule templates.

## Basic checks

```bash
helm lint chart
helm template demo chart -f chart/values-dev.yaml
helm template demo chart -f chart/values-stage.yaml
helm template demo chart -f chart/values-prod.yaml
```

## Istio rendering

```bash
helm template demo chart -f chart/values-dev.yaml -f chart/values-istio.yaml
```

## Invalid values check

```bash
helm template demo chart -f chart/values-dev.yaml -f experiments/invalid-values/bad-container-port.yaml
```

## Render all examples

```bash
make render-all
```

## Count YAML lines

```bash
make count-lines
```
