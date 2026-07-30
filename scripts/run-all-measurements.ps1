[CmdletBinding()]
param(
    [string]$ProjectRoot = ".",
    [string]$ReleaseName = "demo",
    [string]$Namespace = "demo-app",
    [string]$KindCluster = "vkr-demo",
    [string]$ImageTag = "nonroot-local",
    [int]$ManualBaseOneEnvLines = 389,
    [int]$TemplateRuns = 5,
    [int]$LocalPort = 8080,
    [switch]$SkipBuild,
    [switch]$SkipKind,
    [switch]$SkipDeploy,
    [switch]$SkipSmoke
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path $ProjectRoot
$ChartPath = Join-Path $Root "chart"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ResultsRoot = Join-Path $Root "experiment-results"
$Results = Join-Path $ResultsRoot $Timestamp
$RenderedDir = Join-Path $Results "rendered"
$LogsDir = Join-Path $Results "logs"
$SmokeDir = Join-Path $Results "smoke"

New-Item -ItemType Directory -Force -Path $ResultsRoot, $Results, $RenderedDir, $LogsDir, $SmokeDir | Out-Null

$script:CommandRows = @()
$script:LineRows = @()
$script:TimingRows = @()
$script:SmokeRows = @()

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Assert-CommandExists {
    param([string]$CommandName)

    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        throw "Command not found in PATH: $CommandName"
    }
}

function ConvertTo-CmdLine {
    param([string[]]$Command)

    return ($Command | ForEach-Object {
        if ($_ -match "\s") {
            '"' + $_ + '"'
        } else {
            $_
        }
    }) -join " "
}

function Invoke-External {
    param(
        [string]$Name,
        [string[]]$Command,
        [switch]$AllowFailure
    )

    $logPath = Join-Path $LogsDir "$Name.txt"
    $cmdLine = ConvertTo-CmdLine $Command

    "PS> $cmdLine" | Out-File -FilePath $logPath -Encoding utf8
    Write-Info $cmdLine

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $exe = $Command[0]
    $args = @()
    if ($Command.Count -gt 1) {
        $args = $Command[1..($Command.Count - 1)]
    }

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $output = & $exe @args 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldErrorActionPreference
    }

    $sw.Stop()

    $output | Out-File -FilePath $logPath -Encoding utf8 -Append

    $script:CommandRows += [PSCustomObject]@{
        name      = $Name
        command   = $cmdLine
        exit_code = $exitCode
        seconds   = [Math]::Round($sw.Elapsed.TotalSeconds, 3)
        log_file  = "logs/$Name.txt"
    }

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "Command failed: $cmdLine. See: $logPath"
    }

    return [PSCustomObject]@{
        Name     = $Name
        ExitCode = $exitCode
        Seconds  = $sw.Elapsed.TotalSeconds
        Output   = $output
        LogPath  = $logPath
    }
}

function Invoke-TemplateToFile {
    param(
        [string]$Name,
        [string[]]$HelmArgs,
        [string]$OutputFile,
        [switch]$AllowFailure
    )

    $logPath = Join-Path $LogsDir "$Name.txt"
    $cmd = @("helm") + $HelmArgs
    $cmdLine = ConvertTo-CmdLine $cmd

    "PS> $cmdLine" | Out-File -FilePath $logPath -Encoding utf8
    Write-Info $cmdLine

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $output = & helm @HelmArgs 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldErrorActionPreference
    }

    $sw.Stop()

    $output | Out-File -FilePath $logPath -Encoding utf8 -Append

    $script:CommandRows += [PSCustomObject]@{
        name      = $Name
        command   = $cmdLine
        exit_code = $exitCode
        seconds   = [Math]::Round($sw.Elapsed.TotalSeconds, 3)
        log_file  = "logs/$Name.txt"
    }

    if ($exitCode -eq 0) {
        $output | Out-File -FilePath $OutputFile -Encoding utf8
    }

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "helm template failed: $cmdLine. See: $logPath"
    }

    return [PSCustomObject]@{
        Name     = $Name
        ExitCode = $exitCode
        Seconds  = $sw.Elapsed.TotalSeconds
        Output   = $output
        LogPath  = $logPath
    }
}

