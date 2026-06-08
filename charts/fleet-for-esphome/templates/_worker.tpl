{{/* Standalone Fleet for ESPHome worker Deployment */}}
{{- define "fleet-for-esphome.workerDeployment" -}}
{{- if .Values.worker.deployment.enabled -}}
{{- $serverUrl := .Values.worker.deployment.serverUrl -}}
{{- if and (not $serverUrl) .Values.server.enabled -}}
  {{- $serverUrl = printf "http://%s:8765" (include "common.names.fullname" .) -}}
{{- end -}}
{{- if not $serverUrl -}}
  {{- fail "worker.deployment.serverUrl is required when server.enabled=false" -}}
{{- end -}}
{{- $secretName := .Values.worker.deployment.existingSecret.name | default (include "common.names.fullname" .) -}}
{{- $secretKey := .Values.worker.deployment.existingSecret.key | default "SERVER_TOKEN" -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "common.names.fullname" . }}-worker
  labels:
    {{- include "common.labels" . | nindent 4 }}
    app.kubernetes.io/component: worker
spec:
  revisionHistoryLimit: {{ .Values.controller.revisionHistoryLimit }}
  replicas: {{ .Values.worker.deployment.replicas }}
  strategy:
    type: Recreate
  selector:
    matchLabels:
      {{- include "common.labels.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: worker
  template:
    metadata:
      labels:
        {{- include "common.labels.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: worker
        {{- with .Values.worker.deployment.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- with .Values.worker.deployment.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      hostNetwork: {{ .Values.hostNetwork }}
      dnsPolicy: {{ default (ternary "ClusterFirstWithHostNet" "ClusterFirst" .Values.hostNetwork) .Values.dnsPolicy }}
      {{- with .Values.worker.deployment.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: worker
          image: {{ printf "%s:%s" .Values.worker.image.repository (default .Chart.AppVersion .Values.worker.image.tag) | quote }}
          imagePullPolicy: {{ .Values.worker.image.pullPolicy }}
          {{- with .Values.worker.deployment.securityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          env:
            - name: SERVER_URL
              value: {{ tpl $serverUrl . | quote }}
            - name: SERVER_TOKEN
              valueFrom:
                secretKeyRef:
                  name: {{ $secretName }}
                  key: {{ $secretKey }}
            - name: HOSTNAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            {{- range $name, $value := .Values.worker.deployment.env }}
            - name: {{ $name }}
              value: {{ $value | quote }}
            {{- end }}
          volumeMounts:
            - name: esphome-versions
              mountPath: /esphome-versions
          {{- with .Values.worker.deployment.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      volumes:
        - name: esphome-versions
          emptyDir: {}
      {{- with .Values.worker.deployment.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.worker.deployment.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.worker.deployment.topologySpreadConstraints }}
      topologySpreadConstraints:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.worker.deployment.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}
{{- end -}}
