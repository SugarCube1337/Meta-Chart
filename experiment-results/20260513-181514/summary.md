# Measurement results

Run date: 2026-05-13 18:15:43

## Input configuration line count

| Metric | Value |
|---|---:|
| values.yaml | 263 |
| values-dev.yaml | 20 |
| values-stage.yaml | 19 |
| values-prod.yaml | 33 |
| values-istio.yaml | 28 |
| All values files without billingService | 363 |
| billing-service-values.yaml | 13 |
| All values files with billingService | 376 |
| Manual billingService baseline | 142 |
| rendered-dev.yaml | 845 |
| rendered-dev-with-billing.yaml | 1002 |

## Derived metrics

| Metric | Value |
|---|---:|
| Manual baseline for 4 services, 1 environment | 389 |
| Manual baseline for 5 services, 1 environment | 531 |
| Manual baseline for 5 services, 3 environments | 1593 |
| Metachart values files with billingService | 376 |
| Reduction for 5 services and 3 environments | 76.4 % |
| Reduction when adding billingService | 90.8 % |
| Manual billingService is larger than values-based approach | 10.9 x |
| Rendered manifest delta after billingService | 157 lines |
| Generated Kubernetes manifest lines per one billingService input line | 12.1 |
| Average helm template dev time | 0.108 sec |

## Output files

- command-results.csv
- line-count.csv
- helm-template-time.csv
- smoke-tests.csv
- schema-validation.csv
- docker-image-sizes.csv
- rendered/
- logs/
- smoke/
