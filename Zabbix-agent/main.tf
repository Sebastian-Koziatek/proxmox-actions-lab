# Lista wszystkich maszyn Zabbix Agent i ich parametrów
# VMID: 1000 + ostatni oktet IP (10.123.1.161-175 → VMID 1161-1175)
locals {
  all_vms = {
    1  = { name = "vmzabbixagent01", mac = "BC:24:11:D3:BF:B6", ip = "10.123.1.161", vmid = 1161 }
    2  = { name = "vmzabbixagent02", mac = "BC:24:11:AD:2B:BD", ip = "10.123.1.162", vmid = 1162 }
    3  = { name = "vmzabbixagent03", mac = "BC:24:11:A1:D8:14", ip = "10.123.1.163", vmid = 1163 }
    4  = { name = "vmzabbixagent04", mac = "BC:24:11:5E:A4:35", ip = "10.123.1.164", vmid = 1164 }
    5  = { name = "vmzabbixagent05", mac = "BC:24:11:45:04:2E", ip = "10.123.1.165", vmid = 1165 }
    6  = { name = "vmzabbixagent06", mac = "BC:24:11:4E:39:42", ip = "10.123.1.166", vmid = 1166 }
    7  = { name = "vmzabbixagent07", mac = "BC:24:11:E1:AB:64", ip = "10.123.1.167", vmid = 1167 }
    8  = { name = "vmzabbixagent08", mac = "BC:24:11:9A:51:3A", ip = "10.123.1.168", vmid = 1168 }
    9  = { name = "vmzabbixagent09", mac = "BC:24:11:64:F8:6B", ip = "10.123.1.169", vmid = 1169 }
    10 = { name = "vmzabbixagent10", mac = "BC:24:11:1A:B3:4C", ip = "10.123.1.170", vmid = 1170 }
    11 = { name = "vmzabbixagent11", mac = "BC:24:11:D5:04:24", ip = "10.123.1.171", vmid = 1171 }
    12 = { name = "vmzabbixagent12", mac = "BC:24:11:EB:1C:F5", ip = "10.123.1.172", vmid = 1172 }
    13 = { name = "vmzabbixagent13", mac = "BC:24:11:C5:9A:4F", ip = "10.123.1.173", vmid = 1173 }
    14 = { name = "vmzabbixagent14", mac = "BC:24:11:10:F4:ED", ip = "10.123.1.174", vmid = 1174 }
    15 = { name = "vmzabbixagent15", mac = "BC:24:11:D2:E3:01", ip = "10.123.1.175", vmid = 1175 }
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
  disk_size      = 50
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
