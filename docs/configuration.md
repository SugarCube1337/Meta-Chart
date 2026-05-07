# Описание конфигурационной модели

Метачарт использует единую модель данных, расположенную в секции `services`. Каждый сервис описывается однотипным набором параметров. Это позволяет избежать копирования однотипных Kubernetes-манифестов и сосредоточить различия между сервисами в values-файлах.

## Глобальные параметры

```yaml
global:
  applicationName: demo-multiservice-app
  namespace: demo-app
  environment: dev
  imagePullPolicy: IfNotPresent
```

Параметры секции `global` применяются ко всему приложению: задают имя приложения, окружение, namespace и общую политику загрузки образов.

## Описание сервиса

```yaml
services:
  frontend:
    enabled: true
    replicaCount: 1
    image:
      repository: nginx
      tag: "1.25"
    containerPort: 80
```

Ключ сервиса используется для формирования имён Kubernetes-объектов и labels. Например, сервис `apiGateway` будет преобразован в компонент `api-gateway`.

## Сетевые параметры

```yaml
service:
  enabled: true
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  host: api.local
  path: /
```

`Service` обеспечивает внутреннее взаимодействие компонентов в Kubernetes. `Ingress` включается только для сервисов, которым нужен внешний HTTP-доступ.

## Конфигурация и секреты

```yaml
configMap:
  enabled: true
  data:
    ROUTING_MODE: internal

secret:
  enabled: true
  stringData:
    DB_PASSWORD: change-me
```

Открытые параметры передаются через `ConfigMap`, чувствительные — через `Secret`. При включении соответствующих секций контейнер автоматически получает их через `envFrom`.

## Окружения

Базовый файл `values.yaml` задаёт общую структуру. Файлы `values-dev.yaml`, `values-stage.yaml` и `values-prod.yaml` переопределяют параметры окружений: namespace, host-имена, количество реплик, ресурсные ограничения и autoscaling.
