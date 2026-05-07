{{/*
Common helper templates for vkr-metachart.
*/}}

{{- define "vkr-metachart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "vkr-metachart.serviceName" -}}
{{- .serviceName | kebabcase | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "vkr-metachart.serviceFullname" -}}
{{- $root := .root -}}
{{- $serviceName := .serviceName | kebabcase -}}
{{- printf "%s-%s" $root.Release.Name $serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "vkr-metachart.serviceLabels" -}}
helm.sh/chart: {{ include "vkr-metachart.chart" .root | quote }}
app.kubernetes.io/name: {{ include "vkr-metachart.serviceName" . | quote }}
app.kubernetes.io/instance: {{ .root.Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service | quote }}
app.kubernetes.io/part-of: {{ .root.Values.global.applicationName | default .root.Chart.Name | quote }}
app.kubernetes.io/component: {{ include "vkr-metachart.serviceName" . | quote }}
environment: {{ .root.Values.global.environment | default "dev" | quote }}
{{- with .root.Values.global.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "vkr-metachart.serviceSelectorLabels" -}}
app.kubernetes.io/instance: {{ .root.Release.Name | quote }}
app.kubernetes.io/component: {{ include "vkr-metachart.serviceName" . | quote }}
{{- end -}}

{{- define "vkr-metachart.namespace" -}}
{{- .Values.global.namespace | default .Release.Namespace -}}
{{- end -}}
