# Implementation Tasks

## 1. Project Setup

- [x] 1.1 Create `./providers/terraform-provider-homelab/` directory
- [x] 1.2 Initialize Go module with `go mod init github.com/sflab-io/terraform-provider-homelab`
- [x] 1.3 Set Go version to 1.24.2 in `go.mod`
- [x] 1.4 Add Terraform Plugin Framework dependency
- [x] 1.5 Create `internal/provider/` directory structure

## 2. Provider Implementation

- [x] 2.1 Create `main.go` with provider server setup
- [x] 2.2 Implement provider type in `internal/provider/provider.go`
- [x] 2.3 Implement `Metadata()` method to set provider type name to "homelab"
- [x] 2.4 Implement `Schema()` method (empty schema - no provider-level config)
- [x] 2.5 Implement `Configure()` method (no-op - no shared client needed)
- [x] 2.6 Implement `DataSources()` method to register naming datasource
- [x] 2.7 Implement `Resources()` method (return empty slice - no resources)

## 3. Naming Datasource Implementation

- [x] 3.1 Create `internal/provider/naming_data_source.go`
- [x] 3.2 Define datasource struct implementing `datasource.DataSource` interface
- [x] 3.3 Implement `Metadata()` method to set datasource type name to "naming"
- [x] 3.4 Define schema with required attributes: `env` (string) and `app` (string)
- [x] 3.5 Define schema with computed attribute: `name` (string)
- [x] 3.6 Implement `Read()` method to concatenate `env` and `app` with hyphen separator
- [x] 3.7 Implement attribute validation for required fields

## 4. Build Tooling

- [x] 4.1 Create `.goreleaser.yml` for future release automation
- [x] 4.2 Add `.gitignore` entries for Go build artifacts and Terraform cache
- [x] 4.3 Verify `go install` compiles provider successfully

## 5. Local Development Setup

- [x] 5.1 Create example `.terraformrc` configuration snippet for dev overrides
- [x] 5.2 Document the local installation path for the provider binary
- [x] 5.3 Add README.md with setup and usage instructions

## 6. Testing and Verification

- [x] 6.1 Create `examples/data-sources/naming/` directory
- [x] 6.2 Write example Terraform configuration using the naming datasource
- [x] 6.3 Install provider locally using `go install`
- [x] 6.4 Configure `.terraformrc` dev overrides
- [x] 6.5 Run `terraform init` in example directory
- [x] 6.6 Run `terraform plan` to verify datasource returns expected output
- [x] 6.7 Test with multiple env/app combinations (dev-web, prod-db, etc.)
- [x] 6.8 Verify validation errors for missing required attributes

## 7. Documentation

- [x] 7.1 Add provider overview documentation
- [x] 7.2 Document datasource attributes and behavior
- [x] 7.3 Document local development workflow
- [x] 7.4 Add usage examples showing name generation
- [x] 7.5 Document future roadmap (resources, functions, integration)

## 8. Code Quality

- [x] 8.1 Run `go fmt` on all Go source files
- [x] 8.2 Run `go vet` to check for common issues
- [x] 8.3 Ensure all Go code follows standard Go conventions
- [x] 8.4 Verify no hardcoded values or test credentials
- [x] 8.5 Add appropriate Go comments for exported types and functions
