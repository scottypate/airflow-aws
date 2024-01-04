FROM apache/airflow:2.8.0 as dev

COPY dags/ /git/airflow-dags-private.git/dags

COPY images/pod-template-local.yaml /opt/airflow/pod-template-local.yaml
COPY images/pod-template-prod.yaml /opt/airflow/pod-template-prod.yaml
