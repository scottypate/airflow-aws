# Store the secrets as local values for use
locals {
  postgres_user = jsondecode(aws_secretsmanager_secret_version.airflow_postgres.secret_string)["username"]
  postgres_pass = jsondecode(aws_secretsmanager_secret_version.airflow_postgres.secret_string)["password"]
}

# Create a subnet group for RDS
resource "aws_db_subnet_group" "airflow" {
  name       = "airflow_${var.region}"
  subnet_ids = [aws_subnet.main["a"].id, aws_subnet.main["b"].id]

  tags = {
    Name = "airflow-${var.region}"
  }
}

# Create the RDS database instance that Airflow uses
resource "aws_db_instance" "airflow" {
  allocated_storage                   = 100
  storage_type                        = "gp2"
  engine                              = "postgres"
  engine_version                      = "14.8"
  instance_class                      = "db.t3.micro"
  db_name                             = "airflow"
  iam_database_authentication_enabled = true
  db_subnet_group_name                = aws_db_subnet_group.airflow.name
  multi_az                            = false
  publicly_accessible                 = false
  username                            = local.postgres_user
  password                            = local.postgres_pass
  vpc_security_group_ids              = [aws_security_group.airflow.id]
  identifier                          = "airflow-${var.region}"
  skip_final_snapshot                 = true

  tags = {
    Name = "airflow-${var.region}"
  }
}
