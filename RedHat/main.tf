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
  disk_size     = 50
  disk_datastore = "Samsung980"
  os_type       = "l26"
  vm_tags       = var.vm_tags
  enable_agent  = false
  
  depends_on = [null_resource.check_vm_conflicts]
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