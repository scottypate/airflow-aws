FROM apache/airflow:2.6.1 as dev

COPY dags/ /opt/airflow/dags/
COPY images/pod-template-local.yaml /opt/airflow/pod-template-local.yaml
COPY images/pod-template-prod.yaml /opt/airflow/pod-template-prod.yaml
