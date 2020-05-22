# GCP Endpoints for Cloud Function tutorial

This example repository automates the deployment described here: https://cloud.google.com/endpoints/docs/openapi/get-started-cloud-functions

Also few small modifications to the resulting API was done.

## Makefile to the rescue

There are few things in life that even MasterCard cant solve. Even though we use CloudBuild to deploy this tutorial we need to grant few IAM roles for cloudbuild service for example.

Makefile targets available:

* all - executes none
* none - taunts you if executed
* enable-cloudbuild-api - enables cloudbuild service api if not yet enabled
* grant-security-roles-for-cloudbuild - executes enable-cloudbuild-api and grants required roles for cloudbuild service user afterwards
* cloudbuild-create - executes grant-security-roles-for-cloudbuild and submits cloudbuild.create.yaml file for Cloudbuild to run.
* cloudbuild-update - submits cloudbuild.update.yaml file for Cloudbuild to run.
* query-hello-api - uses curl to send a request to the API endpoint. Parses output with jq command to make output look nice.
* query-helloname-api - uses curl to send a request to API endpoint. As a name parameter it uses $USER environment variable. Parses output with jq.
* delete-func - delete cloud functions created by CloudBuild
* delete-service - removes ESP container from Cloud Run
* delete-endpoint - removes Endpoint configuration
* delete-security-roles-for-cloudbuild - removes IAM roles from cloudbuild user
* cleanup - executes delete-func, delete-service and delete-security-roles-for-cloudbuild and gives user information on how to finish the cleanup.

BUT WAIT, THERES MORE!

Since the default project name targets my own project you can overwrite it with by running make like so: make GCP_PROJECT=your-project-id cloudbuild-create

Note that you need to use the GCP_PROJECT= variable for each consequent make call as well.

## Cloudbuild automation

Two jobs exist for cloudbuild the other one (create) is used to "bootstrap" the environment and second one (update) describes on how to update the endpoint with another definition for new endpoint.

## Endpoints configurations

For create and update runs of CloudBuild there are separate Swagger configuration files that define the API.

All of the API's are open to the world. Security definition tutorial coming later, maybe.
