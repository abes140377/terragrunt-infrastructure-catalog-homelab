# Multi-VM DNS Integration Capability

## MODIFIED Requirements

### Requirement: DNS Unit VM Identifier Support

The DNS unit SHALL support extracting a specific VM's IP address from the multi-VM output map using a VM identifier.

#### Scenario: VM identifier value

- **WHEN** the DNS unit is configured for multi-VM integration
- **THEN** it SHALL accept `values.vm_identifier` as a string
- **AND** this identifier SHALL match a key in the proxmox_vm unit's `vms` output map
- **AND** the identifier SHALL be optional (for backwards compatibility with single-VM pattern)

#### Scenario: Multi-VM dependency mock outputs

- **WHEN** the DNS unit declares a dependency on a compute unit (VM or LXC)
- **THEN** it SHALL define mock_outputs that include both:
  - `vms`: Map structure for multi-VM pattern
  - `ipv4`: Single string for backwards compatibility
- **AND** the mock `vms` map SHALL contain at least one VM entry with `ipv4` field

#### Scenario: Specific VM IP extraction

- **WHEN** the DNS unit needs to extract a specific VM's IP
- **THEN** it SHALL use a local variable to compute the IP address
- **AND** SHALL use pattern: `dependency.compute.outputs.vms[values.vm_identifier].ipv4`
- **AND** SHALL use `try()` to handle cases where:
  - `vm_identifier` is not provided (fall back to single-VM pattern)
  - The identifier doesn't exist in the map
  - The `vms` output doesn't exist (backwards compatibility)

#### Scenario: IP extraction fallback logic

- **WHEN** extracting VM IP address
- **THEN** the DNS unit SHALL attempt in order:
  1. Multi-VM pattern: `dependency.compute.outputs.vms[values.vm_identifier].ipv4`
  2. Single-VM pattern: `dependency.compute.outputs.ipv4`
  3. Direct addresses: `values.addresses`
  4. Empty list: `[]`
- **AND** SHALL use nested `try()` calls to implement this fallback chain

### Requirement: DNS Unit Backwards Compatibility

The DNS unit SHALL remain compatible with existing single-VM and LXC patterns while supporting the new multi-VM pattern.

#### Scenario: Single-VM dependency compatibility

- **WHEN** the DNS unit is used with a single-VM proxmox-vm unit (legacy)
- **THEN** it SHALL successfully extract the IP from `dependency.compute.outputs.ipv4`
- **AND** SHALL NOT require `values.vm_identifier` to be set
- **AND** SHALL work exactly as it did before multi-VM support

#### Scenario: LXC container compatibility

- **WHEN** the DNS unit is used with an LXC container unit
- **THEN** it SHALL continue to work using `dependency.compute.outputs.ipv4`
- **AND** SHALL NOT be affected by multi-VM changes
- **AND** SHALL use `values.lxc_unit_path` as before

#### Scenario: Direct addresses compatibility

- **WHEN** the DNS unit is used with direct `values.addresses` (no dependency)
- **THEN** it SHALL continue to accept and use the addresses list directly
- **AND** SHALL NOT require a compute dependency
- **AND** SHALL work for manual DNS record management

### Requirement: DNS Unit Input Validation

The DNS unit SHALL validate inputs to provide clear error messages when misconfigured for multi-VM usage.

#### Scenario: Missing VM identifier error

- **WHEN** `vm_identifier` is required but not provided
- **THEN** the DNS unit SHALL fail with a clear error message
- **AND** the error SHALL explain that `vm_identifier` is required for multi-VM pattern
- **AND** SHALL suggest checking the VM identifier exists in the VMs map

#### Scenario: Null IP address validation

- **WHEN** the extracted IP address is null (VM IP not available)
- **THEN** the DNS unit SHALL provide a clear error message
- **AND** the error SHALL indicate the VM's QEMU guest agent may not be running
- **AND** SHALL prevent creating DNS records with null addresses

#### Scenario: VM identifier not found error

- **WHEN** `vm_identifier` doesn't exist in the `vms` output map
- **THEN** the dependency output access SHALL fail with a key error
- **AND** Terraform SHALL provide an error indicating the key doesn't exist
- **AND** the error context SHALL help user identify the invalid identifier

### Requirement: DNS Unit Documentation

The DNS unit SHALL document the multi-VM usage pattern and the vm_identifier parameter.

#### Scenario: Terragrunt.hcl inline documentation

- **WHEN** the DNS unit terragrunt.hcl is viewed
- **THEN** it SHALL include comments explaining:
  - How to use with single VM (legacy pattern)
  - How to use with multiple VMs (vm_identifier required)
  - The fallback logic for IP extraction
- **AND** SHALL provide examples of each usage pattern

#### Scenario: Values parameter documentation

- **WHEN** values are referenced in the DNS unit
- **THEN** it SHALL include comments documenting:
  - `vm_unit_path`: Path to VM unit for dependency
  - `lxc_unit_path`: Path to LXC unit for dependency
  - `vm_identifier`: Which VM to get IP from in multi-VM scenarios
  - `addresses`: Direct IP addresses (bypasses dependencies)

### Requirement: DNS Provider Configuration Compatibility

The DNS unit's provider generation SHALL remain unchanged to ensure compatibility with both single and multi-VM patterns.

#### Scenario: Provider generation block

- **WHEN** the DNS provider is generated
- **THEN** it SHALL use the same `generate "provider"` block as before
- **AND** SHALL configure DNS server, port, TSIG key name and algorithm from values
- **AND** SHALL accept `var.dns_key_secret` from environment variable
- **AND** SHALL NOT require changes for multi-VM support

#### Scenario: DNS module interface

- **WHEN** the DNS unit calls the DNS module
- **THEN** it SHALL pass inputs exactly as before:
  - `zone`: DNS zone name
  - `name`: DNS record name
  - `addresses`: List of IP addresses (single item for one VM)
  - `ttl`: Time-to-live value
- **AND** the DNS module SHALL NOT require changes for multi-VM support

#### Scenario: Multiple DNS records pattern

- **WHEN** multiple VMs need DNS records
- **THEN** multiple DNS unit instances SHALL be created (one per VM)
- **AND** each unit SHALL call the DNS module independently
- **AND** each unit SHALL create a single DNS A record
- **AND** this pattern leverages Terragrunt's unit composition, not DNS module changes
