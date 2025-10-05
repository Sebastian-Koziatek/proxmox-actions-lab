variable "vm_name" {
  description = "Nazwa maszyny wirtualnej"
  type        = string
}

variable "mac_address" {
  description = "MAC address dla interfejsu sieciowego"
  type        = string
}

variable "vm_tags" {
  description = "Tagi przypisane do VM"
  type        = list(string)
}
