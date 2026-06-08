{{/* Define Fleet for ESPHome secret values */}}
{{- define "fleet-for-esphome.secret" -}}
{{- $secretName := include "common.names.fullname" . -}}
{{- $existingSecret := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- $existingToken := "" -}}
{{- if $existingSecret -}}
  {{- $existingToken = (index $existingSecret.data "SERVER_TOKEN" | default "" | b64dec) -}}
{{- end -}}
SERVER_TOKEN: {{ default (randAlphaNum 64) $existingToken | quote }}
{{- end -}}
