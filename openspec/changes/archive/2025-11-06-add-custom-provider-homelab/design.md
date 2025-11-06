# Design Document: Custom Terraform Provider - Homelab

## Context

The terragrunt-infrastructure-catalog-homelab repository currently uses external providers (bpg/proxmox, hashicorp/dns) for all infrastructure operations. As the catalog grows, we need consistent naming conventions across LXC containers, VMs, resource pools, and DNS records. Rather than embedding naming logic in each module, we want a centralized approach that can evolve independently.

A custom Terraform provider offers:
- **Centralized naming logic**: Single source of truth for naming patterns
- **Type safety**: Terraform validates inputs at plan time
- **Extensibility**: Easy to add more datasources, resources, or functions later
- **Reusability**: Can be used across all modules and units

**Stakeholders**: Infrastructure engineers managing homelab resources, future contributors to the catalog.

**Constraints**:
- Must use Go 1.24.2 (already managed by mise)
- Must follow Terraform Plugin Framework (modern approach)
- Must not disrupt existing infrastructure code
- Must be installable locally without registry publication (POC phase)

## Goals / Non-Goals

**Goals:**
- Implement a minimal, working Terraform provider using the Plugin Framework
- Provide a single datasource (`naming`) that generates standardized names
- Demonstrate local provider installation and usage workflow
- Establish foundation for future provider enhancements

**Non-Goals:**
- Publishing provider to Terraform Registry (future work)
- Implementing resources or provider functions (future work)
- Integrating provider into existing modules/units/stacks (future work)
- Complex validation logic beyond required attribute checks (future work)
- Automated testing framework (future work)

## Decisions

### Decision: Use Terraform Plugin Framework (not SDK)

**Why**: The Plugin Framework is the modern, recommended approach for new providers. It offers better type safety, clearer APIs, and improved performance over the legacy SDK v2.

**Alternatives considered**:
- **Plugin SDK v2**: Legacy approach, still supported but not recommended for new providers
- **Plugin Framework**: Modern approach with better developer experience and future-proof

**Chosen**: Plugin Framework

### Decision: Minimal Datasource Implementation

**Why**: For POC phase, we want the simplest possible implementation to validate the approach. A datasource that concatenates two strings is sufficient to prove the concept without complexity.

**Alternatives considered**:
- **Complex naming logic**: Add prefixes, suffixes, validation rules, character limits
- **Multiple datasources**: Implement separate datasources for containers, VMs, pools
- **Simple concatenation**: Just `<env>-<app>`

**Chosen**: Simple concatenation - complexity can be added later based on real-world needs

### Decision: Monorepo Placement in `./providers/`

**Why**: Keeping the provider in the same repository as the infrastructure catalog makes development easier during POC phase and keeps related code together. The `./providers/` directory clearly indicates custom/local providers vs external ones.

**Alternatives considered**:
- **Separate repository**: More standard for published providers, but adds overhead for POC
- **Monorepo approach**: Simpler for development, easier to iterate
- **Location choices**: `./providers/`, `tools/providers/`

**Chosen**: Monorepo in `./providers/` directory - the dot prefix indicates it's tooling/infrastructure

### Decision: Local Installation Only (No Registry)

**Why**: Publishing to the Terraform Registry requires versioning, documentation, automated tests, and ongoing maintenance. For POC, local installation via `go install` and `.terraformrc` dev overrides is sufficient.

**Alternatives considered**:
- **Terraform Registry**: Standard distribution, but overkill for POC
- **GitHub releases**: Simpler than registry, but still requires release automation
- **Local installation**: Simplest for POC, can publish later if valuable

**Chosen**: Local installation only

### Decision: Go Module Path

**Why**: Using `github.com/abes140377/terraform-provider-homelab` as the module path follows Go conventions and aligns with the repository owner. This makes the eventual transition to a separate repository easier if needed.

**Module path**: `github.com/abes140377/terraform-provider-homelab`

### Decision: Provider Name "homelab"

**Why**: The provider name should reflect its purpose (homelab infrastructure) and be concise. Users will reference it as `provider "homelab" {}` in Terraform configs.

**Alternatives considered**:
- `sflab`: Too specific to current environment
- `homelab`: Generic, describes the use case
- `infrastructure`: Too generic

**Chosen**: `homelab`

### Decision: Datasource Name "naming"

**Why**: The datasource should be descriptive but concise. Users will reference it as `data "homelab_naming" "example" {}`.

**Alternatives considered**:
- `naming_convention`: Too verbose
- `name_generator`: Awkward phrasing
- `naming`: Clear and concise
- `name`: Too generic

**Chosen**: `naming` (results in `homelab_naming` datasource type)

## Architecture

### Provider Structure

