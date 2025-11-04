# Implementation Tasks: Enable Multi-VM Deployment with DNS Resolution

## Task Ordering and Dependencies

Tasks are ordered to enable incremental progress with testable deliverables at each step. Tasks marked with `||` can be executed in parallel.

---

## Phase 1: Module Layer (Foundation)

### Task 1.1: Update proxmox-vm module variables
**Description**: Replace single-VM variables with map-based input structure.
**Files**: `modules/proxmox-vm/variables.tf`
**Actions**:
1. Replace existing `vm_name` and `pool_id` variables with new `vms` variable
2. Define `vms` as `map(object({...}))` with:
   - `vm_name` (string, required)
   - `memory` (optional number, default 2048)
   - `cores` (optional number, default 2)
   - `pool_id` (optional string, default "")
3. Set default value to `{}`
4. Document the structure in variable description with examples

**Validation**:
- Run `tofu fmt` in `modules/proxmox-vm/`
- Run `tofu validate` (will fail until main.tf is updated - that's expected)

---

### Task 1.2: Update proxmox-vm module main resource
**Description**: Convert VM resource to use for_each with the vms map.
**Files**: `modules/proxmox-vm/main.tf`
**Actions**:
1. Add `for_each = var.vms` to `proxmox_virtual_environment_vm.this` resource
2. Replace direct variable references with `each.value.*`:
   - `name = each.value.vm_name`
   - `memory.dedicated = each.value.memory`
   - `pool_id = each.value.pool_id != "" ? each.value.pool_id : null`
3. Keep existing configuration for:
   - `node_name = "pve1"`
   - `clone.vm_id = 9002`
   - `agent.enabled = true`
   - `initialization.ip_config.ipv4.address = "dhcp"`
4. Add comment explaining for_each pattern

**Validation**:
- Run `tofu fmt` in `modules/proxmox-vm/`
- Run `tofu validate` - should pass with no errors
- Verify resource addressing: `proxmox_virtual_environment_vm.this["<key>"]`

---

### Task 1.3: Update proxmox-vm module outputs
**Description**: Change output from single IP to map of VM attributes.
**Files**: `modules/proxmox-vm/outputs.tf`
**Actions**:
1. Replace `ipv4` output with `vms` output
2. Use `for` expression to create map:
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
3. Document output structure in description

**Validation**:
- Run `tofu fmt` in `modules/proxmox-vm/`
- Run `tofu validate` - should pass
- Run pre-commit hooks: `pre-commit run --all-files`

---

## Phase 2: Unit Layer (Wrappers)

### Task 2.1: Update proxmox-vm unit for multi-VM input
**Description**: Modify unit to accept and pass vms map with pool merging logic.
**Files**: `units/proxmox-vm/terragrunt.hcl`
**Actions**:
1. Add locals block for pool ID merging:
   ```hcl
   locals {
     global_pool_id = try(values.pool_id, "")
     vms_with_pool = local.global_pool_id != "" ? {
       for k, vm in values.vms : k => merge(vm, {
         pool_id = try(vm.pool_id, local.global_pool_id)
       })
     } : values.vms
   }
   ```
2. Update inputs block to pass `vms = local.vms_with_pool`
3. Add comments explaining the pool merging pattern
4. Keep existing `include "root"` and `include "provider_proxmox"` blocks

**Validation**:
- Run `tofu fmt` on the file
- Verify HCL syntax is valid
- Check that values pattern is consistent

---

### Task 2.2: Update DNS unit for multi-VM support
**Description**: Add vm_identifier support for extracting specific VM IP from multi-VM output.
**Files**: `units/dns/terragrunt.hcl`
**Actions**:
1. Update `dependency "compute"` mock_outputs to include both patterns:
   ```hcl
   mock_outputs = {
     vms = {
       "mock" = { ipv4 = "192.168.1.100" }
     }
     ipv4 = "192.168.1.100"  # Backwards compatibility
   }
   ```
2. Add local variable for IP extraction:
   ```hcl
   locals {
     vm_ip = try(
       dependency.compute.outputs.vms[values.vm_identifier].ipv4,
       dependency.compute.outputs.ipv4,
       null
     )
   }
   ```
3. Update inputs to use `local.vm_ip`:
   ```hcl
   addresses = try(
     [local.vm_ip],
     values.addresses,
     []
   )
   ```
4. Add comments explaining multi-VM vs single-VM pattern

**Validation**:
- Run `tofu fmt` on the file
- Verify HCL syntax is valid
- Check that fallback logic covers all cases

---

## Phase 3: Example Units (Local Testing)

### Task 3.1: Update example proxmox-vm unit wrapper
**Description**: Modify example unit to demonstrate multi-VM pattern with local module path.
**Files**: `examples/terragrunt/stacks/homelab-proxmox-vm/units/proxmox-vm/terragrunt.hcl`
**Actions**:
1. Keep existing `include "root"` and provider generation blocks
2. Update dependency block to handle both patterns:
   ```hcl
   dependency "proxmox_pool" {
     config_path = try(values.pool_unit_path, "../proxmox-pool")
     mock_outputs = { pool_id = "mock-pool" }
     skip_outputs = try(values.pool_id != "", false)
   }
   ```
3. Add locals for pool merging (same logic as Task 2.1)
4. Update inputs to pass `vms = local.vms_with_pool`

**Validation**:
- Run `tofu fmt` on the file
- Verify dependency handling is correct
- Check that module source path is relative

---

### Task 3.2: Update example DNS unit wrapper
**Description**: Modify example DNS unit to support vm_identifier.
**Files**: `examples/terragrunt/stacks/homelab-proxmox-vm/units/dns/terragrunt.hcl`
**Actions**:
1. Keep existing provider generation and dependency blocks
2. Add locals for IP extraction (same logic as Task 2.2)
3. Update inputs to use `local.vm_ip` in addresses
4. Add comments showing both single-VM and multi-VM usage patterns

**Validation**:
- Run `tofu fmt` on the file
- Verify dependency outputs handling
- Check that fallback logic is complete

---

## Phase 4: Stack Layer (Composition)

### Task 4.1: Update example stack with multi-VM configuration
**Description**: Modify stack to demonstrate deploying multiple VMs with DNS.
**Files**: `examples/terragrunt/stacks/homelab-proxmox-vm/terragrunt.stack.hcl`
**Actions**:
1. Update locals to define multiple VMs:
   ```hcl
   locals {
     pool_id = "example-multi-vm-pool"
     vms = {
       "web01" = { vm_name = "web-server-01", memory = 4096 }
       "web02" = { vm_name = "web-server-02", memory = 4096 }
       "db01"  = { vm_name = "database-01", memory = 8192 }
     }
   }
   ```
2. Update proxmox_vm unit to pass `values.vms = local.vms`
3. Replace single DNS unit with dynamic block:
   ```hcl
   dynamic "unit" {
     for_each = local.vms
     content {
       source = "./units/dns"
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
4. Add comprehensive comments explaining the multi-VM + DNS pattern

**Validation**:
- Run `tofu fmt` on the file
- Verify dynamic block syntax is correct
- Check that all DNS units will have unique paths

---

### Task 4.2: Update production stack configuration
**Description**: Update production stack to use new multi-VM pattern with Git URLs.
**Files**: `stacks/homelab-proxmox-vm/terragrunt.stack.hcl`
**Actions**:
1. Update locals to support `values.vms` pattern:
   ```hcl
   locals {
     pool_id = values.pool_id != "" ? values.pool_id : ""
     vms     = values.vms
   }
   ```
2. Update proxmox_vm unit to pass `values.vms = local.vms`
3. Add dynamic DNS unit block (same pattern as Task 4.1, but with Git URLs)
4. Add comment explaining values pattern for external consumption

**Validation**:
- Run `tofu fmt` on the file
- Verify Git URL references are correct
- Check that values pattern is documented

---

## Phase 5: Documentation

### Task 5.1: Update CLAUDE.md VM module documentation
**Description**: Document new multi-VM module capabilities.
**Files**: `CLAUDE.md`
**Sections to update**:
1. **Infrastructure Resources → Virtual Machines**:
   - Update inputs: `vms` (map of objects) instead of `vm_name` (string)
   - Document map structure with all properties (vm_name, memory, cores, pool_id)
   - Update outputs: `vms` (map) instead of `ipv4` (string)
   - Add example of map structure

2. **Key Architecture Concepts → Examples Directory**:
   - Update proxmox-vm example description to mention multi-VM support

**Validation**:
- Verify markdown formatting
- Check for broken links
- Ensure examples are consistent with implementation

---

### Task 5.2: Update CLAUDE.md stack documentation || Task 5.1
**Description**: Document multi-VM stack patterns and dynamic DNS unit generation.
**Files**: `CLAUDE.md`
**Sections to update**:
1. **Working with Stacks**:
   - Add example showing multi-VM stack configuration
   - Document dynamic unit block pattern for DNS
   - Show how to add/remove VMs from the configuration

2. **Terragrunt Operations**:
   - Update VM stack deployment example to show multi-VM case
   - Add commands for verifying multiple DNS records

3. **Development Guidelines → Adding New Stacks**:
   - Add multi-VM stack as reference example
   - Explain dynamic unit generation pattern

**Validation**:
- Verify markdown formatting
- Check code examples are syntactically correct
- Ensure all commands are accurate

---

### Task 5.3: Add inline documentation to module || Task 5.2
**Description**: Add comprehensive comments in module files.
**Files**:
- `modules/proxmox-vm/variables.tf`
- `modules/proxmox-vm/main.tf`
- `modules/proxmox-vm/outputs.tf`

**Actions**:
1. Add example usage in variables.tf showing the vms map structure
2. Document the for_each pattern in main.tf
3. Explain output structure in outputs.tf
4. Add note about extending with new properties

**Validation**:
- Verify comments are clear and helpful
- Ensure examples are valid HCL

---

## Phase 6: Testing and Validation

### Task 6.1: Cleanup and format all files
**Description**: Ensure all files are properly formatted and pass pre-commit hooks.
**Files**: All modified files
**Actions**:
1. Run `tofu fmt -recursive` from repository root
2. Run `mise run terragrunt:cleanup` to remove cache files
3. Run `pre-commit run --all-files`
4. Fix any issues reported by hooks

**Validation**:
- All pre-commit hooks pass
- No trailing whitespace
- All files end with newline
- No secrets detected by gitleaks

---

### Task 6.2: Test module with example inputs
**Description**: Validate module works with multi-VM input.
**Files**: `modules/proxmox-vm/`
**Actions**:
1. Create temporary `terraform.tfvars` with test data:
   ```hcl
   vms = {
     "test01" = { vm_name = "test-vm-01" }
     "test02" = { vm_name = "test-vm-02", memory = 4096 }
   }
   ```
2. Run `tofu init` in module directory
3. Run `tofu validate`
4. Run `tofu plan` (will fail on provider auth - that's expected)
5. Verify plan shows 2 VMs being created
6. Delete temporary file

**Validation**:
- Module validates successfully
- Plan shows correct number of VMs
- Resource addressing is correct (vm.this["test01"], vm.this["test02"])

---

### Task 6.3: Test example stack generation
**Description**: Verify example stack generates correctly with multi-VM config.
**Files**: `examples/terragrunt/stacks/homelab-proxmox-vm/`
**Actions**:
1. Navigate to example stack directory
2. Set required environment variables (can use dummy values for testing):
   ```bash
   export AWS_ACCESS_KEY_ID="test"
   export AWS_SECRET_ACCESS_KEY="test"
   export PROXMOX_VE_API_TOKEN="test@test!test=test"
   export TF_VAR_dns_key_secret="test"
   ```
3. Run `terragrunt stack generate`
4. Verify `.terragrunt-stack/` directory structure:
   - `proxmox-pool/` directory exists
   - `proxmox-vm/` directory exists
   - `dns-web01/`, `dns-web02/`, `dns-db01/` directories exist (one per VM)
5. Check each DNS unit has correct configuration
6. Run `terragrunt stack run plan` (will fail on connectivity - that's expected)
7. Cleanup: `rm -rf .terragrunt-stack`

**Validation**:
- Stack generates without errors
- Correct number of DNS units created (one per VM)
- Each DNS unit has unique path
- Dependencies are correctly configured

---

### Task 6.4: Verify OpenSpec compliance
**Description**: Validate all requirements in spec deltas are addressed.
**Files**: `openspec/changes/enable-multi-vm-deployment/`
**Actions**:
1. Review each requirement in all spec files:
   - `specs/multi-vm-module/spec.md`
   - `specs/multi-vm-unit/spec.md`
   - `specs/multi-vm-stack/spec.md`
   - `specs/multi-vm-dns-integration/spec.md`
2. For each scenario, verify implementation exists
3. Create checklist mapping scenarios to implementation locations
4. Ensure all scenarios are covered

**Validation**:
- All requirements implemented
- All scenarios testable
- No missing functionality

---

### Task 6.5: Run OpenSpec validation
**Description**: Ensure proposal passes OpenSpec strict validation.
**Files**: All OpenSpec files in change directory
**Actions**:
1. Run `openspec validate enable-multi-vm-deployment --strict`
2. Review any errors or warnings
3. Fix any issues identified
4. Re-run validation until it passes

**Validation**:
- `openspec validate` passes with no errors
- All spec deltas are properly structured
- Cross-references are valid

---

## Phase 7: Finalization

### Task 7.1: Create comprehensive example with comments
**Description**: Ensure example stack is well-documented for users.
**Files**: `examples/terragrunt/stacks/homelab-proxmox-vm/terragrunt.stack.hcl`
**Actions**:
1. Add header comment block explaining:
   - Purpose: Multi-VM deployment with DNS integration
   - How to customize VMs (add/remove from map, change properties)
   - Required environment variables
   - Deployment commands
   - Verification commands (dig for each VM)
2. Add inline comments for each VM explaining its role
3. Add comment showing how to add new properties to VMs

**Validation**:
- Example is self-explanatory
- Commands are accurate and complete
- User can understand without reading other docs

---

### Task 7.2: Update README if exists || Task 7.1
**Description**: Update repository README with multi-VM examples.
**Files**: `README.md` (if exists)
**Actions**:
1. Check if README.md exists in repository root
2. If it exists, add/update section on multi-VM deployment
3. Include quick start example showing vms map
4. Link to CLAUDE.md for detailed documentation

**Validation**:
- README is consistent with CLAUDE.md
- Examples work as documented
- Links are not broken

---

## Completion Criteria

- [x] All module, unit, and stack files updated with multi-VM support
- [x] DNS integration works with multiple VMs using dynamic unit generation
- [x] All examples demonstrate multi-VM usage
- [x] CLAUDE.md fully documents new capabilities
- [x] All pre-commit hooks pass
- [x] OpenSpec validation passes with `--strict` flag
- [x] Example stack generates and plans successfully
- [x] All tasks completed and validated

---

## Estimated Time per Phase

- **Phase 1** (Module): 2-3 hours
- **Phase 2** (Units): 1-2 hours
- **Phase 3** (Example Units): 1-2 hours
- **Phase 4** (Stacks): 2-3 hours
- **Phase 5** (Documentation): 2-3 hours
- **Phase 6** (Testing): 2-3 hours
- **Phase 7** (Finalization): 1 hour

**Total**: 11-17 hours across 7 phases

---

## Dependency Graph

```
Phase 1 (Module)
    ↓
Phase 2 (Units) → Phase 3 (Example Units)
    ↓                     ↓
    └─────→ Phase 4 (Stacks)
                ↓
Phase 5 (Documentation) can happen in parallel with Phase 1-4
                ↓
            Phase 6 (Testing)
                ↓
          Phase 7 (Finalization)
```

Tasks within Phase 5 can run in parallel. Testing should validate everything together.
