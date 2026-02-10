variable "proxmox_api_token" {
  description = "API token do autoryzacji w Proxmox"
  type        = string
  sensitive   = true
}

variable "vm_tags" {
  description = "Tagi przypisane do VM"
  type        = list(string)
  default     = ["monitoring", "ubuntu", "terraform"]
}

variable "zakres" {
  description = "Zakres maszyn do utworzenia (single/range/list)"
  type        = string
  default     = "all"
}

variable "clone_vm_id" {
  description = "ID template VM do klonowania"
  type        = number
  default     = 993
}

variable "cores" {
  description = "Liczba CPU cores na VM"
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Liczba CPU sockets na VM"
  type        = number
  default     = 1
}

variable "cpu_type" {
  description = "Typ CPU"
  type        = string
  default     = "host"
}

variable "memory" {
  description = "RAM w MB"
  type        = number
  default     = 2048
}

variable "net_model" {
  description = "Model karty sieciowej"
  type        = string
  default     = "e1000"
}

variable "net_bridge" {
  description = "Bridge sieciowy"
  type        = string
  default     = "vmbr0"
}
