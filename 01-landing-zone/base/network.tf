resource "stackit_network" "this" {
  project_id = var.project_id
  name       = "${var.name_prefix}-m10-${var.name_suffix}"
  routed     = true
}

resource "stackit_security_group" "this" {
  project_id = var.project_id
  name       = "${var.name_prefix}-m10-${var.name_suffix}"
  stateful   = true
}

# TODO: Complete this rule with all required fields
# resource "stackit_security_group_rule" "ssh" {}
# resource "stackit_security_group_rule" "wireguard" {}

resource "stackit_network_interface" "this" {
  project_id         = var.project_id
  network_id         = stackit_network.this.network_id
  name               = "${var.name_prefix}-m10-${var.name_suffix}"
  security_group_ids = [stackit_security_group.this.security_group_id]
}

resource "stackit_public_ip" "this" {
  project_id           = var.project_id
  network_interface_id = stackit_network_interface.this.network_interface_id
  labels = {
    name = "${var.name_prefix}-m10-${var.name_suffix}"
  }
}

output "public_ip" {
  value = stackit_public_ip.this.ip
}
