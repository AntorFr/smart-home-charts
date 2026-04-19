{{/*
This template serves as the blueprint for CronJob objects that are created
within the common library.
*/}}
{{- define "common.cronjob" }}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ include "common.names.fullname" . }}
  {{- with (merge (.Values.controller.labels | default dict) (include "common.labels" $ | fromYaml)) }}
  labels: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with (merge (.Values.controller.annotations | default dict) (include "common.annotations" $ | fromYaml)) }}
  annotations: {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  schedule: {{ required "cronjob.schedule is required when controller.type is cronjob" .Values.cronjob.schedule | quote }}
  {{- $concurrencyPolicy := default "Allow" .Values.cronjob.concurrencyPolicy }}
  {{- if not (has $concurrencyPolicy (list "Allow" "Forbid" "Replace")) }}
    {{- fail (printf "Not a valid cronjob.concurrencyPolicy (%s). Must be one of Allow, Forbid, Replace" $concurrencyPolicy) }}
  {{- end }}
  concurrencyPolicy: {{ $concurrencyPolicy }}
  successfulJobsHistoryLimit: {{ default 3 .Values.cronjob.successfulJobsHistoryLimit }}
  failedJobsHistoryLimit: {{ default 1 .Values.cronjob.failedJobsHistoryLimit }}
  {{- with .Values.cronjob.startingDeadlineSeconds }}
  startingDeadlineSeconds: {{ . }}
  {{- end }}
  {{- with .Values.cronjob.timeZone }}
  timeZone: {{ . | quote }}
  {{- end }}
  {{- if kindIs "bool" .Values.cronjob.suspend }}
  suspend: {{ .Values.cronjob.suspend }}
  {{- end }}
  jobTemplate:
    metadata:
      {{- with (merge (.Values.controller.labels | default dict) (include "common.labels" $ | fromYaml)) }}
      labels: {{- toYaml . | nindent 8 }}
      {{- end }}
    spec:
      {{- with .Values.cronjob.backoffLimit }}
      backoffLimit: {{ . }}
      {{- end }}
      {{- with .Values.cronjob.activeDeadlineSeconds }}
      activeDeadlineSeconds: {{ . }}
      {{- end }}
      {{- with .Values.cronjob.ttlSecondsAfterFinished }}
      ttlSecondsAfterFinished: {{ . }}
      {{- end }}
      {{- with .Values.cronjob.parallelism }}
      parallelism: {{ . }}
      {{- end }}
      {{- with .Values.cronjob.completions }}
      completions: {{ . }}
      {{- end }}
      template:
        metadata:
          {{- with include ("common.podAnnotations") . }}
          annotations:
            {{- . | nindent 12 }}
          {{- end }}
          labels:
            {{- include "common.labels.selectorLabels" . | nindent 12 }}
            {{- with .Values.podLabels }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
        spec:
          {{- $restartPolicy := default "OnFailure" .Values.cronjob.restartPolicy }}
          {{- if not (has $restartPolicy (list "OnFailure" "Never")) }}
            {{- fail (printf "Not a valid cronjob.restartPolicy (%s). Must be OnFailure or Never" $restartPolicy) }}
          {{- end }}
          restartPolicy: {{ $restartPolicy }}
          {{- include "common.controller.pod" . | nindent 10 }}
{{- end }}
