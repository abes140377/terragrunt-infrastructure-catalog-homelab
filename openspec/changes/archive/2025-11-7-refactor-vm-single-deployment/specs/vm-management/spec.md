# vm-management Specification Deltas

## MODIFIED Requirements

### Requirement: VM Module Integration

The catalog SHALL provide a Terragrunt unit that wraps the proxmox-vm module following the standard three-layer architecture pattern with single-VM deployment.

#### Scenario: VM unit structure

- **WHEN** the proxmox-vm unit is created
- **THEN** it SHALL contain a `terragrunt.hcl` file in `units/proxmox-vm/`
- **AND** follow the same structure as existing units (proxmox-lxc, proxmox-pool)

#### Scenario: VM unit source reference

- **WHEN** the unit is defined for external consumption
- **THEN** it SHALL use a Git URL source: `git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-vm?ref=${values.version}`
- **AND** include a comment explaining the Git URL pattern for shallow directory consumption

#### Scenario: VM unit parameterization

- **WHEN** the unit is configured
- **THEN** it SHALL use the `values` pattern for inputs:
  - `values.vm_name` (required): Name of the VM to create
  - `values.memory` (optional, default: 2048): Memory allocation in MB
  - `values.cores` (optional, default: 2): CPU cores
  - `values.pool_id` (optional, default: ""): Proxmox pool ID for resource organization
  - `values.version` (required): Git reference for module source
- **AND** include `include "root"` block pointing to root.hcl

#### Scenario: VM module capabilities

- **WHEN** the unit deploys a VM
- **THEN** it SHALL leverage the proxmox-vm module functionality:
  - Clone from template VM (ID 9002)
  - Deploy on node pve1
  - Configure dedicated memory (default: 2048MB)
  - Configure CPU cores (default: 2)
  - Enable QEMU guest agent for IP address retrieval
  - Use DHCP for IPv4 configuration
  - Assign to resource pool if pool_id is provided

### Requirement: VM Unit Example Configuration

The catalog SHALL provide an example configuration demonstrating VM unit usage with concrete values for local testing.

#### Scenario: Example directory structure

- **WHEN** the example is created
- **THEN** it SHALL be located in `examples/terragrunt/units/proxmox-vm/`
- **AND** contain a `terragrunt.hcl` file

#### Scenario: Example source path

- **WHEN** the example is defined
- **THEN** it SHALL use a relative path source: `../../../.././/modules/proxmox-vm`
- **AND** include a comment explaining local development usage versus Git URL for external repositories

#### Scenario: Example provider configuration

- **WHEN** the example is configured
- **THEN** it SHALL generate the Proxmox provider configuration block
- **AND** read provider settings from `provider-config.hcl`
- **AND** enable SSH agent support

#### Scenario: Example pool dependency

- **WHEN** the example demonstrates pool integration
- **THEN** it SHALL declare a dependency on `../proxmox-pool`
- **AND** use `mock_outputs` for plan-time execution
- **AND** pass the pool_id to the VM module inputs

#### Scenario: Example VM configuration

- **WHEN** the example is configured
- **THEN** it SHALL specify concrete values:
  - `vm_name`: "example-terragrunt-units-proxmox-vm"
  - `pool_id`: from dependency output
  - Optional: `memory`, `cores` for customization

### Requirement: VM Stack Composition

The catalog SHALL provide a reusable stack that composes proxmox-pool, proxmox-vm, and dns units for complete single VM deployment with DNS registration.

#### Scenario: Stack structure

- **WHEN** the homelab-proxmox-vm stack is created
- **THEN** it SHALL be located in `stacks/homelab-proxmox-vm/`
- **AND** contain a `terragrunt.stack.hcl` file

#### Scenario: Stack unit composition

- **WHEN** the stack is defined
- **THEN** it SHALL include three units:
  - `proxmox_pool`: Creates resource pool
  - `proxmox_vm`: Deploys a single virtual machine
  - `dns`: Registers VM IP in DNS
- **AND** each unit SHALL specify a `path` attribute for deployment location within `.terragrunt-stack`

#### Scenario: Stack parameterization

- **WHEN** the stack is configured
- **THEN** it SHALL use `values` for parameterization:
  - `values.pool_id`: Pool identifier
  - `values.vm_name`: Virtual machine name
  - `values.memory` (optional): Memory allocation
  - `values.cores` (optional): CPU cores
  - `values.version`: Git reference for units
- **AND** use `locals` to pass values between units

#### Scenario: Stack unit sources

- **WHEN** the stack references units
- **THEN** it SHALL use Git URLs for external consumption:
  - `git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=${values.version}`
  - `git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${values.version}`
  - `git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${values.version}`
- **AND** include comments explaining the Git URL pattern

#### Scenario: Stack dependency configuration

- **WHEN** the stack configures units
- **THEN** the proxmox_vm unit SHALL receive:
  - `vm_name`: VM name from values
  - `memory`: Memory allocation (optional)
  - `cores`: CPU cores (optional)
  - `pool_id`: Pool identifier
  - `pool_unit_path = "../proxmox-pool"` to enable dependency on pool creation
- **AND** the dns unit SHALL receive:
  - `zone`: DNS zone
  - `name`: VM name
  - DNS configuration (dns_server, dns_port, key_name, key_algorithm)
  - `vm_unit_path = "../proxmox-vm"` to enable dependency on VM IP address
  - NO vm_identifier required (single VM output)

