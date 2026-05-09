{{/*
Common helper templates for the Helm metachart.
*/}}

{{- define "meta-chart.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "meta-chart.fullname" -}}
{{- if .Values.global.fullnameOverride -}}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "meta-chart.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "meta-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "meta-chart.namespace" -}}
{{- default .Release.Namespace .Values.global.namespace -}}
{{- end -}}

{{- define "meta-chart.serviceName" -}}
{{- printf "%s-%s" .root.Release.Name .serviceName | kebabcase | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "meta-chart.configMapName" -}}
{{- printf "%s-config" (include "meta-chart.serviceName" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "meta-chart.secretName" -}}
{{- printf "%s-secret" (include "meta-chart.serviceName" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "meta-chart.selectorLabels" -}}
app.kubernetes.io/instance: {{ .root.Release.Name | quote }}
app.kubernetes.io/component: {{ .serviceName | kebabcase | quote }}
{{- end -}}

{{- define "meta-chart.serviceLabels" -}}
app.kubernetes.io/name: {{ include "meta-chart.name" .root | quote }}
app.kubernetes.io/instance: {{ .root.Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service | quote }}
app.kubernetes.io/component: {{ .serviceName | kebabcase | quote }}
app.kubernetes.io/part-of: {{ include "meta-chart.name" .root | quote }}
helm.sh/chart: {{ include "meta-chart.chart" .root | quote }}
{{- with .root.Values.global.commonLabels }}
{{ toYaml . }}
{{- end -}}
{{- end -}}

{{- define "meta-chart.image" -}}
{{- $root := .root -}}
{{- $service := .service -}}
{{- $repo := required "service.image.repository is required" $service.image.repository -}}
{{- $tag := default (default $root.Chart.AppVersion $root.Values.global.imageTag) $service.image.tag -}}
{{- if $root.Values.global.imageRegistry -}}
{{- printf "%s/%s:%s" ($root.Values.global.imageRegistry | trimSuffix "/") $repo $tag -}}
{{- else -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}
{{- end -}}

{{- define "meta-chart.serviceDnsName" -}}
{{- $root := .root -}}
{{- $serviceName := .serviceName -}}
{{- $k8sName := include "meta-chart.serviceName" (dict "root" $root "serviceName" $serviceName) -}}
{{- $namespace := include "meta-chart.namespace" $root -}}
{{- $domainSuffix := default "svc.cluster.local" $root.Values.serviceDiscovery.domainSuffix -}}
{{- printf "%s.%s.%s" $k8sName $namespace $domainSuffix -}}
{{- end -}}

{{- define "meta-chart.effectiveService" -}}
{{/*
This helper is intentionally not used for rendering because Helm helpers return strings.
Effective service maps are computed inside every template through mergeOverwrite.
*/}}
{{- end -}}
