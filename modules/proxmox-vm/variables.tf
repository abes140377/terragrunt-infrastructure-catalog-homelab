variable "env" {
  description = "The environment this VM belongs to (e.g., dev, staging, prod)."
  type        = string
}

variable "app" {
  description = "The application this VM belongs to (e.g., web, db, api)."
  type        = string
}

variable "memory" {
  description = "The amount of memory in MB allocated to the virtual machine."
  type        = number
  default     = 2048
}

variable "cores" {
  description = "The number of CPU cores allocated to the virtual machine."
  type        = number
  default     = 2
}

variable "pool_id" {
  description = "The ID of the Proxmox pool to which the virtual machine will be assigned."
  type        = string
  default     = ""
}

variable "network_config" {
  description = <<-EOT
    Network configuration for the virtual machine. Supports both DHCP (default) and static IP configuration.

    For DHCP (default):
      network_config = {
        type = "dhcp"
      }

    For static IP:
      network_config = {
        type        = "static"
        ip_address  = "192.168.1.100"
        cidr        = 24
        gateway     = "192.168.1.1"
        dns_servers = ["8.8.8.8", "8.8.4.4"]  # Optional
      }
  EOT
  type = object({
    type        = string
    ip_address  = optional(string)
    cidr        = optional(number)
    gateway     = optional(string)
    dns_servers = optional(list(string), [])
  })
  default = {
    type = "dhcp"
  }

  validation {
    condition     = contains(["dhcp", "static"], var.network_config.type)
    error_message = "network_config.type must be either 'dhcp' or 'static'."
  }

  validation {
    condition = var.network_config.type == "dhcp" || (
      var.network_config.ip_address != null &&
      var.network_config.cidr != null &&
      var.network_config.gateway != null
    )
    error_message = "When network_config.type is 'static', ip_address, cidr, and gateway must be provided."
  }
}
