# DAGS

These DAGs are synced to the Airflow scheduler via a git-sync sidecar in k8s. The sidecar pulls down the changes in the DAGs periodically and allows you to separate the DAGs code from the infra code if desired. 
