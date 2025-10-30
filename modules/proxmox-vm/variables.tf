variable "vm_name" {
  description = "The name of the Proxmox VM to be created."
  type        = string
}

variable "pool_id" {
  description = "The ID of the Proxmox pool to which the VM will be assigned."
  type        = string
  default     = ""
}
