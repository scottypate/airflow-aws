locals {
  postgres_secrets = {
    "password" : random_password.airflow_postgres.result
    "username" : "airflow"
  }
}

resource "random_password" "airflow_postgres" {
  length  = 22
  lower   = false
  special = false
}

resource "aws_secretsmanager_secret" "airflow_postgres" {
  name                           = "airflow-postgres"
  force_overwrite_replica_secret = true
  recovery_window_in_days        = 0
}

resource "aws_secretsmanager_secret_version" "airflow_postgres" {
  secret_id     = aws_secretsmanager_secret.airflow_postgres.id
  secret_string = jsonencode(local.postgres_secrets)
}
