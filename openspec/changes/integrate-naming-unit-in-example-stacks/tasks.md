# Tasks: Integrate Naming Unit in Example Stacks

## Implementation Order

### 1. Add naming unit to homelab-proxmox-vm example stack ✓
- [x] Add naming unit configuration to `examples/terragrunt/stacks/homelab-proxmox-vm/terragrunt.stack.hcl`
- [x] Configure with `env = "staging"` and `app = "vm1"`
- [x] Set unit path to `naming`
- [x] Update VM units to consume naming unit output instead of hardcoded `vm_name`
- [x] Update DNS units to use the generated name
- [x] **Validation**: Run `terragrunt stack generate` and verify naming unit appears in `.terragrunt-stack/naming/`

### 2. Add naming unit to homelab-proxmox-container example stack ✓
- [x] Add naming unit configuration to `examples/terragrunt/stacks/homelab-proxmox-container/terragrunt.stack.hcl`
- [x] Configure with `env = "staging"` and `app = "container1"`
- [x] Set unit path to `naming`
- [x] Update LXC units to consume naming unit output instead of hardcoded `hostname`
- [x] Update DNS units to use the generated name
- [x] **Validation**: Run `terragrunt stack generate` and verify naming unit appears in `.terragrunt-stack/naming/`

### 3. Test VM stack deployment ✓
- [x] Navigate to `examples/terragrunt/stacks/homelab-proxmox-vm/`
- [x] Run `terragrunt stack run plan` (validated configuration)
- [x] Verify VMs will be created with names `staging-vm1-1` and `staging-vm1-2`
- [x] Verify DNS records will use the generated names
- [x] **Validation**: Plan output shows correct VM names and DNS FQDNs

**Note**: Plan validation confirms correct naming integration. Actual deployment (`apply`) was not performed to avoid creating/modifying live infrastructure.

### 4. Test container stack deployment ✓
- [x] Navigate to `examples/terragrunt/stacks/homelab-proxmox-container/`
- [x] Run `terragrunt stack run plan` (validated configuration)
- [x] Verify containers will be created with names `staging-container1-1` and `staging-container1-2`
- [x] Verify DNS records will use the generated names
- [x] **Validation**: Plan output shows correct container hostnames and DNS FQDNs

**Note**: Plan validation confirms correct naming integration. Actual deployment (`apply`) was not performed to avoid creating/modifying live infrastructure.

### 5. Cleanup test resources
- [ ] Run `terragrunt stack run destroy` for both stacks (if deployed)
- [ ] Verify all resources (VMs, containers, DNS records) are removed
- [ ] **Validation**: Check Proxmox UI and DNS server for no remaining resources

**Note**: Cleanup not required as resources were not deployed. Plan validation was sufficient to verify naming integration.

## Parallelizable Work

- Tasks 1 and 2 can be done in parallel (different stack files)
- Tasks 3 and 4 must be done sequentially after tasks 1-2

## Dependencies

- Task 3 depends on task 1 (VM stack configuration)
- Task 4 depends on task 2 (container stack configuration)
- Task 5 depends on tasks 3 and 4 (cleanup after testing)

## Environment Requirements

Before testing (tasks 3-4):
```bash
export AWS_ACCESS_KEY_ID="your-minio-access-key"
export AWS_SECRET_ACCESS_KEY="your-minio-secret-key"
export PROXMOX_VE_API_TOKEN="root@pam!tofu=xxxxxxxx"
export TF_VAR_dns_key_secret="your-tsig-key-secret"
```
