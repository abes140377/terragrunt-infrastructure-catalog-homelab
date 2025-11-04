# Design: Enable Multi-VM Deployment with DNS Resolution

## Architecture Decision: Map-Based For-Each Pattern

### Rationale

After analyzing the existing codebase and Terraform/Terragrunt patterns, we'll use a **map-based `for_each`** approach rather than a list-based approach. This provides:

1. **Stable Resource Addressing**: Map keys become stable Terraform resource identifiers (`proxmox_virtual_environment_vm.this["web01"]`)
2. **Easy Updates**: Modifying a VM's properties doesn't affect other VMs' resource addresses
3. **Clear Intent**: Each VM has a semantic identifier that appears in Terraform state
4. **Extensibility**: Easy to add properties without restructuring the entire configuration

### Alternative Considered: Count-Based Pattern

Using `count` with a list of VM configurations was rejected because:
- Resource addressing changes if list order changes (VM at index 0 becomes index 1)
- Harder to target specific VMs for updates or deletion
- Less intuitive when reading Terraform state

## Component Design

### 1. Module Layer (`modules/proxmox-vm`)

**Input Variable Structure**:

```hcl
variable "vms" {
  description = "Map of VMs to create. Key is VM identifier, value is VM configuration."
  type = map(object({
    vm_name = string
    memory  = optional(number, 2048)
    cores   = optional(number, 2)
    pool_id = optional(string, "")
  }))
  default = {}
}
```

**Resource Definition**:

```hcl
resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.vms

  name      = each.value.vm_name
  node_name = "pve1"
  pool_id   = each.value.pool_id != "" ? each.value.pool_id : null

  clone {
    vm_id = 9002
  }

  agent {
    enabled = true
  }

  memory {
    dedicated = each.value.memory
  }

  # Future: Add CPU cores configuration
  # cpu {
  #   cores = each.value.cores
  # }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}
```

**Output Structure**:

```hcl
output "vms" {
  description = "Map of VM identifiers to their attributes"
  value = {
    for k, vm in proxmox_virtual_environment_vm.this : k => {
      id   = vm.id
      name = vm.name
      ipv4 = try(vm.ipv4_addresses[1][0], null)
    }
  }
}
```

This output structure allows downstream units to:
- Iterate over all VMs
- Access specific VMs by their identifier
- Get VM-specific attributes (IP, name, ID)

### 2. Unit Layer (`units/proxmox-vm`)

**Values Pattern**:

The unit will accept a `values.vms` map and pass it directly to the module:

```hcl
inputs = {
  vms = try(values.vms, {})
}
```

**Optional Pool Integration**:

If a single `pool_id` is provided at the unit level, it will be merged into each VM configuration:

```hcl
locals {
  # Merge global pool_id into each VM config if provided
  vms_with_pool = try(values.pool_id, "") != "" ? {
    for k, vm in values.vms : k => merge(vm, {
      pool_id = try(vm.pool_id, values.pool_id)
    })
  } : values.vms
}

inputs = {
  vms = local.vms_with_pool
}
```

### 3. DNS Integration Pattern

**Decision**: Use **dynamic DNS unit generation** in the stack (Option A from proposal).

This approach:
- Keeps DNS module simple (one record per unit, no changes needed)
- Leverages Terragrunt's native `for_each` support in stacks
- Each DNS unit depends on the corresponding VM
- Clear, explicit dependencies in the stack configuration

**Stack DNS Configuration**:

```hcl
# Generate one DNS unit per VM
dynamic "unit" {
  for_each = local.vms

  content {
    source = "git::...//units/dns?ref=${values.version}"
    path   = "dns-${unit.key}"

    values = {
      zone          = "home.sflab.io."
      name          = unit.value.vm_name
      dns_server    = "192.168.1.13"
      dns_port      = 5353
      key_name      = "ddnskey."
      key_algorithm = "hmac-sha512"
      vm_unit_path  = "../proxmox-vm"
      vm_identifier = unit.key  # NEW: Which VM in the map to get IP from
    }
  }
}
```

**DNS Unit Enhancement**:

The DNS unit needs minor enhancement to support extracting a specific VM's IP from the multi-VM output:

```hcl
dependency "compute" {
  config_path = try(values.vm_unit_path, try(values.lxc_unit_path, ""))

  mock_outputs = {
    vms = {
      "mock" = {
        ipv4 = "192.168.1.100"
      }
    }
    # For backwards compatibility with single-VM pattern
    ipv4 = "192.168.1.100"
  }
}

locals {
  # Extract specific VM IP if vm_identifier is provided
  vm_ip = try(
    dependency.compute.outputs.vms[values.vm_identifier].ipv4,
    dependency.compute.outputs.ipv4,  # Fallback to old single-VM pattern
    null
  )
}

inputs = {
  zone      = values.zone
  name      = values.name
  addresses = try(
    [local.vm_ip],
    values.addresses,
    []
  )
  ttl = try(values.ttl, 300)
}
```

### 4. Stack Layer (`stacks/homelab-proxmox-vm`)

**Configuration Structure**:

