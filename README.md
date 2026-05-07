# vkr-metachart

`vkr-metachart` — учебный Helm-метачарт для ВКР на тему «Разработка структуры управления конфигурацией многосервисных приложений на основе шаблонов».

Цель проекта — показать, как несколько сервисов можно описывать через единую структуру `values.yaml`, а типовые Kubernetes-ресурсы генерировать шаблонами Helm. Это снижает дублирование YAML-конфигураций и упрощает сопровождение инфраструктурного кода.

## Что генерирует метачарт

Для каждого включённого сервиса метачарт может сформировать:

- `Deployment`;
- `Service`;
- `Ingress`;
- `ConfigMap`;
- `Secret`;
- `HorizontalPodAutoscaler`.

Поддерживаются параметры:

- имя и тег Docker-образа;
- количество реплик;
- порт контейнера;
- переменные среды выполнения;
- конфигурационные параметры через `ConfigMap`;
- чувствительные параметры через `Secret`;
- resource requests и limits;
- readiness/liveness probes;
- ingress host, path и annotations;
- разные values-файлы для окружений `dev`, `stage`, `prod`.

## Структура проекта

```text
vkr-metachart/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-stage.yaml
├── values-prod.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── hpa.yaml
│   └── NOTES.txt
├── baseline/
│   └── manual-k8s/
├── docs/
│   ├── configuration.md
│   └── comparison.md
└── scripts/
    └── count_yaml_lines.py
```

## Проверка шаблонов

```bash
helm lint ./vkr-metachart
```

## Рендеринг окружений

```bash
helm template demo ./vkr-metachart -f ./vkr-metachart/values-dev.yaml > rendered-dev.yaml
helm template demo ./vkr-metachart -f ./vkr-metachart/values-stage.yaml > rendered-stage.yaml
helm template demo ./vkr-metachart -f ./vkr-metachart/values-prod.yaml > rendered-prod.yaml
```

## Установка в Kubernetes

```bash
helm upgrade --install demo ./vkr-metachart \
  -f ./vkr-metachart/values-dev.yaml \
  --namespace demo-dev \
  --create-namespace
```

## Добавление нового сервиса

Новый сервис добавляется в секцию `services` файла `values.yaml` или одного из окружений:

```yaml
services:
  paymentService:
    enabled: true
    replicaCount: 1
    image:
      repository: hashicorp/http-echo
      tag: "1.0"
    containerPort: 5678
    args:
      - "-text=payment-service"
    service:
      enabled: true
      type: ClusterIP
      port: 8080
    ingress:
      enabled: false
    configMap:
      enabled: true
      data:
        PAYMENT_PROVIDER: test
    secret:
      enabled: false
      stringData: {}
```

После добавления сервиса не требуется создавать отдельные шаблоны `Deployment`, `Service` или `Ingress`: они будут сформированы метачартом автоматически.

## Подготовка данных для экспериментальной части ВКР

Для сравнения можно использовать каталог `baseline/manual-k8s`, где приведены примерные ручные Kubernetes-манифесты для тех же сервисов. Скрипт ниже считает количество значимых строк YAML:

```bash
python scripts/count_yaml_lines.py baseline/manual-k8s values.yaml values-dev.yaml values-stage.yaml values-prod.yaml templates
```
