## Context

The Terragrunt infrastructure catalog uses a three-layer architecture: modules, units, and stacks. The DNS module and unit have been created but are not yet integrated into any stacks. This change adds DNS capability to the `proxmox-container` stack, which currently creates an LXC container in a Proxmox resource pool.

Key constraints:
- Production stacks use Git URLs and cannot use Terragrunt `dependency` blocks across units (values pattern required)
- Example stacks use relative paths and can use `dependency` blocks for local testing
- DNS TSIG credentials must not be hardcoded (use environment variables)
- DNS registration must occur after container creation and IP assignment

## Goals / Non-Goals

**Goals:**
- Automatically register LXC container IP addresses in DNS when stack is deployed
- Ensure DNS unit executes after container creation (proper ordering)
- Provide testable example stack with local unit wrappers
- Maintain consistency with existing stack patterns (proxmox-container architecture)
- Use environment variable for DNS credentials (TF_VAR_dns_key_secret)

**Non-Goals:**
- Support for multiple DNS zones in a single stack (use fixed `home.sflab.io.` zone)
- Dynamic DNS server selection (use fixed `192.168.1.13:53`)
- DNS record deletion before container destruction (left for future enhancement)
- Integration into other stacks beyond proxmox-container

## Decisions

### Decision 1: Values Pattern for Production Stack

**What:** Production stack passes container IP to DNS unit via `values.container_ip` pattern rather than dependency blocks.

**Why:**
- Production stacks use Git URLs where units are isolated shallow directories
- Dependency blocks require relative paths between units which don't exist in shallow clones
- Values pattern is the documented approach for cross-unit data flow in production stacks
- Consistent with existing proxmox-container stack pattern (poolid passed via values)

**Alternatives considered:**
- Use dependency blocks in production stack: Not feasible due to Git URL isolation
- Use data sources to query container IP: Adds complexity and potential timing issues

### Decision 2: Dependency Block for Example Stack

**What:** Example stack unit wrapper uses `dependency` block to obtain LXC container IP from proxmox_lxc unit.

**Why:**
- Example stacks use relative paths where units are co-located
- Dependency blocks provide automatic ordering and output passing
- Mock outputs enable `terragrunt plan` without deploying dependencies
- Consistent with existing example patterns in the catalog

**Alternatives considered:**
- Use values pattern in examples too: Adds unnecessary complexity for local testing
- Manual IP configuration in examples: Defeats the purpose of automated integration

### Decision 3: Environment Variable for DNS Secret

**What:** DNS TSIG key secret passed via `TF_VAR_dns_key_secret` environment variable.

**Why:**
- Consistent with standalone DNS unit usage pattern
- Prevents secret leakage in stack configuration files
- Enables use of SOPS-encrypted `.creds.env.yaml` for secret storage
- Standard Terraform/OpenTofu pattern for sensitive variables

**Alternatives considered:**
- Pass secret via values parameter: Risk of exposing in Terragrunt logs and plan output
- Use Terraform Vault provider: Adds external dependency not present in current architecture

### Decision 4: DNS Record Name from Hostname

**What:** DNS record name is set to the container hostname (values.hostname), creating FQDN `${hostname}.home.sflab.io`.

**Why:**
- Logical one-to-one mapping between container hostname and DNS name
- Consistent naming convention across infrastructure
- Simplifies troubleshooting (hostname matches DNS name)

**Alternatives considered:**
- Allow custom DNS name separate from hostname: Adds complexity without clear benefit
- Generate DNS name from poolid or other identifier: Less intuitive for users

### Decision 5: Fixed DNS Zone and Server

**What:** Hardcode DNS zone to `home.sflab.io.` and DNS server to `192.168.1.13:53`.

**Why:**
- Homelab environment has single DNS zone and server
- Reduces configuration complexity for users
- Can be made configurable in future if multi-zone support needed

**Alternatives considered:**
- Make zone and server configurable: Over-engineering for current single-zone homelab use case
- Use DNS auto-discovery: Not applicable for BIND9 RFC 2136 updates

## Architecture Diagram

```
Stack: proxmox-container
├── Unit: proxmox_pool
│   └── Creates resource pool
├── Unit: proxmox_lxc
│   ├── Depends on: proxmox_pool (via values.poolid)
│   ├── Creates LXC container
│   └── Outputs: ipv4 (container IP address)
└── Unit: dns
    ├── Depends on: proxmox_lxc (via values.container_ip)
    ├── Creates DNS A record
    └── Inputs: zone, name, addresses, dns_server, key_name, key_algorithm, key_secret
```

**Execution Order:**
1. `proxmox_pool` creates resource pool
2. `proxmox_lxc` creates container in pool (depends on poolid)
3. `dns` registers container IP in DNS (depends on container_ip)

## Implementation Pattern

### Production Stack Structure

```hcl
# stacks/proxmox-container/terragrunt.stack.hcl
locals {
  poolid       = values.poolid
  hostname     = values.hostname
  password     = values.password
  container_ip = values.container_ip  # NEW: passed between units
}

unit "proxmox_lxc" {
  source = "git::...//units/proxmox-lxc?ref=${values.version}"
  path   = "proxmox-lxc"
  values = {
    hostname = local.hostname
    password = local.password
    poolid   = local.poolid
  }
}

unit "dns" {
  source = "git::...//units/dns?ref=${values.version}"
  path   = "dns"
  values = {
    zone          = "home.sflab.io."
    name          = local.hostname
    addresses     = [local.container_ip]  # Depends on LXC unit output
    dns_server    = "192.168.1.13"
    dns_port      = 53
    key_name      = "terraform-key"
    key_algorithm = "hmac-sha256"
    key_secret    = "" # Passed via TF_VAR_dns_key_secret
  }
}
```

