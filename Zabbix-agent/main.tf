# Lista wszystkich maszyn Zabbix Agent i ich parametrów
# VMID: 1000 + ostatni oktet IP (10.123.1.91-105 → VMID 1091-1105)
locals {
  all_vms = {
    1  = { name = "vmzabbixagent01", mac = "BC:24:11:F1:A3:01", ip = "10.123.1.91",  vmid = 1091 }
    2  = { name = "vmzabbixagent02", mac = "BC:24:11:F1:A3:02", ip = "10.123.1.92",  vmid = 1092 }
    3  = { name = "vmzabbixagent03", mac = "BC:24:11:F1:A3:03", ip = "10.123.1.93",  vmid = 1093 }
    4  = { name = "vmzabbixagent04", mac = "BC:24:11:F1:A3:04", ip = "10.123.1.94",  vmid = 1094 }
    5  = { name = "vmzabbixagent05", mac = "BC:24:11:F1:A3:05", ip = "10.123.1.95",  vmid = 1095 }
    6  = { name = "vmzabbixagent06", mac = "BC:24:11:F1:A3:06", ip = "10.123.1.96",  vmid = 1096 }
    7  = { name = "vmzabbixagent07", mac = "BC:24:11:F1:A3:07", ip = "10.123.1.97",  vmid = 1097 }
    8  = { name = "vmzabbixagent08", mac = "BC:24:11:F1:A3:08", ip = "10.123.1.98",  vmid = 1098 }
    9  = { name = "vmzabbixagent09", mac = "BC:24:11:F1:A3:09", ip = "10.123.1.99",  vmid = 1099 }
    10 = { name = "vmzabbixagent10", mac = "BC:24:11:F1:A3:0A", ip = "10.123.1.100", vmid = 1100 }
    11 = { name = "vmzabbixagent11", mac = "BC:24:11:F1:A3:0B", ip = "10.123.1.101", vmid = 1101 }
    12 = { name = "vmzabbixagent12", mac = "BC:24:11:F1:A3:0C", ip = "10.123.1.102", vmid = 1102 }
    13 = { name = "vmzabbixagent13", mac = "BC:24:11:F1:A3:0D", ip = "10.123.1.103", vmid = 1103 }
    14 = { name = "vmzabbixagent14", mac = "BC:24:11:F1:A3:0E", ip = "10.123.1.104", vmid = 1104 }
    15 = { name = "vmzabbixagent15", mac = "BC:24:11:F1:A3:0F", ip = "10.123.1.105", vmid = 1105 }
  }

  zakres_lista = var.zakres == "all" ? [for i in range(1,16) : i] : distinct(flatten([for part in split(",", var.zakres) : (
    can(regex("^\\d+$", part)) ? [tonumber(part)] : (
      can(regex("^(\\d+)-(\\d+)$", part)) ? [for i in range(tonumber(regex("^(\\d+)-(\\d+)$", part)[0]), tonumber(regex("^(\\d+)-(\\d+)$", part)[1])+1) : i] : []
    )
  )]))
  selected_vms = { for k, v in local.all_vms : k => v if contains(local.zakres_lista, tonumber(k)) }
}

module "vm" {
  source   = "./modules/universal-vm"
  for_each = local.selected_vms

  vm_id          = each.value.vmid
  vm_name        = each.value.name
  node_name      = "proxmox"
  clone_vm_id    = var.clone_vm_id
  cores          = var.cores
  sockets        = var.sockets
  cpu_type       = var.cpu_type
  memory         = var.memory
  net_model      = var.net_model
  net_bridge     = var.net_bridge
  mac_address    = each.value.mac
  disk_interface = "scsi0"
  disk_size      = 60
  disk_datastore = "Samsung980"
  os_type        = "l26"
  vm_tags        = var.vm_tags
  enable_agent   = false
}

output "selected_vms" {
  description = "Lista wybranych VM do zarządzania"
  value       = { for k, v in local.selected_vms : k => v.name }
}

output "created_vms" {
  description = "Informacje o VM zarządzanych przez Terraform"
  value       = { for k, v in module.vm : k => v.vm_basic }
}
