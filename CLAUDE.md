<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terragrunt infrastructure catalog for homelab Proxmox environments. It provides reusable infrastructure components (modules, units, and stacks) for managing Proxmox resources and DNS records using OpenTofu/Terraform and Terragrunt.

### Tool Versions

Managed via mise (mise.toml):
- **Go**: 1.24.2
- **OpenTofu**: 1.9.0
- **Terragrunt**: 0.78.0
- **MinIO Client (mc)**: latest

Run `mise install` to install all required tools.

**Note**: When you `cd` into the project directory, mise will automatically:
- Install all required tools if not present
- Install pre-commit hooks for code quality checks

### Key Architecture Concepts

**Three-Layer Architecture:**

1. **Modules** (`modules/`): Raw Terraform/OpenTofu modules
   - `proxmox-lxc`: Creates LXC containers on Proxmox
   - `proxmox-pool`: Creates Proxmox resource pools
   - `dns`: Manages DNS A records on BIND9 servers
   - These are basic building blocks with no Terragrunt-specific logic

2. **Units** (`units/`): Terragrunt wrappers around modules
   - Each unit references a module via Git URL (for external consumption)
   - Units use `values` pattern for parameterization (e.g., `values.hostname`)
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

# Set DNS TSIG key secret (required for DNS module)
export TF_VAR_dns_key_secret="your-tsig-key-secret"
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

# Run pre-commit hooks manually
pre-commit run --all-files
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
   - `inputs` block using `values.*` pattern for parameterization
3. Add example in `examples/terragrunt/units/` with:
   - Local relative path to module (e.g., `../../../.././/modules/proxmox-lxc`)
   - Direct `inputs` block with concrete values or dependency outputs

### Adding New Stacks

1. Create stack directory in `stacks/`
2. Create `terragrunt.stack.hcl` with:
   - Multiple `unit` blocks referencing units via Git URLs
   - `values` blocks to pass inputs between units
   - Use `dependency` pattern in unit definitions if needed

### Working with Dependencies

Units in `examples/` can declare dependencies on other units using the `dependency` block:

```hcl
terraform {
  source = "../../../.././/modules/proxmox-lxc"

  # Pass variables via extra_arguments
  extra_arguments "variables" {
    commands = ["apply", "plan"]

    arguments = [
      "-var", "password=your-password",
    ]
  }
}

dependency "proxmox_pool" {
  config_path = "../proxmox-pool"

  mock_outputs = {
    poolid = "mock-pool"
  }
}

inputs = {
  hostname = "example-container"
  poolid   = dependency.proxmox_pool.outputs.poolid
}
```

**Note**: Standalone units in `units/` use the `values` pattern instead of direct inputs.

### Passing Variables to Modules

Variables can be passed to Terraform modules in several ways:

1. **Via extra_arguments in terragrunt.hcl**:
```hcl
terraform {
  extra_arguments "variables" {
    commands = ["apply", "plan", "destroy"]
    arguments = ["-var", "password=my-password"]
  }
}
```

2. **Via TF_VAR_ environment variables**:
```bash
export TF_VAR_password="my-password"
terragrunt apply
```

3. **Via CLI arguments**:
```bash
terragrunt apply -var="password=my-password"
```

