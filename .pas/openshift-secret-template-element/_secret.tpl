{{/* PAS OpenShift Secret resource template */}}
{{- define "secret" }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ .name }}
type: Opaque
{{- if .data }}
data:
  {{ .data }}
{{- end }}
{{- if .stringData }}
stringData:
  {{- range $key, $val := .stringData }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
{{- end }}
{{- end }}
