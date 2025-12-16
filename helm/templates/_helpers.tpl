{{/*
Expand the name of the chart.
*/}}
{{- define "canary-demo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "canary-demo.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "canary-demo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "canary-demo.labels" -}}
helm.sh/chart: {{ include "canary-demo.chart" . }}
{{ include "canary-demo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "canary-demo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "canary-demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "canary-demo.fullname" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "canary-demo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "canary-demo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Stable service name
*/}}
{{- define "canary-demo.stableServiceName" -}}
{{- printf "%s-stable" (include "canary-demo.fullname" .) }}
{{- end }}

{{/*
Canary service name
*/}}
{{- define "canary-demo.canaryServiceName" -}}
{{- printf "%s-canary" (include "canary-demo.fullname" .) }}
{{- end }}

{{/*
Root service name
*/}}
{{- define "canary-demo.rootServiceName" -}}
{{- printf "%s-root" (include "canary-demo.fullname" .) }}
{{- end }}

{{/*
Ingress name
*/}}
{{- define "canary-demo.ingressName" -}}
{{- printf "%s-ingress" (include "canary-demo.fullname" .) }}
{{- end }}
