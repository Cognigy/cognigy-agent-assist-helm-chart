# Cognigy Agent Assist Helm Chart

Cognigy Agent Assist offers a variety of advanced features that empower agents to provide faster and more accurate customer support.

## Prerequisites

- Kubernetes v1.19-1.24 running on either:
  - AWS EKS
  - Azure AKS
  - "generic" on-premises kubernetes platform. Running Cognigy Agent Assist on-premises will require additional manual steps, we recommend to use public clouds (AWS or Azure) instead.
- kubectl utility connected to the kubernetes cluster
- Helm 3.8.0+
- MongoDB Helm chart installed in the same cluster. Here is the [setup guide](https://github.com/Cognigy/cognigy-mongodb-helm-chart)
- Cognigy.AI Helm chart installed in the same cluster. Here is the [setup guide](https://github.com/Cognigy/cognigy-ai-helm-chart)
- For using Cognigy Live Agent with Cognigy Agent Assist, its Helm chart needs to be installed in the same cluster. Here is the [setup guide](https://docs.cognigy.com/live-agent/installation/deployment/installation-using-helm/)

## Configuration

To deploy a new Cognigy Agent Assist setup you need to create a separate file with Helm release values. You can use `values_prod.yaml` as a baseline, we recommend to start with it:

1. Make a copy of `values_prod.yaml` into a new file and name it accordingly, we refer to it as `YOUR_VALUES_FILE.yaml` later in this document.
2. **Do not make** a copy of default `values.yaml` file as it contains hardcoded docker images references for all microservices, and in this case you will need to change all of them manually during upgrades. However, you can add some variables from default `values.yaml` file into your customized `YOUR_VALUES_FILE.yaml` later on, e.g. for tweaking CPU/RAM resources of Cognigy Agent Assist microservices. We describe this process later in the document.

### Setting Essential Parameters

You need to set at least following parameters in `YOUR_VALUES_FILE.yaml`:

1. Cognigy Image repository credentials: set `imageCredentials.username` and `imageCredentials.password` accordingly.
2. MongoDB root credentials: set `mongodb.auth` `username` and `password` to `rootUser` and `rootPassword` values of MongoDB helm release created before.

### Installing the Chart

1. Download chart dependencies:

```bash
helm dependency update
```

2. Install Cognigy Agent Assist Helm release:

- Installing from Cognigy Container Registry (recommended), specify proper `HELM_CHART_VERSION` and `YOUR_VALUES_FILE.yaml`:
  - Login into Cognigy helm registry (provide your Cognigy Container Registry credentials):
  ```
  helm registry login cognigy.azurecr.io \
  --username <your-username> \
  --password <your-password>
  ```
  - Install Helm Chart into a separate `agent-assist` namespace:
  ```
  helm upgrade --install --namespace agent-assist cognigy-agent-assist oci://cognigy.azurecr.io/helm/agent-assist --version HELM_CHART_VERSION --values YOUR_VALUES_FILE.yaml --create-namespace
  ```
- Alternatively you can install it from the local chart (not recommended):
  ```
  helm upgrade --install --namespace agent-assist --values YOUR_VALUES_FILE.yaml cognigy-agent-assist .
  ```

3. Verify that all pods are in a ready state:

```
kubectl get pods --namespace agent-assist
```

Try to access the Agent Assist Workspace frontend URL, it should be available at `AGENT_ASSIST_WORKSPACE_FRONTEND_URL_WITH_PROTOCOL` value defined in `YOUR_VALUES_FILE.yaml`.

The URL needs to provide fake parameters for `sessionId`, `userId`, `URLToken`, `organisationId`, `projectId` and `configId` query parameters, e.g.:

`https://<agent-assist-url>/?sessionId=test&userId=test&URLToken=test&organisationId=test&projectId=test&configId=test`

### Upgrading Helm Release

To upgrade Cognigy Agent Assist platform to a newer version, you need to upgrade the existing Helm release to a particular `HELM_CHART_VERSION`, for this execute:

```bash
helm upgrade --namespace agent-assist cognigy-agent-assist oci://cognigy.azurecr.io/helm/agent-assist --version HELM_CHART_VERSION --values YOUR_VALUES_FILE.yaml
```

### Modifying Resources

Default resources for Cognigy Agent Assist microservices specified in `values.yaml` are tailored to provide consistent performance for typical production use-cases. However, to meet particular demands, you can modify RAM/CPU resources or number of replicas for separate microservices in your Cognigy Agent Assist installation. For this you need to copy specific variables from default `values.yaml` into `YOUR_VALUES_FILE.yaml` for a particular microservice and adjust the `Request/Limits` and `replica` values accordingly.

**IMPORTANT:** Do not copy `image` value as you will need to modify it manually during upgrades!

For example, for `backend` microservice copy from `values.yaml` and adjust in `YOUR_VALUES_FILE.yaml` following variables:

```
backend:
  replica: 1
  resources:
    requests:
      cpu: '0.4'
      memory: 400M
    limits:
      cpu: '0.4'
      memory: 500M
```

### Cognigy.AI integration

#### Cognigy.AI Endpoint URL

The `COGNIGY_AI_ENDPOINT_URL_WITH_PROTOCOL` value needs to point to the `cognigy-ai` service-endpoint ingress URL. This value is used by the Agent Assist Workspace backend to connect to Cognigy.AI. The value can be checked in the `cognigy-ai` Helm chart deployment file.

#### Cognigy.AI Endpoint Access Token Secret

The `cognigyServiceEndpointApiAccessToken.existingSecret` value is for generating a secret that is used to authenticate the Agent Assist Workspace API with Cognigy.AI. This secret is the Cognigy.AI service-endpoint `SERVICE_ENDPOINT_API_ACCESS_TOKEN` environment variable value. The environment variable used by the Agent Assist Workspace backend is `COGNIGY_AI_ENDPOINT_ACCESS_TOKEN` that can be checked in its deployment file.

```yaml
# custom-values.yaml
cognigyServiceEndpointApiAccessToken:
  existingSecret: cognigy-service-endpoint-api-access-token
```

You can use the following command to get the value of the `SERVICE_ENDPOINT_API_ACCESS_TOKEN` environment variable:

```bash
kubectl get secret --namespace cognigy-ai cognigy-service-endpoint-api-access-token -o jsonpath="{.data.api-access-token}" | base64 -d
```

#### Cognigy.AI Handover Access Token Secret

The `cognigyServiceHandoverApiAccessToken.existingSecret` value is for generating a secret that is used to authenticate the Agent Assist Workspace API with Cognigy.AI. This secret is the Cognigy.AI service-handover `SERVICE_HANDOVER_API_ACCESS_TOKEN` environment variable value. The environment variable used by the Agent Assist Workspace backend is `COGNIGY_AI_HANDOVER_ACCESS_TOKEN` that can be checked in its deployment file.

```yaml
# custom-values.yaml
cognigyServiceHandoverApiAccessToken:
  existingSecret: cognigy-service-handover-api-access-token
```

You can use the following command to get the value of the `SERVICE_HANDOVER_API_ACCESS_TOKEN` environment variable:

```bash
kubectl get secret --namespace cognigy-ai cognigy-service-handover-api-access-token -o jsonpath="{.data.api-access-token}" | base64 -d
```

#### Cognigy.AI Helm chart Modifications

The following values are required to be filled in order to integrate with Cognigy.AI Helm chart values:

```yaml
# custom-values.yaml
cognigyEnv:
  # * means all organizations are allowed to be used in Agent Assist, otherwise specify a list of allowed organization IDs "org-id-1,org-id-2"
  FEATURE_ENABLE_AGENT_ASSIST_WORKSPACE_WHITELIST: "*"
  AGENT_ASSIST_WORKSPACE_FRONTEND_URL_WITH_PROTOCOL: https://agent-assist.test
  AGENT_ASSIST_WORKSPACE_API_BASE_URL_WITH_PROTOCOL: https://api-agent-assist.test
```

#### Agent Assist API Access Token for Cognigy.AI services

Assuming that Agent Assist is deployed on a production cluster with the `values.yaml` existing secrets filled, there is a need to create a new secret in the `cognigy-ai` namespace containing the `apiKey.existingSecret` value defined in the Cognigy Agent Assist Helm chart `values.yaml` file. Once the secret is created, it needs to be added into the cognigy-ai helm chart values for the services like this:

```yaml
serviceAi:
  # ...
  extraEnvVars:
    # ...
    - name: AGENT_ASSIST_WORKSPACE_API_ACCESS_TOKEN
      valueFrom:
        secretKeyRef:
          name: cognigy-agent-assist-workspace-credentials
          key: api-access-token

serviceEndpoint:
  # ...
  extraEnvVars:
    # ...
    - name: AGENT_ASSIST_WORKSPACE_API_ACCESS_TOKEN
      valueFrom:
        secretKeyRef:
          name: cognigy-agent-assist-workspace-credentials
          key: api-access-token

serviceHandover:
  # ...
  extraEnvVars:
    # ...
    - name: AGENT_ASSIST_WORKSPACE_API_ACCESS_TOKEN
      valueFrom:
        secretKeyRef:
          name: cognigy-agent-assist-workspace-credentials
          key: api-access-token
```

### Live Agent integration (optional)

To integrate Cognigy Agent Assist with Live Agent, you need to provide following values in the Live Agent Helm Chart `custom-values.yaml` file:

```yaml
configmap:
  #...
  FEATURE_USE_AGENT_ASSIST_WORKSPACE: "true"
```

And perform a helm upgrade as per the [Live Agent Helm Chart documentation](https://docs.cognigy.com/live-agent/installation/deployment/installation-updates/).

### Do testing without installing the Helm chart

#### Testing linting

Run the following command to test the linting:

        `helm lint ./`

#### Testing templates generation

Run the following command to test the templates generation:

        `helm template ./`
