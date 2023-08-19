from pendulum import datetime, duration
from airflow import DAG
from airflow.configuration import conf
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import (
    KubernetesPodOperator,
)

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": datetime(2023, 8, 6),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": duration(minutes=5),
}

with DAG(
    dag_id="example_kubernetes_pod_1", schedule="*/30 * * * *", default_args=default_args
) as dag:
    KubernetesPodOperator(
        namespace="airflow",
        image="hello-world",
        labels={"dag": "example_kubernetes_pod_1"},
        name="airflow-test-pod",
        task_id="hello-world",
        is_delete_operator_pod=True,
        get_logs=True,
        in_cluster=True
    )