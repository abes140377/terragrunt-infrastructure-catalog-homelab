# Multi-VM Unit Capability

## MODIFIED Requirements

### Requirement: VM Unit Map Input Support

The proxmox-vm unit SHALL pass the VMs map from values to the module while supporting optional global pool assignment.

#### Scenario: VMs map pass-through

- **WHEN** the unit is configured
- **THEN** it SHALL accept `values.vms` as a map of VM configurations
- **AND** SHALL pass `values.vms` directly to the module's `vms` input
- **AND** SHALL use `try(values.vms, {})` to provide empty map default

#### Scenario: Global pool ID merging

- **WHEN** a global `values.pool_id` is provided at the unit level
- **THEN** the unit SHALL merge this pool_id into each VM configuration that doesn't have its own pool_id
- **AND** SHALL preserve per-VM pool_id values if specified
- **AND** SHALL use a local variable to compute the merged VMs map before passing to module

#### Scenario: Pool ID merge logic

- **WHEN** merging pool IDs
- **THEN** for each VM in `values.vms`:
  - IF the VM has its own `pool_id` specified, use that value
  - ELSE IF `values.pool_id` is provided and not empty, use that value
  - ELSE leave `pool_id` as empty string (no pool assignment)
- **AND** SHALL use HCL `for` expression with `merge()` to implement this logic

#### Scenario: Pool unit path dependency support

- **WHEN** `values.pool_unit_path` is provided
- **THEN** the unit SHALL create a dependency block on the proxmox-pool unit
- **AND** SHALL obtain the pool_id from `dependency.proxmox_pool.outputs.pool_id`
- **AND** SHALL use this pool_id as the global pool_id for merging

### Requirement: VM Unit Output Structure

The proxmox-vm unit SHALL expose the module's VMs map output for downstream dependencies.

#### Scenario: Unit outputs definition

- **WHEN** the unit outputs are defined
- **THEN** it SHALL have no explicit outputs block (rely on Terragrunt's automatic output passing)
- **AND** the module's `vms` output SHALL be available to dependent units as `dependency.<unit_name>.outputs.vms`

#### Scenario: Backwards compatibility output

- **WHEN** supporting potential single-VM legacy patterns
- **THEN** the module MAY include an `ipv4` output that extracts a single VM's IP
- **AND** this output SHALL use `try()` to handle both single and multi-VM cases
- **AND** this is optional and not required for the multi-VM pattern

### Requirement: VM Unit Configuration Pattern

The proxmox-vm unit SHALL maintain consistency with existing unit patterns while supporting the new multi-VM structure.

#### Scenario: Include blocks structure

- **WHEN** the unit is defined
- **THEN** it SHALL include the root configuration via `include "root"`
- **AND** SHALL include the Proxmox provider configuration via `include "provider_proxmox"`
- **AND** SHALL use Git URL source for external consumption: `git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/proxmox-vm?ref=${values.version}`

#### Scenario: Required values

- **WHEN** the unit is used
- **THEN** it SHALL require `values.vms` as a map of VM configurations
- **AND** SHALL optionally accept `values.pool_id` for global pool assignment
- **AND** SHALL optionally accept `values.pool_unit_path` for pool dependency
- **AND** SHALL optionally accept `values.version` for Git source reference

#### Scenario: Example unit wrapper

- **WHEN** an example unit wrapper is created
- **THEN** it SHALL be located in `examples/terragrunt/stacks/homelab-proxmox-vm/units/proxmox-vm/`
- **AND** SHALL use relative module path `../../../../../.././/modules/proxmox-vm`
- **AND** SHALL demonstrate dependency on proxmox-pool unit
- **AND** SHALL show the pool ID merging pattern in action
