# Implementation Tasks

## 1. DNS Module Implementation

- [x] 1.1 Create `modules/dns/main.tf` with `dns_a_record_set` resource
- [x] 1.2 Create `modules/dns/variables.tf` with required inputs (zone, name, addresses, ttl, dns_server, key_name, key_algorithm, key_secret)
- [x] 1.3 Create `modules/dns/outputs.tf` with record information outputs (fqdn, addresses)
- [x] 1.4 Create `modules/dns/versions.tf` with hashicorp/dns provider requirements (>= 3.4.0)
- [x] 1.5 Run `tofu fmt` on all DNS module files
- [x] 1.6 Validate module with `tofu init && tofu validate` in module directory

## 2. DNS Unit Implementation

- [x] 2.1 Create `units/dns/terragrunt.hcl` with Git URL source reference
- [x] 2.2 Configure unit to use `values` pattern (values.zone, values.name, values.addresses)
- [x] 2.3 Include `root.hcl` configuration
- [x] 2.4 Add provider configuration block for DNS provider in unit
- [x] 2.5 Run `tofu fmt` on unit terragrunt.hcl

## 3. Example Configuration

- [x] 3.1 Create `examples/terragrunt/units/dns/terragrunt.hcl` with relative path source
- [x] 3.2 Configure example with concrete values for local BIND9 server (192.168.1.13)
- [x] 3.3 Add `extra_arguments` block for passing dns_key_secret variable
- [x] 3.4 Add example DNS zone and record values in inputs block
- [x] 3.5 Run `tofu fmt` on example terragrunt.hcl

## 4. Documentation

- [x] 4.1 Update CLAUDE.md "Repository Overview" section with DNS management capability
- [x] 4.2 Add DNS module details to "Proxmox Resources" section (rename to "Infrastructure Resources")
- [x] 4.3 Document required environment variables (TF_VAR_dns_key_secret, BIND9 TSIG key setup)
- [x] 4.4 Add DNS provider configuration details to "Provider Configuration" section
- [x] 4.5 Add mise task for BIND9 TSIG key generation (optional)

## 5. Secrets Management

- [x] 5.1 Document TSIG key storage pattern in .creds.env.yaml
- [x] 5.2 Add example BIND9 named.conf configuration snippet to documentation
- [x] 5.3 Document how to generate TSIG key using `tsig-keygen` or `rndc-confgen`

## 6. Quality Checks

- [x] 6.1 Run pre-commit hooks on all new files
- [x] 6.2 Verify no hardcoded secrets (gitleaks check)
- [x] 6.3 Ensure all HCL files are formatted
- [x] 6.4 Validate module independently
- [x] 6.5 Test example configuration with mock outputs (terragrunt plan with BIND9 unavailable)

## 7. Integration Testing (Optional)

- [x] 7.1 Generate test TSIG key on BIND9 server
- [x] 7.2 Configure test DNS zone for homelab (e.g., home.sflab.io)
- [x] 7.3 Run terragrunt plan in example directory
- [x] 7.4 Run terragrunt apply to create test record
- [x] 7.5 Verify DNS record with dig/nslookup
- [x] 7.6 Run terragrunt destroy to clean up
