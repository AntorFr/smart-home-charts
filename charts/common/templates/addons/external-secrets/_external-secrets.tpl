{{/*
External Secrets add-on: pulls secrets from a backend (e.g. OpenBao/Vault) via
the External Secrets Operator and injects them into the pod's containers.

It renders one ExternalSecret per group of keys, and auto-wires the consuming
container's envFrom to the materialized Secret, so a chart never has to
hand-write the ExternalSecret or coordinate the envFrom name.

Grouping exists because an ExternalSecret syncs ATOMICALLY: one missing remote
key fails the whole object, and every container depending on that Secret goes
down with it. Splitting per consumer confines the blast radius: a missing
sidecar key only leaves that sidecar without its Secret.

  - `data` is the DEFAULT group: materializes `<fullname>-secrets`, auto-wired
    into the main container's envFrom.
  - `groups.<name>.data` each materialize `<fullname>-<name>-secrets` with
    their own ExternalSecret. When `<name>` matches an `additionalContainers`
    entry, that container's envFrom is auto-wired to it.

Values:
  externalSecrets:
    enabled: true
    store: openbao-<cluster>        # SecretStore / ClusterSecretStore name
    storeKind: ClusterSecretStore   # default; use SecretStore for a namespaced one
    refreshInterval: 1h             # default
    data:                           # default group -> <fullname>-secrets (main container)
      ANTHROPIC_API_KEY: { key: llm/anthropic-antre, property: api_key }
      OIDC_CLIENT_SECRET: { key: oidc/merlin, property: client_secret }
    groups:                         # one extra ExternalSecret per group
      voice:                        # -> <fullname>-voice-secrets, auto-wired into
        data:                       #    additionalContainers.voice when it exists
          ESPHOME_NOISE_KEY: { key: home/esphome, property: api_key }
        # store / storeKind / refreshInterval: optional per-group overrides
        # (default: inherited from the externalSecrets block above)
*/}}

{{/* Mutate values BEFORE the controller renders: append each group's target
     Secret to its consumer's envFrom. optional:true avoids
     CreateContainerConfigError on first deploy, before ESO has had a chance to
     sync the Secret (self-heals once synced). */}}
{{- define "common.addon.externalSecrets" -}}
  {{- if .Values.externalSecrets.enabled -}}
    {{- $fullname := include "common.names.fullname" . -}}
    {{- if .Values.externalSecrets.data -}}
      {{- $ref := dict "secretRef" (dict "name" (printf "%s-secrets" $fullname) "optional" true) -}}
      {{- $envFrom := append (default (list) .Values.envFrom) $ref -}}
      {{- $_ := set .Values "envFrom" $envFrom -}}
    {{- end -}}
    {{- range $groupName, $group := (default dict .Values.externalSecrets.groups) -}}
      {{- $container := get (default dict $.Values.additionalContainers) $groupName -}}
      {{- if and $group.data $container -}}
        {{- $ref := dict "secretRef" (dict "name" (printf "%s-%s-secrets" $fullname $groupName) "optional" true) -}}
        {{- $envFrom := append (default (list) $container.envFrom) $ref -}}
        {{- $_ := set $container "envFrom" $envFrom -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/* One ExternalSecret object, WITHOUT a leading `---` and trimmed: the caller
     emits the document separator on its own line. Never rely on whitespace
     chomping to separate documents — a chomped trailing newline glues `---` to
     the previous line and YAML then merges both documents (duplicate keys, last
     one wins), silently dropping an object.
     Args: root (chart context), name (target Secret name), es (dict: store,
     storeKind, refreshInterval, data). */}}
{{- define "common.externalsecret.single" -}}
  {{- $root := .root -}}
  {{- $es := .es -}}
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: {{ .name }}
  labels: {{- include "common.labels" $root | nindent 4 }}
  annotations: {{- include "common.annotations" $root | nindent 4 }}
spec:
  refreshInterval: {{ $es.refreshInterval | default "1h" }}
  secretStoreRef:
    name: {{ required "externalSecrets.store is required when externalSecrets.enabled" $es.store }}
    kind: {{ $es.storeKind | default "ClusterSecretStore" }}
  target:
    name: {{ .name }}
    creationPolicy: Owner
  data:
    {{- range $secretKey, $remote := $es.data }}
    - secretKey: {{ $secretKey }}
      remoteRef:
        key: {{ required (printf "externalSecrets: %s.key is required" $secretKey) $remote.key }}
        {{- with $remote.property }}
        property: {{ . }}
        {{- end }}
    {{- end }}
{{- end -}}

{{/* The ExternalSecret objects materialized by the External Secrets Operator:
     one for the default group (`data`), one per named group (`groups`). Each
     document is emitted behind an explicit `---` line (see note above). */}}
{{- define "common.externalsecret" -}}
  {{- if .Values.externalSecrets.enabled -}}
    {{- $es := .Values.externalSecrets -}}
    {{- $fullname := include "common.names.fullname" . -}}
    {{- if $es.data }}
---
{{ include "common.externalsecret.single" (dict "root" . "name" (printf "%s-secrets" $fullname) "es" $es) | trim }}
    {{- end }}
    {{- range $groupName, $group := (default dict $es.groups) }}
      {{- if $group.data }}
        {{- $merged := dict
              "store" (default $es.store $group.store)
              "storeKind" (default $es.storeKind $group.storeKind)
              "refreshInterval" (default $es.refreshInterval $group.refreshInterval)
              "data" $group.data }}
---
{{ include "common.externalsecret.single" (dict "root" $ "name" (printf "%s-%s-secrets" $fullname $groupName) "es" $merged) | trim }}
      {{- end }}
    {{- end }}
  {{- end -}}
{{- end -}}
