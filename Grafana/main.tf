# Lista wszystkich maszyn i ich parametrów
locals {
  all_vms = {
    1 = { name = "vmgrafanasrv01", mac = "BC:24:11:EE:87:3D", ip = "10.123.1.141" }
    2 = { name = "vmgrafanasrv02", mac = "BC:24:11:3B:9C:18", ip = "10.123.1.142" }
    3 = { name = "vmgrafanasrv03", mac = "BC:24:11:58:C0:47", ip = "10.123.1.143" }
    4 = { name = "vmgrafanasrv04", mac = "BC:24:11:32:30:50", ip = "10.123.1.144" }
    5 = { name = "vmgrafanasrv05", mac = "BC:24:11:C4:8C:E4", ip = "10.123.1.145" }
    6 = { name = "vmgrafanasrv06", mac = "BC:24:11:C3:E0:4F", ip = "10.123.1.146" }
    7 = { name = "vmgrafanasrv07", mac = "BC:24:11:C9:1D:CD", ip = "10.123.1.147" }
    8 = { name = "vmgrafanasrv08", mac = "BC:24:11:E9:9E:E1", ip = "10.123.1.148" }
    9 = { name = "vmgrafanasrv09", mac = "BC:24:11:15:87:74", ip = "10.123.1.149" }
    10 = { name = "vmgrafanasrv10", mac = "BC:24:11:12:3C:4B", ip = "10.123.1.150" }
    11 = { name = "vmgrafanasrv11", mac = "BC:24:11:10:0C:31", ip = "10.123.1.151" }
    12 = { name = "vmgrafanasrv12", mac = "BC:24:11:44:CA:2C", ip = "10.123.1.152" }
    13 = { name = "vmgrafanasrv13", mac = "BC:24:11:BD:13:E3", ip = "10.123.1.153" }
    14 = { name = "vmgrafanasrv14", mac = "BC:24:11:DE:DD:63", ip = "10.123.1.154" }
    15 = { name = "vmgrafanasrv15", mac = "BC:24:11:94:F4:87", ip = "10.123.1.155" }
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

# Zatrzymanie jeśli istnieją konflikty
resource "null_resource" "check_vm_conflicts" {
  count = length(local.vm_conflicts) > 0 ? 1 : 0
  
  provisioner "local-exec" {
    command = "echo '${local.conflict_message}' && exit 1"
  }
}

module "vm" {
  source        = "./modules/universal-vm"
  for_each      = local.vms_to_create  # Tylko VM które nie istnieją
  vm_name       = each.value.name
  node_name     = "proxmox"
  clone_vm_id   = 997
  cores         = 2
  sockets       = 1
  cpu_type      = "host"
  memory        = 2048
  net_model     = "e1000"
  net_bridge    = "vmbr0"
  mac_address   = each.value.mac
  # IP statyczny przypisujesz w systemie / po MAC – Terraform tu go nie konfiguruje
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
