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
   - Each unit must specify a `path` attribute for deployment location
   - Example: `stacks/proxmox-container/` combines proxmox-pool, proxmox-lxc, and dns units

**Examples Directory:**
The `examples/terragrunt/` directory contains working examples for local testing:

- `examples/terragrunt/units/`: Individual unit examples with relative module paths
- `examples/terragrunt/stacks/`: Complete stack examples with local unit wrappers
- Examples use relative paths (e.g., `../../../.././/modules/proxmox-lxc`) instead of Git URLs

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

# Working with stacks
cd examples/terragrunt/stacks/proxmox-container

# Generate stack (creates .terragrunt-stack directory)
terragrunt stack generate

# Plan changes for entire stack
terragrunt stack run plan

# Apply changes for entire stack
terragrunt stack run apply

# Destroy stack resources
terragrunt stack run destroy
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
   - Each `unit` block **must** include a `path` attribute (deployment path within `.terragrunt-stack`)
   - `values` blocks to pass inputs between units
   - Dependencies are handled via `values` pattern, not `dependency` blocks
3. Create example stack in `examples/terragrunt/stacks/` with:
   - Local unit wrappers in `units/` subdirectory for testing
   - Direct references to modules via relative paths
   - Concrete values in `locals` block

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
    pool_id = "mock-pool"
  }
}

inputs = {
  hostname = "example-container"
  pool_id  = dependency.proxmox_pool.outputs.pool_id
}
```

**Note**: Standalone units in `units/` use the `values` pattern instead of direct inputs.

### Working with Stacks

Stacks allow you to deploy multiple units together as a coordinated group. Here's an example stack structure with DNS integration:

```hcl
# stacks/proxmox-container/terragrunt.stack.hcl
locals {
  pool_id  = values.pool_id
  hostname = values.hostname
  password = values.password
}

unit "proxmox_pool" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=${values.version}"
  path   = "proxmox-pool"  # REQUIRED: deployment path within .terragrunt-stack

  values = {
    pool_id = local.pool_id
  }
}

unit "proxmox_lxc" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-lxc?ref=${values.version}"
  path   = "proxmox-lxc"  # REQUIRED: deployment path within .terragrunt-stack

  values = {
    hostname        = local.hostname
    password        = local.password
    pool_id         = local.pool_id
    pool_unit_path  = "../proxmox-pool"
  }
}

unit "dns" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${values.version}"
  path   = "dns"  # REQUIRED: deployment path within .terragrunt-stack

  values = {
    zone           = "home.sflab.io."
    name           = local.hostname
    dns_server     = "192.168.1.13"
    dns_port       = 5353
    key_name       = "ddnskey."
    key_algorithm  = "hmac-sha512"
    lxc_unit_path  = "../proxmox-lxc"  # Enables dependency on LXC container IP
  }
}
```

**Important Stack Requirements:**

1. Each `unit` block **must** have a `path` attribute
2. Dependencies between units are handled via unit paths (e.g., `lxc_unit_path`) that enable dependency blocks within units
3. The DNS unit automatically gets the container IP through its dependency on the LXC unit
4. Use `terragrunt stack run <command>` to operate on the entire stack
5. Stack generates units into `.terragrunt-stack/` directory (gitignored)

**DNS Stack Integration:**

- The `dns` unit registers the container's IP address in DNS after creation
- Set `TF_VAR_dns_key_secret` environment variable before deploying the stack
- The DNS unit uses `lxc_unit_path` to create a dependency on the LXC container unit
- Execution order: `proxmox_pool` → `proxmox_lxc` → `dns` (automatic via dependencies)
- After deployment, the container is resolvable at `${hostname}.home.sflab.io`

**Deploying a Stack with DNS:**

```bash
# Set required environment variables
export AWS_ACCESS_KEY_ID="your-minio-access-key"
export AWS_SECRET_ACCESS_KEY="your-minio-secret-key"
export PROXMOX_VE_API_TOKEN="root@pam!tofu=xxxxxxxx"
export TF_VAR_dns_key_secret="your-tsig-key-secret"

# Navigate to stack directory
cd examples/terragrunt/stacks/proxmox-container

# Generate and deploy stack
terragrunt stack generate
terragrunt stack run apply

# Verify DNS resolution (note: DNS server runs on port 5353)
dig example-stack-container.home.sflab.io @192.168.1.13 -p 5353
```

For local testing, create example stacks in `examples/terragrunt/stacks/` with local unit wrappers that use relative paths to modules.

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

2. **Via TF*VAR* environment variables**:

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
  - Optional inputs: `pool_id` (string, default: "")
  - Network interface: `veth0` on `vmbr0` bridge with DHCP
  - Disk: 8GB on `local-lvm` datastore
  - Unprivileged containers by default
  - Outputs: `ipv4` (container IP address)
- **Resource Pools** (`modules/proxmox-pool`): For organizing Proxmox resources
  - Resource: `proxmox_virtual_environment_pool`
  - Required inputs: `pool_id` (string)
  - Optional inputs: `description` (string, default: "")
  - Outputs: `pool_id` (pool identifier)

**DNS Resources:**

- **DNS A Records** (`modules/dns`): Manages DNS A records on BIND9 servers via RFC 2136 dynamic updates
  - Resource: `dns_a_record_set`
  - Provider: `hashicorp/dns` (>= 3.4.0) - configured in units, not in module
  - Required inputs:
    - `zone` (string): DNS zone name (e.g., "home.sflab.io.")
    - `name` (string): Record name within the zone
    - `addresses` (list(string)): List of IPv4 addresses
  - Optional inputs:
    - `ttl` (number, default: 300)
  - Outputs: `fqdn` (fully qualified domain name), `addresses` (IP addresses)
  - DNS Server Configuration (in units):
    - Server: `192.168.1.13:5353` (Port 5353, not default 53!)
    - TSIG Key: `ddnskey` (fully-qualified with trailing dot)
    - Algorithm: `hmac-sha512`
    - Authentication: Uses TSIG (Transaction Signature) for secure dynamic DNS updates
    - Secret: Passed via `TF_VAR_dns_key_secret` environment variable

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

## Important Reminders

- Do not add any 'DNS TSIG Key Setup' instructions to CLUADE.md because the setup is done in a separate Ansible project
