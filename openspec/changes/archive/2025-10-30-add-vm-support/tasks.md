# Implementation Tasks

## 1. Create VM Unit

- [x] 1.1 Create `units/proxmox-vm/terragrunt.hcl` file
- [x] 1.2 Add `include "root"` block pointing to root.hcl
- [x] 1.3 Configure `terraform.source` with Git URL to proxmox-vm module
- [x] 1.4 Define `inputs` block using values pattern (values.vm_name, values.pool_id, values.version)
- [x] 1.5 Add explanatory comments about Git URL pattern for external consumption
- [x] 1.6 Verify file follows same structure as units/proxmox-lxc/terragrunt.hcl

## 2. Create VM Unit Example

- [x] 2.1 Create `examples/terragrunt/units/proxmox-vm/terragrunt.hcl` file
- [x] 2.2 Add `include "root"` block pointing to root.hcl
- [x] 2.3 Configure `locals` for reading provider configuration
- [x] 2.4 Add `generate "provider"` block for Proxmox provider
- [x] 2.5 Configure `terraform.source` with relative path to module: `../../../.././/modules/proxmox-vm`
- [x] 2.6 Add `dependency "proxmox_pool"` block with mock_outputs
- [x] 2.7 Define `inputs` block with concrete values (vm_name, pool_id from dependency)
- [x] 2.8 Add explanatory comments about local vs Git URL usage
- [x] 2.9 Test example: `cd examples/terragrunt/units/proxmox-vm && terragrunt init && terragrunt plan`

## 3. Create VM Stack

- [x] 3.1 Create `stacks/homelab-proxmox-vm/terragrunt.stack.hcl` file
- [x] 3.2 Define `locals` block for pool_id and vm_name values
- [x] 3.3 Add `unit "proxmox_pool"` block with Git URL source and path attribute
- [x] 3.4 Add `unit "proxmox_vm"` block with Git URL source, path attribute, and pool_unit_path
- [x] 3.5 Add `unit "dns"` block with Git URL source, path attribute, and vm_unit_path
- [x] 3.6 Configure DNS unit with zone, dns_server, dns_port, key settings
- [x] 3.7 Add explanatory comments about Git URLs for external consumption
- [x] 3.8 Verify structure matches stacks/homelab-proxmox-container/terragrunt.stack.hcl

## 4. Create VM Stack Example

- [x] 4.1 Create `examples/terragrunt/stacks/homelab-proxmox-vm/` directory
- [x] 4.2 Create `examples/terragrunt/stacks/homelab-proxmox-vm/terragrunt.stack.hcl` file
- [x] 4.3 Define `locals` block with concrete values (pool_id, vm_name)
- [x] 4.4 Add three unit blocks referencing `./units/` subdirectories
- [x] 4.5 Add explanatory comments about local vs Git URL usage

## 5. Create VM Stack Example Unit Wrappers

- [x] 5.1 Create `examples/terragrunt/stacks/homelab-proxmox-vm/units/proxmox-pool/terragrunt.hcl`
- [x] 5.2 Configure proxmox-pool wrapper with relative path to module: `../../../../../.././/modules/proxmox-pool`
- [x] 5.3 Create `examples/terragrunt/stacks/homelab-proxmox-vm/units/proxmox-vm/terragrunt.hcl`
- [x] 5.4 Configure proxmox-vm wrapper with relative path to module: `../../../../../.././/modules/proxmox-vm`
- [x] 5.5 Add dependency block for proxmox-pool with skip_outputs logic
- [x] 5.6 Create `examples/terragrunt/stacks/homelab-proxmox-vm/units/dns/terragrunt.hcl`
- [x] 5.7 Configure dns wrapper with relative path to module: `../../../../../.././/modules/dns`
- [x] 5.8 Add dependency block for proxmox-vm to get IP address
- [x] 5.9 Ensure all wrappers include root.hcl and generate provider blocks
- [x] 5.10 Test example stack: `cd examples/terragrunt/stacks/homelab-proxmox-vm && terragrunt stack generate && terragrunt stack run plan`

## 6. Update Documentation

- [x] 6.1 Update CLAUDE.md "Infrastructure Resources" section with VM module documentation
- [x] 6.2 Update CLAUDE.md "Examples Directory" section with VM examples
- [x] 6.3 Update CLAUDE.md "Adding New Units" section with VM unit reference
- [x] 6.4 Update CLAUDE.md "Adding New Stacks" section with VM stack reference
- [x] 6.5 Add VM deployment commands to CLAUDE.md "Terragrunt Operations" section

## 7. Quality Assurance

- [x] 7.1 Run `tofu fmt -recursive` to format all new HCL files
- [x] 7.2 Run `pre-commit run --all-files` to verify code quality
- [x] 7.3 Verify no hardcoded secrets detected by gitleaks
- [x] 7.4 Test VM unit example deployment (init, plan)
- [x] 7.5 Test VM stack example generation and planning
- [x] 7.6 Verify all new files follow project conventions
- [x] 7.7 Confirm Git URL patterns match existing units and stacks
- [x] 7.8 Validate OpenSpec proposal: `openspec validate add-vm-support --strict`
