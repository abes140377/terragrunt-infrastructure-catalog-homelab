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
   - `proxmox-vm`: Creates virtual machines on Proxmox via template cloning
   - `proxmox-pool`: Creates Proxmox resource pools
   - `dns`: Manages DNS A records on BIND9 servers (supports both normal and wildcard records)
   - `naming`: Wrapper around the homelab provider for standardized resource naming
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
   - Example: `stacks/homelab-proxmox-container/` combines proxmox-pool, proxmox-lxc, and dns units

**Examples Directory:**
The `examples/` directory contains working examples for local testing:

**Terragrunt Examples** (`examples/terragrunt/`):
- `examples/terragrunt/units/`: Individual unit examples with relative module paths
  - `proxmox-lxc`: LXC container deployment example
  - `proxmox-vm`: Virtual machine deployment example
  - `proxmox-pool`: Resource pool creation example
  - `dns`: DNS record management example (normal records only)
  - `dns-wildcard`: Wildcard DNS record example (wildcard records only)
  - `naming`: Naming convention example
- `examples/terragrunt/stacks/`: Complete stack examples using local units
  - `homelab-proxmox-pool`: Proxmox resource pool only
  - `homelab-proxmox-container`: LXC container + pool + DNS
  - `homelab-proxmox-vm`: Virtual machine + pool + DNS (requires SSH key configuration)
  - `homelab-wildcard-dns`: LXC container with both regular and wildcard DNS records
  - **Note**: Stack examples reference units via relative paths (`../../../../units/`) for local testing
- Unit examples use relative paths to modules (e.g., `../../../.././/modules/proxmox-lxc`)
- Stack examples use relative paths to units (e.g., `../../../../units/dns`) for easier testing

**Direct OpenTofu Examples** (`examples/tofu/`):
- Direct module usage without Terragrunt wrappers
- Available examples: `proxmox-lxc`, `proxmox-vm`, `proxmox-pool`, `dns`, `naming`
- Useful for testing modules independently
- Use relative paths to reference modules (e.g., `../../../modules/proxmox-lxc`)

**Git URL Pattern:**
Units and stacks use Git URLs in their `source` field because they are designed to be consumed as shallow directories by external users who won't have access to the full repository. The examples use relative paths (`../../../.././/modules/proxmox-lxc`) for local development.

### Configuration Files

**Root Configuration** (`examples/terragrunt/root.hcl`):

- Defines shared locals for S3 backend and provider configuration
- Reads from `backend-config.hcl`, `provider-config.hcl`, and `dns-config.hcl`
- Generates `backend.tf` and `provider.tf` for all child modules
- All units must include this via `include "root"`

**Backend Configuration** (`examples/terragrunt/backend-config.hcl`):

- Uses MinIO as S3-compatible backend
- Requires environment variables: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- Endpoint: `http://minio.home.sflab.io:9000`

**Provider Configuration** (`examples/terragrunt/provider-config.hcl`):

- Configures bpg/proxmox provider (>= 0.69.0)
- Default host: `proxmox.home.sflab.io:8006`
- Uses `PROXMOX_VE_API_TOKEN` environment variable for authentication
- SSH agent support enabled for advanced operations

**DNS Configuration** (`examples/terragrunt/dns-config.hcl`):

- Centralized DNS server configuration for all DNS units
- Server: `192.168.1.13:5353`
- TSIG key name: `ddnskey.`
- Algorithm: `hmac-sha512`
- Used by DNS units to configure the hashicorp/dns provider

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

# List MinIO buckets and their contents
mise run minio:list

# Setup Proxmox resources (creates role and user)
mise run proxmox:setup

# Edit SOPS-encrypted secrets
mise run secrets:edit

# Clean up Terragrunt cache files
mise run terragrunt:cleanup

# Quick apply for units (interactive selection menu)
mise run terragrunt:unit:apply

# Quick plan for units (interactive selection menu)
mise run terragrunt:unit:plan

# Quick destroy for units (interactive selection menu)
mise run terragrunt:unit:destroy

# Quick apply for stacks (interactive selection menu)
mise run terragrunt:stack:apply

# Quick plan for stacks (interactive selection menu)
mise run terragrunt:stack:plan

