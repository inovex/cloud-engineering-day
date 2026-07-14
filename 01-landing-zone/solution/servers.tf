locals {
  // stackit image list
  image_id = "2379aa40-becb-4143-87c4-5f0702c3b0bb" # Ubuntu 26.04
  # stackit server machine-type list
  machine_type = "g3i.1" # Intel Emerald Rapids 6548Y+ CPU instance, 1 vCPU, 4 GB RAM

  cloud_init_shell_scripts = fileset("cloud-init/", "*.sh")

  jumphost_cloud_config = templatefile("${path.module}/cloud-init/cloud-init-jumphost.yaml.tpl", {
    ssh_public_key            = stackit_key_pair.this.public_key,
    default_jumphost_password = random_password.jumphost.result,
    fqdn                      = stackit_dns_record_set.this.name
  })
}
# The following setup allows password-only access in case ssh keys
# are not working for you. We use a strong password generated
# by terraform. It is recommended to disallow all
# password authentification for hardening.
resource "random_password" "jumphost" {
  length = 15
  # no special characters for easier copying and in order to avoid
  # escaping in cloud-init yaml file
  special = false
}

output "jumphost_password" {
  value     = random_password.jumphost.result
  sensitive = true
}

resource "stackit_key_pair" "this" {
  name       = "${var.name_prefix}-rsa-key-${var.name_suffix}"
  public_key = chomp(file(var.ssh_public_key_path))
}


data "cloudinit_config" "jumphost" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = local.jumphost_cloud_config
  }

  dynamic "part" {
    for_each = local.cloud_init_shell_scripts
    content {
      filename     = part.value
      content_type = "text/x-shellscript"
      content      = file("cloud-init/${part.value}")
    }
  }
}

resource "stackit_server" "jumphost" {
  project_id = var.project_id
  name       = "${var.name_prefix}-m10-jumphost-${var.name_suffix}"

  boot_volume = {
    source_type           = "image"
    size                  = 64             # GB
    source_id             = local.image_id # Ubuntu 26.04
    delete_on_termination = true
  }
  machine_type = local.machine_type # flavors
  keypair_name = stackit_key_pair.this.name

  user_data = data.cloudinit_config.jumphost.rendered

  network_interfaces = [
    stackit_network_interface.this.network_interface_id
  ]
}
