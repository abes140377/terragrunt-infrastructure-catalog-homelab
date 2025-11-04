variable "vms" {
  description = <<-EOT
    Map of VMs to create. Key is a unique VM identifier, value is VM configuration.

    Example:
    vms = {
      "web01" = {
        vm_name = "web-server-01"
        memory  = 4096
        cores   = 2
        pool_id = "web-pool"
      }
      "db01" = {
        vm_name = "database-01"
        memory  = 8192
        cores   = 4
      }
    }
  EOT
  type = map(object({
    vm_name = string
    memory  = optional(number, 2048)
    cores   = optional(number, 2)
    pool_id = optional(string, "")
  }))
  default = {}
}
