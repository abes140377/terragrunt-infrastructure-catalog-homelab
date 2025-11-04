# Multi-VM Module Capability

## MODIFIED Requirements

### Requirement: VM Module Map-Based Input

The proxmox-vm module SHALL accept a map of VM configurations instead of single VM parameters to enable creating multiple VMs from one module invocation.

#### Scenario: VM map variable definition

- **WHEN** the module is configured
- **THEN** it SHALL define a `vms` variable of type `map(object({...}))`
- **AND** the map key SHALL be a unique VM identifier string
- **AND** the map value SHALL be an object containing:
  - `vm_name` (string, required): The name of the VM in Proxmox
  - `memory` (number, optional, default 2048): Memory in MB
  - `cores` (number, optional, default 2): Number of CPU cores
  - `pool_id` (string, optional, default ""): Proxmox pool ID
- **AND** the `vms` variable SHALL have a default value of empty map `{}`

#### Scenario: For-each resource iteration

- **WHEN** VMs are created
- **THEN** the `proxmox_virtual_environment_vm` resource SHALL use `for_each = var.vms`
- **AND** the resource identifier SHALL be `proxmox_virtual_environment_vm.this["<vm_identifier>"]`
- **AND** each VM SHALL use `each.value.<property>` to access configuration values

#### Scenario: VM resource configuration from map

- **WHEN** each VM is configured
- **THEN** it SHALL use `each.value.vm_name` for the VM name
- **AND** SHALL use `each.value.memory` for memory configuration
- **AND** SHALL use `each.value.cores` for CPU core configuration
- **AND** SHALL use `each.value.pool_id` for pool assignment (if not empty)
- **AND** SHALL continue to clone from template VM ID 9002 on node pve1
- **AND** SHALL enable QEMU guest agent for IP retrieval
- **AND** SHALL use DHCP for IPv4 configuration

#### Scenario: Empty VMs map handling

- **WHEN** the `vms` variable is an empty map `{}`
- **THEN** the module SHALL create zero VM resources
- **AND** the module SHALL execute successfully without errors
- **AND** the outputs SHALL be empty maps

### Requirement: VM Module Map-Based Output

The proxmox-vm module SHALL output a map of VM attributes keyed by VM identifier to enable downstream units to access specific VM information.

#### Scenario: VMs output structure

- **WHEN** VMs are created
- **THEN** the module SHALL output a `vms` map
- **AND** each key SHALL be the VM identifier from the input map
- **AND** each value SHALL be an object containing:
  - `id` (string): Proxmox VM resource ID
  - `name` (string): VM name in Proxmox
  - `ipv4` (string or null): VM IPv4 address from QEMU guest agent

#### Scenario: VMs output iteration

- **WHEN** the `vms` output is defined
- **THEN** it SHALL use `for` expression to iterate over all created VMs
- **AND** SHALL use `try()` to handle cases where IPv4 is not available
- **AND** SHALL set `ipv4 = null` when QEMU guest agent doesn't report an address

#### Scenario: Empty VMs output

- **WHEN** no VMs are created (empty input map)
- **THEN** the `vms` output SHALL be an empty map `{}`
- **AND** the output SHALL be valid and not cause errors

### Requirement: VM Module Property Extensibility

The proxmox-vm module SHALL be designed to easily accept additional VM properties without breaking existing configurations.

#### Scenario: Optional property defaults

- **WHEN** a new VM property is added to the module
- **THEN** it SHALL use Terraform's `optional()` type constraint with a default value
- **AND** existing configurations that don't specify the property SHALL use the default
- **AND** the module SHALL remain backwards compatible with configurations missing the new property

#### Scenario: Adding CPU cores property

- **WHEN** CPU cores configuration is added
- **THEN** it SHALL be defined as `cores = optional(number, 2)`
- **AND** SHALL default to 2 cores if not specified
- **AND** SHALL be applied in the VM resource configuration

#### Scenario: Future property additions

- **WHEN** additional properties are needed (e.g., disk_gb, boot_order, tags)
- **THEN** they SHALL follow the same pattern:
  - Add to `vms` object type with `optional(type, default)`
  - Use in resource with `each.value.property_name`
  - Document in variable description
- **AND** SHALL NOT require changes to existing VM configurations
