variable "app" {
  description = "The name of the application this compute resource belongs to (e.g., web, db)."
  type        = string
}

variable "env" {
  description = "The environment this compute resource belongs to (e.g., staging, prod)."
  type        = string
}
