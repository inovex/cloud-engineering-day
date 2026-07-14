terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = "0.101.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.0"
    }
  }
}

provider "stackit" {
  default_region = "eu01"
}
