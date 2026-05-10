param(
  [string]$Tag = "dev-local",
  [string]$Cluster = "vkr-demo"
)
$services = @("frontend", "api-gateway", "user-service", "order-service", "notification-worker")
foreach ($svc in $services) {
  kind load docker-image "$svc`:$Tag" --name $Cluster
}
