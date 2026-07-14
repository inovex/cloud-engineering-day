# This file writes Terraform outputs into ./generated as human-readable files
# that are consumed by downstream steps (2_basics shell scripts, Helm values).
#
# Pattern note: writing files as a side effect of terraform apply is a pragmatic
# convenience for local workflows and training environments. In a CI/CD pipeline
# you would instead pass outputs between stages via environment variables,
# a secrets manager (e.g. Vault), or a pipeline artifact store — avoiding the
# need to commit or share generated files at all.

locals {
  hostname = "nextcloud"
}

resource "local_file" "chart_values" {
  content = templatefile("${path.module}/templates/nextcloud-values.yaml.tmpl", {
    host    = local.hostname
    domain  = var.domain
    mariadb = local.mariadb_access
    s3      = local.s3_access
    maxPods = stackit_ske_cluster.this.node_pools[0].maximum
  })
  filename = "${path.module}/generated/nextcloud_chart_values.yml"
}

# dotenv flat output, useful for sourcing in shell scripts
locals {
  tf_flat_output = merge(
    {
      domain  = var.domain
      project = var.project_id
      # sa_json = local.stackit_service_account_key
    },
    { for k, v in local.mariadb_access : "mariadb_${k}" => v },
    { for k, v in local.s3_access : "s3_${k}" => v }
  )

  dotenv_content = join("\n", [
    for k in sort(keys(local.tf_flat_output)) :
    "${upper(k)}=${jsonencode(local.tf_flat_output[k])}"
  ])
}

resource "local_file" "generated_env" {
  content  = local.dotenv_content
  filename = "${path.module}/generated/tf_output.env"
}

# This is just passing input data to a well-known output path
#resource "local_file" "service_account" {
#  content = file(var.stackit_service_account_key_file)
#  filename = "${path.module}/generated/sa.json"
#}
