# Implementation Tasks

## 1. Project Setup

- [ ] 1.1 Create `.providers/terraform-provider-homelab/` directory
- [ ] 1.2 Initialize Go module with `go mod init github.com/abes140377/terraform-provider-homelab`
- [ ] 1.3 Set Go version to 1.24.2 in `go.mod`
- [ ] 1.4 Add Terraform Plugin Framework dependency
- [ ] 1.5 Create `internal/provider/` directory structure

## 2. Provider Implementation

- [ ] 2.1 Create `main.go` with provider server setup
- [ ] 2.2 Implement provider type in `internal/provider/provider.go`
- [ ] 2.3 Implement `Metadata()` method to set provider type name to "homelab"
- [ ] 2.4 Implement `Schema()` method (empty schema - no provider-level config)
- [ ] 2.5 Implement `Configure()` method (no-op - no shared client needed)
- [ ] 2.6 Implement `DataSources()` method to register naming datasource
- [ ] 2.7 Implement `Resources()` method (return empty slice - no resources)

## 3. Naming Datasource Implementation

- [ ] 3.1 Create `internal/provider/naming_data_source.go`
- [ ] 3.2 Define datasource struct implementing `datasource.DataSource` interface
- [ ] 3.3 Implement `Metadata()` method to set datasource type name to "naming"
- [ ] 3.4 Define schema with required attributes: `env` (string) and `app` (string)
- [ ] 3.5 Define schema with computed attribute: `name` (string)
- [ ] 3.6 Implement `Read()` method to concatenate `env` and `app` with hyphen separator
- [ ] 3.7 Implement attribute validation for required fields

## 4. Build Tooling

- [ ] 4.1 Create `GNUmakefile` with targets: `install`, `generate`, `test`
- [ ] 4.2 Create `.goreleaser.yml` for future release automation
- [ ] 4.3 Add `.gitignore` entries for Go build artifacts and Terraform cache
- [ ] 4.4 Verify `go install` compiles provider successfully

## 5. Local Development Setup

- [ ] 5.1 Create example `.terraformrc` configuration snippet for dev overrides
- [ ] 5.2 Document the local installation path for the provider binary
- [ ] 5.3 Add README.md with setup and usage instructions

## 6. Testing and Verification

- [ ] 6.1 Create `examples/data-sources/naming/` directory
- [ ] 6.2 Write example Terraform configuration using the naming datasource
- [ ] 6.3 Install provider locally using `go install`
- [ ] 6.4 Configure `.terraformrc` dev overrides
- [ ] 6.5 Run `terraform init` in example directory
- [ ] 6.6 Run `terraform plan` to verify datasource returns expected output
- [ ] 6.7 Test with multiple env/app combinations (dev-web, prod-db, etc.)
- [ ] 6.8 Verify validation errors for missing required attributes

## 7. Documentation

- [ ] 7.1 Add provider overview documentation
- [ ] 7.2 Document datasource attributes and behavior
- [ ] 7.3 Document local development workflow
- [ ] 7.4 Add usage examples showing name generation
- [ ] 7.5 Document future roadmap (resources, functions, integration)

## 8. Code Quality

- [ ] 8.1 Run `go fmt` on all Go source files
- [ ] 8.2 Run `go vet` to check for common issues
- [ ] 8.3 Ensure all Go code follows standard Go conventions
- [ ] 8.4 Verify no hardcoded values or test credentials
- [ ] 8.5 Add appropriate Go comments for exported types and functions
