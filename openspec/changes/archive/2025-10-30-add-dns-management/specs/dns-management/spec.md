# DNS Management Capability

## ADDED Requirements

### Requirement: DNS Module Structure

The DNS module SHALL follow the standard three-layer architecture pattern used by existing modules (proxmox-lxc, proxmox-pool).

#### Scenario: Module file organization

- **WHEN** the DNS module is created
- **THEN** it SHALL contain `main.tf`, `variables.tf`, `outputs.tf`, and `versions.tf` files
- **AND** all files SHALL be formatted with `tofu fmt`

#### Scenario: Module naming convention

- **WHEN** the DNS module is referenced
- **THEN** it SHALL be named `dns` (lowercase, descriptive)
- **AND** located in `modules/dns/` directory

### Requirement: DNS Provider Configuration

The DNS module SHALL use the HashiCorp DNS provider (hashicorp/dns) for managing DNS records via RFC 2136 dynamic updates.

#### Scenario: Provider version requirements

- **WHEN** the module declares provider requirements
- **THEN** it SHALL specify `hashicorp/dns` as the provider source
- **AND** require version >= 3.4.0
- **AND** require OpenTofu >= 1.9.0

#### Scenario: BIND9 server connection

- **WHEN** the provider is configured
- **THEN** it SHALL support connecting to the BIND9 DNS server at 192.168.1.13
- **AND** use TSIG authentication with configurable key name, algorithm, and secret

### Requirement: DNS A Record Management

The DNS module SHALL provide the ability to create and manage DNS A records on the configured BIND9 server.

#### Scenario: A record creation

- **WHEN** a DNS A record is defined with zone, name, and IP addresses
- **THEN** the module SHALL create a `dns_a_record_set` resource
- **AND** support multiple IP addresses for the same record
- **AND** allow configurable TTL values

#### Scenario: Required input variables

- **WHEN** the module is invoked
- **THEN** it SHALL require the following variables:
  - `zone` (string): DNS zone name (e.g., "home.sflab.io.")
  - `name` (string): Record name within the zone
  - `addresses` (list(string)): List of IPv4 addresses
  - `dns_server` (string): DNS server address and port
  - `key_name` (string): TSIG key name for authentication
  - `key_algorithm` (string): TSIG key algorithm (e.g., "hmac-sha256")
  - `key_secret` (string, sensitive): TSIG key secret

#### Scenario: Optional input variables

- **WHEN** the module is invoked
- **THEN** it SHALL support optional variables:
  - `ttl` (number): Time-to-live in seconds (default: 300)

#### Scenario: Output values

- **WHEN** a DNS record is created
- **THEN** the module SHALL output:
  - `fqdn` (string): Fully qualified domain name of the record
  - `addresses` (list(string)): IP addresses assigned to the record

### Requirement: DNS Unit Configuration

The DNS unit SHALL wrap the DNS module following the Terragrunt unit pattern used by existing units.

#### Scenario: Unit source reference

- **WHEN** the unit is defined for external consumption
- **THEN** it SHALL use a Git URL source: `git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//modules/dns?ref=${values.version}`
- **AND** include a comment explaining the Git URL pattern

#### Scenario: Unit parameterization

- **WHEN** the unit is configured
- **THEN** it SHALL use the `values` pattern for inputs (values.zone, values.name, values.addresses)
- **AND** include `include "root"` block pointing to root.hcl

#### Scenario: Root configuration inclusion

- **WHEN** the unit is initialized
- **THEN** it SHALL include root.hcl for backend and provider configuration
- **AND** follow the same pattern as proxmox-lxc and proxmox-pool units

### Requirement: DNS Example Configuration

The catalog SHALL provide an example configuration demonstrating DNS module usage with concrete values.

#### Scenario: Example directory structure

- **WHEN** the example is created
- **THEN** it SHALL be located in `examples/terragrunt/units/dns/`
- **AND** contain a `terragrunt.hcl` file

#### Scenario: Example source path

- **WHEN** the example is defined
- **THEN** it SHALL use a relative path source: `../../../.././/modules/dns`
- **AND** include a comment explaining local development usage

#### Scenario: Example authentication

- **WHEN** the example is configured
- **THEN** it SHALL demonstrate passing the TSIG key secret via `extra_arguments`
- **AND** reference environment variable `TF_VAR_dns_key_secret`

#### Scenario: Example DNS server configuration

- **WHEN** the example is configured
- **THEN** it SHALL target the BIND9 server at 192.168.1.13:53
- **AND** use realistic example values for zone, name, and addresses

### Requirement: DNS Secrets Management

Sensitive DNS authentication credentials SHALL be managed securely following the project's SOPS encryption pattern.

#### Scenario: TSIG key storage

- **WHEN** TSIG credentials are stored
- **THEN** they SHALL be encrypted in `.creds.env.yaml` using SOPS
- **AND** accessed via environment variables (`TF_VAR_dns_key_secret`)

#### Scenario: No hardcoded secrets

- **WHEN** pre-commit hooks run
- **THEN** gitleaks SHALL NOT detect any hardcoded TSIG secrets in module or unit files
- **AND** all sensitive values SHALL be passed via variables or environment variables

### Requirement: DNS Documentation

The catalog documentation SHALL include comprehensive guidance for DNS management capabilities.

#### Scenario: CLAUDE.md updates

- **WHEN** the DNS module is added
- **THEN** CLAUDE.md SHALL document:
  - DNS module capabilities and resource types
  - Required environment variables for TSIG authentication
  - BIND9 server configuration requirements
  - Example usage patterns
