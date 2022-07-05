src = {
  backend    = "s3"
  config_key = "terraform/fintechless/ftl-msa-rmq-out/aws_iam_eks_node_group/terraform.tfstate"

  node_group_name = "ftl-msa-rmq-out-node-group"
  ami_type        = "AL2_x86_64"
  capacity_type   = "SPOT"
  instance_types  = ["t3.medium"]

  scaling_config = {
    desired_size = 1
    max_size     = 25
    min_size     = 1
  }
}