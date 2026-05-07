# Rendered examples

Этот каталог предназначен для результатов команды `helm template`.

Пример формирования файлов:

```bash
helm template demo .. -f ../values-dev.yaml > rendered-dev.yaml
helm template demo .. -f ../values-stage.yaml > rendered-stage.yaml
helm template demo .. -f ../values-prod.yaml > rendered-prod.yaml
```
