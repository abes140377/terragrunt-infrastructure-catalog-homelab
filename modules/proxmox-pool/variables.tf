variable "pool_id" {
  description = "The ID of the Proxmox pool."
  type        = string
}

variable "description" {
  description = "The description of the Proxmox pool."
  type        = string
  default     = "value"
}
