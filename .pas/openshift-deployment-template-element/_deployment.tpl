{{/* PAS OpenShift Deployment resource template */}}
{{- define "deployment" }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .name }}
  labels:
    compound: {{ .compoundName }}
    version: {{ .compoundVersion }}
    {{- range $key, $val := .labels }}
    {{ $key }}: {{ $val | quote }}
    {{- end }}
spec:
  replicas: {{ .replicaCount }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: '{{ .maxUnavailablePercent }}%'
  selector:
    matchLabels:
      compound: {{ .compoundName }}
      version: {{ .compoundVersion }}
      {{- range $key, $val := .labels }}
      {{ $key }}: {{ $val | quote }}
      {{- end }}
  template:
    metadata:
      labels:
        compound: {{ .compoundName }}
        version: {{ .compoundVersion }}
        {{- range $key, $val := .labels }}
        {{ $key }}: {{ $val | quote }}
        {{- end }}
    spec:
      containers:
        - name: {{ .compoundName }}
          image: {{ .imageName }}
          env:
            {{- range $index, $item := .env }}
            - name: {{ $item.name }}
              value: {{ $item.value }}
            {{- end }}
            {{- range $index, $item := .envFromSecrets }}
            - name: {{ $item.name }}
              valueFrom:
                secretKeyRef:
                  name: {{ $item.secretKeyRefName }}
                  key: {{ $item.secretKeyRefKey }}
            {{- end }}
          volumeMounts:
            - name: docker-graph-storage
              mountPath: /var/lib/docker
            - name: docker-socket-volume
              mountPath: /var/run/docker.sock
          {{- if .preStopCommand }}
          lifecycle:
            preStop:
              exec:
                command:
                  - {{ .preStopCommand }}
          {{- end }}
      volumes:
        - name: docker-graph-storage
          emptyDir: {}
        - name: docker-socket-volume
          hostPath:
            path: /var/run/docker.sock
{{- end }}
