resource "stackit_ske_cluster" "this" {
  project_id = var.project_id
  name       = "${var.name_prefix}-m23" # The cannot be longer than 11 characters, so we just use the prefix

  node_pools = [
    {
      name = "p1"
      #machine_type       = "c1a.2d" # one of the cheapest available
      machine_type       = "c1a.4d" # 4 CPU, 8 GB RAM; roughly 2 times the cost and power of c1a.2d
      minimum            = 2
      max_surge          = 2
      maximum            = 10
      availability_zones = ["eu01-2"]
      volume_size        = 25
      volume_type        = "storage_premium_perf4"
    }
  ]
  maintenance = {
    enable_kubernetes_version_updates    = true
    enable_machine_image_version_updates = true
    start                                = "01:00:00Z"
    end                                  = "02:00:00Z"
  }
  extensions = {
    dns = {
      enabled = true,
      zones   = [stackit_dns_zone.this.dns_name]
    }
    # observability = {
    #   enabled     = true
    #   instance_id = stackit_observability_instance.this.instance_id
    # }
  }
}

resource "stackit_ske_kubeconfig" "this" {
  project_id   = var.project_id
  cluster_name = stackit_ske_cluster.this.name

  refresh    = true
  expiration = 60 * 60 * 24 * 30 # one month (base unit: seconds). Max is 6 months
}

resource "local_file" "kubeconfig_output" {
  content  = stackit_ske_kubeconfig.this.kube_config
  filename = "${path.module}/generated/kubeconfig-${stackit_ske_cluster.this.name}.yaml"
}
