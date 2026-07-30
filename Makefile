.PHONY: lint render render-all render-istio build-local load-kind deploy-kind smoke-test

lint:
	helm lint ./chart

render:
	helm template demo ./chart -f ./chart/values-dev.yaml

render-all:
	helm template demo .\chart -f .\chart\values-dev.yaml
	helm template demo .\chart -f .\chart\values-stage.yaml
	helm template demo .\chart -f .\chart\values-prod.yaml

render-istio:
	helm template demo ./chart -f ./chart/values-dev.yaml -f ./chart/values-istio.yaml

build-local:
	./scripts/build-local.sh

load-kind:
	./scripts/load-kind.sh

deploy-kind:
	./scripts/deploy-kind.sh

smoke-test:
	./scripts/smoke-test.sh
