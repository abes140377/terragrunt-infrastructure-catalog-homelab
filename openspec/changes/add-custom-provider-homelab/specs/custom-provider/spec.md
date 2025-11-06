# Custom Provider Specification

## ADDED Requirements

### Requirement: Provider Implementation

The system SHALL provide a custom Terraform provider named `homelab` using the Terraform Plugin Framework that enables standardized resource naming for homelab infrastructure.

#### Scenario: Provider initialization

- **WHEN** Terraform initializes the `homelab` provider
- **THEN** the provider successfully registers with Terraform
- **AND** the provider metadata reports type name as `homelab`

#### Scenario: Provider configuration

- **WHEN** the provider is configured in a Terraform configuration
- **THEN** the provider accepts configuration without errors
- **AND** the provider is available for datasource operations

### Requirement: Naming Datasource

The system SHALL provide a datasource named `naming` that generates standardized names based on environment and application identifiers.

#### Scenario: Name generation with valid inputs

- **WHEN** the datasource is invoked with `env = "dev"` and `app = "web"`
- **THEN** the datasource returns a computed `name` attribute with value `"dev-web"`

#### Scenario: Name generation with production environment

- **WHEN** the datasource is invoked with `env = "prod"` and `app = "db"`
- **THEN** the datasource returns a computed `name` attribute with value `"prod-db"`

#### Scenario: Required attribute validation

- **WHEN** the datasource is invoked without `env` attribute
- **THEN** Terraform validation fails with a clear error message
- **AND** the error indicates that `env` is a required attribute

#### Scenario: Required attribute validation for app

- **WHEN** the datasource is invoked without `app` attribute
- **THEN** Terraform validation fails with a clear error message
- **AND** the error indicates that `app` is a required attribute

### Requirement: Project Structure

The system SHALL organize the custom provider code in a standard Go project structure compatible with Terraform provider development practices.

#### Scenario: Directory organization

- **WHEN** the provider codebase is examined
- **THEN** it contains `.providers/terraform-provider-homelab/` directory
- **AND** it contains `main.go` as the provider entry point
- **AND** it contains `internal/provider/` directory for provider logic
- **AND** it contains `go.mod` and `go.sum` for dependency management

#### Scenario: Provider package structure

- **WHEN** the provider implementation is examined
- **THEN** the `internal/provider/` directory contains provider implementation
- **AND** the `internal/provider/` directory contains datasource implementation
- **AND** the provider follows Terraform Plugin Framework conventions

### Requirement: Build and Installation

The system SHALL provide build tooling that enables local development and installation of the custom provider.

#### Scenario: Provider compilation

- **WHEN** `go install` is executed in the provider directory
- **THEN** the provider binary compiles without errors
- **AND** the binary is installed to the Go bin directory

#### Scenario: Local development configuration

- **WHEN** `.terraformrc` dev overrides are configured for the provider
- **THEN** Terraform uses the local provider build
- **AND** Terraform does not attempt to download the provider from the registry

#### Scenario: Build automation

- **WHEN** `make install` is executed
- **THEN** the provider is compiled and installed locally
- **AND** the installation succeeds without errors

### Requirement: Go Version Compatibility

The system SHALL use Go 1.24.2 for provider development, consistent with the project's existing Go version managed by mise.

#### Scenario: Go version declaration

- **WHEN** the provider's `go.mod` file is examined
- **THEN** it declares `go 1.24.2` as the Go version
- **AND** all dependencies are compatible with Go 1.24.2

#### Scenario: Build with project Go version

- **WHEN** the provider is built using the mise-managed Go toolchain
- **THEN** the build succeeds without version compatibility errors
- **AND** the resulting binary runs correctly

### Requirement: Minimal Implementation Scope

The system SHALL implement only the provider infrastructure and naming datasource, excluding resources and provider functions to maintain POC simplicity.

#### Scenario: Datasource-only implementation

- **WHEN** the provider implementation is examined
- **THEN** it contains exactly one datasource implementation
- **AND** it contains zero resource implementations
- **AND** it contains zero provider function implementations

#### Scenario: No infrastructure integration

- **WHEN** the provider is implemented
- **THEN** it is not referenced in any existing modules
- **AND** it is not referenced in any existing units
- **AND** it is not referenced in any existing stacks
- **AND** it exists solely for proof-of-concept validation

### Requirement: Terraform Plugin Framework Usage

The system SHALL implement the provider using the Terraform Plugin Framework (not the legacy SDK) to leverage modern provider development patterns.

#### Scenario: Framework dependency

- **WHEN** the provider's `go.mod` dependencies are examined
- **THEN** it includes `github.com/hashicorp/terraform-plugin-framework` dependency
- **AND** it does NOT include `github.com/hashicorp/terraform-plugin-sdk` dependency

#### Scenario: Provider interface implementation

- **WHEN** the provider type is examined
- **THEN** it implements the `provider.Provider` interface from the Plugin Framework
- **AND** it implements all required methods: Metadata, Schema, Configure, DataSources, Resources
