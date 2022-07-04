variable "src" {
  type = object({
    backend         = string
    config_key_ecr  = string
    config_key_node = string
    msa             = string
    image_version   = string
    msa_config = list(object({
      identify             = string
      replicas             = string
      rabbitmq_queue       = string
      rabbitmq_exchange    = string
      rabbitmq_routing_key = string
    }))
  })
}
