{{/*
nginxweb.fullname 템플릿 정의
*/}}
{{- define "nginxweb.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end -}}

{{/*
nginxweb.name 템플릿 정의
*/}}
{{- define "nginxweb.name" -}}
{{ .Chart.Name }}
{{- end -}}

{{/*
nginxweb.labels 템플릿 정의
*/}}
{{- define "nginxweb.labels" -}}
app.kubernetes.io/name: "{{ include "nginxweb.name" . }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
app.kubernetes.io/version: "{{ .Chart.AppVersion }}"
app.kubernetes.io/component: "nginx"
app.kubernetes.io/part-of: "nginxweb"
{{- end -}}

{{/*
nginxweb.selectorLabels 템플릿 정의 (추가된 부분)
*/}}
{{- define "nginxweb.selectorLabels" -}}
app.kubernetes.io/name: "{{ include "nginxweb.name" . }}"
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end -}}

{{/*
ConfigMap 템플릿
*/}}
{{- define "nginxweb.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "nginxweb.fullname" . }}-config
  labels:
    {{- include "nginxweb.labels" . | nindent 4 }}
  annotations:
    description: "ConfigMap for NGINX web deployment"
    version: "1.0"
data:
  nginx.conf: |
    {{ .Values.nginx.config.nginxConf | indent 4 }}
  default.conf: |
    {{ .Values.nginx.config.defaultConf | indent 4 }}
{{- end -}}

{{/*
Deployment 템플릿
*/}}
{{- define "nginxweb.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "nginxweb.fullname" . }}
  labels:
    {{- include "nginxweb.labels" . | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ include "nginxweb.name" . }}
  template:
    metadata:
      labels:
        app: {{ include "nginxweb.name" . }}
    spec:
      containers:
        - name: nginx
          image: {{ .Values.nginx.image }}
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
            - name: nginx-config
              mountPath: /etc/nginx/conf.d/default.conf
              subPath: default.conf
      volumes:
        - name: nginx-config
          configMap:
            name: {{ include "nginxweb.fullname" . }}-config
{{- end -}}

{{/*
Horizontal Pod Autoscaler (HPA) 템플릿
*/}}
{{- define "nginxweb.hpa" -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "nginxweb.fullname" . }}-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "nginxweb.fullname" . }}
  minReplicas: 1
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
{{- end -}}

{{/*
Ingress 템플릿
*/}}
{{- define "nginxweb.ingress" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "nginxweb.fullname" . }}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: {{ .Release.Name }}.{{ .Values.ingress.host }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ include "nginxweb.fullname" . }}
                port:
                  number: 80
{{- end -}}

{{/*
Secret 템플릿
*/}}
{{- define "nginxweb.secret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "nginxweb.fullname" . }}-secret
type: Opaque
data:
  dbPassword: {{ .Values.secret.dbPassword | b64enc }}
{{- end -}}

{{/*
Service 템플릿
*/}}
{{- define "nginxweb.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "nginxweb.fullname" . }}
  labels:
    {{- include "nginxweb.labels" . | nindent 4 }}
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: {{ include "nginxweb.name" . }}
  type: {{ .Values.service.type }}
{{- end -}}

{{/*
ServiceAccount 템플릿
*/}}
{{- define "nginxweb.serviceaccount" -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "nginxweb.fullname" . }}
{{- end -}}
