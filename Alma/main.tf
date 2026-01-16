# Lista wszystkich maszyn Alma i ich parametrów
locals {
  all_vms = {
    1 = { name = "vmalmasz01", mac = "BC:24:11:B6:AB:AB", ip = "10.123.1.21" }
    2 = { name = "vmalmasz02", mac = "BC:24:11:98:F5:05", ip = "10.123.1.22" }
    3 = { name = "vmalmasz03", mac = "BC:24:11:18:A9:2C", ip = "10.123.1.23" }
    4 = { name = "vmalmasz04", mac = "BC:24:11:49:16:7A", ip = "10.123.1.24" }
    5 = { name = "vmalmasz05", mac = "BC:24:11:B7:14:0C", ip = "10.123.1.25" }
    6 = { name = "vmalmasz06", mac = "BC:24:11:65:AC:8E", ip = "10.123.1.26" }
    7 = { name = "vmalmasz07", mac = "BC:24:11:18:AB:A5", ip = "10.123.1.27" }
    8 = { name = "vmalmasz08", mac = "BC:24:11:5E:81:8D", ip = "10.123.1.28" }
    9 = { name = "vmalmasz09", mac = "BC:24:11:01:38:5F", ip = "10.123.1.29" }
    10 = { name = "vmalmasz10", mac = "BC:24:11:1B:8D:A5", ip = "10.123.1.30" }
    11 = { name = "vmalmasz11", mac = "BC:24:11:2E:54:5E", ip = "10.123.1.31" }
    12 = { name = "vmalmasz12", mac = "BC:24:11:79:97:27", ip = "10.123.1.32" }
    13 = { name = "vmalmasz13", mac = "BC:24:11:78:C1:17", ip = "10.123.1.33" }
    14 = { name = "vmalmasz14", mac = "BC:24:11:7C:E0:1B", ip = "10.123.1.34" }
    15 = { name = "vmalmasz15", mac = "BC:24:11:61:15:64", ip = "10.123.1.35" }
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