# Quick destroy for stacks (interactive selection menu)
mise run terragrunt:stack:destroy

# Generate stack locally
mise run terragrunt:stack:generate

# Run all tests (with flags: -t tofu, -u units, -s stacks, -a all)
mise run test:all -- -t  # Run only tofu module tests
mise run test:all -- -u  # Run only terragrunt unit tests
mise run test:all -- -s  # Run only terragrunt stack tests (requires committed changes)
mise run test:all -- -a  # Run all tests

# Note: Stack tests require all changes to be committed and pushed to GitHub
# because they fetch units from the remote repository (ref=main)

# Direct OpenTofu commands for examples/tofu (interactive selection or specify target)
mise run tofu:init        # Interactive menu
mise run tofu:init naming # Specific target
mise run tofu:plan
mise run tofu:apply
mise run tofu:output
mise run tofu:destroy
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

# Working with VM units
cd examples/terragrunt/units/proxmox-vm

# Initialize and deploy VM
terragrunt init
terragrunt plan
terragrunt apply

# Working with stacks
cd examples/terragrunt/stacks/homelab-proxmox-container

# Generate stack (creates .terragrunt-stack directory)
terragrunt stack generate

# Plan changes for entire stack
terragrunt stack run plan

# Apply changes for entire stack
terragrunt stack run apply

# Destroy stack resources
terragrunt stack run destroy

# Working with VM stacks
cd examples/terragrunt/stacks/homelab-proxmox-vm

# Set required environment variables
export AWS_ACCESS_KEY_ID="your-minio-access-key"
export AWS_SECRET_ACCESS_KEY="your-minio-secret-key"
export PROXMOX_VE_API_TOKEN="root@pam!tofu=xxxxxxxx"
export TF_VAR_dns_key_secret="your-tsig-key-secret"

# Generate and deploy VM stack
terragrunt stack generate
terragrunt stack run apply

# Verify DNS resolution (note: DNS server runs on port 5353)
dig example-stack-vm.home.sflab.io @192.168.1.13 -p 5353
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
   - Local relative path to module (e.g., `../../../.././/modules/proxmox-lxc` or `../../../.././/modules/proxmox-vm`)
   - Direct `inputs` block with concrete values or dependency outputs

Examples:
- `units/proxmox-lxc/terragrunt.hcl`: LXC container unit
- `units/proxmox-vm/terragrunt.hcl`: Virtual machine unit (requires `ssh_public_key_path`)
- `units/proxmox-pool/terragrunt.hcl`: Resource pool unit
- `units/dns/terragrunt.hcl`: DNS record unit (supports both regular and wildcard DNS records via `record_types` parameter)
- `units/naming/terragrunt.hcl`: Naming convention unit

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

Examples in `stacks/` (production stacks using Git URLs):
- `stacks/homelab-proxmox-container/`: LXC container stack with pool and DNS
- `stacks/homelab-proxmox-vm/`: Virtual machine stack with pool and DNS (requires SSH key path configuration)

Examples in `examples/terragrunt/stacks/` (local testing stacks):
- `examples/terragrunt/stacks/homelab-proxmox-pool/`: Proxmox resource pool only
- `examples/terragrunt/stacks/homelab-proxmox-container/`: LXC container with pool and DNS
- `examples/terragrunt/stacks/homelab-proxmox-vm/`: VM with pool and DNS
- `examples/terragrunt/stacks/homelab-wildcard-dns/`: LXC container with both normal and wildcard DNS records

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
  env      = "dev"
  app      = "example"
  password = "your-password"
  pool_id  = dependency.proxmox_pool.outputs.pool_id
}
```

**Note**: Standalone units in `units/` use the `values` pattern instead of direct inputs.

### Working with Stacks

Stacks allow you to deploy multiple units together as a coordinated group. Here's an example stack structure with DNS integration:

```hcl
# stacks/homelab-proxmox-container/terragrunt.stack.hcl
locals {
  pool_id  = values.pool_id
  env      = values.env
  app      = values.app
  password = values.password
}

unit "proxmox_pool" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=${values.version}"
  path   = "proxmox-pool"  # REQUIRED: deployment path within .terragrunt-stack

  values = {
    pool_id = local.pool_id
  }
}

