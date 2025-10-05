terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.5"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.node_name

  # Linked clone dla szybkiego deployment
  clone {
    vm_id = var.clone_vm_id
    full  = false  # Linked clone - znacznie szybszy
  }

  # Bezpieczne timeouty - nie za długie, nie za krótkie
  timeout_clone           = 300   # 5 minut na clone
  timeout_create          = 600   # 10 minut na utworzenie
  timeout_shutdown_vm     = 180   # 3 minuty na shutdown
  timeout_stop_vm         = 120   # 2 minuty na stop
  timeout_start_vm        = 180   # 3 minuty na start

  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  network_device {
    model       = var.net_model
    bridge      = var.net_bridge
    mac_address = var.mac_address
  }

  disk {
    interface    = var.disk_interface
    size         = var.disk_size
    datastore_id = var.disk_datastore
  }

  operating_system { type = var.os_type }

  dynamic "agent" {
    for_each = var.enable_agent ? [1] : []
    content {
      enabled = true
      timeout = "5m"
    }
  }

  tags = var.vm_tags
}


output "vm_basic" {
  value = {
    name = proxmox_virtual_environment_vm.vm.name
    vm_id = proxmox_virtual_environment_vm.vm.vm_id
    node  = proxmox_virtual_environment_vm.vm.node_name
  }
  description = "Podstawowe dane VM"
}