4. **Via .tfvars file**:
```bash
echo 'password = "my-password"' > terraform.tfvars
terragrunt apply
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

### Infrastructure Resources

Current modules support:

**Proxmox Resources:**
- **LXC Containers** (`modules/proxmox-lxc`): Ubuntu 24.04 standard template on `pve1` node
  - Resource: `proxmox_virtual_environment_container`
  - Required inputs: `hostname` (string), `password` (string, sensitive)
  - Optional inputs: `poolid` (string, default: "")
  - Network interface: `veth0` on `vmbr0` bridge with DHCP
  - Disk: 8GB on `local-lvm` datastore
  - Unprivileged containers by default
  - Outputs: `ipv4` (container IP address)
- **Resource Pools** (`modules/proxmox-pool`): For organizing Proxmox resources
  - Resource: `proxmox_virtual_environment_pool`
  - Required inputs: `poolid` (string)
  - Optional inputs: `description` (string, default: "")
  - Outputs: `poolid` (pool identifier)

**DNS Resources:**
- **DNS A Records** (`modules/dns`): Manages DNS A records on BIND9 servers via RFC 2136 dynamic updates
  - Resource: `dns_a_record_set`
  - Provider: `hashicorp/dns` (>= 3.4.0)
  - Required inputs:
    - `zone` (string): DNS zone name (e.g., "home.sflab.io.")
    - `name` (string): Record name within the zone
    - `addresses` (list(string)): List of IPv4 addresses
    - `dns_server` (string): DNS server address and port (e.g., "192.168.1.13:53")
    - `key_name` (string): TSIG key name for authentication
    - `key_algorithm` (string): TSIG key algorithm (e.g., "hmac-sha256")
    - `key_secret` (string, sensitive): TSIG key secret
  - Optional inputs: `ttl` (number, default: 300)
  - Outputs: `fqdn` (fully qualified domain name), `addresses` (IP addresses)
  - Authentication: Uses TSIG (Transaction Signature) for secure dynamic DNS updates

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
- Password now required as variable (was previously hardcoded)

## Code Quality

### Pre-commit Hooks

The repository uses pre-commit hooks to maintain code quality:
- **gitleaks**: Detects hardcoded secrets and credentials
- **fix end of files**: Ensures files end with a newline
- **trim trailing whitespace**: Removes trailing whitespace
- **OpenTofu fmt**: Formats all .tf files
- **OpenTofu validate**: Validates Terraform module syntax and configuration

Hooks run automatically on commit. To run manually:
```bash
pre-commit run --all-files
```

### Environment Variables

Sensitive credentials are stored in `.creds.env.yaml` (SOPS-encrypted):
- `MINIO_USERNAME`, `MINIO_PASSWORD`: MinIO admin credentials
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`: MinIO service account for Terragrunt backend
- `PROXMOX_VE_API_TOKEN`: Proxmox API token for bpg/proxmox provider
- `DNS_TSIG_KEY_SECRET`: TSIG key secret for DNS dynamic updates

To edit encrypted secrets:
```bash
mise run secrets:edit
```

**Module-specific variables** can be passed via:
- `TF_VAR_*` environment variables (e.g., `TF_VAR_password`, `TF_VAR_dns_key_secret`)
- CLI arguments (e.g., `-var="password=..."`)
- Terragrunt `extra_arguments` block (see "Passing Variables to Modules" section)

Example:
```bash
export TF_VAR_password="your-secure-password"
export TF_VAR_dns_key_secret="your-tsig-key-secret"
terragrunt apply
```

#### DNS TSIG Key Setup

To enable DNS dynamic updates on your BIND9 server, you need to configure TSIG (Transaction Signature) authentication:

**1. Generate TSIG Key on BIND9 Server:**

```bash
# Using tsig-keygen (recommended)
tsig-keygen -a hmac-sha256 terraform-key > /etc/bind/terraform-key.conf

# Or using rndc-confgen
rndc-confgen -a -c /etc/bind/terraform-key.conf -k terraform-key -t /var/run/named
```

**2. Configure BIND9 to Accept Dynamic Updates:**

Add to `/etc/bind/named.conf.local`:

```bind
include "/etc/bind/terraform-key.conf";

zone "home.sflab.io" {
    type master;
    file "/var/lib/bind/db.home.sflab.io";
    allow-update { key terraform-key; };
};
```

**3. Store TSIG Secret in SOPS:**

Extract the secret from the key file and add to `.creds.env.yaml`:

```bash
# View the generated key
sudo cat /etc/bind/terraform-key.conf

# Add to .creds.env.yaml using mise
mise run secrets:edit
```

Add this entry:
```yaml
DNS_TSIG_KEY_SECRET: "your-base64-secret-from-key-file"
```

**4. Use in Terragrunt:**

Reference the secret via environment variable:

```bash
export TF_VAR_dns_key_secret="$(sops -d .creds.env.yaml | yq '.DNS_TSIG_KEY_SECRET')"
```

Or use the `extra_arguments` block in terragrunt.hcl (see `examples/terragrunt/units/dns/terragrunt.hcl`).
