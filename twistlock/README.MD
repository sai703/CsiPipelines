# Template Pipeline Application Example : TWISTLOCK
---
## Overview
This is a security application `scan.yaml` for Twistlock. Though the file is paramaterized like a template it is designed to be called with the `docker_build` template found in this repo. The variables for the `scan.yaml` must be set (in ADO pipeline library) and then called when the pipeline builds. 

The twistlock directory contains three twistlock scan templates: 
- `scan.yaml` : scans a single image. 
- `bulk-scan.yaml` : scans multiple images
- `acr-scan.yaml` : scans ACR

---
## Requirements
- Requires a docker image. This template does not run by itself.
- Requires a variable group to be set for Twistlock ID & Password. (ADO Pipeline Library)

---
## Instructions for `scan.yaml`
The `pipeline.yaml` found within the example folder illustrates how twistlock scan operates when a pipeline builds. It is called within the `docker_build` template.

``` yaml 
# The twistlock variable group holds the id and password
variables:
- group: twistlock
``` 
``` yaml
tag: latest
risk_profile: internal.headless-services.nonpci
twistlock_id: $(twistlock_id)  ## Here we call the ARM variable safely storing the id
twistlock_password: $(twistlock_password) ## Here we call the ARM variable safely storing the password
```
## Parameters
- `image_with_tag` : refers to the image being created by the `docker_build` template
- `twistlock_id` : referst to the id set in the variable group being called.
- `twistlock_password` : refers to the password set in the variable group being called.
---
## Instructions for `bulk-scan.yaml`

---
---
## Instructions for `acr-scan.yaml`

---
## Documentation 
### creating variable groups
https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml

### twistlock
https://cdn.twistlock.com/docs/downloads/Twistlock-Reference-Architecture.pdf

