# Lista wszystkich maszyn Zabbix Agent i ich parametrów
locals {
  all_vms = {
    1 = { name = "vmzabbixagent01", mac = "BC:24:11:D3:BF:B6", ip = "10.123.1.161" }
    2 = { name = "vmzabbixagent02", mac = "BC:24:11:AD:2B:BD", ip = "10.123.1.162" }
    3 = { name = "vmzabbixagent03", mac = "BC:24:11:A1:D8:14", ip = "10.123.1.163" }
    4 = { name = "vmzabbixagent04", mac = "BC:24:11:5E:A4:35", ip = "10.123.1.164" }
    5 = { name = "vmzabbixagent05", mac = "BC:24:11:45:04:2E", ip = "10.123.1.165" }
    6 = { name = "vmzabbixagent06", mac = "BC:24:11:4E:39:42", ip = "10.123.1.166" }
    7 = { name = "vmzabbixagent07", mac = "BC:24:11:E1:AB:64", ip = "10.123.1.167" }
    8 = { name = "vmzabbixagent08", mac = "BC:24:11:9A:51:3A", ip = "10.123.1.168" }
    9 = { name = "vmzabbixagent09", mac = "BC:24:11:64:F8:6B", ip = "10.123.1.169" }
    10 = { name = "vmzabbixagent10", mac = "BC:24:11:1A:B3:4C", ip = "10.123.1.170" }
    11 = { name = "vmzabbixagent11", mac = "BC:24:11:D5:04:24", ip = "10.123.1.171" }
    12 = { name = "vmzabbixagent12", mac = "BC:24:11:EB:1C:F5", ip = "10.123.1.172" }
    13 = { name = "vmzabbixagent13", mac = "BC:24:11:C5:9A:4F", ip = "10.123.1.173" }
    14 = { name = "vmzabbixagent14", mac = "BC:24:11:10:F4:ED", ip = "10.123.1.174" }
    15 = { name = "vmzabbixagent15", mac = "BC:24:11:D2:E3:01", ip = "10.123.1.175" }
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
