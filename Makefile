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

.PHONY: apply-kube-manifests-%
apply-kube-manifests-%:
	./scripts/apply-kube-manifests.sh $*

.PHONY: login-docker
login-docker:
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

.PHONY: build-ecr-airflow-image
build-ecr-airflow-image: login-docker
	yq -i '.spec.containers[].image = strenv(DOCKER_IMAGE)' ./images/pod-template-prod.yaml
	docker build \
		--platform linux/amd64 \
		-t ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/airflow:prod \
		-f ./images/airflow.Dockerfile .

.PHONY: push-ecr-airflow-image
push-ecr-airflow-image: build-ecr-airflow-image
	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/airflow:prod

.PHONY: lint-yaml
lint-yaml:
	yamllint -c manifests/.yamllint manifests

.PHONY: terraform-apply
terraform-apply:
	cd terraform/${REGION} && terraform apply

.PHONY: terraform-destroy
terraform-destroy:
	cd terraform/${REGION} && terraform destroy

.PHONY: update-kubeconfig
update-kubeconfig:
	aws eks --region ${REGION} update-kubeconfig --name airflow

.PHONY: set-kube-secrets-%
set-kube-secrets-%:
	./scripts/set-kube-secrets.sh $*
	
