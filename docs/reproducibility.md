# Воспроизводимость экспериментальной проверки

## 1. Назначение

Данный документ описывает порядок повторения экспериментальной проверки Helm-метачарта, разработанного для управления конфигурацией многосервисного приложения в Kubernetes.

Эксперимент проверяет:
- корректность Helm-чарта;
- успешность рендеринга Kubernetes-манифестов;
- работу schema validation;
- сокращение объёма входной конфигурации;
- успешность развёртывания демонстрационного приложения в kind-кластере;
- доступность health/readiness/metrics/dependencies endpoint-ов.

## 2. Проверяемый объект

Проверяемым объектом является Helm-метачарт `vkr-metachart-4.0.0`.

В состав проверочного стенда входят 5 демонстрационных сервисов:
- frontend;
- api-gateway;
- user-service;
- order-service;
- notification-worker.

Метачарт генерирует Kubernetes-ресурсы:
- Deployment;
- Service;
- Ingress;
- ConfigMap;
- Secret;
- ServiceAccount;
- NetworkPolicy;
- ServiceMonitor;
- опциональные Istio Gateway, VirtualService и DestinationRule.

## 3. Требуемые инструменты

Для повторения эксперимента необходимы:

| Инструмент | Назначение |
|---|---|
| Docker Desktop | сборка Docker-образов демонстрационных сервисов |
| Helm | lint, template, install/upgrade |
| kubectl | проверка ресурсов в Kubernetes |
| kind | локальный Kubernetes-кластер |
| PowerShell | запуск автоматизированных сценариев |

Перед запуском рекомендуется зафиксировать версии:

```powershell
docker version
helm version
kubectl version --client
kind version