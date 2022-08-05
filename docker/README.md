# Pipeline Template: Docker
---
## Overview
 This is a docker template for building and pushing docker images. The `docker-build.yaml` also scans the image with `twistlock`. The Dockerfile pulls a basic alpine image for example purposes.   

---
## Requirements
- Variable groups should be set for Twistlock ID & Password. (ADO Library)
- An Azure Service Connection to the ACR is required.

---
## Instructions
- Create or request access to the required resources.
- Create a Dockerfile for your application.
- Fill in variables where necessary on `pipeline.yaml`.
- Fill in paramaters where necessary on  `pipeline.yaml`.
- Run the `pipline.yaml`.
---
## Parameters
#### for `docker-build` template : 
- `build_context` : refers to the application directory.
- `container_registry` : refers to the name of the `Azure Container Registry`.
- `acr_url` : refers to the full `Azure Container Registry` login url.
- `docker_repository` : docker image name.
- `dockerfile_path` : points to the dockerfile for the application.
- `tag` : desired tag.
- `risk_profile` : refering to `risk_profile` (will likely remain the same as example in `pipeline.yaml`).
- `twistlock_id` : reffering to twislock id being pulled from variable group. 
- `twistlock_password`: reffering to twistlock password being pulled from variable group.
---
## Documentation
### creating variable groups
https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml
### creating a resource manager and service connection
https://docs.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops
### dockerising an application (dotNet)
https://docs.microsoft.com/en-us/dotnet/core/docker/build-container?tabs=windows