### Example Stack Structure

```hcl
# examples/terragrunt/stacks/proxmox-container/terragrunt.stack.hcl
locals {
  poolid   = "example-pool"
  hostname = "example-stack-container"
  password = "SecurePassword123!"
}

unit "proxmox_lxc" {
  source = "./units/proxmox-lxc"
  path   = "proxmox-lxc"
  values = {
    hostname        = local.hostname
    password        = local.password
    poolid          = local.poolid
    pool_unit_path  = "../proxmox-pool"
  }
}

unit "dns" {
  source = "./units/dns"
  path   = "dns"
  values = {
    zone           = "home.sflab.io."
    name           = local.hostname
    dns_server     = "192.168.1.13"
    key_name       = "terraform-key"
    key_algorithm  = "hmac-sha256"
    lxc_unit_path  = "../proxmox-lxc"  # For dependency block
  }
}
```

```hcl
# examples/terragrunt/stacks/proxmox-container/units/dns/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../.././/modules/dns"

  extra_arguments "variables" {
    commands  = ["apply", "plan", "destroy"]
    arguments = ["-var", "key_secret=${get_env("TF_VAR_dns_key_secret", "")}"]
  }
}

dependency "proxmox_lxc" {
  config_path = try(values.lxc_unit_path, "../proxmox-lxc")
  mock_outputs = {
    ipv4 = "192.168.1.100"
  }
}

inputs = {
  zone          = values.zone
  name          = values.name
  addresses     = [dependency.proxmox_lxc.outputs.ipv4]
  dns_server    = values.dns_server
  dns_port      = try(values.dns_port, 53)
  key_name      = values.key_name
  key_algorithm = values.key_algorithm
  key_secret    = get_env("TF_VAR_dns_key_secret", "")
}
```

## Risks / Trade-offs

### Risk: Container IP not immediately available

**Scenario:** LXC container created but DHCP lease not yet assigned when DNS unit runs.

**Mitigation:**
- Terragrunt dependency ordering ensures container is created first
- Proxmox provider waits for container initialization before returning IP
- If IP not available, DNS module will fail explicitly (better than silent failure)

### Risk: DNS update authentication failure

**Scenario:** TSIG key secret not set or incorrect in environment variable.

**Mitigation:**
- Clear error message from DNS provider when authentication fails
- Documentation includes troubleshooting section for DNS credentials
- Pre-commit hooks prevent hardcoded secrets

### Risk: DNS record conflicts

**Scenario:** Container hostname already exists in DNS zone.

**Mitigation:**
- DNS provider will update existing record (RFC 2136 behavior)
- Users should ensure unique hostnames across infrastructure
- Future enhancement: Add conflict detection and validation

### Trade-off: Fixed DNS zone vs configurable

**Decision:** Use fixed `home.sflab.io.` zone initially.

**Rationale:**
- Homelab environment has single DNS zone
- Reduces configuration complexity for 90% use case
- Can be made configurable later without breaking changes

**Impact:**
- Users with multiple zones must create separate stacks
- Future enhancement can add `values.dns_zone` parameter

## Migration Plan

### Step 1: Add DNS unit to production stack

1. Edit `stacks/proxmox-container/terragrunt.stack.hcl`
2. Add `container_ip` local variable
3. Add DNS unit block with Git URL source
4. Set required values for DNS unit
5. Run `tofu fmt` on modified file

### Step 2: Create DNS unit wrapper for examples

1. Create directory `examples/terragrunt/stacks/proxmox-container/units/dns/`
2. Create `terragrunt.hcl` with relative module path
3. Add DNS provider generation block
4. Add dependency block for proxmox_lxc unit
5. Configure inputs with environment variable support

### Step 3: Add DNS unit to example stack

1. Edit `examples/terragrunt/stacks/proxmox-container/terragrunt.stack.hcl`
2. Add DNS unit block with local source path
3. Set required values using local variables

### Step 4: Update documentation

1. Add DNS stack integration section to CLAUDE.md
2. Document required environment variables
3. Add DNS verification examples
4. Document dependency ordering pattern

### Step 5: Validation

1. Run `terragrunt stack generate` on example stack
2. Run `terragrunt stack run plan` to validate configuration
3. Deploy example stack to test environment
4. Verify DNS resolution: `dig example-stack-container.home.sflab.io`
5. Run pre-commit hooks to ensure code quality

### Rollback Plan

If DNS integration causes issues:
1. Remove DNS unit blocks from both stack files
2. Delete DNS unit wrapper directory
3. Revert documentation changes
4. Containers will still be created (DNS is additive, not blocking)

## Open Questions

**Q: Should DNS records be deleted when containers are destroyed?**

A: Deferred to future enhancement. Current implementation leaves DNS records in place after container deletion. This is safe (orphaned records) but not ideal. Future iteration can add `prevent_destroy` lifecycle rules or explicit cleanup steps.

**Q: How to handle container IP changes (e.g., DHCP lease renewal)?**

A: Out of scope for initial integration. Homelab DHCP typically has long lease times and MAC-based reservations. Dynamic DNS updates on IP change would require additional tooling (e.g., DHCP hooks or container-side scripts).

**Q: Should DNS TTL be configurable?**

A: Default 300 seconds is reasonable for homelab. Can be made configurable via `values.dns_ttl` if users request it. Low priority enhancement.
