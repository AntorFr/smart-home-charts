{{- define "kurrier.envSecretName" -}}
{{- if .Values.envFile.existingSecret -}}
{{- .Values.envFile.existingSecret -}}
{{- else -}}
{{- default (printf "%s-env" (include "common.names.fullname" .)) .Values.envFile.nameOverride -}}
{{- end -}}
{{- end -}}

{{- define "kurrier.profile" -}}
{{- $profiles := .Values.compatibility.profiles | default dict -}}
{{- $profileName := .Values.compatibility.profile | default "" -}}
{{- (get $profiles $profileName | default dict) | toYaml -}}
{{- end -}}

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

{{- define "kurrier.resolveTag" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $explicit := .explicit | default "" -}}
{{- $profile := (include "kurrier.profile" $root | fromYaml) | default dict -}}
{{- $expected := dig "images" $component "tag" "" $profile -}}
{{- if and $root.Values.compatibility.strict (ne $explicit "") (ne $expected "") (ne $explicit $expected) -}}
{{- fail (printf "compatibility.strict=true: component '%s' tag '%s' differs from profile '%s' tag '%s'" $component $explicit $root.Values.compatibility.profile $expected) -}}
{{- end -}}
{{- if ne $explicit "" -}}
{{- $explicit -}}
{{- else -}}
{{- $expected -}}
{{- end -}}
{{- end -}}

{{- define "kurrier.stack.serviceName" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- printf "%s-%s" (include "common.names.fullname" $root) $name -}}
{{- end -}}

{{- define "kurrier.stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common.names.fullname" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .name }}
{{- end -}}

{{- define "kurrier.stack.commonLabels" -}}
{{ include "common.labels" .root }}
app.kubernetes.io/component: {{ .name }}
{{- end -}}
