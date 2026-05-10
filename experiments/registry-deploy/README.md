# Registry deploy experiment

Render chart with GitLab registry image path:

```bash
helm template demo ./chart \
  -f ./chart/values-dev.yaml \
  --set global.imageRegistry="$CI_REGISTRY_IMAGE" \
  --set global.imageTag="$CI_COMMIT_SHORT_SHA"
```

Expected result: all images in Deployment manifests use `$CI_REGISTRY_IMAGE/<service>:$CI_COMMIT_SHORT_SHA`.
