# HELM PIPELINE TEMPLATE : HELM
---
## Overview
This is directory contains two helm templates `helm-build.yaml` and `helm-deploy.yaml`

---
## Requirements :
- Helm Version `3.6.3` is required for `helm-build` to function as expected. Otherwise the 'save' block in the template will not work. 
- An `Azure Service Principal` is required. 
- A specific `Service Connection` is required: `Azure Resource Manager` this must be set MANUALLY and passed the `Service Principal`
---
## Instructions :
Create the pipeline.yaml within the helm app directory.
 - The `pipeline.yaml` for the helm application should exist within the helm application folder. 
 - For our example the `pipeline.yaml` can be found within the 'example' folder along with all other helm dependencies. 

Apply the template to the `pipeline.yaml`
- In the "resources" block specify the repository containing the template, the type of repository (git in our example), and finally for the name, use the project name followed by the repository where the template resides
- See below from helm `example` (`pipeline.yaml`) :
```yaml
resources:
  repositories:
  - repository: application-pipeline-templates 
    type: git
    name: EBG DevOps/application-pipeline-templates 
```
- After setting the `resources` block we can call the template using a `jobs` definition.

```yaml
jobs:
- template: /helm/helm-build.yaml@application-pipeline-templates
  parameters:
```
Apply the required Parameters to the template. 
- After extending the template you will pass in the parameters that apply.
- These can be found on the first block of code on the `helm-build.yaml` and alsow listed below.  
- The user can apply more templates to their pipeline by adding `templates` under `jobs`, each new template has to have it's own set of parameters passed in. 
---
## Parameters :
What follows is a brief desciption of the parameters being passed into the template. They are all passed in as strings. 

- name: `azureSubscriptionEndpoint`
    - Refers to the `service connection` the helm app will be using. In the example pipeline it is called `helm-build`. The type of connection must be an `Azure Resource Manager` connection set up manually with the appropriate connections back to the `Service Principal`.
- name: `azureResourceGroup`
    - Refers to the `resource group` where you are going to deploy your application. 

- name: `kubernetesCluster`
    - Refers to the name of the kubernetes cluster being used for your application. 

- name: `chartPath`
    - Refers to the `Chart.yaml` file located in the example directory. Or in the directory containing the Helm dependencies you will be using.

- name: `chartNameForACR`
  - Refers to the `name` found in `Chart.yaml`

- name: `chartPathForACR`
    - Refers to the `Chart.yaml` file located in the 'example' directory.

- name: `azureSubscriptionEndpointForACR`
    - Refers to the `service connection` set up for the app specifically using a service principle authentication.
- name: `azureResourceGroupForACR`
    - Refers to the resource group hosting the Kubernetes Cluster to be used.

- name: `azureContainerRegistry`
    - Refers to the name of the container registry hosting your project. 
- name: 'chart_version`
    - Refers to the version of the chart.
---
## Documentation 
Further documentation for Packaging and Deploying helm charts can be found here:

- https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/helm-deploy?view=azure-devops

Further documentation for Template types and Usage:

- https://docs.microsoft.com/en-us/azure/devops/pipelines/process/templates?view=azure-devops