```hcl
locals {
  pool_id = "example-multi-vm-pool"

  vms = {
    "web01" = {
      vm_name = "web-server-01"
      memory  = 4096
    }
    "web02" = {
      vm_name = "web-server-02"
      memory  = 4096
    }
    "db01" = {
      vm_name = "database-01"
      memory  = 8192
    }
  }
}

unit "proxmox_pool" {
  source = "git::...//units/proxmox-pool?ref=${values.version}"
  path   = "proxmox-pool"

  values = {
    pool_id = local.pool_id
  }
}

unit "proxmox_vm" {
  source = "git::...//units/proxmox-vm?ref=${values.version}"
  path   = "proxmox-vm"

  values = {
    vms             = local.vms
    pool_id         = local.pool_id
    pool_unit_path  = "../proxmox-pool"
  }
}

# Generate DNS unit for each VM
dynamic "unit" {
  for_each = local.vms

  content {
    source = "git::...//units/dns?ref=${values.version}"
    path   = "dns-${unit.key}"

    values = {
      zone          = "home.sflab.io."
      name          = unit.value.vm_name
      dns_server    = "192.168.1.13"
      dns_port      = 5353
      key_name      = "ddnskey."
      key_algorithm = "hmac-sha512"
      vm_unit_path  = "../proxmox-vm"
      vm_identifier = unit.key
    }
  }
}
```

## Data Flow

```
Stack Local Variables (vms map)
    ↓
Unit: proxmox_vm (passes vms map)
    ↓
Module: proxmox-vm (for_each creates VMs)
    ↓
Module Output: vms map (VM_ID → {name, ipv4, ...})
    ↓
Multiple DNS Units (one per VM, via dynamic block)
    ↓
Each DNS Unit gets specific VM IP via vm_identifier
    ↓
DNS Module: Creates A record for each VM
```

## Extensibility Plan

### Adding New VM Properties

To add a new property (e.g., CPU cores, disk size):

1. **Module**: Add to `vms` variable object type with `optional()`:
   ```hcl
   cores   = optional(number, 2)
   disk_gb = optional(number, 32)
   ```

2. **Module**: Use in resource configuration:
   ```hcl
   cpu {
     cores = each.value.cores
   }
   ```

3. **Stack/Unit**: Simply add to VM configuration maps:
   ```hcl
   "web01" = {
     vm_name = "web-server-01"
     memory  = 4096
     cores   = 4        # New property
     disk_gb = 100      # New property
   }
   ```

No changes needed to the overall structure or other components!

## Backwards Compatibility Strategy

Since backwards compatibility is not required, the new implementation will fully replace the old pattern. However, to ease migration:

1. **Provide migration guide** showing how to convert single-VM configs to multi-VM:
   ```hcl
   # Old pattern
   vm_name = "my-vm"

   # New pattern
   vms = {
     "default" = {
       vm_name = "my-vm"
     }
   }
   ```

2. **Document the change** in CLAUDE.md with clear examples
3. **Update all examples** to use the new multi-VM pattern

## Error Handling

### Empty VMs Map

If `vms = {}` is provided:
- Module creates zero VMs (valid Terraform behavior)
- No DNS records created
- Pool still created if specified

### Invalid VM Configuration

Terraform's type validation will catch:
- Missing required fields (`vm_name`)
- Invalid types (string passed for memory)
- Invalid values handled by Proxmox provider

### IP Address Retrieval Failure

If a VM doesn't get an IP (QEMU agent not running):
- Module output will have `ipv4 = null` for that VM
- DNS unit will attempt to create record with null address
- Terraform will error, preventing invalid DNS records

**Recommendation**: Add validation in DNS unit:
```hcl
validation {
  condition     = local.vm_ip != null
  error_message = "VM IP address is not available. Ensure QEMU guest agent is running."
}
```

## Testing Strategy

### Module Testing

1. Test with single VM in map
2. Test with multiple VMs (2-3)
3. Test with empty map
4. Test with all optional properties specified
5. Validate outputs structure

### Unit Testing

1. Test pool integration (with and without pool_id)
2. Test value merging (global pool_id + per-VM pool_id)
3. Validate dependency handling

### Stack Testing

1. Deploy example stack with 2-3 VMs
2. Verify all VMs created in Proxmox
3. Verify all DNS records resolve correctly
4. Test adding a new VM (plan, apply)
5. Test removing a VM (plan, destroy)
6. Test modifying VM properties (plan, apply)

### Integration Testing

1. Full stack deployment from scratch
2. Verify execution order (pool → VMs → DNS records)
3. Verify DNS resolution for all VMs
4. Test stack destruction (DNS → VMs → pool)

## Performance Considerations

### Parallel VM Creation

Terraform will create all VMs in parallel (up to parallelism limit, default 10).

### DNS Record Creation

Each DNS unit runs independently, so DNS records are created in parallel after VMs are ready.

### State File Size

Multiple VMs increase state file size proportionally, but should not be a concern for homelab scale (< 100 VMs).

## Security Considerations

### TSIG Key Management

No changes to existing pattern:
- Key secret passed via `TF_VAR_dns_key_secret`
- Not stored in any configuration file
- Each DNS unit receives the secret independently

### VM Access Credentials

No changes to existing pattern:
- No VM passwords in module (handled by template)
- SSH keys managed through cloud-init in template VM

## Documentation Requirements

1. **CLAUDE.md Updates**:
   - Update VM module documentation with new `vms` variable
   - Update stack examples with multi-VM pattern
   - Add migration guide section

2. **README Updates** (if exists):
   - Update quick start examples
   - Add multi-VM usage examples

3. **Inline Comments**:
   - Document `vms` map structure in variables.tf
   - Document output structure in outputs.tf
   - Add examples in unit terragrunt.hcl files

4. **Example Stack**:
   - Include comprehensive multi-VM example (3+ VMs)
   - Document each VM's purpose in comments
   - Show varied configurations (different memory, etc.)
