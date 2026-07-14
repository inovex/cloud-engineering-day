resource "stackit_dns_zone" "this" {
  project_id = var.project_id
  name       = "${var.name_prefix}-m10-tf-${var.name_suffix}"

  dns_name      = var.domain
  contact_email = "hostmaster@stackit.cloud"
  type          = "primary"
  acl           = "192.168.0.0/24"
  description   = "Managed by terraform, for landing zone"
  default_ttl   = 3600
}

# you can dig/nsresolve this example but it won't work in the browser
resource "stackit_dns_record_set" "this" {
  project_id = var.project_id
  zone_id    = stackit_dns_zone.this.zone_id
  name       = "jumphost.${stackit_dns_zone.this.dns_name}"

  type    = "A"
  ttl     = 60
  comment = "Managed by terraform"

  records = [
    # This is not dynamically updated. But while the machine is running, the public IP is stable and can be used for DNS resolution.
    stackit_public_ip.this.ip
  ]
}

output "jumphost_fqdn" {
  value = stackit_dns_record_set.this.name
}
