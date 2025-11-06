# Terraform Provider: Homelab

A custom Terraform/OpenTofu provider for standardized resource naming in homelab infrastructure environments.

## Overview

The Homelab provider enables consistent naming conventions across all infrastructure resources (LXC containers, VMs, resource pools, DNS records) through a simple, reusable datasource. This proof-of-concept implementation demonstrates the viability of custom providers for centralized naming logic.

## Features

- **Standardized Naming**: Generate consistent names following the pattern `<env>-<app>`
- **Type Safety**: Terraform validates inputs at plan time
- **Zero Configuration**: No provider-level configuration required
- **Extensible**: Foundation for future datasources, resources, and functions

## Requirements

- [Go](https://golang.org/doc/install) 1.24.2 (managed via mise in this project)
- [OpenTofu](https://opentofu.org/) >= 1.9.0 or [Terraform](https://www.terraform.io/downloads.html) >= 1.0

## Installation

### Local Development Setup

1. **Build and install the provider:**

```bash
  cd .providers/terraform-provider-homelab
  make install
```

This installs the provider binary to your Go bin directory (typically `$GOPATH/bin` or `$HOME/go/bin`).

2. **Configure dev overrides:**

Create or edit `~/.terraformrc` (or `~/.tofurc` for OpenTofu) with the following content:

```hcl
  provider_installation {
    dev_overrides {
      "registry.terraform.io/abes140377/homelab" = "/path/to/your/go/bin"
    }

    direct {}
  }
```

   **To find your Go bin directory:**
```bash
  # If using mise (project setup):
  echo ~/.local/share/mise/installs/go/1.24.2/bin

  # Or check GOBIN:
  go env GOBIN

  # If GOBIN is empty, use GOPATH/bin:
  echo "$(go env GOPATH)/bin"
```

3. **Verify installation:**

```bash
  cd examples/data-sources/naming
  TF_CLI_CONFIG_FILE=.terraformrc tofu plan
```

You should see output showing the generated names.

## Usage

### Basic Example

```hcl
terraform {
  required_providers {
    homelab = {
      source = "registry.terraform.io/abes140377/homelab"
    }
  }
}

provider "homelab" {}

# Generate a name for a development web server
data "homelab_naming" "dev_web" {
  env = "dev"
  app = "web"
}

# Use the generated name
output "resource_name" {
  value = data.homelab_naming.dev_web.name  # Output: "dev-web"
}
```

### Data Source: homelab_naming

Generates standardized names based on environment and application identifiers.

#### Arguments

- `env` (String, Required) - The environment name (e.g., `dev`, `staging`, `prod`)
- `app` (String, Required) - The application name (e.g., `web`, `db`, `api`)

#### Attributes

- `name` (String) - The generated name following the pattern `<env>-<app>`

#### Example

```hcl
data "homelab_naming" "prod_database" {
  env = "prod"
  app = "db"
}

output "database_name" {
  value = data.homelab_naming.prod_database.name  # Output: "prod-db"
}
```

### Integration with Other Resources

The naming datasource can be used to ensure consistent naming across your infrastructure:

```hcl
# Generate a name
data "homelab_naming" "app_server" {
  env = "prod"
  app = "api"
}

# Use it in a Proxmox LXC container
resource "proxmox_virtual_environment_container" "app" {
  hostname = data.homelab_naming.app_server.name
  # ... other configuration
}

# Use it in DNS records
resource "dns_a_record_set" "app" {
  zone      = "example.com."
  name      = data.homelab_naming.app_server.name
  addresses = [proxmox_virtual_environment_container.app.ipv4_addresses[0]]
}
```

## Development

### Building from Source

```bash
# Clone the repository
cd .providers/terraform-provider-homelab

# Install dependencies
go mod tidy

# Build the provider
make build

# Or build and install
make install
```

### Running Tests

```bash
# Format code
make fmt

# Run static analysis
make vet

# Test with example configuration
cd examples/data-sources/naming
TF_CLI_CONFIG_FILE=.terraformrc tofu plan
```

### Project Structure

```
.providers/terraform-provider-homelab/
├── main.go                          # Provider server entry point
├── go.mod                           # Go module definition
├── internal/
│   └── provider/
│       ├── provider.go              # Provider implementation
│       └── naming_data_source.go    # Naming datasource implementation
└── examples/
    └── data-sources/
        └── naming/
            ├── main.tf              # Usage example
            └── validation-test.tf   # Validation test examples
```

## Limitations

This is a proof-of-concept implementation with the following limitations:

- **No Registry Publication**: Provider must be installed locally; not available in Terraform Registry
- **Simple Logic**: Only concatenates `env` and `app` with a hyphen; no advanced validation or transformations
- **No Resources**: Only implements a datasource; no managed resources
- **No Functions**: Provider functions not implemented
- **Manual Testing**: No automated test framework

## Future Enhancements

Potential improvements for future iterations:

1. **Enhanced Validation**: Add validation for allowed environment names and character restrictions
2. **Additional Attributes**: Support resource type, location, project identifiers
3. **Resources**: Implement managed resources for naming conventions storage
4. **Provider Functions**: Add utility functions for name manipulation
5. **Registry Publication**: Package and publish to Terraform Registry
6. **Automated Testing**: Implement acceptance tests using Terraform plugin testing framework

## Troubleshooting

### Provider Not Found

**Issue**: Terraform/OpenTofu cannot find the provider.

**Solution**:
1. Verify the provider is installed: `ls -la $(go env GOPATH)/bin/terraform-provider-homelab`
2. Check your `.terraformrc` configuration points to the correct directory
3. Ensure the provider address matches: `registry.terraform.io/abes140377/homelab`

### Dev Override Warnings

**Issue**: Seeing warnings about "Provider development overrides are in effect".

**Solution**: This is expected behavior when using dev overrides. The warnings remind you that you're using a local build instead of a registry version. You can skip `terraform init` when using dev overrides.

### Build Failures

**Issue**: `go install` or `make install` fails.

**Solution**:
1. Verify Go version: `go version` (should be 1.24.2)
2. Clean and rebuild: `go clean -cache && go mod tidy && make install`
3. Check for missing dependencies: `go mod download`

## Contributing

This is a proof-of-concept provider developed for the terragrunt-infrastructure-catalog-homelab project. Future enhancements will be considered based on real-world usage patterns and feedback.

## License

This provider is part of the terragrunt-infrastructure-catalog-homelab project and follows the same licensing terms.

## Resources

- [Terraform Plugin Framework Documentation](https://developer.hashicorp.com/terraform/plugin/framework)
- [HashiCorp Provider Scaffolding Framework](https://github.com/hashicorp/terraform-provider-scaffolding-framework)
- [OpenTofu Documentation](https://opentofu.org/docs/)
