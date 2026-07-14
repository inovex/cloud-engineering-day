resource "stackit_observability_instance" "this" {
  project_id                             = var.project_id
  name                                   = "${var.name_prefix}-m23-${var.name_suffix}"
  plan_name                              = "Observability-Starter-EU01" # cheapest!
  acl                                    = ["1.1.1.1/32", "0.0.0.0/0"]
  metrics_retention_days                 = 90
  metrics_retention_days_5m_downsampling = 90
  metrics_retention_days_1h_downsampling = 90
}

resource "stackit_observability_credential" "this" {
  project_id  = var.project_id
  instance_id = stackit_observability_instance.this.instance_id
}

locals {
  grafana_access = {
    dashboard_url = stackit_observability_instance.this.dashboard_url
    grafana_url   = stackit_observability_instance.this.grafana_url

    push_username = stackit_observability_credential.this.username
    push_password = stackit_observability_credential.this.password

    metrics_url   = stackit_observability_instance.this.metrics_push_url
    otlp_logs_url = stackit_observability_instance.this.otlp_http_logs_url
  }
}

output "grafana_access" {
  value     = local.grafana_access
  sensitive = true
}
