src = {
  backend    = "s3"
  config_key = "terraform/fintechless/ftl-msa-rmq-out/aws_iam_eks_node_group/terraform.tfstate"

  role_name   = "ftl-msa-rmq-out-node-group-iam-role"
  description = "IAM role used by the Fintechless EKS cluster"

  aws_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]
}
