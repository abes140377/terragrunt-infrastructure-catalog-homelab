# Multi-VM Stack Capability

## MODIFIED Requirements

### Requirement: Stack Multi-VM Configuration

The homelab-proxmox-vm stack SHALL support defining multiple VMs in a single locals block with a map structure for unified configuration.

#### Scenario: VMs map definition in stack

- **WHEN** the stack is configured
- **THEN** it SHALL define a `vms` map in the locals block
- **AND** each key SHALL be a unique VM identifier (e.g., "web01", "db01")
- **AND** each value SHALL be a map containing VM-specific configuration:
  - `vm_name` (required): The VM name in Proxmox
  - `memory` (optional): Memory in MB
  - `cores` (optional): Number of CPU cores
  - `pool_id` (optional): Per-VM pool override

#### Scenario: Stack locals pattern

- **WHEN** the stack is configured
- **THEN** it SHALL define `local.pool_id` for the shared resource pool
- **AND** SHALL define `local.vms` as the map of VM configurations
- **AND** MAY define other shared configuration values (DNS zone, server, etc.)

#### Scenario: Example multi-VM configuration

- **WHEN** the example stack demonstrates multi-VM usage
- **THEN** it SHALL include at least 2-3 VMs in the `vms` map
- **AND** SHALL show varied configurations (different memory sizes, names)
- **AND** SHALL use clear, descriptive VM identifiers as map keys
- **AND** SHALL include comments explaining each VM's purpose

### Requirement: Stack Proxmox VM Unit Configuration

The stack's proxmox_vm unit SHALL be configured to deploy all VMs defined in the locals block.

#### Scenario: Proxmox VM unit in stack

- **WHEN** the stack defines the proxmox_vm unit
- **THEN** it SHALL reference the unit source with Git URL or local path
- **AND** SHALL specify `path = "proxmox-vm"` for deployment location
- **AND** SHALL pass `values.vms = local.vms` to deploy all VMs
- **AND** SHALL pass `values.pool_id = local.pool_id` for pool assignment
- **AND** SHALL pass `values.pool_unit_path = "../proxmox-pool"` for dependency

#### Scenario: Proxmox pool unit in stack

- **WHEN** the stack defines the proxmox_pool unit
- **THEN** it SHALL be defined before the proxmox_vm unit
- **AND** SHALL create the pool that all VMs will join
- **AND** SHALL receive `values.pool_id = local.pool_id`

### Requirement: Stack Dynamic DNS Unit Generation

The stack SHALL generate one DNS unit per VM using dynamic blocks to register each VM's IP address in DNS.

#### Scenario: Dynamic DNS unit block

- **WHEN** DNS units are defined in the stack
- **THEN** the stack SHALL use `dynamic "unit"` block with `for_each = local.vms`
- **AND** each iteration SHALL create a separate DNS unit
- **AND** the iterator variable SHALL be named `unit` with `unit.key` and `unit.value`

#### Scenario: DNS unit path uniqueness

- **WHEN** each DNS unit is generated
- **THEN** it SHALL have a unique `path` attribute based on the VM identifier
- **AND** SHALL use pattern `path = "dns-${unit.key}"`
- **AND** this ensures each DNS unit deploys to a separate directory

#### Scenario: DNS unit source reference

- **WHEN** each DNS unit is defined
- **THEN** it SHALL reference the dns unit source (Git URL or local path)
- **AND** SHALL use the same `values.version` as other units
- **AND** SHALL include comment explaining Git URL pattern for external consumption

#### Scenario: DNS unit values configuration

- **WHEN** each DNS unit is configured
- **THEN** it SHALL receive values:
  - `zone`: DNS zone (e.g., "home.sflab.io.")
  - `name`: VM name from `unit.value.vm_name`
  - `dns_server`: DNS server address
  - `dns_port`: DNS server port
  - `key_name`: TSIG key name
  - `key_algorithm`: TSIG algorithm
  - `vm_unit_path`: Path to proxmox_vm unit (e.g., "../proxmox-vm")
  - `vm_identifier`: VM identifier (e.g., `unit.key`) to extract specific VM IP

#### Scenario: DNS dependency on specific VM

- **WHEN** DNS unit needs a specific VM's IP address
- **THEN** it SHALL reference the proxmox_vm unit via `vm_unit_path`
- **AND** SHALL use `vm_identifier` to select the specific VM from the `vms` output map
- **AND** the DNS unit SHALL extract the IP using `outputs.vms[vm_identifier].ipv4`

### Requirement: Stack Example Configuration

The stack example SHALL demonstrate real-world multi-VM deployment with clear, documented configuration.

#### Scenario: Example stack location

- **WHEN** the example stack is created
- **THEN** it SHALL be located in `examples/terragrunt/stacks/homelab-proxmox-vm/`
- **AND** SHALL contain `terragrunt.stack.hcl` file
- **AND** SHALL contain `units/` subdirectory with local unit wrappers

#### Scenario: Example VMs configuration

- **WHEN** the example stack is configured
- **THEN** it SHALL define at least 3 VMs with descriptive identifiers:
  - Example: "web01", "web02", "db01"
  - OR: "frontend", "backend", "database"
- **AND** SHALL show varied memory configurations (e.g., 4096 for web, 8192 for DB)
- **AND** SHALL include inline comments explaining each VM

#### Scenario: Example documentation

- **WHEN** the example stack is provided
- **THEN** it SHALL include comments at the top explaining:
  - Purpose of the stack (multi-VM deployment with DNS)
  - How to customize VMs (add/remove from map)
  - Required environment variables
  - How to deploy and verify

#### Scenario: Example unit wrappers

- **WHEN** example unit wrappers are created
- **THEN** they SHALL be in `examples/terragrunt/stacks/homelab-proxmox-vm/units/`
- **AND** SHALL include: `proxmox-pool/`, `proxmox-vm/`, `dns/`
- **AND** each SHALL use relative paths to modules (not Git URLs)
- **AND** SHALL demonstrate the local testing pattern
