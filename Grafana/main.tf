# Lista wszystkich maszyn i ich parametrów
# VMID: 1000 + ostatni oktet IP (10.123.1.41-55 → VMID 1041-1055)
locals {
  all_vms = {
    1 = { name = "vmgrafanasrv01", mac = "BC:24:11:EE:87:3D", ip = "10.123.1.41", vmid = 1041 }
    2 = { name = "vmgrafanasrv02", mac = "BC:24:11:3B:9C:18", ip = "10.123.1.42", vmid = 1042 }
    3 = { name = "vmgrafanasrv03", mac = "BC:24:11:58:C0:47", ip = "10.123.1.43", vmid = 1043 }
    4 = { name = "vmgrafanasrv04", mac = "BC:24:11:32:30:50", ip = "10.123.1.44", vmid = 1044 }
    5 = { name = "vmgrafanasrv05", mac = "BC:24:11:C4:8C:E4", ip = "10.123.1.45", vmid = 1045 }
    6 = { name = "vmgrafanasrv06", mac = "BC:24:11:C3:E0:4F", ip = "10.123.1.46", vmid = 1046 }
    7 = { name = "vmgrafanasrv07", mac = "BC:24:11:C9:1D:CD", ip = "10.123.1.47", vmid = 1047 }
    8 = { name = "vmgrafanasrv08", mac = "BC:24:11:E9:9E:E1", ip = "10.123.1.48", vmid = 1048 }
    9 = { name = "vmgrafanasrv09", mac = "BC:24:11:15:87:74", ip = "10.123.1.49", vmid = 1049 }
    10 = { name = "vmgrafanasrv10", mac = "BC:24:11:12:3C:4B", ip = "10.123.1.50", vmid = 1050 }
    11 = { name = "vmgrafanasrv11", mac = "BC:24:11:10:0C:31", ip = "10.123.1.51", vmid = 1051 }
    12 = { name = "vmgrafanasrv12", mac = "BC:24:11:44:CA:2C", ip = "10.123.1.52", vmid = 1052 }
    13 = { name = "vmgrafanasrv13", mac = "BC:24:11:BD:13:E3", ip = "10.123.1.53", vmid = 1053 }
    14 = { name = "vmgrafanasrv14", mac = "BC:24:11:DE:DD:63", ip = "10.123.1.54", vmid = 1054 }
    15 = { name = "vmgrafanasrv15", mac = "BC:24:11:94:F4:87", ip = "10.123.1.55", vmid = 1055 }
  }

  zakres_lista = var.zakres == "all" ? [for i in range(1,16) : i] : distinct(flatten([for part in split(",", var.zakres) : (
    can(regex("^\\d+$", part)) ? [tonumber(part)] : (
      can(regex("^(\\d+)-(\\d+)$", part)) ? [for i in range(tonumber(regex("^(\\d+)-(\\d+)$", part)[0]), tonumber(regex("^(\\d+)-(\\d+)$", part)[1])+1) : i] : []
    )
  )]))
  selected_vms = { for k, v in local.all_vms : k => v if contains(local.zakres_lista, tonumber(k)) }
}

# Moduł VM dla każdej wybranej maszyny
# Terraform sam zarządza lifecycle na podstawie stanu (tfstate)
module "vm" {
  source        = "./modules/universal-vm"
  for_each      = local.selected_vms  # Wszystkie wybrane VM
  vm_id         = each.value.vmid
  vm_name       = each.value.name
  node_name     = "proxmox"
  clone_vm_id   = 997
  cores         = 2
  sockets       = 1
  cpu_type      = "host"
  memory        = 2048
  net_model     = "e1000"
  net_bridge    = "vmbr0"
  mac_address   = each.value.mac
  # IP statyczny przypisujesz w systemie / po MAC – Terraform tu go nie konfiguruje
  disk_interface = "scsi0"
  disk_size     = 50
  disk_datastore = "Samsung980"
  os_type       = "l26"
  vm_tags       = var.vm_tags
  enable_agent  = false
}

# Outputs
output "selected_vms" {
  description = "Lista wybranych VM do zarządzania"
  value = {for k, v in local.selected_vms : k => v.name}
}

output "created_vms" {
  description = "Informacje o VM zarządzanych przez Terraform"
  value = {for k, v in module.vm : k => v.vm_basic}
}
