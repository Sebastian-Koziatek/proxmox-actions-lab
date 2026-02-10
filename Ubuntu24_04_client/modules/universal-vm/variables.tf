variable "vm_id" {
  description = "ID maszyny wirtualnej (VMID)"
  type        = number
  default     = null
}
variable "vm_name" { 
  description = "Nazwa tworzonej VM"
  type = string 
}
variable "node_name" { 
  description = "Nazwa noda Proxmox"
  type = string 
}
variable "clone_vm_id" { 
  description = "ID template wykorzystywanego do klonowania"
  type = number 
}
variable "cores" { 
  description = "Liczba vCPU cores"
  type = number 
}
variable "sockets" { 
  description = "Liczba sockets"
  type = number 
}
variable "cpu_type" { 
  description = "Typ CPU (np. host)"
  type = string 
}
variable "memory" { 
  description = "RAM w MB"
  type = number 
}
variable "net_model" { 
  description = "Model karty sieciowej"
  type = string 
}
variable "net_bridge" { 
  description = "Bridge sieciowy (np. vmbr0)"
  type = string 
}
variable "mac_address" { 
  description = "MAC address przypisany do VM"
  type = string 
}
variable "disk_interface" { 
  description = "Interfejs dysku (np. scsi0)"
  type = string 
}
variable "disk_size" { 
  description = "Rozmiar dysku w GB"
  type = number 
}
variable "disk_datastore" { 
  description = "Nazwa datastore / storage ID"
  type = string 
}
variable "os_type" { 
  description = "Typ OS w Proxmox (np. l26)"
  type = string 
}
variable "vm_tags" { 
  description = "Lista tagów dla VM"
  type = list(string)
  default = []
}
variable "enable_agent" {
  description = "Czy włączyć guest agent (jeśli zainstalowany w template)"
  type        = bool
  default     = false
}
