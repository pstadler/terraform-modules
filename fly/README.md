# Terraform Fly + Cloudflare DNS

Simple terraform module to deploy apps to [Fly](https://fly.io/) using [Cloudflare](https://www.cloudflare.com/) as DNS provider.

## Usage

```tf
module "app" {
  source = "github.com/pstadler/terraform-modules/fly"

  app_name        = "example-pstadler-dev"
  fly_org         = "pstadler-dev"
  fly_region      = "ams"
  tld             = "pstadler.dev"
  dns_records = [
    { name = "example", type = "CNAME" },
    { name = "example2", type = "A" }
  ]
  volumes = [{
    name = "data"
    size = 3
  }]
  fly_api_token        = var.fly_api_token
  cloudflare_api_token = var.cloudflare_api_token
}

variable "fly_api_token" {
  default = ""
}

variable "cloudflare_api_token" {
  default = ""
}
```

### Environment variables

```sh
export TF_VAR_fly_api_token=<token>
export TF_VAR_cloudflare_api_token=<token>
```