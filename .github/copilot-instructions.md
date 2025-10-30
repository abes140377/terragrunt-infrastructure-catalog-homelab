# Copilot Instructions for terragrunt-infrastructure-catalog-homelab

## Project Overview

This repo is a Terragrunt infrastructure catalog for homelab Proxmox environments. It provides reusable modules, units, and stacks for managing Proxmox resources and DNS records using OpenTofu/Terraform and Terragrunt.

## Architecture

- **Modules (`modules/`)**: Raw OpenTofu/Terraform modules (e.g., `proxmox-lxc`, `proxmox-pool`, `dns`). No Terragrunt logic.
- **Units (`units/`)**: Terragrunt wrappers around modules. Use Git URLs for external consumption, `values.*` for parameterization, and `include "root"` for shared config.
- **Stacks (`stacks/`)**: Compositions of multiple units. Use `terragrunt.stack.hcl` with required `path` attributes for each unit. Dependencies between units are handled via unit paths and `values` blocks, not Terragrunt `dependency` blocks.
- **Examples (`examples/terragrunt/`)**: Local test setups using relative paths instead of Git URLs.

## Key Workflows

- **Tooling**: Managed via `mise.toml`. Run `mise install` to set up all required tools (OpenTofu, Terragrunt, MinIO client, Go).
- **Environment Setup**: Export required secrets as env vars (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `PROXMOX_VE_API_TOKEN`, `TF_VAR_dns_key_secret`). Secrets are SOPS-encrypted in `.creds.env.yaml`.
- **Terragrunt Operations**:
  - Units: `terragrunt init|plan|apply|destroy` in `examples/terragrunt/units/<unit>`
  - Stacks: `terragrunt stack generate`, then `terragrunt stack run <plan|apply|destroy>` in `examples/terragrunt/stacks/<stack>`
- **Development**:
  - Format: `tofu fmt -recursive`
  - Validate: `tofu init && tofu validate` in module dirs
  - Pre-commit: `pre-commit run --all-files` (includes gitleaks, whitespace, tofu fmt/validate)
  - Clean: `mise run terragrunt:cleanup`

## Patterns & Conventions

- **Units**: Always use Git URLs for `terraform.source` except in local examples (use relative paths with double-slash `//`).
- **Stacks**: Each unit block in `terragrunt.stack.hcl` must have a `path` attribute. Pass dependencies via unit paths and `values` blocks.
- **State**: Managed in MinIO (S3-compatible). Backend config and provider config are auto-generated and should not be committed.
- **Sensitive Inputs**: Pass via `TF_VAR_*` env vars, CLI `-var` args, or Terragrunt `extra_arguments`.
- **Provider**: Uses `bpg/proxmox` (not telmate/proxmox). Token format: `username@realm!tokenname=secret`.
- **DNS**: Uses RFC 2136 dynamic updates on port 5353. TSIG key secret via `TF_VAR_dns_key_secret`.

## Integration Points

- **MinIO**: S3 backend for state. Requires credentials and bucket setup (`mise run minio:setup`).
- **Proxmox**: API token required for provider. Setup via `mise run proxmox:setup`.
- **DNS**: TSIG key secret required. DNS server at `192.168.1.13:5353`.

## References

- See `CLAUDE.md` and `openspec/AGENTS.md` for authoritative spec, change proposal, and architecture guidance.
- Example files: `examples/terragrunt/root.hcl`, `examples/terragrunt/s3-backend.hcl`, `examples/terragrunt/provider.hcl`, `modules/*`, `units/*`, `stacks/*`.

## Quickstart

```bash
mise install
mise run minio:setup
mise run proxmox:setup
mise run install-deps
mise run secrets:edit
mise run terragrunt:cleanup
```

## Important Reminders

- Do not commit generated `backend.tf` or `provider.tf` files.
- Do not add DNS TSIG key setup instructions here (handled by separate Ansible project).
- Always consult `openspec/AGENTS.md` for planning, proposals, or ambiguous requests.
