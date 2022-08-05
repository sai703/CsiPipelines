# Pipeline Templates
## Overview
These templates facilitate pipeline createion. Please refer to the documentation (`READ.me`) in each directory for specific instructions regarding deployment requirements as well as parameter and variable specifics. 

---
## Applying a Template
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
- These can be found on the first block of code on the `helm-build.yaml` for example.  
- The user can apply more templates to their pipeline by adding `templates` under `jobs`, each new template has to have it's own set of parameters passed in. 
---
## Working with two Repositories
Using more than one Rep: 
- The `yaml` below line is pulling in two repositories. 

``` yaml
resources:
  repositories:
  - repository: app
    type: git
    name: Cloud/Foundation-RunningBalance-Api-DDA
    endpoint: AzureRepoAccess   
  - repository: application-pipeline-templates
    type: git
    name: EBG DevOps/application-pipeline-templates   
```
---
## Contents 
The `pipline_templates` repo contains the following 
directories:

1. `application` (dockerized dotNet example)
    - example-app
        - CHART
        - obj
        - Properties
        - appsettings.Development.json
        - appsettings.json
        - Dockerfile
        - example-app.csproj
        - pipeline.yaml
        - Programs.cs
    - README.md 

1. `docker` (docker-build template with Twisltlock) 
    - example
        - Dockerfile
        - Pipeline.yaml
    - docker-build.yaml
    - README.md

1. `helm` 
    - example
        - charts
        - templates
        - Chart.yaml
        - pipeline.yaml
        - values.yaml
    - helm-build.yaml
    - helm-deploy.yaml
    - README.md

1. `twistlcok`
    - example
        - pipeline.yaml
    - README.md
    - scan.yaml
---


