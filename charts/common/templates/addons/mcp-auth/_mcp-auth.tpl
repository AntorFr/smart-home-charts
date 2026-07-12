{{/*
Template to render the mcp-auth addon: wires an OAuth proxy sidecar in front of
the main MCP container. It injects the proxy container, routes the primary
service port to the proxy, and provisions the proxy's /data volume (which holds
the DCR-registered clients and sessions — must persist so callers keep their
"one login for life" token across pod restarts).
*/}}
{{- define "common.addon.mcpAuth" -}}
{{- if .Values.addons.mcpAuth.enabled -}}
  {{- $a := .Values.addons.mcpAuth -}}

  {{/* Inject the proxy container into additionalContainers. */}}
  {{- $container := include "common.addon.mcpAuth.container" . | fromYaml -}}
  {{- if $container -}}
    {{- $_ := set .Values.additionalContainers "addon-mcp-auth" $container -}}
  {{- end -}}

  {{/* Route the primary service port to the proxy instead of the app. */}}
  {{- if .Values.service.main -}}
    {{- range $pname, $port := .Values.service.main.ports -}}
      {{- if $port.primary -}}
        {{- $_ := set $port "targetPort" $a.listenPort -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{/* Provision the /data volume for the proxy. hostPath persists DCR
       clients+sessions; empty hostPath falls back to an ephemeral emptyDir. */}}
  {{- if $a.persistence.hostPath -}}
    {{- $vol := dict "enabled" "true" "mountPath" "-" "type" "hostPath" "hostPath" $a.persistence.hostPath -}}
    {{- $_ := set .Values.persistence "mcpauth-data" $vol -}}
    {{/* hostPath is root-owned on creation; chown it to the proxy's uid. */}}
    {{- $initName := "mcp-auth-perms" -}}
    {{- $init := dict
        "image" $a.initImage
        "securityContext" (dict "runAsNonRoot" false "runAsUser" 0 "runAsGroup" 0)
        "command" (list "sh" "-c" (printf "chown -R %d:%d /data && chmod -R u+rwX /data" (int $a.runAsUser) (int $a.runAsUser)))
        "volumeMounts" (list (dict "name" "mcpauth-data" "mountPath" "/data")) -}}
    {{- $_ := set .Values.initContainers $initName $init -}}
  {{- else -}}
    {{- $vol := dict "enabled" "true" "mountPath" "-" "type" "emptyDir" -}}
    {{- $_ := set .Values.persistence "mcpauth-data" $vol -}}
  {{- end -}}
{{- end -}}
{{- end -}}
