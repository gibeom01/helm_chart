{{/*
Expand the name of the chart.
*/}}
{{- define "mysqldb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "mysqldb.fullname" -}}
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
{{- define "mysqldb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mysqldb.labels" -}}
helm.sh/chart: {{ include "mysqldb.chart" . }}
{{ include "mysqldb.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mysqldb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mysqldb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mysqldb.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mysqldb.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
ConfigMap definition
*/}}
{{- define "mysqldb.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "mysqldb.fullname" . }}-config
  labels:
    {{- include "mysqldb.labels" . | nindent 4 }}
data:
  db.properties: |
    database.host=localhost
    database.port=3306
    database.name=exampledb
    database.user=root
    database.password=secret
{{- end }}

{{/*
Secret definition
*/}}
{{- define "mysqldb.secret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "mysqldb.fullname" . }}-secret
  labels:
    {{- include "mysqldb.labels" . | nindent 4 }}
type: Opaque
data:
  username: {{ .Values.secret.username | b64enc }}
  password: {{ .Values.secret.password | b64enc }}
{{- end }}

{{/*
Horizontal Pod Autoscaler
*/}}
{{- define "mysqldb.hpa" -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "mysqldb.fullname" . }}
  labels:
    {{- include "mysqldb.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "mysqldb.fullname" . }}
  minReplicas: {{ .Values.hpa.minReplicas }}
  maxReplicas: {{ .Values.hpa.maxReplicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.hpa.cpuUtilization }}
{{- end }}

{{/*
Ingress definition
*/}}
{{- define "mysqldb.ingress" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "mysqldb.fullname" . }}
  annotations:
    {{- with .Values.ingress.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  rules:
  - host: {{ .Values.ingress.host }}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{ include "mysqldb.fullname" . }}
            port:
              number: {{ .Values.service.port }}
{{- if .Values.ingress.tls }}
  tls:
  - hosts:
    - {{ .Values.ingress.host }}
    secretName: {{ .Values.ingress.tlsSecretName }}
{{- end }}
{{- end }}
