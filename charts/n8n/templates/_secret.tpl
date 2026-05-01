{{/* Define n8n secret values */}}
{{- define "n8n.secret" -}}
{{- $secretName := include "common.names.fullname" . -}}
{{- $existingSecret := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- $existingKey := "" -}}
{{- if $existingSecret -}}
  {{- $existingKey = (index $existingSecret.data "N8N_ENCRYPTION_KEY" | default "" | b64dec) -}}
{{- end -}}
N8N_ENCRYPTION_KEY: {{ default (randAlphaNum 64) $existingKey | quote }}
{{- end -}}