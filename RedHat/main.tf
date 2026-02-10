# Lista wszystkich maszyn RedHat i ich parametrów
# VMID: 1000 + ostatni oktet IP (10.123.1.1-15 → VMID 1001-1015)
locals {
  all_vms = {
    1 = { name = "vmrhelsz01", mac = "BC:24:11:65:CB:EA", ip = "10.123.1.1", vmid = 1001 }
    2 = { name = "vmrhelsz02", mac = "BC:24:11:FB:9F:51", ip = "10.123.1.2", vmid = 1002 }
    3 = { name = "vmrhelsz03", mac = "BC:24:11:BA:D2:5D", ip = "10.123.1.3", vmid = 1003 }
    4 = { name = "vmrhelsz04", mac = "BC:24:11:70:19:C3", ip = "10.123.1.4", vmid = 1004 }
    5 = { name = "vmrhelsz05", mac = "BC:24:11:02:AD:5D", ip = "10.123.1.5", vmid = 1005 }
    6 = { name = "vmrhelsz06", mac = "BC:24:11:8A:CB:50", ip = "10.123.1.6", vmid = 1006 }
    7 = { name = "vmrhelsz07", mac = "BC:24:11:8F:78:BB", ip = "10.123.1.7", vmid = 1007 }
    8 = { name = "vmrhelsz08", mac = "BC:24:11:CD:23:32", ip = "10.123.1.8", vmid = 1008 }
    9 = { name = "vmrhelsz09", mac = "BC:24:11:AA:2F:30", ip = "10.123.1.9", vmid = 1009 }
    10 = { name = "vmrhelsz10", mac = "BC:24:11:28:DD:1F", ip = "10.123.1.10", vmid = 1010 }
    11 = { name = "vmrhelsz11", mac = "BC:24:11:E5:F6:FB", ip = "10.123.1.11", vmid = 1011 }
    12 = { name = "vmrhelsz12", mac = "BC:24:11:73:19:B4", ip = "10.123.1.12", vmid = 1012 }
    13 = { name = "vmrhelsz13", mac = "BC:24:11:19:60:D5", ip = "10.123.1.13", vmid = 1013 }
    14 = { name = "vmrhelsz14", mac = "BC:24:11:0E:7C:71", ip = "10.123.1.14", vmid = 1014 }
    15 = { name = "vmrhelsz15", mac = "BC:24:11:C4:18:59", ip = "10.123.1.15", vmid = 1015 }
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

# Resource do sprawdzenia konfliktów (wykonuje się przed VM)
resource "null_resource" "check_vm_conflicts" {
  count = length(local.vm_conflicts) > 0 ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo '${local.conflict_message}' && exit 1"
  }
}

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
  disk_size     = 50
  disk_datastore = "Samsung980"
  os_type       = "l26"
  vm_tags       = var.vm_tags
  enable_agent  = false
  
  depends_on = [null_resource.check_vm_conflicts]
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