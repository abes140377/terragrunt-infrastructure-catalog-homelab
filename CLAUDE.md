# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terragrunt infrastructure catalog for homelab Proxmox environments. It provides reusable infrastructure components (modules, units, and stacks) for managing Proxmox resources using OpenTofu/Terraform and Terragrunt.

### Tool Versions

Managed via mise (mise.toml):
- **Go**: 1.24.2
- **OpenTofu**: 1.9.0
- **Terragrunt**: 0.78.0
- **MinIO Client (mc)**: latest

Run `mise install` to install all required tools.

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
- Requires environment variables: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- Endpoint: `http://minio.home.sflab.io:9000`

**Provider Configuration** (`examples/terragrunt/provider.hcl`):
- Configures bpg/proxmox provider (>= 0.69.0)
- Default host: `proxmox.home.sflab.io:8006`
- Uses `PROXMOX_VE_API_TOKEN` environment variable for authentication
- SSH agent support enabled for advanced operations

## Common Commands

### Environment Setup

```bash
# Set MinIO credentials (required for Terragrunt backend)
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"

# Set Proxmox credentials (required for bpg/proxmox provider)
# Format: username@realm!tokenname=secret
export PROXMOX_VE_API_TOKEN="root@pam!tofu=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### Mise Tasks

```bash
# Setup MinIO bucket and service account
mise run minio:setup

# Setup Proxmox resources
mise run proxmox:setup

# Install Python dependencies
mise run install-deps

# Edit SOPS-encrypted secrets
mise run secrets:edit

# Clean up Terragrunt cache files
mise run terragrunt:cleanup
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

# Working with stacks (from repository root)
cd stacks/proxmox-container

# View stack configuration
terragrunt render

# Deploy stack (not yet implemented in examples)
# terragrunt run-all plan
# terragrunt run-all apply
```

### Development Commands

```bash
# Format all Terraform/OpenTofu files
tofu fmt -recursive

# Validate Terraform modules
cd modules/proxmox-lxc
tofu init
tofu validate

# Clean up Terragrunt and Terraform cache files
mise run terragrunt:cleanup
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
  - Resource: `proxmox_virtual_environment_container`
  - Network interface: `veth0` on `vmbr0` bridge with DHCP
  - Disk: 8GB on `local-lvm` datastore
  - Unprivileged containers by default
- **Resource Pools**: For organizing Proxmox resources
  - Resource: `proxmox_virtual_environment_pool`

### Provider Migration Notes

This repository uses the **bpg/proxmox** provider (version >= 0.69.0), not the older telmate/proxmox provider. Key differences:

**Resource Names:**
- LXC: `proxmox_virtual_environment_container` (was `proxmox_lxc`)
- Pool: `proxmox_virtual_environment_pool` (was `proxmox_pool`)

**Authentication:**
- Environment variable: `PROXMOX_VE_API_TOKEN` (was `PM_API_TOKEN_ID` + `PM_API_TOKEN_SECRET`)
- Token format: `username@realm!tokenname=secret` (single string)

**LXC Container Configuration:**
- Attributes wrapped in nested blocks: `initialization`, `disk`, `network_interface`, `operating_system`
- Network interface name: `veth0` (was `eth0`)
- IP config: `initialization.ip_config.ipv4.address = "dhcp"`