function Get-LineCount {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return 0
    }

    $item = Get-Item $Path

    if ($item.PSIsContainer) {
        $files = Get-ChildItem -LiteralPath $Path -Recurse -File |
            Where-Object {
                $_.Extension -in @(".yaml", ".yml", ".json", ".tpl")
            }

        $total = 0
        foreach ($file in $files) {
            $total += (Get-Content -LiteralPath $file.FullName -ErrorAction Stop).Count
        }

        return $total
    }

    return (Get-Content -LiteralPath $Path -ErrorAction Stop).Count
}

function Add-LineMetric {
    param(
        [string]$Metric,
        [string]$Path,
        [string]$Group = "general"
    )

    $fullPath = Join-Path $Root $Path

    if (-not (Test-Path $fullPath)) {
        $script:LineRows += [PSCustomObject]@{
            metric = $Metric
            group  = $Group
            path   = $Path
            lines  = 0
            exists = $false
        }
        return
    }

    $lines = Get-LineCount $fullPath

    $script:LineRows += [PSCustomObject]@{
        metric = $Metric
        group  = $Group
        path   = $Path
        lines  = $lines
        exists = $true
    }
}

function Get-MetricLines {
    param([string]$Metric)

    $row = $script:LineRows | Where-Object { $_.metric -eq $Metric } | Select-Object -First 1
    if ($null -eq $row) {
        return 0
    }

    return [int]$row.lines
}

function Add-ManualBillingMetric {
    $candidates = @(
        "experiments/add-service/manual-billing-service.yaml",
        "experiments/add-service/billing-service-manual.yaml",
        "experiments/add-service/manual/billing-service.yaml",
        "baseline/manual-k8s/billing-service.yaml",
        "experiments/baseline/manual-k8s/billing-service.yaml"
    )

    foreach ($candidate in $candidates) {
        $full = Join-Path $Root $candidate
        if (Test-Path $full) {
            Add-LineMetric -Metric "manual-billing-service" -Path $candidate -Group "manual"
            return
        }
    }

    $script:LineRows += [PSCustomObject]@{
        metric = "manual-billing-service"
        group  = "manual"
        path   = "not-found"
        lines  = 0
        exists = $false
    }
}

function Measure-HelmTemplateTime {
    param(
        [string]$Name,
        [string[]]$HelmArgs,
        [int]$Runs
    )

    for ($i = 1; $i -le $Runs; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $oldErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"

        try {
            $output = & helm @HelmArgs 2>&1
            $exitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $oldErrorActionPreference
        }
        $sw.Stop()

        $script:TimingRows += [PSCustomObject]@{
            test      = $Name
            run       = $i
            exit_code = $exitCode
            seconds   = [Math]::Round($sw.Elapsed.TotalSeconds, 3)
        }

        if ($exitCode -ne 0) {
            $logPath = Join-Path $LogsDir "$Name-time-run-$i-error.txt"
            $output | Out-File -FilePath $logPath -Encoding utf8
            throw "helm template timing failed. See: $logPath"
        }
    }
}

