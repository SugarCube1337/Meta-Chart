param(
  [string]$Tag = "dev-local"
)
$services = @("frontend", "api-gateway", "user-service", "order-service", "notification-worker")
foreach ($svc in $services) {
  docker build -t "$svc`:$Tag" "services/$svc"
}
