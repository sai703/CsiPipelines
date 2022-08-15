# Azure Http Trigger Function Application Example
---
## Overview
This directory contains two templates: `build-publish.yaml` and `deploy.yaml`. The `pipeline.yaml` in the example folder (example/dotnet/src/pipeline.yaml) illustrates how the templates work together to deploy the sample http function app. The `pipeline.yaml` pulls in an additional `test.yaml` template located in the application dotnet subfolder (application/dotnet/test.yaml). This template enables testing and can be used with different dotnet applications. It's also possible to call the templates several times and in doing so deploy multiple applications simultaneously. 

---
## Requirements :
- Succesfull deployment of the application is contingent on the `Test` stage of the `pipeline.yaml` passing.
- The `Test` stage should be the first to run as demonstrated in the `pipeline.yaml`.
- A resources block to the `application-pipeline-templates` repo is requried  
- An `Azure Subscription` is required.
---
## Instructions :
- Create a resource block linking the `application-pipeline-template` repo.
```yaml
resources:
  repositories:
  - repository: application-pipeline-templates
    type: git
    name: EBG DevOps/application-pipeline-templates
```
- Run the test stage by linking the template and provide parameters.
```yaml
- template: /application/dotnet/test.yaml@application-pipeline-templates
  parameters:
    build_configuration: Release
    reports_folder: $(Common.TestResultsDirectory)
```
- Run the build-publish stage by linking the template and providing parameters
```yaml
- template: /function-app/build-publish.yaml@application-pipeline-templates
  parameters:
    artifact_name: construct
    project_file: $(Build.SourcesDirectory)/function-app/example/dotnet/src/dotnet-function-example.csproj
```
- Run the deploy stage by linking the templae and providing parameters
```yaml
- template: /function-app/deploy.yaml@application-pipeline-templates
  parameters:
    function_app_name: windows-httpfunction-app
    azure_subscription: CSITransformationSandbox(77233efb-37e6-4159-b817-fbbbd968dbe6) 
    artifact_name: construct
    environment: sandbox
    notify_users: "CSI\\EBG DevOps Team"
```
- For a complete illustration of how the examples above work together please refer to the `pipeline.yaml` (example/dotnet/src/pipeline.yaml). 
---
## Parameters :
#### for `build-publish.yaml` template :
- `artifact_name` : refers to the name of the artifact that will be output. (user set)
- `project_file` : refers to the name of the file being punblished (user set)
- `build_configuration` : refers to the build configuration for the project file (user seet)
- `publish_flags` : are optional and allow the user to add any flags they deem necessary (user set)
- `output_dir` : refers to the directory the published artifact will be output to  (user set)


#### for `deploy.yaml` template :
- `function_app_name` : refers to the name of the app you're building (user set)
- `azure_subscription` : refers to the subscription where the application is operating (existing. user provided)
- `artifact_name` : refers to the name of the artifact that was created in the build stage. (user set previously)
- `environment` : referes to the environment the application will be published in. (user set - provided) 

---
## Documentation :
### Azure Functions Http Trigger
https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger?tabs=in-process%2Cfunctionsv2&pivots=programming-language-csharp
