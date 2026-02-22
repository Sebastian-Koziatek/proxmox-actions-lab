# Lista wszystkich maszyn Alma i ich parametrów
# VMID: 1000 + ostatni oktet IP (10.123.1.21-35 → VMID 1021-1035)
locals {
  all_vms = {
    1 = { name = "vmalmasz01", mac = "BC:24:11:B6:AB:AB", ip = "10.123.1.21", vmid = 1021 }
    2 = { name = "vmalmasz02", mac = "BC:24:11:98:F5:05", ip = "10.123.1.22", vmid = 1022 }
    3 = { name = "vmalmasz03", mac = "BC:24:11:18:A9:2C", ip = "10.123.1.23", vmid = 1023 }
    4 = { name = "vmalmasz04", mac = "BC:24:11:49:16:7A", ip = "10.123.1.24", vmid = 1024 }
    5 = { name = "vmalmasz05", mac = "BC:24:11:B7:14:0C", ip = "10.123.1.25", vmid = 1025 }
    6 = { name = "vmalmasz06", mac = "BC:24:11:65:AC:8E", ip = "10.123.1.26", vmid = 1026 }
    7 = { name = "vmalmasz07", mac = "BC:24:11:18:AB:A5", ip = "10.123.1.27", vmid = 1027 }
    8 = { name = "vmalmasz08", mac = "BC:24:11:5E:81:8D", ip = "10.123.1.28", vmid = 1028 }
    9 = { name = "vmalmasz09", mac = "BC:24:11:01:38:5F", ip = "10.123.1.29", vmid = 1029 }
    10 = { name = "vmalmasz10", mac = "BC:24:11:1B:8D:A5", ip = "10.123.1.30", vmid = 1030 }
    11 = { name = "vmalmasz11", mac = "BC:24:11:2E:54:5E", ip = "10.123.1.31", vmid = 1031 }
    12 = { name = "vmalmasz12", mac = "BC:24:11:79:97:27", ip = "10.123.1.32", vmid = 1032 }
    13 = { name = "vmalmasz13", mac = "BC:24:11:78:C1:17", ip = "10.123.1.33", vmid = 1033 }
    14 = { name = "vmalmasz14", mac = "BC:24:11:7C:E0:1B", ip = "10.123.1.34", vmid = 1034 }
    15 = { name = "vmalmasz15", mac = "BC:24:11:61:15:64", ip = "10.123.1.35", vmid = 1035 }
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
  source   = "./modules/universal-vm"
  for_each = local.selected_vms  # Wszystkie wybrane VM

  vm_id         = each.value.vmid
  vm_name       = each.value.name
  node_name     = "proxmox"
  clone_vm_id   = var.clone_vm_id
  cores         = var.cores
  sockets       = var.sockets
  cpu_type      = var.cpu_type
  memory        = var.memory
  net_model     = var.net_model
  net_bridge    = var.net_bridge
  mac_address   = each.value.mac
  disk_interface = "scsi0"
  disk_size     = 50
  disk_datastore = "Samsung980"
  os_type       = "l26"
  vm_tags       = var.vm_tags
  enable_agent  = false
  
  # depends_on = [null_resource.check_vm_conflicts]  # WYŁĄCZONE
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