src = {
  backend         = "s3"
  config_key_ecr  = "terraform/fintechless/ftl-msa-rmq-out/aws_ecr_repository/terraform.tfstate"
  config_key_node = "terraform/fintechless/ftl-msa-rmq-out/aws_eks_node_group/terraform.tfstate"

  msa           = "rmq-out"
  image_version = "latest"
  msa_config = [{
    identify             = "iso20022-msg-in-pacs-008"
    replicas             = 1
    rabbitmq_queue       = "queue-iso20022-msg-in-pacs-008"
    rabbitmq_exchange    = "exchange-iso20022-msg-in-pacs-008"
    rabbitmq_routing_key = "queue-iso20022-msg-in-pacs-008"
    }
  ]
}
