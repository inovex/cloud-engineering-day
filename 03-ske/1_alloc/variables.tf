# These variables can be assigned to in the *.auto.tfvars file

variable "project_id" {
  type        = string
  description = "STACKIT project where to work in"
}

variable "domain" {
  type        = string
  description = <<-EOT
    Subdomain below .stackit.zone you want to allocate.
    Free stackit subdomains:
     .runs.onstackit.cloud
     .stackit.{rocks,gg,zone,run}
  EOT

  validation {
    condition = (
      can(regex(".+\\.runs\\.onstackit\\.cloud$", var.domain)) ||
      can(regex(".+\\.stackit\\.(rocks|gg|zone|run)$", var.domain))
    )
    error_message = "The domain must be a valid subdomain ending in '.runs.onstackit.cloud' or '.stackit.{rocks,gg,zone,run}'."
  }
}

variable "name_prefix" {
  type        = string
  default     = "training"
  description = <<-EOT
    Common prefix (=beginning) for all named STACKIT resources to be allocated. Will be visible in Web Portal and CLI.
    In a shared organization, consider your initials such as "John Doe" becomes "jd".
    If you organization is shared beyond this course, consider a context such as "training-jd"
    
    Attention: Assert that Name prefix + name suffix string length <= 11, because SKE node pool has a maximum length of 15.
    That is, a rule of thumb is a name prefix and name suffix not exceed 4 characters each in length!
  EOT

  validation {
    condition     = length(var.name_prefix) <= 5
    error_message = "The name prefix must not exceed 5 characters in length."
  }
}

variable "name_suffix" {
  type        = string
  default     = "1"
  description = <<-EOT
    Common suffix (=ending) for all named STACKIT resources to be allocated. Will be visible in Web Portal and CLI.
    If you run tf multiple times and runs fail or you end in a sick state, consider increasing this number and
    delete old (stale, dangling) resources manually via web browser or CLI.
  EOT
}
