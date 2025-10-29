# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terragrunt infrastructure catalog for homelab Proxmox environments. It provides reusable infrastructure components (modules, units, and stacks) for managing Proxmox resources using OpenTofu/Terraform and Terragrunt.

### Key Architecture Concepts

**Three-Layer Architecture:**

1. **Modules** (`modules/`): Raw Terraform/OpenTofu modules
   - `proxmox-lxc`: Creates LXC containers on Proxmox
   - `proxmox-pool`: Creates Proxmox resource pools
   - These are basic building blocks with no Terragrunt-specific logic

2. **Units** (`units/`): Terragrunt wrappers around modules
   - Each unit references a module via Git URL (for external consumption)
   - Units define how modules are configured and can declare dependencies
   - Example: `units/proxmox-lxc/terragrunt.hcl` wraps `modules/proxmox-lxc`

3. **Stacks** (`stacks/`): Compositions of multiple units
   - Define multiple units that work together
   - Use `terragrunt.stack.hcl` files
   - Example: `stacks/proxmox-container/` combines proxmox-pool and proxmox-lxc units

**Git URL Pattern:**
Units and stacks use Git URLs in their `source` field because they are designed to be consumed as shallow directories by external users who won't have access to the full repository. The examples use relative paths (`../../../.././/modules/proxmox-lxc`) for local development.

### Configuration Files

**Root Configuration** (`examples/terragrunt/root.hcl`):
- Defines shared locals for S3 backend and provider configuration
- Reads from `s3-backend.hcl` and `provider.hcl`
- Generates `backend.tf` and `provider.tf` for all child modules
- All units must include this via `include "root"`

**Backend Configuration** (`examples/terragrunt/s3-backend.hcl`):
- Uses MinIO as S3-compatible backend
- Requires environment variables: `MINIO_ACCESS_KEY` and `MINIO_SECRET_KEY`
- Endpoint: `http://minio.home.sflab.io:9000`

**Provider Configuration** (`examples/terragrunt/provider.hcl`):
- Configures Proxmox provider
- Default host: `proxmox.home.sflab.io:8006`

## Common Commands

### Environment Setup

```bash
# Set MinIO credentials (required for Terragrunt backend)
export MINIO_ACCESS_KEY="your-access-key"
export MINIO_SECRET_KEY="your-secret-key"

# Set Proxmox credentials (required for Proxmox provider)
export PM_API_TOKEN_ID="user@pam!token-id"
export PM_API_TOKEN_SECRET="token-secret"
```

### Mise Tasks

```bash
# Setup MinIO bucket and service account
mise run minio:setup

# Install Python dependencies
mise run install-deps

# Edit SOPS-encrypted secrets
mise run secrets:edit
```

### Terragrunt Operations

```bash
# Working with units (examples)
cd examples/terragrunt/units/proxmox-lxc

# Initialize
terragrunt init

# Plan changes
terragrunt plan

# Apply changes
terragrunt apply

# Destroy resources
terragrunt destroy

# Working with stacks
cd examples/terragrunt/stacks/proxmox-container

# Run commands on all units in stack
terragrunt run-all plan
terragrunt run-all apply
terragrunt run-all destroy
```

### Development Commands

```bash
# Clean up Terragrunt cache files
./scripts/terragrunt-cleanup

# Format all Terraform files
terraform fmt -recursive

# Validate Terraform modules
cd modules/proxmox-lxc
terraform init
terraform validate
```

## Development Guidelines

### Adding New Modules

1. Create module directory in `modules/`
2. Define resources in `main.tf`
3. Declare variables in `variables.tf`
4. Export outputs in `outputs.tf`
5. Specify provider requirements in `versions.tf`

### Adding New Units

1. Create unit directory in `units/`
2. Create `terragrunt.hcl` with:
   - `include "root"` block pointing to `root.hcl`
   - `terraform.source` pointing to Git URL (or relative path for examples)
   - `inputs` block mapping unit inputs to module variables
3. Add example in `examples/terragrunt/units/`

### Adding New Stacks

1. Create stack directory in `stacks/`
2. Create `terragrunt.stack.hcl` with:
   - Multiple `unit` blocks referencing units via Git URLs
   - `values` blocks to pass inputs between units
   - Use `dependency` pattern in unit definitions if needed

### Working with Dependencies

Units can declare dependencies on other units using the `dependency` block:

```hcl
dependency "proxmox_pool" {
  config_path = "../proxmox-pool"

  mock_outputs = {
    poolid = "mock-pool"
  }
}

inputs = {
  poolid = dependency.proxmox_pool.outputs.poolid
}
```

## Important Notes

### Source References

- **Units in `units/`**: Use Git URLs for external consumption
- **Examples in `examples/terragrunt/units/`**: Use relative paths like `../../../.././/modules/proxmox-lxc`
- The double-slash (`//`) in relative paths is required for proper module resolution

### State Management

- State is stored in MinIO (S3-compatible storage)
- Bucket naming: `${prefix}-homelab-terragrunt-tfstates`
- State files: `${path_relative_to_include()}/tofu.tfstate`
- Locking is enabled via `use_lockfile = true`

### Generated Files

Terragrunt automatically generates:
- `backend.tf`: S3 backend configuration
- `provider.tf`: Proxmox provider configuration

These are regenerated on each run and should not be committed to version control.

### Proxmox Resources

Current modules support:
- **LXC Containers**: Ubuntu 24.04 standard template on `pve1` node
- **Resource Pools**: For organizing Proxmox resources
- Default network: DHCP on `vmbr0` bridge
- Default storage: `local-lvm` with 8G rootfs
