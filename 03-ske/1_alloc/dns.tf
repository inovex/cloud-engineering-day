resource "stackit_dns_zone" "this" {
  project_id = var.project_id
  name       = "${var.name_prefix}-m23-tf-${var.name_suffix}"

  dns_name      = var.domain
  contact_email = "hostmaster@stackit.cloud"
  type          = "primary"
  acl           = "192.168.0.0/24" #TODO: needed?
  description   = "Managed by terraform, primarily populated by K8S"
  default_ttl   = 3600
}

# you can dig/nsresolve this example but it won't work in the browser
resource "stackit_dns_record_set" "this" {
  project_id = var.project_id
  zone_id    = stackit_dns_zone.this.zone_id
  name       = "example.${stackit_dns_zone.this.dns_name}"

  type    = "CNAME"
  comment = "Example comment"
  # do not forget the . at the end of a FQDN
  records = ["example.com."]
}
