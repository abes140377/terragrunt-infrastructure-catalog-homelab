# Implementation Tasks

## 1. Module Refactoring

- [ ] 1.1 Update `modules/proxmox-vm/variables.tf` to replace `vms` map with individual variables
  - [ ] 1.1.1 Add `vm_name` (string, required)
  - [ ] 1.1.2 Add `memory` (number, optional, default: 2048)
  - [ ] 1.1.3 Add `cores` (number, optional, default: 2)
  - [ ] 1.1.4 Update `pool_id` (string, optional, default: "")
  - [ ] 1.1.5 Remove `vms` variable
- [ ] 1.2 Update `modules/proxmox-vm/main.tf` to remove for_each pattern
  - [ ] 1.2.1 Remove `for_each = var.vms` from resource declaration
  - [ ] 1.2.2 Update `name` to use `var.vm_name` directly
  - [ ] 1.2.3 Update `memory.dedicated` to use `var.memory`
  - [ ] 1.2.4 Update `pool_id` reference to use `var.pool_id`
  - [ ] 1.2.5 Add `cpu` block with `cores = var.cores`
  - [ ] 1.2.6 Remove all `each.value` and `each.key` references
- [ ] 1.3 Update `modules/proxmox-vm/outputs.tf` to return single values
  - [ ] 1.3.1 Replace `vms` map output with individual outputs
  - [ ] 1.3.2 Add `ipv4` output (VM IP address)
  - [ ] 1.3.3 Add `vm_id` output (Proxmox VM ID)
  - [ ] 1.3.4 Add `vm_name` output (VM name)

## 2. Unit Updates

- [ ] 2.1 Update `units/proxmox-vm/terragrunt.hcl` for single-VM inputs
  - [ ] 2.1.1 Replace `vms` map input with individual values inputs
  - [ ] 2.1.2 Map `values.vm_name` to `vm_name` input
  - [ ] 2.1.3 Map `values.memory` to `memory` input (with default)
  - [ ] 2.1.4 Map `values.cores` to `cores` input (with default)
  - [ ] 2.1.5 Map `values.pool_id` to `pool_id` input
  - [ ] 2.1.6 Remove pool_id merging logic for vms map
- [ ] 2.2 Update `units/dns/terragrunt.hcl` to simplify IP extraction
  - [ ] 2.2.1 Update mock_outputs to include both map and single patterns for backwards compatibility
  - [ ] 2.2.2 Update addresses input logic to try single ipv4 output first
  - [ ] 2.2.3 Keep fallback for LXC compatibility
  - [ ] 2.2.4 Remove vm_identifier extraction for multi-VM map (first in try chain)

## 3. Stack Updates

- [ ] 3.1 Update `stacks/homelab-proxmox-vm/terragrunt.stack.hcl` for single VM
  - [ ] 3.1.1 Simplify locals to single VM values (pool_id, vm_name, optional memory/cores)
  - [ ] 3.1.2 Remove multi-VM vms map structure
  - [ ] 3.1.3 Update proxmox_vm unit to pass individual values (vm_name, memory, cores, pool_id)
  - [ ] 3.1.4 Remove dns_web01, dns_web02, dns_db01 units
  - [ ] 3.1.5 Add single dns unit with simplified configuration
  - [ ] 3.1.6 Remove vm_identifier from dns unit values
  - [ ] 3.1.7 Update comments to reflect single VM deployment

## 4. Example Updates

- [ ] 4.1 Update `examples/terragrunt/units/proxmox-vm/terragrunt.hcl`
  - [ ] 4.1.1 Update inputs to use individual values (vm_name, pool_id)
  - [ ] 4.1.2 Verify dependency on proxmox-pool still works
  - [ ] 4.1.3 Update comments for clarity
- [ ] 4.2 Update `examples/terragrunt/stacks/homelab-proxmox-vm/terragrunt.stack.hcl`
  - [ ] 4.2.1 Simplify to single VM configuration in locals
  - [ ] 4.2.2 Remove multi-VM vms map
  - [ ] 4.2.3 Update proxmox_vm unit values to pass individual parameters
  - [ ] 4.2.4 Remove dns_web01, dns_web02, dns_db01 units
  - [ ] 4.2.5 Add single dns unit without vm_identifier
  - [ ] 4.2.6 Update header comments and documentation
- [ ] 4.3 Update `examples/terragrunt/stacks/homelab-proxmox-vm/units/proxmox-vm/terragrunt.hcl`
  - [ ] 4.3.1 Update inputs to accept individual values from parent stack
  - [ ] 4.3.2 Remove vms map handling
  - [ ] 4.3.3 Verify pool dependency still works
- [ ] 4.4 Update `examples/terragrunt/stacks/homelab-proxmox-vm/units/dns/terragrunt.hcl`
  - [ ] 4.4.1 Remove vm_identifier from inputs
  - [ ] 4.4.2 Simplify addresses input to use single ipv4 output
  - [ ] 4.4.3 Update mock_outputs for backwards compatibility

## 5. Documentation Updates

- [ ] 5.1 Update `CLAUDE.md` VM module documentation
  - [ ] 5.1.1 Update "Infrastructure Resources" section with single-VM pattern
  - [ ] 5.1.2 Document new required inputs (vm_name) and optional inputs (memory, cores, pool_id)
  - [ ] 5.1.3 Document new outputs (ipv4, vm_id, vm_name)
  - [ ] 5.1.4 Remove multi-VM map references
- [ ] 5.2 Update `CLAUDE.md` VM stack documentation
  - [ ] 5.2.1 Update "Working with Stacks" section with single-VM example
  - [ ] 5.2.2 Remove multi-VM stack examples
  - [ ] 5.2.3 Update "Adding New Stacks" guidance
  - [ ] 5.2.4 Note migration path for multi-VM users
- [ ] 5.3 Update `CLAUDE.md` examples documentation
  - [ ] 5.3.1 Update "Examples Directory" section
  - [ ] 5.3.2 Update "Terragrunt Operations" section with single-VM commands
  - [ ] 5.3.3 Remove multi-VM deployment command examples

## 6. Testing and Validation

- [ ] 6.1 Validate Terraform module syntax
  - [ ] 6.1.1 Run `tofu fmt -recursive` on all modified files
  - [ ] 6.1.2 Run `tofu validate` in modules/proxmox-vm directory
- [ ] 6.2 Test example unit deployment
  - [ ] 6.2.1 Test `examples/terragrunt/units/proxmox-vm` with `terragrunt plan`
  - [ ] 6.2.2 Verify dependency on proxmox-pool works
  - [ ] 6.2.3 Verify outputs are correctly returned
- [ ] 6.3 Test example stack deployment
  - [ ] 6.3.1 Test `examples/terragrunt/stacks/homelab-proxmox-vm` with `terragrunt stack generate`
  - [ ] 6.3.2 Run `terragrunt stack run plan` to verify configuration
  - [ ] 6.3.3 Verify DNS unit correctly depends on VM unit
  - [ ] 6.3.4 Verify DNS unit extracts IP without vm_identifier
- [ ] 6.4 Run pre-commit hooks
  - [ ] 6.4.1 Execute `pre-commit run --all-files`
  - [ ] 6.4.2 Fix any formatting or validation issues
