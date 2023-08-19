REGION=us-west-2
CLUSTER_NAME=airflow
AWS_ACCOUNT_ID=<AWS_ACCOUNT_ID>
POSTGRES_PASSWORD=$(shell sh -c "aws secretsmanager get-secret-value --secret-id airflow-postgres --region $(REGION) --output text --query SecretString" | jq -r .password)
POSTGRES_HOST=$(shell sh -c "aws rds describe-db-instances --region $(REGION) --query 'DBInstances[0].Endpoint.Address' --db-instance-identifier airflow-$(REGION) --output text")
CONNECTION_STRING=postgresql+psycopg2://airflow:$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):5432/airflow
DOCKER_IMAGE=$(AWS_ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/airflow:prod

SHELL = /bin/bash
.PHONY: install-requirements
install-requirements:
	brew install minikube && \
	brew install kubectl && \
	brew install jq && \
	brew install yq

.PHONY: start-minikube
start-minikube:
	minikube start

.PHONY: build-minikube-airflow-image
build-minikube-airflow-image: start-minikube
	minikube image build \
		-t local-airflow-image \
		--build-env POD_TEMPLATE_FILE=/opt/airflow/pod-template-local.yaml \
		-f ./images/airflow.Dockerfile .

.PHONY: apply-local-kube-config
apply-local-kube-config:
	./scripts/apply.sh local

.PHONY: apply-prod-kube-config
apply-prod-kube-config:
	yq -i '.spec.template.spec.containers[].image = "$(DOCKER_IMAGE)"' ./manifests/overlays/prod/scheduler-deployment.yaml
	yq -i '.spec.template.spec.initContainers[].image = "$(DOCKER_IMAGE)"' ./manifests/overlays/prod/scheduler-deployment.yaml
	yq -i '.spec.template.spec.containers[].image = "$(DOCKER_IMAGE)"' ./manifests/overlays/prod/webserver-deployment.yaml
	yq -i '.spec.template.spec.initContainers[].image = "$(DOCKER_IMAGE)"' ./manifests/overlays/prod/webserver-deployment.yaml
	yq -i '.spec.containers[].image = "$(DOCKER_IMAGE)"' ./images/pod-template-prod.yaml
	# ./scripts/apply.sh prod

.PHONY: login-docker
login-docker:
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com

.PHONY: build-ecr-airflow-image
build-ecr-airflow-image: login-docker
	docker build \
		--platform linux/amd64 \
		-t $(AWS_ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/airflow:prod \
		-f ./images/airflow.Dockerfile .

.PHONY: push-ecr-airflow-image
push-ecr-airflow-image: build-ecr-airflow-image
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/airflow:prod

.PHONY: lint-yaml
lint-yaml:
	yamllint -c manifests/.yamllint manifests

.PHONY: terraform-apply
terraform-apply:
	cd terraform/$(REGION) && terraform apply

.PHONY: terraform-destroy
terraform-destroy:
	cd terraform/$(REGION) && terraform destroy

.PHONY: update-kubeconfig
update-kubeconfig:
	aws eks --region ${REGION} update-kubeconfig --name ${CLUSTER_NAME}

.PHONY: set-kube-secrets
set-kube-secrets:
	kubectl create namespace airflow
	kubectl delete secret postgres --ignore-not-found -n airflow
	@kubectl create secret generic postgres \
		-n airflow \
		--save-config \
		--from-literal=connection='$(CONNECTION_STRING)'
