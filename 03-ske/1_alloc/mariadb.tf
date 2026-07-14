resource "stackit_mariadb_instance" "this" {
  project_id = var.project_id
  name       = "${var.name_prefix}-m23-${var.name_suffix}"
  version    = "10.11"
  plan_name  = "stackit-mariadb-1.2.10-replica"
  parameters = {
    sgw_acl = "193.148.160.0/19,45.129.40.0/21,45.135.244.0/22,0.0.0.0/0" # TODO global reachability
  }
}

resource "stackit_mariadb_credential" "this" {
  project_id  = var.project_id
  instance_id = stackit_mariadb_instance.this.instance_id
}

locals {
  mariadb_access = {
    hostname      = stackit_mariadb_credential.this.host
    port          = stackit_mariadb_credential.this.port
    database_name = stackit_mariadb_credential.this.name
    username      = stackit_mariadb_credential.this.username
    password      = stackit_mariadb_credential.this.password
  }
}

output "mariadb_access" {
  value     = local.mariadb_access
  sensitive = true
}
