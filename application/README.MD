# Template Pipeline Application Example
---
## Overview
This is an application pipline template with an example of a dockerized dotNet web application running through Helm being deployed to Kubernetes. The `pipeline.yaml` to be referenced is within the `example-app` folder. 

---
## Requirements 
- Variable groups should be set for Twistlock ID & Password. (ADO Library)
- Variable groups should be set for `Azure Container Registry` access. (ADO Library)  
- Helm is required.
- An `Azure Container Registry` is required. 
- An `Azure Resource Manager` is required.
- An `Azure Service Principal` is required.  
---
## Instructions
- Create or request access to the required resources.
- Create a Dockerfile for your application.
- Fill in variables where necessary on `pipeline.yaml`.
- Fill in paramaters where necessary on  `pipeline.yaml`.
- Create a `Helm Chart` and modify contents.
- Run the `pipeline.yaml`.
---
## Helm 
- A Helm Chart must be created. To do this, Helm must be installed. Documentation links for this are provided below.
- `Chart.yaml` and `values.yaml` should be updated to reflect required application data and desired parameters.
---
## Parameters
#### for `docker-build` template : 
- `build_context` : refers to the application directory.
- `container_registry` : refers to the name of the `Azure Container Registry`.
- `acr_url` : refers to the full `Azure Container Registry` login url.
- `docker_repository` : docker image name.
- `dockerfile_path` : points to the dockerfile for the application.
- `tag` : desired tag.
- `risk_profile` : refering to `risk_profile` (will likely remain the same as example).
- `twistlock_id` : reffering to twislock id being pulled from variable group. 
- `twistlock_password`: reffering to twistlock password being pulled from variable group.
#### for `helm-build` template :
- `azure_subscription_endpoint`: refers to the `Azure Resource Manager` service connection. 
- `azure_resrouce_group` : refers to the name of the `Azure Resource Group` holding the AKS cluster. 
- `chart_path` : points to the Helm Chart in the application directory. 
- `chart_name` : app-name including version.
- `chart_version` : expects version.   
- `azure_container_registry` : refers to `Azure Container Registry`.
#### for `helm-deploy` template : 
- `kubernetes_service_endpoint` : name for the k8s cluster.
- `azure_resource_group` : refers to the `Azure Resource Group` holding the cluster.
- `kubernetes_clulster` : name of the AKS cluster.
- `chart_name` : expects chart name.
- `chart_version` : expects version. 
- `release_name` : expects release name.
- `azure_container_registry` : refers to the `Azure Container Registry`.
- `acr_username` : reffering to ARM ID set in variable group. 
- `acr_password` : reffering to ARM Password set in the variable group.
- `acr_tenant` : reffering to Azure Tenant set in the variable group.
---
## Documentation
### creating variable groups
https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml
### creating a resource manager and service connection
https://docs.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops
### dockerising an application (dotNet)
https://docs.microsoft.com/en-us/dotnet/core/docker/build-container?tabs=windows
### installing helm
https://helm.sh/docs/intro/install/
### createing a helm chart
https://helm.sh/docs/helm/helm_create/


