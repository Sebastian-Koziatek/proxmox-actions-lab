terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.5"
    }
  }
}
resource "proxmox_virtual_environment_vm" "vmgrafanasrv08" {
  name       = "vmgrafanasrv08"
  node_name  = "proxmox"

  clone {
    vm_id = 997
    full  = true
  }

  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = 2048
  }

  network_device {
    model       = "e1000"
    bridge      = "vmbr0"
    mac_address = "BC:24:11:E9:9E:E1"
  }

  disk {
    interface    = "scsi0"
    size         = 50
    datastore_id = "Samsung980"
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = false
  }

  tags = var.vm_tags 

  connection {
    type     = "ssh"
    user     = "szkolenie"
    password = "szkolenie"
    host     = "10.123.1.108"
    port     = 22
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/^#Port .*/Port 60601/' /etc/ssh/sshd_config",
      "sudo sed -i 's/^Port .*/Port 60601/' /etc/ssh/sshd_config",
      "sudo systemctl daemon-reexec",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart ssh",
    ]
  }
}
