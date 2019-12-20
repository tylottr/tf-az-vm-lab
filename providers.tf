# Config
terraform {
  required_version = ">= 0.12"
}

# Providers
provider "azurerm" {
  version = "~> 1.39"
}

provider "random" {
  version = "~> 2.2"
}

provider "local" {
  version = "~> 1.4"
}

provider "tls" {
  version = "~> 2.1"
}