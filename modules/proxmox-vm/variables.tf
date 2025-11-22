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
