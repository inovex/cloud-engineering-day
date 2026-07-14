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

resource "stackit_security_group_rule" "ssh" {
  project_id        = var.project_id
  security_group_id = stackit_security_group.this.security_group_id
  description       = "Allow SSH access to the jumphost"
  direction         = "ingress"
  ether_type        = "IPv4"
  protocol = {
    name = "tcp"
  }
  port_range = {
    min = 22
    max = 22
  }
  ip_range = "0.0.0.0/0"
}

resource "stackit_security_group_rule" "wg" {
  project_id        = var.project_id
  security_group_id = stackit_security_group.this.security_group_id
  description       = "Allow wireguard access to the jumphost"
  direction         = "ingress"
  ether_type        = "IPv4"
  protocol = {
    name = "udp"
  }
  port_range = {
    min = 51820
    max = 51820
  }
  ip_range = "0.0.0.0/0"
}

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
