lint:
	helm lint .

render-dev:
	helm template demo . -f values-dev.yaml

render-stage:
	helm template demo . -f values-stage.yaml

render-prod:
	helm template demo . -f values-prod.yaml

render-all:
	helm template demo . -f values-dev.yaml > examples/rendered-dev.yaml
	helm template demo . -f values-stage.yaml > examples/rendered-stage.yaml
	helm template demo . -f values-prod.yaml > examples/rendered-prod.yaml

count-lines:
	python scripts/count_yaml_lines.py baseline/manual-k8s
	python scripts/count_yaml_lines.py values.yaml values-dev.yaml values-stage.yaml values-prod.yaml
	python scripts/count_yaml_lines.py templates
