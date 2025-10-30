# stack-dns-integration Specification

## Purpose
TBD - created by archiving change integrate-dns-into-stack. Update Purpose after archive.
## Requirements
### Requirement: DNS Unit Integration in Proxmox Container Stack

The `homelab-proxmox-container` stack SHALL integrate the DNS unit to automatically register LXC container IP addresses in DNS after container creation.

#### Scenario: Production stack DNS unit configuration

- **WHEN** the production stack at `stacks/homelab-proxmox-container/terragrunt.stack.hcl` is defined
- **THEN** it SHALL include a DNS unit with Git URL source `git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${values.version}`
- **AND** the DNS unit SHALL have a `path` attribute set to `dns`
- **AND** the DNS unit SHALL receive values for: zone, name, addresses, dns_server, key_name, key_algorithm, key_secret

#### Scenario: DNS record name from container hostname

- **WHEN** the DNS unit is configured in the stack
- **THEN** the DNS record name SHALL be derived from `values.hostname` (the LXC container hostname)
- **AND** the DNS zone SHALL be `home.sflab.io.`
- **AND** the fully qualified domain name SHALL be `${values.hostname}.home.sflab.io`

#### Scenario: DNS addresses from container IP

- **WHEN** the DNS unit is configured in the stack
- **THEN** the DNS record addresses SHALL reference the LXC container's IP address
- **AND** the IP address SHALL be obtained via the values pattern (not dependency blocks in production stacks)
- **AND** the addresses SHALL be passed as a list with the container's IPv4 address

#### Scenario: DNS server configuration

- **WHEN** the DNS unit is configured
- **THEN** it SHALL target the BIND9 DNS server at `192.168.1.13`
- **AND** use port `53`
- **AND** use TSIG authentication with key name `ddnskey`
- **AND** use TSIG algorithm `hmac-sha256`

#### Scenario: DNS credentials via environment variable

- **WHEN** the DNS unit requires TSIG key secret
- **THEN** it SHALL be passed via `TF_VAR_dns_key_secret` environment variable
- **AND** this SHALL be consistent with standalone DNS unit usage
- **AND** the secret SHALL NOT be hardcoded in any stack or unit file

#### Scenario: Execution ordering

- **WHEN** the stack is applied
- **THEN** the DNS unit SHALL execute after the `proxmox_lxc` unit completes
- **AND** this ordering SHALL be enforced through value dependencies (DNS unit depends on container IP)
- **AND** the DNS record SHALL be created only after the container has a valid IP address

### Requirement: Example Stack DNS Integration

The example stack SHALL provide a testable implementation of DNS integration with local unit wrappers.

#### Scenario: DNS unit wrapper creation

- **WHEN** the example stack is created
- **THEN** it SHALL include a DNS unit wrapper at `examples/terragrunt/stacks/homelab-proxmox-container/units/dns/`
- **AND** the wrapper SHALL contain a `terragrunt.hcl` file
- **AND** the wrapper SHALL use relative module path `../../../../../.././/modules/dns`

#### Scenario: DNS provider generation in unit wrapper

- **WHEN** the DNS unit wrapper is defined
- **THEN** it SHALL include a `generate "provider"` block for the DNS provider
- **AND** the generated provider SHALL configure server address from DNS server input
- **AND** the generated provider SHALL configure TSIG authentication from key inputs

#### Scenario: DNS credentials passing in unit wrapper

- **WHEN** the DNS unit wrapper is configured
- **THEN** it SHALL use `extra_arguments` to pass `dns_key_secret` variable
- **AND** the extra_arguments SHALL reference environment variable `TF_VAR_dns_key_secret`
- **AND** the extra_arguments SHALL apply to `apply`, `plan`, and `destroy` commands

#### Scenario: Example stack DNS unit configuration

- **WHEN** the example stack at `examples/terragrunt/stacks/homelab-proxmox-container/terragrunt.stack.hcl` is defined
- **THEN** it SHALL include a DNS unit with local source path `./units/dns`
- **AND** the DNS unit SHALL have a `path` attribute set to `dns`
- **AND** the DNS unit SHALL use `local.*` references for values (e.g., `local.hostname`)

#### Scenario: Dependency block in example DNS unit wrapper

- **WHEN** the DNS unit wrapper needs the LXC container IP
- **THEN** it SHALL declare a `dependency` block referencing the proxmox_lxc unit
- **AND** the dependency config_path SHALL point to `../proxmox-lxc`
- **AND** the dependency SHALL provide `mock_outputs` with an example IP address
- **AND** the container IP SHALL be obtained via `dependency.proxmox_lxc.outputs.ipv4`

### Requirement: DNS Stack Documentation

The CLAUDE.md documentation SHALL provide comprehensive guidance for using DNS integration in stacks.

#### Scenario: DNS stack integration examples

- **WHEN** documentation describes stack usage
- **THEN** it SHALL include an example of the homelab-proxmox-container stack with DNS integration
- **AND** show both production stack configuration (Git URLs) and example stack configuration (local paths)
- **AND** explain the difference between production and example stack patterns

#### Scenario: DNS environment variable documentation

- **WHEN** documentation describes DNS stack requirements
- **THEN** it SHALL document the `TF_VAR_dns_key_secret` environment variable
- **AND** explain how to set it before running stack commands
- **AND** reference the SOPS-encrypted `.creds.env.yaml` file for secret storage

#### Scenario: DNS verification instructions

- **WHEN** documentation describes DNS stack validation
- **THEN** it SHALL provide commands to verify DNS name resolution (e.g., `dig` or `nslookup`)
- **AND** show expected output for successful DNS registration
- **AND** include troubleshooting steps if name resolution fails

#### Scenario: Stack dependency ordering documentation

- **WHEN** documentation describes DNS integration patterns
- **THEN** it SHALL explain how execution ordering is enforced through value dependencies
- **AND** clarify that production stacks use values pattern while example stacks can use dependency blocks
- **AND** document the difference in approaches and when to use each
