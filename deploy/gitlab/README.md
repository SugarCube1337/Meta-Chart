# GitLab CI/CD and Container Registry

The repository includes `.gitlab-ci.yml` with stages:

1. `validate` — Helm lint and schema validation scenarios.
2. `build` — Docker build for five demo services.
3. `push` — Push service images to GitLab Container Registry.
4. `render` — Render manifests with registry image path and commit tag.
5. `deploy` — Manual Helm deploy step, intended for a configured Kubernetes runner.

Recommended Helm override in CI:

```bash
helm upgrade --install demo ./chart \
  -f ./chart/values-dev.yaml \
  --set global.imageRegistry="$CI_REGISTRY_IMAGE" \
  --set global.imageTag="$CI_COMMIT_SHORT_SHA"
```
