variable "app_name" { type = string }

variable "tld" { type = string }

variable "dns_records" {
  type = list(object({
    name    = string
    type    = optional(string, "CNAME")
    proxied = optional(bool, false)
    value   = optional(string)
  }))
}

variable "fly_region" {
  type    = string
  default = "ams"
}

variable "volumes" {
  type    = list(object({ name = string, size = number }))
  default = []
}

variable "fly_org" {
  type = string
}

variable "fly_api_token" {
  type = string
}

variable "cloudflare_api_token" {
  type = string
}

locals {
  cloudflare_zone_id = lookup(data.cloudflare_zones.domain_zones.zones[0], "id")
}

provider "fly" {
  fly_api_token = var.fly_api_token
}

resource "fly_app" "app" {
  name = var.app_name
  org  = var.fly_org
}

resource "fly_ip" "ip" {
  app  = fly_app.app.name
  type = "v4"

  depends_on = [fly_app.app]
}

resource "fly_volume" "app" {
  for_each = { for i, v in var.volumes : i => v }

  name   = each.value.name
  app    = fly_app.app.name
  size   = each.value.size
  region = var.fly_region

  depends_on = [fly_app.app]
}

resource "fly_cert" "app" {
  for_each = { for i, v in var.dns_records : i => v if !v.proxied }

  app      = fly_app.app.name
  hostname = "${each.value.name}.${var.tld}"

  depends_on = [fly_app.app]
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "cloudflare_zones" "domain_zones" {
  filter {
    name   = var.tld
    status = "active"
    paused = false
  }
}

resource "cloudflare_record" "domain" {
  for_each = { for i, v in var.dns_records : i => v }

  zone_id = local.cloudflare_zone_id
  name    = each.value.name
  value   = each.value.type == "CNAME" ? "${fly_app.app.name}.fly.dev" : each.value.type == "A" ? fly_ip.ip.address : each.value.value
  type    = each.value.type
  proxied = each.value.proxied

  depends_on = [fly_app.app]
}

resource "cloudflare_record" "cert_validation" {
  for_each = { for i, v in fly_cert.app : i => v }

  zone_id = local.cloudflare_zone_id
  name    = each.value.dnsvalidationhostname
  value   = each.value.dnsvalidationtarget
  type    = "CNAME"
  proxied = false

  depends_on = [fly_app.app]
}