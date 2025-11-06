# Add Custom Terraform Provider - Homelab

## Why

The infrastructure catalog currently relies on external providers for all resource naming and conventions. As the homelab infrastructure grows, we need standardized naming patterns that follow consistent conventions across all resources (LXC containers, VMs, pools, DNS records). A custom Terraform provider with a naming datasource will enable centralized naming logic, enforce naming standards, and reduce duplication across modules and units.

## What Changes

- Add a new custom Terraform provider named `homelab` at `providers/terraform-provider-homelab/`
- Implement a minimal provider using the Terraform Plugin Framework (Go 1.24.2)
- Create a single datasource `naming_data_source` that:
  - Accepts `env` (string, required) and `app` (string, required) as input attributes
  - Returns a computed `name` attribute with format `<env>-<app>`
- Follow the structure from hashicorp/terraform-provider-scaffolding-framework
- Include basic Go project structure: `main.go`, `go.mod`, `internal/provider/` directory
- Configure local development setup with `.terraformrc` dev overrides

**Note**: This is a proof-of-concept implementation. No resources or provider functions are included. The provider will NOT be integrated into existing Terraform code yet.

## Impact

- **Affected specs**: New capability `custom-provider`
- **Affected code**: New directory `providers/terraform-provider-homelab/` with Go source code
- **No existing modules/units/stacks affected**: Provider is implemented but not yet consumed
- **Dependencies**: Requires Go 1.24.2 (already managed via mise.toml)
- **Testing**: Local provider installation via `go install` and manual verification with Terraform configuration
- **Future work**: Integration into modules/units after POC validation