unit "proxmox_lxc" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-lxc?ref=${values.version}"
  path   = "proxmox-lxc"  # REQUIRED: deployment path within .terragrunt-stack

  values = {
    env      = local.env
    app      = local.app
    password = local.password
    pool_id  = local.pool_id
  }
}

unit "dns" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${values.version}"
  path   = "dns"  # REQUIRED: deployment path within .terragrunt-stack

  values = {
    env           = local.env
    app           = local.app
    zone          = "home.sflab.io."
    compute_path  = "../proxmox-lxc"  # Enables dependency on LXC container IP
  }
}
```

**Important Stack Requirements:**

1. Each `unit` block **must** have a `path` attribute
2. Dependencies between units are handled via unit paths (e.g., `compute_path`) that enable dependency blocks within units
3. The DNS unit automatically gets the container/VM IP through its dependency on the compute unit (LXC or VM)
4. Use `terragrunt stack run <command>` to operate on the entire stack
5. Stack generates units into `.terragrunt-stack/` directory (gitignored)
6. All infrastructure resources use standardized naming: `<env>-<app>` pattern via the naming module

**DNS Stack Integration:**

- The `dns` unit registers the container/VM IP address in DNS after creation
- Set `TF_VAR_dns_key_secret` environment variable before deploying the stack
- The DNS unit uses `compute_path` to create a dependency on the LXC or VM unit
- Execution order: `proxmox_pool` → `proxmox_lxc`/`proxmox_vm` → `dns` (automatic via dependencies)
- After deployment, resources are resolvable at `${env}-${app}.home.sflab.io`

**Deploying a Stack with DNS:**

```bash
# Set required environment variables
export AWS_ACCESS_KEY_ID="your-minio-access-key"
export AWS_SECRET_ACCESS_KEY="your-minio-secret-key"
export PROXMOX_VE_API_TOKEN="root@pam!tofu=xxxxxxxx"
export TF_VAR_dns_key_secret="your-tsig-key-secret"

# Navigate to stack directory
cd examples/terragrunt/stacks/homelab-proxmox-container

# Generate and deploy stack
terragrunt stack generate
terragrunt stack run apply

# Verify DNS resolution (note: DNS server runs on port 5353)
# Example: If env=dev and app=example, the FQDN will be dev-example.home.sflab.io
dig dev-example.home.sflab.io @192.168.1.13 -p 5353
```

**Deploying Multiple VMs or Containers:**

Both modules (proxmox-vm and proxmox-lxc) follow a single-instance pattern. To deploy multiple resources:

1. **Option 1: Multiple Stack Units** - Create separate units for each VM/container in your stack:
   ```hcl
   # Stack with multiple VMs
   unit "proxmox_vm_1" {
     source = "../../../../units/proxmox-vm"
     path   = "proxmox-vm-1"
     values = {
       env     = "dev"
       app     = "web-1"
       memory  = 4096
       pool_id = local.pool_id
     }
   }

   unit "proxmox_vm_2" {
     source = "../../../../units/proxmox-vm"
     path   = "proxmox-vm-2"
     values = {
       env     = "dev"
       app     = "web-2"
       memory  = 4096
       pool_id = local.pool_id
     }
   }

   # DNS units for each VM
   unit "dns_1" {
     source = "../../../../units/dns"
     path   = "dns-1"
     values = {
       env          = "dev"
       app          = "web-1"
       zone         = "home.sflab.io."
       compute_path = "../proxmox-vm-1"
     }
   }

   unit "dns_2" {
     source = "../../../../units/dns"
     path   = "dns-2"
     values = {
       env          = "dev"
       app          = "web-2"
       zone         = "home.sflab.io."
       compute_path = "../proxmox-vm-2"
     }
   }
   ```

2. **Option 2: Separate Deployments** - Deploy each VM/container as a separate stack instance

This pattern maintains consistency with the LXC module and simplifies configuration.

**VM Network Configuration:**

The proxmox-vm module supports both DHCP (default) and static IP configuration:

```hcl
# DHCP configuration (default)
unit "proxmox_vm" {
  values = {
    env = "dev"
    app = "web"
    # network_config defaults to DHCP
  }
}

