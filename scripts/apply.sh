#!/bin/bash

ENVIRONMENT=$1

if [ "${ENVIRONMENT}" == "prod" ]; then
    kubectl apply -k ./manifests/overlays/prod
elif [ "${ENVIRONMENT}" == "local" ]; then
    kubectl create namespace airflow
    kubectl delete secret postgres --ignore-not-found -n airflow
	kubectl create secret generic postgres \
		-n airflow \
		--save-config \
		--from-literal=connection='postgresql+psycopg2://airflow@postgres:5432/airflow'
    kubectl apply -k  ./manifests/services/logs && \
    while [[ $(kubectl get pvc -n airflow airflow-logs-claim -o 'jsonpath={..status.phase}') != "Bound" ]]; do echo "waiting for PVC status" && sleep 1; done && \
    kubectl apply -k ./manifests/overlays/dev
else 
    echo "Environment ${ENVIRONMENT} not found"
fi
