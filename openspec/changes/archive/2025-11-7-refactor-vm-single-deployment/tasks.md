# Implementation Tasks

## 1. Module Refactoring

- [x] 1.1 Update `modules/proxmox-vm/variables.tf` to replace `vms` map with individual variables
  - [x] 1.1.1 Add `vm_name` (string, required)
  - [x] 1.1.2 Add `memory` (number, optional, default: 2048)
  - [x] 1.1.3 Add `cores` (number, optional, default: 2)
  - [x] 1.1.4 Update `pool_id` (string, optional, default: "")
  - [x] 1.1.5 Remove `vms` variable
- [x] 1.2 Update `modules/proxmox-vm/main.tf` to remove for_each pattern
  - [x] 1.2.1 Remove `for_each = var.vms` from resource declaration
  - [x] 1.2.2 Update `name` to use `var.vm_name` directly
  - [x] 1.2.3 Update `memory.dedicated` to use `var.memory`
  - [x] 1.2.4 Update `pool_id` reference to use `var.pool_id`
  - [x] 1.2.5 Add `cpu` block with `cores = var.cores`
  - [x] 1.2.6 Remove all `each.value` and `each.key` references
- [x] 1.3 Update `modules/proxmox-vm/outputs.tf` to return single values
  - [x] 1.3.1 Replace `vms` map output with individual outputs
  - [x] 1.3.2 Add `ipv4` output (VM IP address)
  - [x] 1.3.3 Add `vm_id` output (Proxmox VM ID)
  - [x] 1.3.4 Add `vm_name` output (VM name)

## 2. Unit Updates

- [x] 2.1 Update `units/proxmox-vm/terragrunt.hcl` for single-VM inputs
  - [x] 2.1.1 Replace `vms` map input with individual values inputs
  - [x] 2.1.2 Map `values.vm_name` to `vm_name` input
  - [x] 2.1.3 Map `values.memory` to `memory` input (with default)
  - [x] 2.1.4 Map `values.cores` to `cores` input (with default)
  - [x] 2.1.5 Map `values.pool_id` to `pool_id` input
  - [x] 2.1.6 Remove pool_id merging logic for vms map
- [x] 2.2 Update `units/dns/terragrunt.hcl` to simplify IP extraction
  - [x] 2.2.1 Update mock_outputs to include both map and single patterns for backwards compatibility
  - [x] 2.2.2 Update addresses input logic to try single ipv4 output first
  - [x] 2.2.3 Keep fallback for LXC compatibility
  - [x] 2.2.4 Remove vm_identifier extraction for multi-VM map (first in try chain)

## 3. Stack Updates

- [x] 3.1 Update `stacks/homelab-proxmox-vm/terragrunt.stack.hcl` for single VM
  - [x] 3.1.1 Simplify locals to single VM values (pool_id, vm_name, optional memory/cores)
  - [x] 3.1.2 Remove multi-VM vms map structure
  - [x] 3.1.3 Update proxmox_vm unit to pass individual values (vm_name, memory, cores, pool_id)
  - [x] 3.1.4 Remove dns_web01, dns_web02, dns_db01 units
  - [x] 3.1.5 Add single dns unit with simplified configuration
  - [x] 3.1.6 Remove vm_identifier from dns unit values
  - [x] 3.1.7 Update comments to reflect single VM deployment

## 4. Example Updates

- [x] 4.1 Update `examples/terragrunt/units/proxmox-vm/terragrunt.hcl`
  - [x] 4.1.1 Update inputs to use individual values (vm_name, pool_id)
  - [x] 4.1.2 Verify dependency on proxmox-pool still works
  - [x] 4.1.3 Update comments for clarity
- [x] 4.2 Update `examples/terragrunt/stacks/homelab-proxmox-vm/terragrunt.stack.hcl`
  - [x] 4.2.1 Simplify to single VM configuration in locals
  - [x] 4.2.2 Remove multi-VM vms map
  - [x] 4.2.3 Update proxmox_vm unit values to pass individual parameters
  - [x] 4.2.4 Remove dns_web01, dns_web02, dns_db01 units
  - [x] 4.2.5 Add single dns unit without vm_identifier
  - [x] 4.2.6 Update header comments and documentation
- [x] 4.3 Update `examples/terragrunt/stacks/homelab-proxmox-vm/units/proxmox-vm/terragrunt.hcl`
  - [x] 4.3.1 Update inputs to accept individual values from parent stack
  - [x] 4.3.2 Remove vms map handling
  - [x] 4.3.3 Verify pool dependency still works
- [x] 4.4 Update `examples/terragrunt/stacks/homelab-proxmox-vm/units/dns/terragrunt.hcl`
  - [x] 4.4.1 Remove vm_identifier from inputs
  - [x] 4.4.2 Simplify addresses input to use single ipv4 output
  - [x] 4.4.3 Update mock_outputs for backwards compatibility

## 5. Documentation Updates

- [x] 5.1 Update `CLAUDE.md` VM module documentation
  - [x] 5.1.1 Update "Infrastructure Resources" section with single-VM pattern
  - [x] 5.1.2 Document new required inputs (vm_name) and optional inputs (memory, cores, pool_id)
  - [x] 5.1.3 Document new outputs (ipv4, vm_id, vm_name)
  - [x] 5.1.4 Remove multi-VM map references
- [x] 5.2 Update `CLAUDE.md` VM stack documentation
  - [x] 5.2.1 Update "Working with Stacks" section with single-VM example
  - [x] 5.2.2 Remove multi-VM stack examples
  - [x] 5.2.3 Update "Adding New Stacks" guidance
  - [x] 5.2.4 Note migration path for multi-VM users
- [x] 5.3 Update `CLAUDE.md` examples documentation
  - [x] 5.3.1 Update "Examples Directory" section
  - [x] 5.3.2 Update "Terragrunt Operations" section with single-VM commands
  - [x] 5.3.3 Remove multi-VM deployment command examples

## 6. Testing and Validation

- [x] 6.1 Validate Terraform module syntax
  - [x] 6.1.1 Run `tofu fmt -recursive` on all modified files
  - [x] 6.1.2 Run `tofu validate` in modules/proxmox-vm directory
- [x] 6.2 Test example unit deployment
  - [x] 6.2.1 Test `examples/terragrunt/units/proxmox-vm` with `terragrunt plan`
  - [x] 6.2.2 Verify dependency on proxmox-pool works
  - [x] 6.2.3 Verify outputs are correctly returned
- [x] 6.3 Test example stack deployment
  - [x] 6.3.1 Test `examples/terragrunt/stacks/homelab-proxmox-vm` with `terragrunt stack generate`
  - [x] 6.3.2 Run `terragrunt stack run plan` to verify configuration
  - [x] 6.3.3 Verify DNS unit correctly depends on VM unit
  - [x] 6.3.4 Verify DNS unit extracts IP without vm_identifier
- [x] 6.4 Run pre-commit hooks
  - [x] 6.4.1 Execute `pre-commit run --all-files`
  - [x] 6.4.2 Fix any formatting or validation issues
