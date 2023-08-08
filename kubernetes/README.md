##This is a deployment pipeline for the API. It builds a Docker image, pushes it to an Azure Container Registry, and deploys it to a Kubernetes cluster.

##Pipeline Overview
This pipeline consists of the following stages:

1.`Build Docker Image`: This stage builds a Docker image for the API using the Dockerfile specified in the pipeline parameters.

2.`Push Docker Image to ACR`: This stage pushes the Docker image to an Azure Container Registry specified in the pipeline parameters.

3.`Deploy to Kubernetes Cluster`: This stage deploys the API to a Kubernetes cluster using a Helm chart specified in the pipeline parameters.


##How to Use
1.To use this pipeline, follow these steps:

2.Fork this repository.

3.Update the pipeline parameters in the azure-pipelines.yml file to match your environment.

4.Commit the changes and push them to your forked repository.

5.Create a new pipeline in Azure DevOps using the azure-pipelines.yml file in your forked repository.

6.Run the pipeline.

## Instructions :
- Create a resource block linking the `application-pipeline-template` repo.
```yaml
resources:
  repositories:
  - repository: application-pipeline-templates
    type: git
    name: EBG DevOps/application-pipeline-templates
```
- Run the build-publish the artifact for API stage by linking the template and providing parameters
```yaml
- template: /docker/build.yaml@application-pipeline-templates
        parameters:
         docker_veracode_appname: ${{ parameters.docker_app_name }}                            
         vsts_feed: ${{ parameters.vsts_feed }}
         project_file: $(Build.SourcesDirectory)/example/dotnet/src/dotnet-function-example.csproj
```
- Run the docker image from the artifact for API stage by linking the template and providing parameters
```yaml
- template: /docker/docker-build.yaml@application-pipeline-templates
  parameters:
    artifact_name: construct
    build_context: $(Build.ArtifactStagingDirectory)/docker_artifact_name
```
- Run the Helm build stage by linking the template and providing parameters
```yaml
- template: /helm/helm-build.yaml@application-pipeline-templates
  parameters:
    chart_name: image_name
    chart_path: $(Build.SourcesDirectory)/example/src/CSI.Images.API/Chart/Chart.yaml
           
```
- Run the Helm deploy stage by linking the template and providing parameters
```yaml
- template: /helm/helm-deploy.yaml@application-pipeline-templates
  parameters:
    kubernetes_cluster: aks_cluster_name
    container_image: azure_container_registry / image_name
```                    


##Pipeline Parameters
This pipeline takes the following parameters:

- `environment` : The environment to deploy to (dev or qa or staging or prod).
- `artifact_name` : The name of the artifact to be deployed.
- `pool` : The Azure VM Scale Set pool to use for running the pipeline.
- `Dockerfile`: The path to the Dockerfile used to build the Docker image.
- `project_file` : The path to the project file for the API.
- `chart_path` : The path to the Helm chart used to deploy the API.
- `chart_version`: The version of the Helm chart.
-`RISK_PROFILE`: The risk profile for Twistlock scanning.
-`TWISTLOCK_ID`: The Twistlock ID for authentication.
-`TWISTLOCK_PASSWORD`: The Twistlock password for authentication.


#Dev and QA Environments
For Dev and QA environments, a ReadyAPI test suite is run to check the readiness of the deployed API.

#Feature Branches
For feature branches, the application is deployed to the Dev environment only.


##Notes
1.This pipeline assumes that you have an Azure Container Registry and a Kubernetes cluster set up for your environment.

2.This pipeline uses Helm to deploy the API to the Kubernetes cluster.

3.This pipeline requires the following environment variables to be set:` twistlock_id`, `twistlock_password`, `client_id`, `client_secret`, and `tenant_id`.

4.This pipeline requires the service connections to be set up in Azure DevOps.




