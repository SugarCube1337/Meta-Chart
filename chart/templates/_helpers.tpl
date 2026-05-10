{{/* Convert service key to kebab-case. */}}
{{- define "vkr.kebab" -}}
{{- regexReplaceAll "([a-z0-9])([A-Z])" . "${1}-${2}" | lower | replace "_" "-" -}}
{{- end -}}

{{- define "vkr.chartName" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "vkr.fullname" -}}
{{- if .Values.global.fullnameOverride -}}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "vkr.chartName" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "vkr.serviceName" -}}
{{- $root := .root -}}
{{- $name := include "vkr.kebab" .name -}}
{{- printf "%s-%s" $root.Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "vkr.namespace" -}}
{{- default .Release.Namespace .Values.global.namespace -}}
{{- end -}}

{{- define "vkr.labels" -}}
helm.sh/chart: {{ .root.Chart.Name }}-{{ .root.Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "vkr.kebab" .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
app.kubernetes.io/part-of: {{ include "vkr.chartName" .root }}
app.kubernetes.io/component: {{ include "vkr.kebab" .name }}
app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
{{- with .root.Values.global.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "vkr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vkr.kebab" .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end -}}

{{- define "vkr.serviceAccountName" -}}
{{- if .root.Values.serviceAccount.create -}}
{{- include "vkr.serviceName" . -}}
{{- else -}}
{{- default "default" .root.Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "vkr.serviceImage" -}}
{{- $root := .root -}}
{{- $service := .service -}}
{{- $registry := default "" $root.Values.global.imageRegistry -}}
{{- $repository := required "service image.repository is required" $service.image.repository -}}
{{- $tag := default (default "latest" $root.Values.global.imageTag) $service.image.tag -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" (trimSuffix "/" $registry) $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end -}}

{{- define "vkr.dependencyUrl" -}}
{{- $root := .root -}}
{{- $dep := .dep -}}
{{- $protocol := default "http" $dep.protocol -}}
{{- $port := default 80 $dep.port -}}
{{- $target := include "vkr.serviceName" (dict "root" $root "name" $dep.service) -}}
{{- $namespace := include "vkr.namespace" $root -}}
{{- printf "%s://%s.%s.svc.cluster.local:%v" $protocol $target $namespace $port -}}
{{- end -}}