# Static IP configuration
unit "proxmox_vm" {
  values = {
    env = "dev"
    app = "web"
    network_config = {
      type        = "static"
      ip_address  = "192.168.1.100"
      cidr        = 24
      gateway     = "192.168.1.1"
      dns_servers = ["8.8.8.8", "8.8.4.4"]  # Optional
    }
  }
}
```

For local testing, create example stacks in `examples/terragrunt/stacks/` with local unit wrappers that use relative paths to modules.

### SSH Key Configuration for VM Stacks

**IMPORTANT**: When deploying VM stacks, SSH keys must be configured with **absolute paths** because:
- Stacks fetch units from GitHub and execute them in `.terragrunt-cache` directories
- Relative paths like `./keys/admin_id_ecdsa.pub` don't work in cache directories
- The `keys/` directory only exists in the repository root

**Solution**: Use `get_repo_root()` to create absolute paths in stack configurations:

```hcl
# In terragrunt.stack.hcl
locals {
  # SSH key configuration - use absolute path for stack deployments
  ssh_public_key_path = "${get_repo_root()}/keys/admin_id_ecdsa.pub"
}

unit "proxmox_vm" {
  source = "../../../../units/proxmox-vm"
  path   = "proxmox-vm"

  values = {
    env                 = "dev"
    app                 = "web"
    ssh_public_key_path = local.ssh_public_key_path  # Pass absolute path
  }
}
```

**Available SSH Keys** (in `keys/` directory):
- `admin_id_ecdsa.pub`: ECDSA public key for admin user SSH access

### Wildcard DNS Records

The DNS module supports creating both normal and wildcard DNS records simultaneously through the `record_types` parameter.

**Record Types**:
- **Normal Record** (`record_types.normal = true`): Creates `{env}-{app}.home.sflab.io`
  - Example: `dev-web.home.sflab.io`
- **Wildcard Record** (`record_types.wildcard = true`): Creates `*.{env}-{app}.home.sflab.io`
  - Example: `*.dev-web.home.sflab.io`
  - Matches: `anything.dev-web.home.sflab.io`, `api.dev-web.home.sflab.io`, etc.

**Default Behavior**: By default, only normal records are created (`normal = true`, `wildcard = false`).

**Usage Examples:**

```hcl
# Create only wildcard record
unit "dns_wildcard" {
  source = "../../../../units/dns"
  path   = "dns-wildcard"

  values = {
    env          = "dev"
    app          = "web"
    zone         = "home.sflab.io."
    record_types = {
      normal   = false
      wildcard = true
    }
    compute_path = "../proxmox-lxc"
  }
}

