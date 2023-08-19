resource "aws_eks_cluster" "airflow" {
  name     = "airflow"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.27"

  vpc_config {
    subnet_ids              = [aws_subnet.main["a"].id, aws_subnet.main["b"].id, aws_subnet.main["c"].id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = concat(var.ip_allowlist, ["${aws_nat_gateway.airflow.public_ip}/32"])
    security_group_ids      = [aws_security_group.airflow.id]
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.kube_cidr
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_role_policy_attachment_1,
    aws_security_group.airflow
  ]
}

resource "aws_eks_addon" "cni" {
  cluster_name = aws_eks_cluster.airflow.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.airflow.name
  node_group_name = "airflow"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.main["a"].id, aws_subnet.main["b"].id, aws_subnet.main["c"].id]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.eks.id
    version = aws_launch_template.eks.latest_version
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_role_policy_attachment_1,
    aws_iam_role_policy_attachment.eks_node_role_policy_attachment_2,
    aws_iam_role_policy_attachment.eks_node_role_policy_attachment_3,

  ]

  timeouts {
    create = "10m"
  }
}
