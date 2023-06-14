terraform {
  required_providers {
    fly = {
      source  = "fly-apps/fly"
      version = "0.0.22"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.7.1"
    }
  }
}