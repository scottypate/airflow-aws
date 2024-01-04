#!/bin/bash

export $(cat .env)

ENVIRONMENT=$1

if [ "${ENVIRONMENT}" == "prod" ]; then
    POSTGRES_SECRET=$(aws secretsmanager get-secret-value --secret-id airflow-postgres --region ${REGION} --output text --query SecretString)
    POSTGRES_PASSWORD=$(echo ${POSTGRES_SECRET} | jq -r '.password')
    POSTGRES_HOST=$(aws rds describe-db-instances --region ${REGION} --query 'DBInstances[0].Endpoint.Address' --db-instance-identifier airflow-${REGION} --output text)
    CONNECTION_STRING=postgresql+psycopg2://airflow:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/airflow

    kubectl create namespace airflow
    kubectl delete secret postgres --ignore-not-found -n airflow
    kubectl delete secret git-ssh-key --ignore-not-found -n airflow
    kubectl delete secret git-secret-known-hosts --ignore-not-found -n airflow
    kubectl delete secret airflow-env --ignore-not-found -n airflow
    
    kubectl create secret generic postgres \
        -n airflow \
        --save-config \
        --from-literal=connection=${CONNECTION_STRING}
    kubectl create secret generic git-ssh-key \
        -n airflow \
        --save-config \
        --from-file=git-ssh-key=${GIT_SSH_KEY_FILE}
    kubectl create secret generic git-secret-known-hosts \
        -n airflow \
        --save-config \
        --from-file=git-secret-known-hosts=${GIT_SSH_KNOWN_HOSTS_FILE}
    kubectl create secret generic airflow-env \
        -n airflow \
        --save-config \
        --from-file=.env

elif [ "${ENVIRONMENT}" == "local" ]; then
    kubectl create namespace airflow
    kubectl delete secret postgres --ignore-not-found -n airflow
    kubectl delete secret git-ssh-key --ignore-not-found -n airflow
    kubectl delete secret git-secret-known-hosts --ignore-not-found -n airflow
    kubectl delete secret airflow-env --ignore-not-found -n airflow

	kubectl create secret generic postgres \
		-n airflow \
		--save-config \
		--from-literal=connection='postgresql+psycopg2://airflow@postgres:5432/airflow'
    kubectl create secret generic git-ssh-key \
        -n airflow \
        --save-config \
        --from-file=git-ssh-key=${GIT_SSH_KEY_FILE}
    kubectl create secret generic git-secret-known-hosts \
        -n airflow \
        --save-config \
        --from-file=git-secret-known-hosts=${GIT_SSH_KNOWN_HOSTS_FILE}
    kubectl create secret generic airflow-env \
        -n airflow \
        --save-config \
        --from-file=.env
else 
    echo "Environment ${ENVIRONMENT} not found"
fi
