{{/*
The mcp-auth sidecar container: an OAuth 2.1 proxy (sigbit/mcp-auth-proxy) put
in front of an MCP server that has no native auth. It federates to an OIDC
provider and only forwards requests once the caller holds a valid token.
*/}}
{{- define "common.addon.mcpAuth.container" -}}
{{- $a := .Values.addons.mcpAuth -}}
name: mcp-auth
image: "{{ $a.image.repository }}:{{ $a.image.tag }}"
imagePullPolicy: {{ $a.image.pullPolicy }}
args:
  - "http://localhost:{{ $a.backendPort }}"
env:
  # LISTEN is set explicitly: the pod usually runs as non-root, which forbids
  # binding ports below 1024 (the proxy defaults to :80).
  - name: LISTEN
    value: ":{{ $a.listenPort }}"
  - name: EXTERNAL_URL
    value: {{ required "addons.mcpAuth.externalUrl is required" $a.externalUrl | quote }}
  # TLS is terminated upstream (ingress); the proxy serves plain HTTP.
  - name: NO_AUTO_TLS
    value: "1"
  - name: OIDC_CONFIGURATION_URL
    value: {{ $a.oidc.configurationUrl | quote }}
  - name: OIDC_CLIENT_ID
    value: {{ required "addons.mcpAuth.oidc.clientId is required" $a.oidc.clientId | quote }}
  - name: OIDC_CLIENT_SECRET
    value: {{ required "addons.mcpAuth.oidc.clientSecret is required" $a.oidc.clientSecret | quote }}
  - name: OIDC_PROVIDER_NAME
    value: {{ $a.oidc.providerName | quote }}
  # groups MUST be in the scopes or the provider omits the groups claim and the
  # attribute filter below rejects everyone.
  - name: OIDC_SCOPES
    value: {{ $a.oidc.scopes | quote }}
  {{- with $a.oidc.allowedAttributes }}
  - name: OIDC_ALLOWED_ATTRIBUTES
    value: {{ . | quote }}
  {{- end }}
  {{- with $a.oidc.allowedUsers }}
  - name: OIDC_ALLOWED_USERS
    value: {{ . | quote }}
  {{- end }}
  {{- range $k, $v := $a.extraEnv }}
  - name: {{ $k }}
    value: {{ $v | quote }}
  {{- end }}
{{- with $a.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
volumeMounts:
  - name: mcpauth-data
    mountPath: /data
{{- with $a.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
