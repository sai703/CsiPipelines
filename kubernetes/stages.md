##Pipeline Overview
This pipeline consists of the following stages:

1.`Build Docker Image`: This stage builds a Docker image for the API using the Dockerfile specified in the pipeline parameters.

2.`Push Docker Image to ACR`: This stage pushes the Docker image to an Azure Container Registry specified in the pipeline parameters.

3.`Deploy to Kubernetes Cluster`: This stage deploys the API to a Kubernetes cluster using a Helm chart specified in the pipeline parameters.

#Docker Build and Push stage
This stage builds and pushes Docker images for the application.

#Jobs
#Publish Artifacts images API
This job publishes the artifacts images API.
-`docker_veracode_appname`: The name of the Veracode application for Docker scanning.
-`VSTS_FEED`: The VSTS feed for storing the artifacts.
-`ARTIFACT_NAME`: The name of the Docker artifact.
-`PROJECT_FILE`: The path to the project file.
#Docker Build
This job builds the Docker image.
-`BUILD_CONTEXT`: The build context for Docker.
-`CONTAINER_REGISTRY`: The container registry to push the Docker image to.
-`ACR_URL`: The URL of the Azure Container Registry.
-`DOCKER_REPOSITORY`: The name of the Docker repository.
-`DOCKERFILE_PATH`: The path to the Dockerfile.
-`RISK_PROFILE`: The risk profile for Twistlock scanning.
-`TWISTLOCK_ID`: The Twistlock ID for authentication.
-`TWISTLOCK_PASSWORD`: The Twistlock password for authentication.

#Deployment Flow
The deployment flow for this stage is as follows:
1.Build and publish the artifacts images API.

2.Build the Docker image.

3.Push the Docker image to the specified container registry.

4.Perform Twistlock scanning for security checks.


##Helm Build Stage
This stage builds a Helm chart and packages it for deployment.

#Jobs
#Helm_build
This job builds the Helm chart and packages it for deployment.

Steps
helm-build.yaml ,This template builds the Helm chart using the specified parameters:

-`azure_subscription_endpoint`: The Azure subscription endpoint to use for the deployment.
-`azure_resource_group`: The name of the Azure resource group to use for the deployment.
-`chart_path`: The path to the Helm chart to build.
-`chart_name`: The name of the Helm chart to build.
-`chart_version`: The version of the Helm chart to build.
-`azure_container_registry`: The name of the Azure Container Registry to use for storing the Helm chart package.



##AKS Deployment stage
This pipeline stage deploys the application to an AKS cluster.

#Environment Variables
The following environment variables are required for this stage:

-`AZURE_SUBSCRIPTION_ENDPOINT`: The Azure subscription endpoint for the AKS cluster.
-`AZURE_RESOURCE_GROUP`: The Azure resource group for the AKS cluster.
-`AKS_CLUSTER_NAME`: The name of the AKS cluster to deploy to.
-`IMAGE_NAME`: The name of the Docker image.
-`CHART_VERSION`: The version of the Helm chart.
-`RELEASE_NAME`: The name of the Helm release.
-`SUB_PRODUCT_NAME`: The name of the sub-product being deployed.
-`ACR_USERNAME`: The username for the Azure Container Registry.
-`ACR_PASSWORD`: The password for the Azure Container Registry.
-`ACR_TENANT`: The tenant for the Azure Container Registry.

#Deployment Flow
The deployment flow for this stage is as follows:

1.Build the Helm chart for the application.

2.Deploy the Helm chart to the AKS cluster.

3.Run a readiness check on the deployed API.

#Dev and QA Environments
For Dev and QA environments, a ReadyAPI test suite is run to check the readiness of the deployed API.

#Feature Branches
For feature branches, the application is deployed to the Dev environment only.