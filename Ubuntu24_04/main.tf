# Lista wszystkich maszyn Ubuntu24_04 i ich parametrów
# VMID: 1000 + ostatni oktet IP (10.123.1.61-75 → VMID 1061-1075)
locals {
  all_vms = {
    1 = { name = "vmubuntusz01", mac = "BC:24:11:F1:A1:01", ip = "10.123.1.61", vmid = 1061 }
    2 = { name = "vmubuntusz02", mac = "BC:24:11:F1:A1:02", ip = "10.123.1.62", vmid = 1062 }
    3 = { name = "vmubuntusz03", mac = "BC:24:11:F1:A1:03", ip = "10.123.1.63", vmid = 1063 }
    4 = { name = "vmubuntusz04", mac = "BC:24:11:F1:A1:04", ip = "10.123.1.64", vmid = 1064 }
    5 = { name = "vmubuntusz05", mac = "BC:24:11:F1:A1:05", ip = "10.123.1.65", vmid = 1065 }
    6 = { name = "vmubuntusz06", mac = "BC:24:11:F1:A1:06", ip = "10.123.1.66", vmid = 1066 }
    7 = { name = "vmubuntusz07", mac = "BC:24:11:F1:A1:07", ip = "10.123.1.67", vmid = 1067 }
    8 = { name = "vmubuntusz08", mac = "BC:24:11:F1:A1:08", ip = "10.123.1.68", vmid = 1068 }
    9 = { name = "vmubuntusz09", mac = "BC:24:11:F1:A1:09", ip = "10.123.1.69", vmid = 1069 }
    10 = { name = "vmubuntusz10", mac = "BC:24:11:F1:A1:0A", ip = "10.123.1.70", vmid = 1070 }
    11 = { name = "vmubuntusz11", mac = "BC:24:11:F1:A1:0B", ip = "10.123.1.71", vmid = 1071 }
    12 = { name = "vmubuntusz12", mac = "BC:24:11:F1:A1:0C", ip = "10.123.1.72", vmid = 1072 }
    13 = { name = "vmubuntusz13", mac = "BC:24:11:F1:A1:0D", ip = "10.123.1.73", vmid = 1073 }
    14 = { name = "vmubuntusz14", mac = "BC:24:11:F1:A1:0E", ip = "10.123.1.74", vmid = 1074 }
    15 = { name = "vmubuntusz15", mac = "BC:24:11:F1:A1:0F", ip = "10.123.1.75", vmid = 1075 }
  }

  zakres_lista = var.zakres == "all" ? [for i in range(1,16) : i] : distinct(flatten([for part in split(",", var.zakres) : (
    can(regex("^\\d+$", part)) ? [tonumber(part)] : (
      can(regex("^(\\d+)-(\\d+)$", part)) ? [for i in range(tonumber(regex("^(\\d+)-(\\d+)$", part)[0]), tonumber(regex("^(\\d+)-(\\d+)$", part)[1])+1) : i] : []
    )
  )]))
  selected_vms = { for k, v in local.all_vms : k => v if contains(local.zakres_lista, tonumber(k)) }
}

# Sprawdzanie istniejących VM
data "proxmox_virtual_environment_vms" "existing_vms" {
  node_name = "proxmox"
}

# Filtrowanie VM które już istnieją
locals {
  existing_vm_names = [for vm in data.proxmox_virtual_environment_vms.existing_vms.vms : vm.name]
  
  # DEBUG: wypisz co znaleziono
  debug_existing = "DEBUG: Istniejące VM: ${join(", ", local.existing_vm_names)}"
  debug_requested = "DEBUG: Żądane VM: ${join(", ", [for k, v in local.selected_vms : v.name])}"
  
  # Sprawdzanie czy któraś z wybranych VM już istnieje
  vm_conflicts = [for k, v in local.selected_vms : v.name if contains(local.existing_vm_names, v.name)]
  
  # VM które mogą być utworzone (nie istnieją jeszcze)
  vms_to_create = {for k, v in local.selected_vms : k => v if !contains(local.existing_vm_names, v.name)}
  
  # Komunikat o konflikcie
  conflict_message = length(local.vm_conflicts) > 0 ? "BŁĄD: Te VM już istnieją: ${join(", ", local.vm_conflicts)}" : ""
}

# Resource do sprawdzenia konfliktów (WYŁĄCZONY - nie działa z workflow_dispatch)
# resource "null_resource" "check_vm_conflicts" {
#   count = length(local.vm_conflicts) > 0 ? 1 : 0
#   
#   provisioner "local-exec" {
#     command = "echo '${local.conflict_message}' && exit 1"
#   }
# }

# Moduł VM dla każdej wybranej maszyny
module "vm" {
  source   = "./modules/universal-vm"
  for_each = local.vms_to_create

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

# Outputs z informacją o sprawdzaniu
output "vm_check_status" {
  description = "Status sprawdzania duplikatów VM"
  value = {
    requested_vms    = [for k, v in local.selected_vms : v.name]
    existing_vms     = local.existing_vm_names
    conflicts        = local.vm_conflicts
    to_create        = [for k, v in local.vms_to_create : v.name]
    conflict_message = local.conflict_message != "" ? local.conflict_message : "Brak konfliktów - można tworzyć VM"
  }
}

output "created_vms" {
  description = "Informacje o utworzonych VM"
  value = {for k, v in module.vm : k => v.vm_basic}
}
