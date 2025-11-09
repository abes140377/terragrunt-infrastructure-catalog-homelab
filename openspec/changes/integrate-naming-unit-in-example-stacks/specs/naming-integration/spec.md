# Spec: Naming Integration in Example Stacks

## ADDED Requirements

### Requirement: Naming Unit Integration in VM Example Stack

The `homelab-proxmox-vm` example stack SHALL integrate the naming unit to demonstrate standardized resource naming.

#### Scenario: Naming unit configuration in VM stack

**Given** the VM example stack at `examples/terragrunt/stacks/homelab-proxmox-vm/terragrunt.stack.hcl`
**When** the stack is configured
**Then** it must include a naming unit with:
- Source: `../../../../units/naming`
- Path: `naming`
- Environment value: `staging`
- Application value: `vm1`

#### Scenario: VM units consume naming unit output

**Given** the naming unit generates a name output
**When** VM units are configured
**Then** they must use the naming unit's output for `vm_name` instead of hardcoded values
**And** the naming dependency must be established through the compute path or similar mechanism

#### Scenario: DNS units consume naming unit output

**Given** the naming unit generates a name output
**When** DNS units are configured
**Then** they must use the naming unit's output for the DNS record `name` field
**And** ensure DNS records match the generated VM names

#### Scenario: VM stack name generation pattern

**Given** environment is `staging` and application is `vm1`
**When** the naming unit generates names
**Then** the base name must be `staging-vm1`
**And** individual VMs must append their instance identifier (e.g., `-1`, `-2`)

### Requirement: Naming Unit Integration in Container Example Stack

The `homelab-proxmox-container` example stack SHALL integrate the naming unit to demonstrate standardized resource naming.

#### Scenario: Naming unit configuration in container stack

**Given** the container example stack at `examples/terragrunt/stacks/homelab-proxmox-container/terragrunt.stack.hcl`
**When** the stack is configured
**Then** it must include a naming unit with:
- Source: `../../../../units/naming`
- Path: `naming`
- Environment value: `staging`
- Application value: `container1`

#### Scenario: LXC units consume naming unit output

**Given** the naming unit generates a name output
**When** LXC units are configured
**Then** they must use the naming unit's output for `hostname` instead of hardcoded values
**And** the naming dependency must be established through the compute path or similar mechanism

#### Scenario: DNS units consume naming unit output

**Given** the naming unit generates a name output
**When** DNS units are configured
**Then** they must use the naming unit's output for the DNS record `name` field
**And** ensure DNS records match the generated container names

#### Scenario: Container stack name generation pattern

**Given** environment is `staging` and application is `container1`
**When** the naming unit generates names
**Then** the base name must be `staging-container1`
**And** individual containers must append their instance identifier (e.g., `-1`, `-2`)

### Requirement: Stack Configuration Backward Compatibility

The example stacks SHALL maintain their existing structure while adding naming integration.

#### Scenario: Existing unit configuration preservation

**Given** both example stacks have existing unit configurations
**When** naming units are added
**Then** all existing units (VM, LXC, DNS) must remain functional
**And** only the name/hostname value source must change

#### Scenario: Local variable usage

**Given** stacks use locals for configuration
**When** naming integration is added
**Then** stacks may use locals to reference naming unit outputs
**Or** reference naming unit outputs directly in unit values blocks

#### Scenario: No module or unit changes

**Given** the naming unit exists at `units/naming/`
**When** example stacks integrate naming
**Then** no changes to the naming unit itself are required
**And** no changes to compute modules (VM, LXC) are required
**And** no changes to the DNS module are required
