resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = file("${path.module}/iam-policy-documents/eks-trust-policy.json")
}

resource "aws_iam_role" "eks_node_role" {
  name               = "eks-node-role"
  assume_role_policy = file("${path.module}/iam-policy-documents/ec2-trust-policy.json")
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy_attachment_1" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_role_policy_attachment_1" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_role_policy_attachment_2" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_role_policy_attachment_3" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "eks_node_role_policy_attachment_4" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role" "eks_pod_execution_role" {
  name               = "eks-pod-execution-role"
  assume_role_policy = file("${path.module}/iam-policy-documents/eks-fargate-trust-policy.json")
}

resource "aws_iam_role_policy_attachment" "eks_pod_execution_role_policy_attachment_1" {
  role       = aws_iam_role.eks_pod_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}