### Requirement: VM Stack Example Configuration

The catalog SHALL provide an example stack demonstrating single VM deployment with local unit wrappers for testing.

#### Scenario: Example stack directory structure

- **WHEN** the example stack is created
- **THEN** it SHALL be located in `examples/terragrunt/stacks/homelab-proxmox-vm/`
- **AND** contain a `terragrunt.stack.hcl` file
- **AND** contain a `units/` subdirectory with local unit wrappers

#### Scenario: Example stack local units

- **WHEN** the example stack uses local testing
- **THEN** it SHALL create unit wrappers in `units/` subdirectory:
  - `units/proxmox-pool/terragrunt.hcl`
  - `units/proxmox-vm/terragrunt.hcl`
  - `units/dns/terragrunt.hcl`
- **AND** each wrapper SHALL use relative paths to modules (e.g., `../../../../../.././/modules/proxmox-vm`)

#### Scenario: Example stack unit sources

- **WHEN** the example stack references units
- **THEN** it SHALL use relative paths: `./units/proxmox-pool`, `./units/proxmox-vm`, `./units/dns`
- **AND** include comments explaining Git URL usage for production

#### Scenario: Example stack values

- **WHEN** the example stack is configured
- **THEN** it SHALL use concrete values in `locals`:
  - `pool_id`: "example-stack-vm-pool"
  - `vm_name`: "example-stack-vm"
  - Optional: `memory`, `cores` for customization
- **AND** demonstrate DNS configuration for home.sflab.io zone

#### Scenario: Example VM unit wrapper

- **WHEN** the VM unit wrapper is created
- **THEN** it SHALL:
  - Include root.hcl configuration
  - Generate Proxmox provider block
  - Use relative source path to module
  - Accept `values.vm_name` as required input
  - Accept `values.memory`, `values.cores`, `values.pool_id` as optional inputs
  - Support optional `values.pool_unit_path` for dependency configuration
  - Use `dependency` block to get pool_id from proxmox-pool unit when pool_unit_path is provided

### Requirement: VM Documentation

The catalog documentation SHALL include comprehensive guidance for single VM management capabilities.

#### Scenario: CLAUDE.md VM module documentation

- **WHEN** CLAUDE.md is updated
- **THEN** it SHALL document in "Infrastructure Resources" section:
  - **Virtual Machines** (`modules/proxmox-vm`): Single VM deployment on Proxmox
  - Resource: `proxmox_virtual_environment_vm`
  - Required inputs: `vm_name` (string)
  - Optional inputs: `memory` (number, default: 2048), `cores` (number, default: 2), `pool_id` (string, default: "")
  - Configuration: Clones from template VM 9002 on pve1 node
  - Network: DHCP IPv4 configuration
  - Agent: QEMU guest agent enabled for IP retrieval
  - Outputs: `ipv4` (VM IP address), `vm_id` (Proxmox VM ID), `vm_name` (VM name)

#### Scenario: CLAUDE.md VM unit documentation

- **WHEN** CLAUDE.md is updated
- **THEN** it SHALL document in "Adding New Units" section:
  - Reference to proxmox-vm unit pattern for single VM deployment
  - Example of values pattern usage for VM units with individual parameters

#### Scenario: CLAUDE.md VM stack documentation

- **WHEN** CLAUDE.md is updated
- **THEN** it SHALL document in "Adding New Stacks" section:
  - Reference to homelab-proxmox-vm stack as an example of single VM + DNS integration
  - Explanation of simplified single VM deployment pattern
  - Note that multi-VM deployments require multiple stack units or separate deployments

#### Scenario: CLAUDE.md VM examples documentation

- **WHEN** CLAUDE.md is updated
- **THEN** it SHALL document in "Examples Directory" section:
  - `examples/terragrunt/units/proxmox-vm/`: Single VM unit example
  - `examples/terragrunt/stacks/homelab-proxmox-vm/`: Complete single VM stack example with DNS

#### Scenario: CLAUDE.md VM deployment commands

- **WHEN** CLAUDE.md is updated
- **THEN** it SHALL include example commands in "Terragrunt Operations" section:
  - Single VM unit deployment example
  - Single VM stack deployment example with DNS verification
  - Remove multi-VM deployment examples and references

## REMOVED Requirements

### Requirement: Multi-VM Map Structure

**Reason**: Refactoring to single-VM pattern removes the need for map-based configuration.

**Migration**: Users deploying multiple VMs should create separate unit instances or stack units for each VM, following the same pattern as the proxmox-lxc module.

#### Scenario: Multi-VM vms map input

- **WHEN** the module was configured for multiple VMs
- **THEN** it accepted a `vms` map variable with VM configurations
- **AND** each VM was identified by a unique key in the map

#### Scenario: Multi-VM outputs map

- **WHEN** multiple VMs were deployed
- **THEN** outputs returned a map of VM identifiers to their attributes
- **AND** DNS units required vm_identifier to extract specific VM IPs

#### Scenario: Multi-VM DNS unit configuration

- **WHEN** DNS records were created for multiple VMs
- **THEN** separate DNS units were required for each VM
- **AND** each DNS unit specified a vm_identifier value to select the VM from the map
