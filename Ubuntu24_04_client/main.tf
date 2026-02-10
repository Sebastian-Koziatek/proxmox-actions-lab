# Lista wszystkich maszyn Ubuntu24_04_client i ich parametrów
# VMID: 1000 + ostatni oktet IP (10.123.1.76-90 → VMID 1076-1090)
locals {
  all_vms = {
    1 = { name = "vmubuntuclsz01", mac = "BC:24:11:F1:A2:01", ip = "10.123.1.76", vmid = 1076 }
    2 = { name = "vmubuntuclsz02", mac = "BC:24:11:F1:A2:02", ip = "10.123.1.77", vmid = 1077 }
    3 = { name = "vmubuntuclsz03", mac = "BC:24:11:F1:A2:03", ip = "10.123.1.78", vmid = 1078 }
    4 = { name = "vmubuntuclsz04", mac = "BC:24:11:F1:A2:04", ip = "10.123.1.79", vmid = 1079 }
    5 = { name = "vmubuntuclsz05", mac = "BC:24:11:F1:A2:05", ip = "10.123.1.80", vmid = 1080 }
    6 = { name = "vmubuntuclsz06", mac = "BC:24:11:F1:A2:06", ip = "10.123.1.81", vmid = 1081 }
    7 = { name = "vmubuntuclsz07", mac = "BC:24:11:F1:A2:07", ip = "10.123.1.82", vmid = 1082 }
    8 = { name = "vmubuntuclsz08", mac = "BC:24:11:F1:A2:08", ip = "10.123.1.83", vmid = 1083 }
    9 = { name = "vmubuntuclsz09", mac = "BC:24:11:F1:A2:09", ip = "10.123.1.84", vmid = 1084 }
    10 = { name = "vmubuntuclsz10", mac = "BC:24:11:F1:A2:0A", ip = "10.123.1.85", vmid = 1085 }
    11 = { name = "vmubuntuclsz11", mac = "BC:24:11:F1:A2:0B", ip = "10.123.1.86", vmid = 1086 }
    12 = { name = "vmubuntuclsz12", mac = "BC:24:11:F1:A2:0C", ip = "10.123.1.87", vmid = 1087 }
    13 = { name = "vmubuntuclsz13", mac = "BC:24:11:F1:A2:0D", ip = "10.123.1.88", vmid = 1088 }
    14 = { name = "vmubuntuclsz14", mac = "BC:24:11:F1:A2:0E", ip = "10.123.1.89", vmid = 1089 }
    15 = { name = "vmubuntuclsz15", mac = "BC:24:11:F1:A2:0F", ip = "10.123.1.90", vmid = 1090 }
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
