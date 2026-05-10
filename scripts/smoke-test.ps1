param(
  [string]$Namespace = "demo-app",
  [string]$Service = "demo-api-gateway",
  [int]$LocalPort = 18080
)
$job = Start-Job -ScriptBlock { param($ns, $svc, $port) kubectl -n $ns port-forward "svc/$svc" "$port`:80" } -ArgumentList $Namespace,$Service,$LocalPort
Start-Sleep -Seconds 3
try {
  Invoke-WebRequest "http://127.0.0.1:$LocalPort/health" -UseBasicParsing
  Invoke-WebRequest "http://127.0.0.1:$LocalPort/api/status" -UseBasicParsing
} finally {
  Stop-Job $job -ErrorAction SilentlyContinue
  Remove-Job $job -ErrorAction SilentlyContinue
}
