# Deployment Specification: Xray with VLESS XTLS Vision

## Overview
This document tracks the evolving specification for the automated deployment of an Xray server configured for VLESS with `flow=xtls-rprx-vision` and TLS termination. The deployment is intended to run on a host provisioned by Terraform and relies on Docker Compose orchestrated via an Ansible playbook.

## Key Requirements
- **Automation First**: Terraform should be able to invoke a single script or command that runs Ansible end-to-end without interactive prompts.
- **Ansible-Driven**: Replace shell scripts with an idiomatic Ansible playbook composed of concise roles.
- **No `.env` File**: All runtime values are injected directly into rendered configuration files (Docker Compose, Xray config) through Ansible variables.
- **Certificate Management**:
  - Re-use existing certificates when present and valid.
  - Support optional forced regeneration while guarding against unnecessary issuance.
- **Docker Compose**: Use the modern `docker compose` CLI to start the Xray container once preparation tasks finish.
- **Documentation**: Provide detailed setup and usage instructions suitable for operators and Terraform integration.

## Implemented Structure
- **Playbook**: `ansible/playbooks/site.yml` runs three roles in order with privilege escalation.
- **Roles**:
  - `certificates`: validates existing Let’s Encrypt assets, optionally re-issues them using a disposable `certbot/certbot` container, and exposes both host and in-container paths for downstream roles.
  - `xray_config`: templates the VLESS inbound configuration with the `xtls-rprx-vision` flow and container-aware certificate paths.
  - `docker_compose`: renders `docker-compose.yml`, ensures project directories exist, and optionally runs `docker compose up -d`.
- **Variables**: All runtime values (domain, email, UUID, ports, image, etc.) are provided through Ansible variables with sane defaults where possible.
- **Shared Defaults**: Each role now defines the certificate and configuration path variables it consumes, eliminating hidden cross-role dependencies.
- **Documentation**: `docs/usage.md` captures prerequisites, variable matrix, Terraform usage, and verification steps.
- **Examples**: Inventory stub at `ansible/inventory/hosts.ini` and Terraform snippet under `terraform/examples/` (to be expanded with additional scenarios as needed).
- **Automation**: GitHub Actions workflow `.github/workflows/ci.yml` installs Ansible, executes a syntax check, and then exercises the playbook in `--check` mode with representative variables. Both steps run via `python -m ansible.cli.playbook` to avoid PATH discrepancies across environments.
- **Tooling Defaults**: Root-level `ansible.cfg` pins the default inventory and `roles_path` so operators (and CI) can run `ansible-playbook` from the repository root without extra flags.

## Certificate Handling Notes
- Existing certificates are probed using `openssl` to prevent unnecessary re-issuance.
- `force_regenerate_certs=true` forces a new certificate request and bypasses reuse logic.
- Certificates are persisted under `{{ certificates_dir }}/live/{{ xray_domain }}` to mirror Let’s Encrypt layout and are mounted into the container at `/etc/ssl/xray`.
- Check mode skips the potentially destructive certificate issuance step while still reporting when issuance would have occurred.

## Docker Compose Considerations
- Uses `teddysun/xray:latest` by default, relying on the image entrypoint to read `/etc/xray/config.json`.
- Volumes mount host config and certificate directories read-only.
- Restart handler restarts the container when templates change, and `docker_compose_up` can disable runtime actions during dry runs.

## Pending Enhancements
- Add automated renewal workflow suggestions (cron, systemd, or dedicated compose service).
- Expand Terraform examples to cover both local and remote execution paths.
- Layer additional CI checks (Yamllint/ansible-lint) for deeper validation beyond syntax.

