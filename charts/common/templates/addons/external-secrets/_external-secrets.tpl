{{/*
External Secrets add-on: pulls secrets from a backend (e.g. OpenBao/Vault) via
the External Secrets Operator and injects them into the main container.

It renders an ExternalSecret that materializes a Secret named
`<fullname>-secrets`, and auto-wires the container's envFrom to that Secret, so a
chart never has to hand-write the ExternalSecret or coordinate the envFrom name.

Values:
  externalSecrets:
    enabled: true
    store: openbao-<app>            # SecretStore / ClusterSecretStore name
    storeKind: ClusterSecretStore   # default; use SecretStore for a namespaced one
    refreshInterval: 1h             # default
    data:
      ANTHROPIC_API_KEY: { key: llm/anthropic-antre, property: api_key }
      OIDC_CLIENT_SECRET: { key: oidc/merlin, property: client_secret }
*/}}

{{/* Mutate values BEFORE the controller renders: append the target Secret to
     envFrom. optional:true avoids CreateContainerConfigError on first deploy,
     before ESO has had a chance to sync the Secret (self-heals once synced). */}}
{{- define "common.addon.externalSecrets" -}}
  {{- if .Values.externalSecrets.enabled -}}
    {{- $name := printf "%s-secrets" (include "common.names.fullname" .) -}}
    {{- $ref := dict "secretRef" (dict "name" $name "optional" true) -}}
    {{- $envFrom := append (default (list) .Values.envFrom) $ref -}}
    {{- $_ := set .Values "envFrom" $envFrom -}}
  {{- end -}}
{{- end -}}

{{/* The ExternalSecret object materialized by the External Secrets Operator. */}}
{{- define "common.externalsecret" -}}
  {{- if .Values.externalSecrets.enabled -}}
    {{- $es := .Values.externalSecrets -}}
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: {{ include "common.names.fullname" . }}-secrets
  labels: {{- include "common.labels" $ | nindent 4 }}
  annotations: {{- include "common.annotations" $ | nindent 4 }}
spec:
  refreshInterval: {{ $es.refreshInterval | default "1h" }}
  secretStoreRef:
    name: {{ required "externalSecrets.store is required when externalSecrets.enabled" $es.store }}
    kind: {{ $es.storeKind | default "ClusterSecretStore" }}
  target:
    name: {{ include "common.names.fullname" . }}-secrets
    creationPolicy: Owner
  data:
    {{- range $secretKey, $remote := $es.data }}
    - secretKey: {{ $secretKey }}
      remoteRef:
        key: {{ required (printf "externalSecrets.data.%s.key is required" $secretKey) $remote.key }}
        {{- with $remote.property }}
        property: {{ . }}
        {{- end }}
    {{- end }}
  {{- end -}}
{{- end -}}
