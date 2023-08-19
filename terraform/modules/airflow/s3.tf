resource "aws_s3_bucket" "airflow_logs" {
  bucket = "airflow-logs-eks-${var.region}"
  force_destroy = true
}