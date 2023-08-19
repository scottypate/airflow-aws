data "aws_ami" "eks" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-1.27-v20230607"]
  }
}

resource "aws_security_group" "airflow" {
  name   = "Airflow"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH from IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ip_allowlist
  }

  ingress {
    description = "Self-referencing ingress rule"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "All inbound traffic from VPC CIDR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "All inbound traffic from Kubernetes CIDR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.kube_cidr]
  }

  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "eks" {
  name = "eks_launch_template"

  vpc_security_group_ids = [aws_security_group.airflow.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp2"
    }
  }

  key_name      = "ssh"
  image_id      = data.aws_ami.eks.id
  instance_type = "t3.medium"
  user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
set -ex
B64_CLUSTER_CA=${aws_eks_cluster.airflow.certificate_authority[0].data}
API_SERVER_URL=${aws_eks_cluster.airflow.endpoint}
K8S_CLUSTER_DNS_IP=172.20.0.10
CLUSTER_NAME=airflow
/etc/eks/bootstrap.sh airflow --kubelet-extra-args '--node-labels=eks.amazonaws.com/nodegroup-image=ami-07c9c86f18d0ff01e,eks.amazonaws.com/capacityType=ON_DEMAND,eks.amazonaws.com/nodegroup=airflow --max-pods=11' --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL --dns-cluster-ip $K8S_CLUSTER_DNS_IP --use-max-pods false --cluster-name $CLUSTER_NAME

--//--
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "EKS-MANAGED-NODE"
    }
  }
}
