# Lista wszystkich maszyn Monitoring Client i ich parametrów
# VMID: 1000 + ostatni oktet IP (10.123.1.76-90 → VMID 1076-1090)
locals {
  all_vms = {
    1 = { name = "vmmonitoringclient01", mac = "BC:24:11:F1:A2:01", ip = "10.123.1.76", vmid = 1076 }
    2 = { name = "vmmonitoringclient02", mac = "BC:24:11:F1:A2:02", ip = "10.123.1.77", vmid = 1077 }
    3 = { name = "vmmonitoringclient03", mac = "BC:24:11:F1:A2:03", ip = "10.123.1.78", vmid = 1078 }
    4 = { name = "vmmonitoringclient04", mac = "BC:24:11:F1:A2:04", ip = "10.123.1.79", vmid = 1079 }
    5 = { name = "vmmonitoringclient05", mac = "BC:24:11:F1:A2:05", ip = "10.123.1.80", vmid = 1080 }
    6 = { name = "vmmonitoringclient06", mac = "BC:24:11:F1:A2:06", ip = "10.123.1.81", vmid = 1081 }
    7 = { name = "vmmonitoringclient07", mac = "BC:24:11:F1:A2:07", ip = "10.123.1.82", vmid = 1082 }
    8 = { name = "vmmonitoringclient08", mac = "BC:24:11:F1:A2:08", ip = "10.123.1.83", vmid = 1083 }
    9 = { name = "vmmonitoringclient09", mac = "BC:24:11:F1:A2:09", ip = "10.123.1.84", vmid = 1084 }
    10 = { name = "vmmonitoringclient10", mac = "BC:24:11:F1:A2:0A", ip = "10.123.1.85", vmid = 1085 }
    11 = { name = "vmmonitoringclient11", mac = "BC:24:11:F1:A2:0B", ip = "10.123.1.86", vmid = 1086 }
    12 = { name = "vmmonitoringclient12", mac = "BC:24:11:F1:A2:0C", ip = "10.123.1.87", vmid = 1087 }
    13 = { name = "vmmonitoringclient13", mac = "BC:24:11:F1:A2:0D", ip = "10.123.1.88", vmid = 1088 }
    14 = { name = "vmmonitoringclient14", mac = "BC:24:11:F1:A2:0E", ip = "10.123.1.89", vmid = 1089 }
    15 = { name = "vmmonitoringclient15", mac = "BC:24:11:F1:A2:0F", ip = "10.123.1.90", vmid = 1090 }
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