# Create both normal AND wildcard records
unit "dns_both" {
  source = "../../../../units/dns"
  path   = "dns-both"

  values = {
    env          = "dev"
    app          = "web"
    zone         = "home.sflab.io."
    record_types = {
      normal   = true   # Creates dev-web.home.sflab.io
      wildcard = true   # Creates *.dev-web.home.sflab.io
    }
    compute_path = "../proxmox-lxc"
  }
}
```

**Example Stack**: See `examples/terragrunt/stacks/homelab-wildcard-dns/` for a complete example with both regular and wildcard DNS records.

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
- Bucket naming: `${prefix}-tfstates`
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
  - Resources:
    - `proxmox_virtual_environment_container` - Main container resource
    - `proxmox_virtual_environment_pool_membership` - Pool assignment (conditional, created only if pool_id provided)
    - Uses `naming` module internally for standardized hostname generation
  - Required inputs:
    - `env` (string): Environment name (e.g., "dev", "staging", "prod")
    - `app` (string): Application name (e.g., "web", "db", "api")
    - `password` (string, sensitive): Root password for the container
  - Optional inputs: `pool_id` (string, default: "") - Assigns container to pool via pool_membership resource
  - Network interface: `veth0` on `vmbr0` bridge with DHCP
  - Disk: 8GB on `local-lvm` datastore
  - Unprivileged containers by default
  - Hostname: Automatically generated as `<env>-<app>` via naming module
  - Outputs: `ipv4` (container IP address)
  - **Note**: Pool assignment uses `proxmox_virtual_environment_pool_membership` resource (not deprecated `pool_id` attribute)
- **Virtual Machines** (`modules/proxmox-vm`): Single VM deployment on Proxmox via template cloning
  - Resources:
    - `proxmox_virtual_environment_vm` - Main VM resource
    - `proxmox_virtual_environment_pool_membership` - Pool assignment (conditional, created only if pool_id provided)
    - Uses `naming` module internally for standardized VM name generation
  - Required inputs:
    - `env` (string): Environment name (e.g., "dev", "staging", "prod")
    - `app` (string): Application name (e.g., "web", "db", "api")
  - Optional inputs:
    - `memory` (number, default: 2048) - Memory allocation in MB
    - `cores` (number, default: 2) - CPU cores
    - `pool_id` (string, default: "") - Assigns VM to pool via pool_membership resource
    - `network_config` (object, default: DHCP) - Network configuration supporting both DHCP and static IP
    - `ssh_public_key_path` (string, required) - SSH public key for admin user access (no default)
    - `username` (string, default: "admin") - Username for SSH access
  - Configuration: Clones from template VM 9002 on `pve1` node
  - Network: Supports both DHCP (default) and static IP configuration
  - Agent: QEMU guest agent enabled for IP address retrieval
  - VM name: Automatically generated as `<env>-<app>` via naming module
  - Outputs: `ipv4` (VM IP address), `vm_id` (Proxmox VM ID), `vm_name` (VM name)
  - **Note**: Pool assignment uses `proxmox_virtual_environment_pool_membership` resource (not deprecated `pool_id` attribute)
- **Resource Pools** (`modules/proxmox-pool`): For organizing Proxmox resources
  - Resource: `proxmox_virtual_environment_pool`
  - Required inputs: `pool_id` (string)
  - Optional inputs: `description` (string, default: "")
  - Outputs: `pool_id` (pool identifier)

**DNS Resources:**

- **DNS A Records** (`modules/dns`): Manages DNS A records on BIND9 servers via RFC 2136 dynamic updates
  - Resource: `dns_a_record_set`
  - Provider: `hashicorp/dns` (>= 3.4.0) - configured in units, not in module
  - Uses `naming` module internally for standardized DNS record name generation
  - Required inputs:
    - `env` (string): Environment name (e.g., "dev", "staging", "prod")
    - `app` (string): Application name (e.g., "web", "db", "api")
    - `zone` (string): DNS zone name (e.g., "home.sflab.io.")
    - `addresses` (list(string)): List of IPv4 addresses
  - Optional inputs:
    - `ttl` (number, default: 300)
    - `record_types` (object, default: `{normal = true, wildcard = false}`) - Controls which DNS record types to create
      - `normal` (bool): Creates standard `{env}-{app}` record
      - `wildcard` (bool): Creates wildcard `*.{env}-{app}` record
      - Both can be true simultaneously to create both record types
  - DNS record name: Automatically generated as `<env>-<app>` via naming module (or `*.<env>-<app>` for wildcard records)
  - Outputs: `fqdn` (normal record FQDN, null if not created), `fqdn_wildcard` (wildcard record FQDN, null if not created), `addresses` (IP addresses)
  - DNS Server Configuration (in units):
    - Server: `192.168.1.13:5353` (Port 5353, not default 53!)
    - TSIG Key: `ddnskey` (fully-qualified with trailing dot)
    - Algorithm: `hmac-sha512`
    - Authentication: Uses TSIG (Transaction Signature) for secure dynamic DNS updates
    - Secret: Passed via `TF_VAR_dns_key_secret` environment variable

**Naming Resources:**

- **Resource Naming** (`modules/naming`): Wrapper around the homelab provider for standardized naming conventions
  - Data Source: `homelab_naming` (from external homelab provider)
  - Provider: `registry.terraform.io/sflab-io/homelab` (version >= 0.3.0)
  - Required inputs:
    - `env` (string): Environment name (e.g., "dev", "staging", "prod")
    - `app` (string): Application name (e.g., "web", "db", "api")
  - Outputs: `generated_name` (generated name following pattern `<env>-<app>`)
  - Usage: Provides consistent naming across all infrastructure resources (LXC, VM, DNS)

**Note**: The homelab provider is published to the Terraform Registry and does not require local installation. All modules (proxmox-lxc, proxmox-vm, dns) use the naming module internally to generate standardized names from `env` and `app` inputs.

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
