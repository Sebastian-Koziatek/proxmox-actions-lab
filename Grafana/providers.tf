terraform {
  backend "local" {
    path = "/tmp/terraform-grafana.tfstate"
  }
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.5"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://10.123.0.3:8006/"
  insecure  = true
  api_token = var.proxmox_api_token
}

