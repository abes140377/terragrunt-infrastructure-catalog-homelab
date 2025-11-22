variable "env" {
  description = "The environment this compute resource belongs to (e.g., staging, prod)."
  type        = string
}

variable "app" {
  description = "The name of the application this compute resource belongs to (e.g., web, db)."
  type        = string
}

variable "password" {
  description = "The password for the root user of the LXC container."
  type        = string
  sensitive   = true
}

variable "pool_id" {
  description = "The ID of the Proxmox pool to which the LXC container will be assigned."
  type        = string
  default     = ""
}
