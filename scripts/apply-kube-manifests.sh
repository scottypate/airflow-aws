#!/bin/bash

export $(cat .env)

ENVIRONMENT=$1

if [ "${ENVIRONMENT}" == "prod" ]; then
	yq -i '.spec.template.spec.initContainers[].image = strenv(DOCKER_IMAGE)' ./manifests/overlays/prod/scheduler-deployment.yaml
    yq -i '.spec.template.spec.containers[].image = strenv(DOCKER_IMAGE)' ./manifests/overlays/prod/scheduler-deployment.yaml
	yq -i '.spec.template.spec.containers[].image = strenv(DOCKER_IMAGE)' ./manifests/overlays/prod/webserver-deployment.yaml
	yq -i '.spec.template.spec.initContainers[].image = strenv(DOCKER_IMAGE)' ./manifests/overlays/prod/webserver-deployment.yaml
	yq -i '.spec.template.spec.initContainers[].image = strenv(DOCKER_IMAGE)' ./images/pod-template-prod.yaml

    kubectl apply -k ./manifests/overlays/prod

elif [ "${ENVIRONMENT}" == "local" ]; then
    kubectl apply -k  ./manifests/services/logs && \
    while [[ $(kubectl get pvc -n airflow airflow-logs-claim -o 'jsonpath={..status.phase}') != "Bound" ]]; do echo "waiting for PVC status" && sleep 1; done && \
    kubectl apply -k ./manifests/overlays/dev
else 
    echo "Environment ${ENVIRONMENT} not found"
fi
