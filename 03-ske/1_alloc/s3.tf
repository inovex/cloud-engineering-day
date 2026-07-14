resource "stackit_objectstorage_bucket" "this" {
  project_id = var.project_id
  name       = "${var.name_prefix}-m23-${var.name_suffix}" # this will be the public bucket name
}

resource "stackit_objectstorage_credentials_group" "this" {
  project_id = var.project_id
  name       = "${var.name_prefix}-m23-cg-${var.name_suffix}"

  depends_on = [
    # This is not actually a dependency, but in a new project, the S3 service might not be enabled yet. The terraform
    # provider attempts to enable the service implicitly, but if two resources do that at the same time, this results
    # in a 409 error.
    stackit_objectstorage_bucket.this,
  ]
}

resource "stackit_objectstorage_credential" "this" {
  project_id           = var.project_id
  credentials_group_id = stackit_objectstorage_credentials_group.this.credentials_group_id

  expiration_timestamp = "2027-12-31T00:00:00Z"
}

locals {
  parsed_url_path_style = regex(
    "(?:(?P<scheme>[^:/?#]+):)?(?://(?P<authority>[^/?#]*))?(?P<path>[^?#]*)(?:\\?(?P<query>[^#]*))?(?:#(?P<fragment>.*))?",
    stackit_objectstorage_bucket.this.url_path_style
  )

  # this structure names follow the relevant part in the nextcloud helm chart
  s3_access = {
    host       = local.parsed_url_path_style.authority
    bucket     = stackit_objectstorage_bucket.this.name
    access_key = stackit_objectstorage_credential.this.access_key
    secret_key = stackit_objectstorage_credential.this.secret_access_key
  }
}

output "s3_acess" {
  value     = local.s3_access
  sensitive = true
}

resource "local_file" "s3cmd_config" {
  content = templatefile("${path.module}/templates/s3cfg.tmpl", {
    s3 = local.s3_access
  })
  filename = "${path.module}/generated/s3cfg"
}