function Add-RenderedKindMetrics {
    param(
        [string]$Name,
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        return
    }

    $kindRows = Select-String -LiteralPath $FilePath -Pattern "^kind:\s*(.+)$" |
        ForEach-Object {
            $_.Matches[0].Groups[1].Value.Trim()
        } |
        Group-Object |
        Sort-Object Name

    foreach ($kind in $kindRows) {
        $script:LineRows += [PSCustomObject]@{
            metric = "$Name-kind-$($kind.Name)"
            group  = "rendered-kind-count"
            path   = $FilePath.Replace("$Results\", "")
            lines  = $kind.Count
            exists = $true
        }
    }
}

function Export-AllCsv {
    $script:CommandRows | Export-Csv -NoTypeInformation -Encoding utf8 -Path (Join-Path $Results "command-results.csv")
    $script:LineRows | Export-Csv -NoTypeInformation -Encoding utf8 -Path (Join-Path $Results "line-count.csv")
    $script:TimingRows | Export-Csv -NoTypeInformation -Encoding utf8 -Path (Join-Path $Results "helm-template-time.csv")
    $script:SmokeRows | Export-Csv -NoTypeInformation -Encoding utf8 -Path (Join-Path $Results "smoke-tests.csv")
}

function Write-Summary {
    $valuesYaml = Get-MetricLines "values.yaml"
    $valuesDev = Get-MetricLines "values-dev.yaml"
    $valuesStage = Get-MetricLines "values-stage.yaml"
    $valuesProd = Get-MetricLines "values-prod.yaml"
    $valuesIstio = Get-MetricLines "values-istio.yaml"
    $billingValues = Get-MetricLines "billing-service-values.yaml"
    $manualBilling = Get-MetricLines "manual-billing-service"
    $renderedDev = Get-MetricLines "rendered-dev.yaml"
    $renderedDevBilling = Get-MetricLines "rendered-dev-with-billing.yaml"

    $valuesWithoutBilling = $valuesYaml + $valuesDev + $valuesStage + $valuesProd + $valuesIstio
    $valuesWithBilling = $valuesWithoutBilling + $billingValues

    $manualFiveOneEnv = $ManualBaseOneEnvLines + $manualBilling
    $manualFiveThreeEnv = $manualFiveOneEnv * 3

    $billingReduction = 0
    $billingRatio = 0
    if ($manualBilling -gt 0 -and $billingValues -gt 0) {
        $billingReduction = [Math]::Round((($manualBilling - $billingValues) / $manualBilling) * 100, 1)
        $billingRatio = [Math]::Round($manualBilling / $billingValues, 1)
    }

    $multiEnvReduction = 0
    if ($manualFiveThreeEnv -gt 0 -and $valuesWithBilling -gt 0) {
        $multiEnvReduction = [Math]::Round((($manualFiveThreeEnv - $valuesWithBilling) / $manualFiveThreeEnv) * 100, 1)
    }

    $renderedDelta = $renderedDevBilling - $renderedDev

    $generatedPerInputLine = 0
    if ($billingValues -gt 0 -and $renderedDelta -gt 0) {
        $generatedPerInputLine = [Math]::Round($renderedDelta / $billingValues, 1)
    }

    $avgTemplate = 0
    $templateRows = $script:TimingRows | Where-Object { $_.test -eq "helm-template-dev" }
    if ($templateRows.Count -gt 0) {
        $avgTemplate = [Math]::Round((($templateRows | Measure-Object -Property seconds -Average).Average), 3)
    }

    $summaryPath = Join-Path $Results "summary.md"

@"
# Measurement results

Run date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Input configuration line count

| Metric | Value |
|---|---:|
| values.yaml | $valuesYaml |
| values-dev.yaml | $valuesDev |
| values-stage.yaml | $valuesStage |
| values-prod.yaml | $valuesProd |
| values-istio.yaml | $valuesIstio |
| All values files without billingService | $valuesWithoutBilling |
| billing-service-values.yaml | $billingValues |
| All values files with billingService | $valuesWithBilling |
| Manual billingService baseline | $manualBilling |
| rendered-dev.yaml | $renderedDev |
| rendered-dev-with-billing.yaml | $renderedDevBilling |

## Derived metrics

| Metric | Value |
|---|---:|
| Manual baseline for 4 services, 1 environment | $ManualBaseOneEnvLines |
| Manual baseline for 5 services, 1 environment | $manualFiveOneEnv |
| Manual baseline for 5 services, 3 environments | $manualFiveThreeEnv |
| Metachart values files with billingService | $valuesWithBilling |
| Reduction for 5 services and 3 environments | $multiEnvReduction % |
| Reduction when adding billingService | $billingReduction % |
| Manual billingService is larger than values-based approach | $billingRatio x |
| Rendered manifest delta after billingService | $renderedDelta lines |
| Generated Kubernetes manifest lines per one billingService input line | $generatedPerInputLine |
| Average helm template dev time | $avgTemplate sec |

## Output files

- command-results.csv
- line-count.csv
- helm-template-time.csv
- smoke-tests.csv
- schema-validation.csv
- docker-image-sizes.csv
- rendered/
- logs/
- smoke/
"@ | Out-File -FilePath $summaryPath -Encoding utf8
}

Assert-CommandExists "helm"

if (-not $SkipBuild -or -not $SkipKind -or -not $SkipDeploy -or -not $SkipSmoke) {
    Assert-CommandExists "kubectl"
}

if (-not $SkipBuild) {
    Assert-CommandExists "docker"
}

if (-not $SkipKind) {
    Assert-CommandExists "kind"
}

if (-not (Test-Path $ChartPath)) {
    throw "chart directory not found: $ChartPath"
}

Write-Info "Results directory: $Results"

Invoke-External -Name "helm-lint" -Command @("helm", "lint", $ChartPath)

$renderJobs = @(
    @{
        Name = "rendered-dev"
        Values = @("chart/values-dev.yaml")
        Out = "rendered-dev.yaml"
    },
    @{
        Name = "rendered-stage"
        Values = @("chart/values-stage.yaml")
        Out = "rendered-stage.yaml"
    },
    @{
        Name = "rendered-prod"
        Values = @("chart/values-prod.yaml")
        Out = "rendered-prod.yaml"
    },
    @{
        Name = "rendered-istio"
        Values = @("chart/values-dev.yaml", "chart/values-istio.yaml")
        Out = "rendered-istio.yaml"
    },
    @{
        Name = "rendered-dev-with-billing"
        Values = @("chart/values-dev.yaml", "experiments/add-service/billing-service-values.yaml")
        Out = "rendered-dev-with-billing.yaml"
    }
)

foreach ($job in $renderJobs) {
    $outFile = Join-Path $RenderedDir $job.Out

    $args = @("template", $ReleaseName, $ChartPath)

    foreach ($valueFile in $job.Values) {
        $fullValue = Join-Path $Root $valueFile

        if (Test-Path $fullValue) {
            $args += @("-f", $fullValue)
        } else {
            throw "values file not found: $fullValue"
        }
    }

    Invoke-TemplateToFile -Name $job.Name -HelmArgs $args -OutputFile $outFile
    Add-LineMetric -Metric $job.Out -Path ("experiment-results/$Timestamp/rendered/" + $job.Out) -Group "rendered"
    Add-RenderedKindMetrics -Name $job.Name -FilePath $outFile
}

$badValuesCandidates = @(
    "experiments/invalid-values/bad-container-port.yaml",
    "experiments/invalid-values/bad-values.yaml"
)

$badValues = $null
foreach ($candidate in $badValuesCandidates) {
    $full = Join-Path $Root $candidate
    if (Test-Path $full) {
        $badValues = $full
        break
    }
}

if ($null -ne $badValues) {
    $schemaResult = Invoke-TemplateToFile `
        -Name "schema-validation-invalid-values" `
        -HelmArgs @("template", $ReleaseName, $ChartPath, "-f", (Join-Path $Root "chart/values-dev.yaml"), "-f", $badValues) `
        -OutputFile (Join-Path $RenderedDir "invalid-values-output.yaml") `
        -AllowFailure

    $schemaPassed = $schemaResult.ExitCode -ne 0

    [PSCustomObject]@{
        test      = "schema-validation-invalid-values"
        expected  = "failure"
        exit_code = $schemaResult.ExitCode
        passed    = $schemaPassed
        log_file  = "logs/schema-validation-invalid-values.txt"
    } | Export-Csv -NoTypeInformation -Encoding utf8 -Path (Join-Path $Results "schema-validation.csv")
}

Add-LineMetric -Metric "values.yaml" -Path "chart/values.yaml" -Group "values"
Add-LineMetric -Metric "values-dev.yaml" -Path "chart/values-dev.yaml" -Group "values"
Add-LineMetric -Metric "values-stage.yaml" -Path "chart/values-stage.yaml" -Group "values"
Add-LineMetric -Metric "values-prod.yaml" -Path "chart/values-prod.yaml" -Group "values"
Add-LineMetric -Metric "values-istio.yaml" -Path "chart/values-istio.yaml" -Group "values"
Add-LineMetric -Metric "billing-service-values.yaml" -Path "experiments/add-service/billing-service-values.yaml" -Group "values"
Add-LineMetric -Metric "helm-templates" -Path "chart/templates" -Group "templates"

Add-ManualBillingMetric

Add-LineMetric -Metric "competitor-kustomize" -Path "competitors/kustomize" -Group "competitors"
Add-LineMetric -Metric "competitor-helm-per-service" -Path "competitors/helm-per-service" -Group "competitors"
Add-LineMetric -Metric "competitor-timoni-cue" -Path "competitors/timoni" -Group "competitors"

Measure-HelmTemplateTime `
    -Name "helm-template-dev" `
    -Runs $TemplateRuns `
    -HelmArgs @("template", $ReleaseName, $ChartPath, "-f", (Join-Path $Root "chart/values-dev.yaml"))

$services = @(
    "frontend",
    "api-gateway",
    "user-service",
    "order-service",
    "notification-worker"
)

if (-not $SkipBuild) {
    foreach ($svc in $services) {
        $svcPath = Join-Path $Root "services/$svc"
        $dockerfile = Join-Path $svcPath "Dockerfile"

        if (Test-Path $dockerfile) {
            Invoke-External -Name "docker-build-$svc" -Command @("docker", "build", "-t", "${svc}:$ImageTag", $svcPath)
        }
    }

    $imageRows = @()

    foreach ($svc in $services) {
        $imageRef = "${svc}:$ImageTag"

        $oldErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"

        try {
            $inspectJson = & docker image inspect $imageRef --format "{{json .}}" 2>&1
            $inspectExitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $oldErrorActionPreference
        }

        if ($inspectExitCode -eq 0 -and $inspectJson) {
            try {
                $imageInfo = $inspectJson | ConvertFrom-Json

                $repoTag = $imageRef
                if ($imageInfo.RepoTags -and $imageInfo.RepoTags.Count -gt 0) {
                    $repoTag = $imageInfo.RepoTags[0]
                }

                $sizeBytes = [int64]$imageInfo.Size

                $imageRows += [PSCustomObject]@{
                    image      = $repoTag
                    size_bytes = $sizeBytes
                    size_mb    = [Math]::Round($sizeBytes / 1MB, 2)
                }
            } catch {
                $imageRows += [PSCustomObject]@{
                    image      = $imageRef
                    size_bytes = 0
                    size_mb    = 0
                }
            }
        } else {
            $imageRows += [PSCustomObject]@{
                image      = $imageRef
                size_bytes = 0
                size_mb    = 0
            }
        }
    }

    $imageRows | Export-Csv -NoTypeInformation -Encoding utf8 -Path (Join-Path $Results "docker-image-sizes.csv")
}

if (-not $SkipKind) {
    $clusters = & kind get clusters 2>$null

    if ($clusters -notcontains $KindCluster) {
        $kindConfig = Join-Path $Root "deploy/kind/kind-config.yaml"

        if (Test-Path $kindConfig) {
            Invoke-External -Name "kind-create-cluster" -Command @("kind", "create", "cluster", "--name", $KindCluster, "--config", $kindConfig)
        } else {
            Invoke-External -Name "kind-create-cluster" -Command @("kind", "create", "cluster", "--name", $KindCluster)
        }
    }

    foreach ($svc in $services) {
        Invoke-External -Name "kind-load-$svc" -Command @("kind", "load", "docker-image", "${svc}:$ImageTag", "--name", $KindCluster)
    }
}

if (-not $SkipDeploy) {
    $null = & kubectl get namespace $Namespace 2>$null

    if ($LASTEXITCODE -ne 0) {
        Invoke-External -Name "kubectl-create-namespace" -Command @("kubectl", "create", "namespace", $Namespace)
    }

    Invoke-External -Name "helm-upgrade-install" -Command @(
        "helm", "upgrade", "--install", $ReleaseName, $ChartPath,
        "-n", $Namespace,
        "--create-namespace",
        "-f", (Join-Path $Root "chart/values-dev.yaml"),
        "--set", "global.imageRegistry=",
        "--set", "global.imageTag=$ImageTag",
        "--set", "global.imagePullPolicy=IfNotPresent"
    )

    Invoke-External -Name "helm-list" -Command @("helm", "list", "-n", $Namespace)
    Invoke-External -Name "kubectl-get-pods" -Command @("kubectl", "get", "pods", "-n", $Namespace, "-o", "wide")
    Invoke-External -Name "kubectl-get-services" -Command @("kubectl", "get", "svc", "-n", $Namespace)
    Invoke-External -Name "kubectl-get-networkpolicies" -Command @("kubectl", "get", "networkpolicy", "-n", $Namespace)
    Invoke-External -Name "kubectl-get-deployments" -Command @("kubectl", "get", "deploy", "-n", $Namespace)

    Invoke-External -Name "kubectl-wait-pods-ready" -Command @(
        "kubectl", "wait",
        "--for=condition=Ready",
        "pod",
        "-l", "app.kubernetes.io/instance=$ReleaseName",
        "-n", $Namespace,
        "--timeout=120s"
    )
}

if (-not $SkipSmoke) {
    $apiSvc = & kubectl get svc -n $Namespace `
        -l "app.kubernetes.io/name=api-gateway,app.kubernetes.io/instance=$ReleaseName" `
        -o "jsonpath={.items[0].metadata.name}" 2>$null

    if (-not $apiSvc) {
        $apiSvc = "$ReleaseName-api-gateway"
    }

    $pfOut = Join-Path $LogsDir "port-forward-api-gateway.out.txt"
    $pfErr = Join-Path $LogsDir "port-forward-api-gateway.err.txt"

    $pfArgs = @(
        "port-forward",
        "svc/$apiSvc",
        "${LocalPort}:80",
        "-n",
        $Namespace
    )

    Write-Info "kubectl $($pfArgs -join ' ')"

    $pf = Start-Process `
        -FilePath "kubectl" `
        -ArgumentList $pfArgs `
        -PassThru `
        -RedirectStandardOutput $pfOut `
        -RedirectStandardError $pfErr `
        -WindowStyle Hidden

    Start-Sleep -Seconds 5

    try {
        $endpoints = @("/health", "/ready", "/metrics", "/dependencies")

        foreach ($endpoint in $endpoints) {
            $url = "http://127.0.0.1:$LocalPort$endpoint"
            $name = $endpoint.TrimStart("/").Replace("/", "-")
            $outFile = Join-Path $SmokeDir "$name.txt"

            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
                $response.Content | Out-File -FilePath $outFile -Encoding utf8

                $script:SmokeRows += [PSCustomObject]@{
                    endpoint    = $endpoint
                    url         = $url
                    status_code = [int]$response.StatusCode
                    passed      = $true
                    output_file = "smoke/$name.txt"
                }
            } catch {
                $_.Exception.Message | Out-File -FilePath $outFile -Encoding utf8

                $script:SmokeRows += [PSCustomObject]@{
                    endpoint    = $endpoint
                    url         = $url
                    status_code = 0
                    passed      = $false
                    output_file = "smoke/$name.txt"
                }
            }
        }
    } finally {
        if ($null -ne $pf -and -not $pf.HasExited) {
            Stop-Process -Id $pf.Id -Force
        }
    }
}

Export-AllCsv
Write-Summary
Export-AllCsv

Write-Host ""
Write-Host "Done. Results directory:"
Write-Host $Results
Write-Host ""
Write-Host "Main file:"
Write-Host (Join-Path $Results "summary.md")