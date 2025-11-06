variable "vm_name" {
  description = "The name of the virtual machine."
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
