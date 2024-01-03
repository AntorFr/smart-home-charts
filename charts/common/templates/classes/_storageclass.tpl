{{/*
This template serves as a blueprint for storage class objects that are created
using the common library.
*/}}
{{- define "common.classes.storageclass" -}}
{{- $values := .Values.storageclass -}}
{{- if hasKey . "ObjectValues" -}}
  {{- with .ObjectValues.storageclass -}}
    {{- $values = . -}}
  {{- end -}}
{{ end -}}
{{- $storageclassName := include "common.names.fullname" . -}}
{{- if and (hasKey $values "nameOverride") $values.nameOverride -}}
  {{- if not (eq $values.nameOverride "-") -}}
    {{- $storageclassName = printf "%v-%v" $storageclassName $values.nameOverride -}}
  {{ end -}}
{{ end }}
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: {{ $storageclassName }}
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
    {{- if $values.retain }}
    "helm.sh/resource-policy": keep
    {{- end }}
    {{- with (merge ($values.annotations | default dict) (include "common.annotations" $ | fromYaml)) }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
provisioner: {{ required (printf "provisioner is required for Storage Class %v" $storageclassName) $values.provisioner | quote }}
{{- if $values.retain -}}
reclaimPolicy: Retain 
{{- end }}
allowVolumeExpansion: true
volumeBindingMode: Immediate
parameters:
  {{- if $values.fstype -}}
  fstype: {{ $values.fstype | quote }}
  {{- end -}}
  {{- if $values.poolname -}}
  poolname: {{ $values.poolname | quote }}
  {{- end -}}
  shared: 'yes'
{{- end -}}




