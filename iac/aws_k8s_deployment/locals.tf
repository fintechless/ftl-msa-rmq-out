locals {
  dockercontainers = yamldecode(file("${abspath(path.module)}/../../.dockercontainers"))

  cluster_name            = data.terraform_remote_state.aws_eks_cluster.outputs.cluster_name
  cluster_node_group_name = data.terraform_remote_state.aws_eks_node_group.outputs.node_group_name
  ns_name                 = data.terraform_remote_state.aws_eks_cluster.outputs.k8s_namespace
  ecr_repository_url      = data.terraform_remote_state.aws_ecr_repository.outputs.repository_url

  deployment_name = local.dockercontainers.msa[var.src.msa].dpl_name

  msa_config = {
    for item_config in var.src.msa_config : item_config.identify => {
      metadata = {
        name      = "${local.deployment_name}"
        namespace = local.ns_name
        labels    = merge({ "app.kubernetes.io/name" = "${local.deployment_name}-${item_config.identify}" }, local.k8s_labels)
      }
      spec = {
        replicas = item_config.replicas

        selector = {
          match_labels = merge({ "app.kubernetes.io/name" = "${local.deployment_name}-${item_config.identify}" }, local.k8s_labels)
        }

        strategy = {
          type = "RollingUpdate"
          rolling_update = {
            max_surge       = 2
            max_unavailable = 1
          }
        }
        template = {
          metadata = { labels = merge({ "app.kubernetes.io/name" = "${local.deployment_name}-${item_config.identify}" }, local.k8s_labels) }
        }

        containers = [
          {
            name              = local.deployment_name
            image             = "${local.ecr_repository_url}:${var.src.image_version}"
            image_pull_policy = "Always"
            envs = concat(
              local.k8s_default_envs, [
                {
                  name  = "LD_LIBRARY_PATH"
                  value = "/usr/local/lib"
                  }, {
                  name  = "SRC_PARALLEL_COUNT"
                  value = 1
                  }, {
                  name  = "FTL_ENVIRON_CONTEXT_SECRET"
                  value = "${local.ftl_cicd_secret_name},${local.ftl_rmq_secret_name}"
                  }, {
                  name  = "RABBITMQ_QUEUE"
                  value = item_config.rabbitmq_queue
                  }, {
                  name  = "RABBITMQ_EXCHANGE"
                  value = item_config.rabbitmq_exchange
                  }, {
                  name  = "RABBITMQ_ROUTING_KEY"
                  value = item_config.rabbitmq_routing_key
                },
            ])
          }
        ]
        tolerations = [
          {
            key      = "reserved-pool"
            value    = "true"
            operator = "Equal"
            effect   = "NoSchedule"
          }
        ]
        affinity = [{
          node_affinity = [
            {
              required_during_scheduling_ignored_during_execution = [
                {
                  node_selector_term = [
                    {
                      match_expressions = [
                        {
                          key      = "eks.amazonaws.com/nodegroup"
                          operator = "In"
                          values   = [local.cluster_node_group_name]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]

          pod_anti_affinity = [
            {
              required_during_scheduling_ignored_during_execution = [
                {
                  label_selector = [
                    {
                      match_expressions = [
                        {
                          key      = "app.kubernetes.io/name"
                          operator = "In"
                          values   = [local.deployment_name]
                        }
                      ]
                    }
                  ]

                  topology_key = "kubernetes.io/hostname"
                }
              ]
            }
          ]
        }]
      }
    }
  }
  config_ecr = {
    region = data.aws_region.this.name
    bucket = local.ftl_bucket
    key    = var.src.config_key_ecr
  }

  config_node = {
    region = data.aws_region.this.name
    bucket = local.ftl_bucket
    key    = var.src.config_key_node
  }
}
