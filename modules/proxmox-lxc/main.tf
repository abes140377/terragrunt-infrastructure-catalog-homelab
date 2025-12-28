data "homelab_naming" "this" {
  env = var.env
  app = var.app
}

data "local_file" "ssh_public_key" {
  filename = var.ssh_public_key_path
}

resource "proxmox_virtual_environment_container" "this" {
  node_name    = "pve1"
  unprivileged = true

  initialization {
    hostname = data.homelab_naming.this.name

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      password = var.password
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  network_interface {
    name   = "veth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }
}

resource "proxmox_virtual_environment_pool_membership" "this" {
  count = var.pool_id != "" ? 1 : 0

  pool_id = var.pool_id
  vm_id   = proxmox_virtual_environment_container.this.vm_id
}
