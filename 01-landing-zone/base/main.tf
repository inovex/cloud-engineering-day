terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = "0.101.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.4.0"
    }
  }
}

provider "stackit" {
  default_region = "eu01"
}
