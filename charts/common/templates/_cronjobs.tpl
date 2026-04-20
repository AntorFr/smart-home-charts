{{/*
Template to render standalone CronJob resources from the top-level `cronjobs:` section.
Each entry creates an independent CronJob alongside the main controller.
*/}}
{{- define "common.cronjobs" -}}
  {{- range $name, $cronjob := .Values.cronjobs -}}
    {{- if and $cronjob (ne (default true $cronjob.enabled) false) -}}
      {{- include "common.cronjobs.item" (dict "rootContext" $ "name" $name "cronjob" $cronjob) }}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Render a single standalone CronJob.
Uses the Values Overlay strategy: temporarily replace .Values fields with
cronjob-specific values, render using existing templates, then restore.
*/}}
{{- define "common.cronjobs.item" -}}
  {{- $root := .rootContext -}}
  {{- $name := .name -}}
  {{- $cj := .cronjob -}}

  {{- /* ---- Save original .Values fields ---- */ -}}
  {{- $origImage := $root.Values.image -}}
  {{- $origCommand := $root.Values.command -}}
  {{- $origArgs := $root.Values.args -}}
  {{- $origEnv := $root.Values.env -}}
  {{- $origEnvFrom := $root.Values.envFrom -}}
  {{- $origPersistence := $root.Values.persistence -}}
  {{- $origInitContainers := $root.Values.initContainers -}}
  {{- $origAdditionalContainers := $root.Values.additionalContainers -}}
  {{- $origResources := $root.Values.resources -}}
  {{- $origSecurityContext := $root.Values.securityContext -}}
  {{- $origPodSecurityContext := $root.Values.podSecurityContext -}}
  {{- $origController := $root.Values.controller -}}
  {{- $origCronjob := $root.Values.cronjob -}}
  {{- $origService := $root.Values.service -}}
  {{- $origProbes := $root.Values.probes -}}
  {{- $origPodAnnotations := $root.Values.podAnnotations -}}
  {{- $origPodLabels := $root.Values.podLabels -}}
  {{- $origLifecycle := $root.Values.lifecycle -}}
  {{- $origTermination := $root.Values.termination -}}
  {{- $origNodeSelector := $root.Values.nodeSelector -}}
  {{- $origAffinity := $root.Values.affinity -}}
  {{- $origTolerations := $root.Values.tolerations -}}

  {{- /* ---- Overlay cronjob values ---- */ -}}
  {{- $_ := set $root.Values "image" (required (printf "cronjobs.%s.image is required" $name) $cj.image) -}}
  {{- $_ := set $root.Values "command" (default list $cj.command) -}}
  {{- $_ := set $root.Values "args" (default list $cj.args) -}}
  {{- $_ := set $root.Values "env" ($cj.env | default dict) -}}
  {{- $_ := set $root.Values "envFrom" (default list $cj.envFrom) -}}
  {{- $_ := set $root.Values "persistence" (default dict $cj.persistence) -}}
  {{- $_ := set $root.Values "initContainers" (default dict $cj.initContainers) -}}
  {{- $_ := set $root.Values "additionalContainers" (default dict $cj.additionalContainers) -}}
  {{- $_ := set $root.Values "resources" (default dict $cj.resources) -}}
  {{- $_ := set $root.Values "securityContext" (default dict $cj.securityContext) -}}
  {{- $_ := set $root.Values "podSecurityContext" (default dict $cj.podSecurityContext) -}}
  {{- $_ := set $root.Values "podAnnotations" (default dict $cj.podAnnotations) -}}
  {{- $_ := set $root.Values "podLabels" (default dict $cj.podLabels) -}}
  {{- $_ := set $root.Values "lifecycle" (default dict $cj.lifecycle) -}}
  {{- $_ := set $root.Values "termination" (default dict $cj.termination) -}}
  {{- $_ := set $root.Values "nodeSelector" (default dict $cj.nodeSelector) -}}
  {{- $_ := set $root.Values "affinity" (default dict $cj.affinity) -}}
  {{- $_ := set $root.Values "tolerations" (default list $cj.tolerations) -}}

  {{- /* Force controller type to cronjob */ -}}
  {{- $_ := set $root.Values "controller" (dict "enabled" true "type" "cronjob" "labels" (default dict $cj.labels) "annotations" (default dict $cj.annotations)) -}}

  {{- /* Map cronjob scheduling fields into .Values.cronjob */ -}}
  {{- $cronjobSpec := dict
    "schedule" (required (printf "cronjobs.%s.schedule is required" $name) $cj.schedule)
    "concurrencyPolicy" (default "Allow" $cj.concurrencyPolicy)
    "successfulJobsHistoryLimit" (default 3 $cj.successfulJobsHistoryLimit)
    "failedJobsHistoryLimit" (default 1 $cj.failedJobsHistoryLimit)
    "restartPolicy" (default "OnFailure" $cj.restartPolicy)
    "backoffLimit" (default 6 $cj.backoffLimit)
  -}}
  {{- with $cj.startingDeadlineSeconds }}{{ $_ := set $cronjobSpec "startingDeadlineSeconds" . }}{{ end -}}
  {{- with $cj.timeZone }}{{ $_ := set $cronjobSpec "timeZone" . }}{{ end -}}
  {{- if kindIs "bool" $cj.suspend }}{{ $_ := set $cronjobSpec "suspend" $cj.suspend }}{{ end -}}
  {{- with $cj.activeDeadlineSeconds }}{{ $_ := set $cronjobSpec "activeDeadlineSeconds" . }}{{ end -}}
  {{- with $cj.ttlSecondsAfterFinished }}{{ $_ := set $cronjobSpec "ttlSecondsAfterFinished" . }}{{ end -}}
  {{- with $cj.parallelism }}{{ $_ := set $cronjobSpec "parallelism" . }}{{ end -}}
  {{- with $cj.completions }}{{ $_ := set $cronjobSpec "completions" . }}{{ end -}}
  {{- $_ := set $root.Values "cronjob" $cronjobSpec -}}

  {{- /* Disable service/probes — CronJobs don't expose ports */ -}}
  {{- $_ := set $root.Values "service" dict -}}
  {{- $_ := set $root.Values "probes" (dict "liveness" (dict "enabled" false) "readiness" (dict "enabled" false) "startup" (dict "enabled" false)) -}}

  {{- /* ---- Render the CronJob manifest ---- */ -}}
  {{- $fullName := include "common.names.fullname" $root }}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ printf "%s-%s" $fullName $name | trunc 63 | trimSuffix "-" }}
  {{- with (merge (default dict $cj.labels) (include "common.labels" $root | fromYaml)) }}
  labels:
    {{- toYaml . | nindent 4 }}
    app.kubernetes.io/component: {{ $name }}
  {{- end }}
  {{- with (merge (default dict $cj.annotations) (include "common.annotations" $root | fromYaml)) }}
  annotations: {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  schedule: {{ $cronjobSpec.schedule | quote }}
  {{- $concurrencyPolicy := $cronjobSpec.concurrencyPolicy }}
  {{- if not (has $concurrencyPolicy (list "Allow" "Forbid" "Replace")) }}
    {{- fail (printf "Not a valid cronjobs.%s.concurrencyPolicy (%s). Must be one of Allow, Forbid, Replace" $name $concurrencyPolicy) }}
  {{- end }}
  concurrencyPolicy: {{ $concurrencyPolicy }}
  successfulJobsHistoryLimit: {{ $cronjobSpec.successfulJobsHistoryLimit }}
  failedJobsHistoryLimit: {{ $cronjobSpec.failedJobsHistoryLimit }}
  {{- with $cronjobSpec.startingDeadlineSeconds }}
  startingDeadlineSeconds: {{ . }}
  {{- end }}
  {{- with $cronjobSpec.timeZone }}
  timeZone: {{ . | quote }}
  {{- end }}
  {{- if kindIs "bool" $cronjobSpec.suspend }}
  suspend: {{ $cronjobSpec.suspend }}
  {{- end }}
  jobTemplate:
    metadata:
      labels:
        {{- include "common.labels" $root | nindent 8 }}
        app.kubernetes.io/component: {{ $name }}
    spec:
      {{- with $cronjobSpec.backoffLimit }}
      backoffLimit: {{ . }}
      {{- end }}
      {{- with $cronjobSpec.activeDeadlineSeconds }}
      activeDeadlineSeconds: {{ . }}
      {{- end }}
      {{- with $cronjobSpec.ttlSecondsAfterFinished }}
      ttlSecondsAfterFinished: {{ . }}
      {{- end }}
      {{- with $cronjobSpec.parallelism }}
      parallelism: {{ . }}
      {{- end }}
      {{- with $cronjobSpec.completions }}
      completions: {{ . }}
      {{- end }}
      template:
        metadata:
          {{- with include ("common.podAnnotations") $root }}
          annotations:
            {{- . | nindent 12 }}
          {{- end }}
          labels:
            {{- include "common.labels.selectorLabels" $root | nindent 12 }}
            app.kubernetes.io/component: {{ $name }}
            {{- with $cj.podLabels }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
        spec:
          {{- $restartPolicy := $cronjobSpec.restartPolicy }}
          {{- if not (has $restartPolicy (list "OnFailure" "Never")) }}
            {{- fail (printf "Not a valid cronjobs.%s.restartPolicy (%s). Must be OnFailure or Never" $name $restartPolicy) }}
          {{- end }}
          restartPolicy: {{ $restartPolicy }}
          {{- include "common.controller.pod" $root | nindent 10 }}

  {{- /* ---- Restore original .Values fields ---- */ -}}
  {{- $_ := set $root.Values "image" $origImage -}}
  {{- $_ := set $root.Values "command" $origCommand -}}
  {{- $_ := set $root.Values "args" $origArgs -}}
  {{- $_ := set $root.Values "env" $origEnv -}}
  {{- $_ := set $root.Values "envFrom" $origEnvFrom -}}
  {{- $_ := set $root.Values "persistence" $origPersistence -}}
  {{- $_ := set $root.Values "initContainers" $origInitContainers -}}
  {{- $_ := set $root.Values "additionalContainers" $origAdditionalContainers -}}
  {{- $_ := set $root.Values "resources" $origResources -}}
  {{- $_ := set $root.Values "securityContext" $origSecurityContext -}}
  {{- $_ := set $root.Values "podSecurityContext" $origPodSecurityContext -}}
  {{- $_ := set $root.Values "controller" $origController -}}
  {{- $_ := set $root.Values "cronjob" $origCronjob -}}
  {{- $_ := set $root.Values "service" $origService -}}
  {{- $_ := set $root.Values "probes" $origProbes -}}
  {{- $_ := set $root.Values "podAnnotations" $origPodAnnotations -}}
  {{- $_ := set $root.Values "podLabels" $origPodLabels -}}
  {{- $_ := set $root.Values "lifecycle" $origLifecycle -}}
  {{- $_ := set $root.Values "termination" $origTermination -}}
  {{- $_ := set $root.Values "nodeSelector" $origNodeSelector -}}
  {{- $_ := set $root.Values "affinity" $origAffinity -}}
  {{- $_ := set $root.Values "tolerations" $origTolerations -}}
{{- end -}}
