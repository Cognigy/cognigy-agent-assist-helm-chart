{{/*
Expand the name of the chart.
*/}}
{{- define "agent-assist.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "agent-assist.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Backend full name
*/}}
{{- define "agent-assist-backend.fullname" -}}
{{ include "agent-assist.fullname" . }}-backend
{{- end }}

{{/*
Frontend full name
*/}}
{{- define "agent-assist-frontend.fullname" -}}
{{ include "agent-assist.fullname" . }}-frontend
{{- end }}

{{/*
Test API Bridge full name
*/}}
{{- define "agent-assist-test-api-bridge.fullname" -}}
{{ include "agent-assist.fullname" . }}-test-api-bridge
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "agent-assist.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "agent-assist.labels" -}}
helm.sh/chart: {{ include "agent-assist.chart" . }}
{{ include "agent-assist.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "agent-assist.selectorLabels" -}}
app.kubernetes.io/name: {{ include "agent-assist.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "grafana.ingress.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "networking.k8s.io/v1") (semverCompare ">= 1.19-0" .Capabilities.KubeVersion.Version) -}}
      {{- print "networking.k8s.io/v1" -}}
  {{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" -}}
    {{- print "networking.k8s.io/v1beta1" -}}
  {{- else -}}
    {{- print "extensions/v1beta1" -}}
  {{- end -}}
{{- end -}}

{{/*
Return if ingress is stable.
*/}}
{{- define "grafana.ingress.isStable" -}}
  {{- eq (include "grafana.ingress.apiVersion" .) "networking.k8s.io/v1" -}}
{{- end -}}

{{/*
Return if ingress supports pathType.
*/}}
{{- define "grafana.ingress.supportsPathType" -}}
  {{- or (eq (include "grafana.ingress.isStable" .) "true") (and (eq (include "grafana.ingress.apiVersion" .) "networking.k8s.io/v1beta1") (semverCompare ">= 1.18-0" .Capabilities.KubeVersion.Version)) -}}
{{- end -}}

{{/*
Return the proper mongodb credentials Secret Name
*/}}
{{- define "mongodbCredentials.secretName.render" -}}
  {{- $mongodbCredentialsSecretName := "" -}}

  {{- if .Values.mongodb.auth.existingSecret -}}
    {{- $mongodbCredentialsSecretName = .Values.mongodb.auth.existingSecret -}}
  {{- else -}}
    {{- $mongodbCredentialsSecretName = "mongodb-connection-creds" -}}
  {{- end -}}

  {{- printf "%s" (tpl $mongodbCredentialsSecretName $) -}}
{{- end -}}

{{- define "connectionString.mongodb" -}}
{{- .mongodbScheme }}://{{- .serviceName -}}:{{- .pw -}}@{{- .mongodbHosts -}}/{{- .serviceName -}}{{- .mongodbParams }}
{{- end }}

{{/*
Return the proper mongodb Atlas credentials Secret Name
*/}}
{{- define "mongodbAtlasCredentials.secretName.render" -}}
  {{- $mongodbAtlasCredentialsSecretName := "" -}}

  {{- if .Values.mongodb.auth.atlas.existingSecret -}}
    {{- $mongodbAtlasCredentialsSecretName = .Values.mongodb.auth.atlas.existingSecret -}}
  {{- else -}}
    {{- $mongodbAtlasCredentialsSecretName = "mongodb-atlas-creds" -}}
  {{- end -}}

  {{- printf "%s" (tpl $mongodbAtlasCredentialsSecretName $) -}}
{{- end -}}


{{/*
Set redis fullname
*/}}
{{- define "agent-assist.redis.fullname" -}}
{{- if .Values.redis.fullnameOverride -}}
{{- .Values.redis.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.redis.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Set redis port
*/}}
{{- define "agent-assist.redis.port" -}}
{{- if .Values.redis.enabled -}}
    6379
{{- else -}}
{{- default 6379 .Values.redis.port -}}
{{- end -}}
{{- end -}}

{{/*
Set redis host
*/}}
{{- define "agent-assist.redis.host" -}}
{{- if and (.Values.redis.enabled) (.Values.redis.sentinel.enabled) -}}
{{- template "agent-assist.redis.fullname" . -}}
{{- else if .Values.redis.enabled -}}
{{- template "agent-assist.redis.fullname" . -}}-master
{{- else -}}
{{- .Values.redis.host -}}
{{- end -}}
{{- end -}}

{{/*
Set the backend api key secret
*/}}
{{- define "agent-assist.backend.apiKey" -}}
{{- if .Values.backend.apiKey.existingSecret -}}
  {{- .Values.backend.apiKey.existingSecret | quote -}}
{{- else -}}
  "agent-assist-api-key"
{{- end -}}
{{- end -}}

{{/*
Set the service-endpoint api key secret
*/}}
{{- define "agent-assist.backend.cognigyServiceEndpointApiAccessToken" -}}
{{- if .Values.backend.cognigyServiceEndpointApiAccessToken.existingSecret -}}
  {{- .Values.backend.cognigyServiceEndpointApiAccessToken.existingSecret | quote -}}
{{- else -}}
  "cognigy-service-endpoint-api-access-token"
{{- end -}}
{{- end -}}

{{/*
Set the service-handover api key secret
*/}}
{{- define "agent-assist.backend.cognigyServiceHandoverApiAccessToken" -}}
{{- if .Values.backend.cognigyServiceHandoverApiAccessToken.existingSecret -}}
  {{- .Values.backend.cognigyServiceHandoverApiAccessToken.existingSecret | quote -}}
{{- else -}}
  "cognigy-service-handover-api-access-token"
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "image.pullSecrets" -}}
  {{- $pullSecrets := list -}}

  {{- if and (.Values.imageCredentials.registry) (.Values.imageCredentials.username) (.Values.imageCredentials.password) -}}
      {{- $pullSecrets = append $pullSecrets "cognigy-registry-token" -}}
  {{- else if .Values.imageCredentials.pullSecrets -}}
    {{- range .Values.imageCredentials.pullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- else -}}
    {{ required "A valid value for .Values.imageCredentials is required!" .Values.imageCredentials.registry }}
    {{ required "A valid value for .Values.imageCredentials is required!" .Values.imageCredentials.username }}
    {{ required "A valid value for .Values.imageCredentials is required!" .Values.imageCredentials.password }}
    {{ required "A valid value for .Values.imageCredentials is required!" .Values.imageCredentials.pullSecrets }}
  {{- end -}}

  {{- if (not (empty $pullSecrets)) -}}
imagePullSecrets:
    {{- range $pullSecrets }}
  - name: {{ . }}
    {{- end -}}
  {{- end -}}
{{- end -}}