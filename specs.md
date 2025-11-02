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
- **Documentation**: Provide detailed setup and usage instructions suitable for operators, Terraform integration, and GitHub Actions automation.

## Implemented Structure
- **Playbook**: `ansible/playbooks/site.yml` runs four roles in order with privilege escalation.
- **Roles**:
  - `docker_prereqs`: installs Docker Engine + Compose from the upstream repository and ensures the deployment user can access the daemon.
  - `certificates`: validates existing Let’s Encrypt assets, optionally re-issues them using a disposable `certbot/certbot` container, and exposes both host and in-container paths for downstream roles.
  - `xray_cleanup`: stops and removes any container or Docker network that would collide with the managed deployment (name/image match to `xray` or listeners on port 443).
  - `xray_deploy`: templates the Vision configuration and docker-compose definition, applies them, performs health checks, and self-heals a stopped/missing container before surfacing recent logs.
- **Variables**: All runtime values (domain, email, UUID, ports, image, ALPN, etc.) are provided through Ansible variables with sane defaults where possible.
- **Shared Defaults**: `ansible/group_vars/all.yml` centralises filesystem layout, image selection, and runtime toggles for every role to avoid hidden dependencies.
- **Documentation**: `docs/usage.md` captures prerequisites, variable matrix, Terraform usage, GitHub Actions deployment notes, and verification steps.
- **Examples**: Inventory stub at `ansible/inventory/hosts.ini` and Terraform snippet under `terraform/examples/` (to be expanded with additional scenarios as needed).
- **Automation**:
  - `.github/workflows/ci.yml` installs Ansible and executes a syntax check on every push, pull request, or manual dispatch.
  - `.github/workflows/deploy.yml` validates requested environments, enforces required secrets/variables, generates a temporary inventory, runs the playbook remotely, and outputs ready-to-import client URIs.
- **Tooling Defaults**: Root-level `ansible.cfg` pins the default inventory and `roles_path` so operators (and CI) can run `ansible-playbook` from the repository root without extra flags.

## Certificate Handling Notes
- Existing certificates are probed using `openssl` to prevent unnecessary re-issuance.
- `force_regenerate_certs=true` forces a new certificate request and bypasses reuse logic.
- Certificates are persisted under `{{ certificates_dir }}/live/{{ xray_domain }}` to mirror Let’s Encrypt layout and the entire certificate tree is mounted into the container at `/etc/ssl`.
- Check mode skips the potentially destructive certificate issuance step while still reporting when issuance would have occurred.

## Docker Compose Considerations
- Uses `ghcr.io/xtls/xray-core:25.10.15` by default, mounting the rendered configuration at `/usr/local/etc/xray` for the image's `-confdir` startup mode.
- Volumes mount host config and certificate directories read-only.
- Recovery logic issues a targeted `docker compose up -d --remove-orphans` when the container is absent or stopped, re-checks status after a short pause, and prints recent logs if the service still fails. Setting `docker_compose_up=false` skips all runtime mutations while still rendering artifacts.

## Pending Enhancements
- Add automated renewal workflow suggestions (cron, systemd, or dedicated compose service).
- Expand Terraform examples to cover both local and remote execution paths.
- Layer additional CI checks (Yamllint/ansible-lint) for deeper validation beyond syntax.
