{{- define "kurrier.envSecretName" -}}
{{- if .Values.envFile.existingSecret -}}
{{- .Values.envFile.existingSecret -}}
{{- else -}}
{{- default (printf "%s-env" (include "common.names.fullname" .)) .Values.envFile.nameOverride -}}
{{- end -}}
{{- end -}}

{{/* Extract the value of an env key from the compose-style envFile content. */}}
{{- define "kurrier.envValue" -}}
{{- $key := .key -}}
{{- $content := .content | default "" -}}
{{- $value := "" -}}
{{- range $line := splitList "\n" $content -}}
	{{- $trimmed := trim $line -}}
	{{- if and $trimmed (not (hasPrefix "#" $trimmed)) (hasPrefix (printf "%s=" $key) $trimmed) -}}
		{{- $parts := regexSplit "=" $trimmed 2 -}}
		{{- if eq (len $parts) 2 -}}
			{{- $value = (index $parts 1 | trim) -}}
		{{- end -}}
	{{- end -}}
{{- end -}}
{{- $value -}}
{{- end -}}

{{/* Extract the password from a postgresql://user:password@host:port/db URL. */}}
{{- define "kurrier.urlPassword" -}}
{{- $url := . | default "" -}}
{{- if regexMatch "^[a-z+]+://[^:/@]+:[^@]+@" $url -}}
{{- regexReplaceAll "^[a-z+]+://[^:/@]+:([^@]+)@.*$" $url "${1}" -}}
{{- end -}}
{{- end -}}

{{/* Image tag for a stack component: explicit tag or the root image.tag. */}}
{{- define "kurrier.stackTag" -}}
{{- $tag := default .root.Values.image.tag .explicit -}}
{{- if not $tag -}}
{{- fail (printf "no image tag for stack component '%s': set stack.services.%s.image.tag or image.tag" .name .name) -}}
{{- end -}}
{{- $tag -}}
{{- end -}}

{{- define "kurrier.stack.serviceName" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- printf "%s-%s" (include "common.names.fullname" $root) $name -}}
{{- end -}}

{{- define "kurrier.stack.selectorLabels" -}}
{{/* name must be per-service: the common/web service selects on
     app.kubernetes.io/name+instance only, so stack pods sharing the release
     name would also receive web traffic. */}}
app.kubernetes.io/name: {{ include "kurrier.stack.serviceName" (dict "root" .root "name" .name) }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .name }}
{{- end -}}

{{- define "kurrier.stack.commonLabels" -}}
{{ include "common.labels" .root }}
app.kubernetes.io/component: {{ .name }}
{{- end -}}
