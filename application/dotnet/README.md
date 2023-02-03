# dotNet Test
---
## Overview
This directory contains a `test.yaml` template. It runs tests and code coverage for dotNet applications.

---
## Requirements :
- The `line coverage` default is set at `80` %. The pipeline will fail if this threshold is not met.
- The `branch coverage` default is set to `80` %. The pipline will fail if this threshold is not met.

---
## Instructions :
- Reference the repository hosting test template as shown bellow.
- Reference test branch under for `template` step and provide required parameters.

```yaml
resources:
  repositories:
  - repository: application-pipeline-templates
    type: git
    name: EBG DevOps/application-pipeline-templates   

jobs:
- job:
  steps:
  - template: /docker/docker-build.yaml@application-pipeline-templates
    parameters:  
      build_context: $(Build.SourcesDirectory)/application/example-app
      container_registry: $(acr_service_endpoint)
```

---
## Parameters :
- `build_configuration`: Referst to configuration to package.
- `reports_folder`: Refers to the directory where the generated report should be saved.
- `fail_if_coverage_empty`: Defaults to false. Fail when code coverage results are missing. 
- `test_flags`: Allows for flags to be passed to arguments.
- `line_coverage_threshold`: The limit set for line coverage. Pipeline will fail if it coverage threshold is not met. Default set to 80 %
- `branch_coverage_threshold`:  The limit set for branch coverage. Pipeline will fail if it coverage threshold is not met. Default set to 80 %

---
## Documentation :