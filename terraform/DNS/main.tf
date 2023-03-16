  terraform {
  cloud {
    organization = "smothersell"
    workspaces {
      name = "DNS-Manager"
    }
  }
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {
  alias    = "dns_records"
  email    = var.cloudflare_email
  api_key  = var.cloudflare_api_key
}