```
./providers/terraform-provider-homelab/
├── main.go                          # Provider server entry point
├── go.mod                           # Go module definition
├── go.sum                           # Dependency checksums
├── .goreleaser.yml                  # Release configuration (future)
├── .gitignore                       # Go and Terraform artifacts
├── README.md                        # Setup and usage docs
├── internal/
│   └── provider/
│       ├── provider.go              # Provider implementation
│       └── naming_data_source.go    # Naming datasource implementation
└── examples/
    └── data-sources/
        └── naming/
            └── main.tf              # Usage example
```

### Component Responsibilities

**main.go**:
- Initializes provider server
- Listens for Terraform requests via Plugin Framework
- Delegates to provider implementation

**internal/provider/provider.go**:
- Implements `provider.Provider` interface
- Registers available datasources (currently just `naming`)
- Provides provider metadata and schema

**internal/provider/naming_data_source.go**:
- Implements `datasource.DataSource` interface
- Defines schema with `env`, `app` (required), and `name` (computed)
- Implements `Read()` to concatenate inputs into standardized name

### Data Flow

1. User writes Terraform config with `data "homelab_naming" "example" { env = "dev"; app = "web" }`
2. Terraform invokes provider's `DataSources()` to discover available datasources
3. Terraform invokes datasource's `Read()` method with user-provided attributes
4. Datasource validates required attributes (`env`, `app`)
5. Datasource computes `name = "<env>-<app>"` (e.g., "dev-web")
6. Terraform makes computed value available to other resources

### Local Development Workflow

1. Developer runs `go install` in `./providers/terraform-provider-homelab/`
2. Binary installed to `$GOPATH/bin/terraform-provider-homelab`
3. Developer configures `.terraformrc` with dev overrides:
```hcl
  provider_installation {
    dev_overrides {
      "registry.terraform.io/abes140377/homelab" = "/path/to/go/bin"
    }
    direct {}
  }
```
4. Terraform uses local binary instead of attempting registry download
5. Developer can iterate on provider code and recompile as needed

## Risks / Trade-offs

### Risk: Go Version Compatibility

**Risk**: Provider requires Go 1.24.2, but developers might have different Go versions installed.

**Mitigation**:
- The project already uses mise to manage Go 1.24.2
- Documentation will emphasize using mise-managed Go
- Go 1.24.2 is recent and widely compatible

### Risk: Plugin Framework Learning Curve

**Risk**: Team members unfamiliar with Terraform provider development might struggle with Plugin Framework concepts.

**Mitigation**:
- Start with minimal implementation (one datasource)
- Include extensive inline comments in code
- Provide working examples in repository
- Reference official HashiCorp tutorials in documentation

### Risk: Local Installation Friction

**Risk**: Developers might struggle with `.terraformrc` dev overrides and local binary paths.

**Mitigation**:
- Provide clear documentation with exact commands
- Include example `.terraformrc` configuration
- Document common troubleshooting steps
- Consider adding a mise task to automate installation

### Trade-off: Monorepo vs Separate Repository

**Trade-off**: Keeping provider in main repository is convenient but less standard.

**Rationale**:
- **Pro**: Easier to iterate during POC phase
- **Pro**: Co-located with infrastructure code that will eventually use it
- **Con**: Non-standard for published providers
- **Con**: Complicates dependency management if provider needs to import catalog code

**Decision**: Accept monorepo approach for POC, plan to extract if provider reaches maturity.

### Trade-off: Simple String Concatenation vs Rich Validation

**Trade-off**: Current design just concatenates strings without validation.

**Rationale**:
- **Pro**: Simplest possible implementation for POC
- **Pro**: Easy to understand and test
- **Con**: No validation of env values (e.g., typo "dve" instead of "dev")
- **Con**: No enforcement of character limits or allowed characters

**Decision**: Start simple, add validation in future iterations based on real-world pain points.

## Migration Plan

N/A - This is a new capability with no existing code to migrate.

## Open Questions

### Q: Should the provider support additional attributes in the future?

**Context**: The naming datasource currently only accepts `env` and `app`. Future needs might include:
- Resource type (container, vm, pool)
- Geographic location or availability zone
- Project or team identifier
- Numeric suffix for uniqueness

**Decision Needed**: Wait for real-world usage patterns before adding complexity.

**Status**: Deferred to future iteration

---

### Q: Should we add validation for allowed environment names?

**Context**: Currently, any string is accepted for `env`. We might want to restrict to known environments (dev, staging, prod).

**Options**:
1. No validation (current approach)
2. Warning for non-standard environments
3. Hard error for non-standard environments

**Decision Needed**: Determine if validation adds value or just friction.

**Status**: Deferred to future iteration

---

### Q: How should we handle provider versioning?

**Context**: For local development, versioning doesn't matter. If we publish to registry, we need semantic versioning.

**Current Approach**: No version management during POC phase

**Future Consideration**: Adopt semantic versioning before registry publication

**Status**: Out of scope for POC
