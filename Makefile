CHART_DIR := .
RELEASE := demo

.PHONY: lint render-dev render-stage render-prod render-all count-lines

lint:
	helm lint $(CHART_DIR)

render-dev:
	helm template $(RELEASE) $(CHART_DIR) -f values-dev.yaml > examples/rendered-dev.yaml

render-stage:
	helm template $(RELEASE) $(CHART_DIR) -f values-stage.yaml > examples/rendered-stage.yaml

render-prod:
	helm template $(RELEASE) $(CHART_DIR) -f values-prod.yaml > examples/rendered-prod.yaml

render-all: render-dev render-stage render-prod

count-lines:
	python scripts/count_yaml_lines.py baseline/manual-k8s values.yaml values-dev.yaml values-stage.yaml values-prod.yaml templates
