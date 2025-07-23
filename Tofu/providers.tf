terraform {
  required_providers {
    exoscale = {
      source = "exoscale/exoscale"
      version = "0.64.2"
    }
  }
}

 
provider "exoscale" {
  # Configuration options
  key    = var.exoscale_api_key
  secret = var.exoscale_api_secret
}
