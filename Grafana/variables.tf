variable "zakres" {
  description = "Zakres maszyn do utworzenia, np. 1,2,4-6 lub all"
  type        = string
  default     = "all"
}
variable "proxmox_api_token" {
  description = "API token do autoryzacji w Proxmox"
  type        = string
  sensitive   = true
}

variable "vm_tags" {
  description = "Tagi przypisane do VM"
  type        = list(string)
  default     = ["grafana", "ubuntu", "terraform"]
}

variable "machines" {
  type    = list(string)
  default = []
}
