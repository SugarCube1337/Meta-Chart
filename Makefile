CHART_DIR := chart
RELEASE := demo

.PHONY: lint template-dev template-stage template-prod template-istio render-all count-lines

lint:
	helm lint $(CHART_DIR)

template-dev:
	helm template $(RELEASE) $(CHART_DIR) -f $(CHART_DIR)/values-dev.yaml

template-stage:
	helm template $(RELEASE) $(CHART_DIR) -f $(CHART_DIR)/values-stage.yaml

template-prod:
	helm template $(RELEASE) $(CHART_DIR) -f $(CHART_DIR)/values-prod.yaml

template-istio:
	helm template $(RELEASE) $(CHART_DIR) -f $(CHART_DIR)/values-dev.yaml -f $(CHART_DIR)/values-istio.yaml

render-all:
	mkdir -p examples
	helm template $(RELEASE) $(CHART_DIR) -f $(CHART_DIR)/values-dev.yaml > examples/rendered-dev.yaml
	helm template $(RELEASE) $(CHART_DIR) -f $(CHART_DIR)/values-stage.yaml > examples/rendered-stage.yaml
	helm template $(RELEASE) $(CHART_DIR) -f $(CHART_DIR)/values-prod.yaml > examples/rendered-prod.yaml
	helm template $(RELEASE) $(CHART_DIR) -f $(CHART_DIR)/values-dev.yaml -f $(CHART_DIR)/values-istio.yaml > examples/rendered-istio.yaml

count-lines:
	python scripts/count_yaml_lines.py $(CHART_DIR)/values.yaml $(CHART_DIR)/values-dev.yaml $(CHART_DIR)/values-stage.yaml $(CHART_DIR)/values-prod.yaml
	python scripts/count_yaml_lines.py $(CHART_DIR)/templates
