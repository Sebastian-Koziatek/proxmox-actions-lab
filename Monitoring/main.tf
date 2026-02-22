# Lista wszystkich maszyn Monitoring i ich parametrów
# VMID: 1000 + ostatni oktet IP (10.123.1.61-75 → VMID 1061-1075)
locals {
  all_vms = {
    1 = { name = "vmmonitoring01", mac = "BC:24:11:F1:A1:01", ip = "10.123.1.61", vmid = 1061 }
    2 = { name = "vmmonitoring02", mac = "BC:24:11:F1:A1:02", ip = "10.123.1.62", vmid = 1062 }
    3 = { name = "vmmonitoring03", mac = "BC:24:11:F1:A1:03", ip = "10.123.1.63", vmid = 1063 }
    4 = { name = "vmmonitoring04", mac = "BC:24:11:F1:A1:04", ip = "10.123.1.64", vmid = 1064 }
    5 = { name = "vmmonitoring05", mac = "BC:24:11:F1:A1:05", ip = "10.123.1.65", vmid = 1065 }
    6 = { name = "vmmonitoring06", mac = "BC:24:11:F1:A1:06", ip = "10.123.1.66", vmid = 1066 }
    7 = { name = "vmmonitoring07", mac = "BC:24:11:F1:A1:07", ip = "10.123.1.67", vmid = 1067 }
    8 = { name = "vmmonitoring08", mac = "BC:24:11:F1:A1:08", ip = "10.123.1.68", vmid = 1068 }
    9 = { name = "vmmonitoring09", mac = "BC:24:11:F1:A1:09", ip = "10.123.1.69", vmid = 1069 }
    10 = { name = "vmmonitoring10", mac = "BC:24:11:F1:A1:0A", ip = "10.123.1.70", vmid = 1070 }
    11 = { name = "vmmonitoring11", mac = "BC:24:11:F1:A1:0B", ip = "10.123.1.71", vmid = 1071 }
    12 = { name = "vmmonitoring12", mac = "BC:24:11:F1:A1:0C", ip = "10.123.1.72", vmid = 1072 }
    13 = { name = "vmmonitoring13", mac = "BC:24:11:F1:A1:0D", ip = "10.123.1.73", vmid = 1073 }
    14 = { name = "vmmonitoring14", mac = "BC:24:11:F1:A1:0E", ip = "10.123.1.74", vmid = 1074 }
    15 = { name = "vmmonitoring15", mac = "BC:24:11:F1:A1:0F", ip = "10.123.1.75", vmid = 1075 }
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
  disk_size     = 60
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
