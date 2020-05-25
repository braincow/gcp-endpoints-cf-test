## configuration, overwrite from commandline if so wished
GCP_PROJECT=antti-peltonens-lab-solita
GCP_REGION=europe-west1
SERVICE_NAME=gcp-cf-endpoint-test

## utility targets

all: none

none:
	@echo Nothing to see here. Go away!

enable-cloudbuild-api:
	gcloud --project ${GCP_PROJECT} services enable cloudbuild.googleapis.com

enable-servicecontrol-api:
	gcloud --project ${GCP_PROJECT} services enable servicecontrol.googleapis.com

## create targets

grant-security-roles-for-cloudbuild: enable-cloudbuild-api
	gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
		--member=serviceAccount:$$(gcloud projects list --filter="${GCP_PROJECT}" --format="value(PROJECT_NUMBER)")@cloudbuild.gserviceaccount.com \
		--role=roles/cloudfunctions.developer
	gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
		--member=serviceAccount:$$(gcloud projects list --filter="${GCP_PROJECT}" --format="value(PROJECT_NUMBER)")@cloudbuild.gserviceaccount.com \
		--role=roles/iam.serviceAccountUser
	gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
		--member=serviceAccount:$$(gcloud projects list --filter="${GCP_PROJECT}" --format="value(PROJECT_NUMBER)")@cloudbuild.gserviceaccount.com \
		--role=roles/run.admin
	gcloud projects add-iam-policy-binding ${GCP_PROJECT} \
		--member=serviceAccount:$$(gcloud projects list --filter="${GCP_PROJECT}" --format="value(PROJECT_NUMBER)")@cloudbuild.gserviceaccount.com \
		--role=roles/servicemanagement.admin

cloudbuild-create: grant-security-roles-for-cloudbuild
	gcloud --project ${GCP_PROJECT} builds submit --config cloudbuild.create.yaml \
		--substitutions=_DEPLOYMENT_REGION=${GCP_REGION},_SERVICE_NAME=${SERVICE_NAME}

## update targets

cloudbuild-update: enable-servicecontrol-update
	gcloud --project ${GCP_PROJECT} builds submit --config cloudbuild.update.yaml \
		--substitutions=_DEPLOYMENT_REGION=${GCP_REGION},_SERVICE_NAME=${SERVICE_NAME}
	@echo ""
	@echo "Enable your new shiny API for your project with make target 'enable-test-api'"
	@echo ""

enable-test-api:
	gcloud --project ${GCP_PROJECT} services enable \
		$(shell gcloud --project ${GCP_PROJECT} endpoints services list --filter="${SERVICE_NAME}" --format="value(NAME)")
	@echo ""
	@echo "Head to gcp console apis & services > credentials menu and create a new API key with access to your new api."
	@echo "Now you can call the /hello/{name} api with ?key= query variable to gain access."
	@echo ""

## runtime!

query-hello-api:
	curl --request GET \
		--header "Content-Type: application/json" \
		https://$(shell gcloud --project ${GCP_PROJECT} endpoints services list --filter="${SERVICE_NAME}" --format="value(NAME)")/hello |jq
	@echo

query-helloname-api:
	read -p "API key: " KEY && \
	curl --request GET \
		--header "Content-Type: application/json" \
		https://$(shell gcloud --project ${GCP_PROJECT} endpoints services list --filter="${SERVICE_NAME}" --format="value(NAME)")/hello/$$USERNAME?key=$$KEY |jq
	@echo

## cleanup targets

delete-func:
	gcloud --project ${GCP_PROJECT} functions delete --region europe-west1 hello_get --quiet
	gcloud --project ${GCP_PROJECT} functions delete --region europe-west1 helloname_get --quiet

delete-service:
	gcloud --project ${GCP_PROJECT} run --region europe-west1 --platform managed services delete ${SERVICE_NAME} --quiet

delete-endpoint:
	gcloud --project ${GCP_PROJECT} endpoints services delete \
		$(shell gcloud --project ${GCP_PROJECT} endpoints services list --filter="${SERVICE_NAME}" --format="value(NAME)") --quiet

delete-security-roles-for-cloudbuild:
	gcloud projects remove-iam-policy-binding ${GCP_PROJECT} \
		--member=serviceAccount:$$(gcloud projects list --filter="${GCP_PROJECT}" --format="value(PROJECT_NUMBER)")@cloudbuild.gserviceaccount.com \
		--role=roles/cloudfunctions.developer
	gcloud projects remove-iam-policy-binding ${GCP_PROJECT} \
		--member=serviceAccount:$$(gcloud projects list --filter="${GCP_PROJECT}" --format="value(PROJECT_NUMBER)")@cloudbuild.gserviceaccount.com \
		--role=roles/iam.serviceAccountUser
	gcloud projects remove-iam-policy-binding ${GCP_PROJECT} \
		--member=serviceAccount:$$(gcloud projects list --filter="${GCP_PROJECT}" --format="value(PROJECT_NUMBER)")@cloudbuild.gserviceaccount.com \
		--role=roles/run.admin
	gcloud projects remove-iam-policy-binding ${GCP_PROJECT} \
		--member=serviceAccount:$$(gcloud projects list --filter="${GCP_PROJECT}" --format="value(PROJECT_NUMBER)")@cloudbuild.gserviceaccount.com \
		--role=roles/servicemanagement.admin

cleanup: delete-service delete-func delete-security-roles-for-cloudbuild
	@echo ""
	@echo "- To delete endpoint run "make delete-endpoint", but be aware that purging of the name happens only after 30 days and undeleting it is a bitch."
	@echo "- Remove the entire 'endpoints-runtime-serverless' image from your ${GCP_PROJECT} projects GCP Docker image registry."
	@echo "- If you created the developer portal for this test go ahead and delete it. If you are using it for other stuff then dont remove it! :)"
	@echo ""

# eof