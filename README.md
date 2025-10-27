# less-vision

Automated deployment toolkit for running [Xray](https://github.com/XTLS/Xray-core) with VLESS `flow=xtls-rprx-vision` behind TLS. The project is designed to be triggered from Terraform and relies on an idiomatic Ansible playbook to prepare certificates, render configuration, and launch Docker Compose.

## Features
- **Idempotent Ansible Playbook** – Roles manage certificates, Xray configuration, and Docker Compose.
- **Certificate Safety** – Existing Let’s Encrypt certificates are re-used when valid, with an option to force regeneration.
- **Infrastructure Ready** – Terraform example shows how to execute the playbook during VM provisioning.
- **Continuous Checks** – GitHub Actions workflow validates syntax and performs a safe dry run on pushes and pull requests.
- **Comprehensive Docs** – Detailed usage guide and living specification to keep the deployment process transparent.

## Repository Layout
```
.
├── ansible/
│   ├── playbooks/
│   │   └── site.yml
│   └── roles/
│       ├── certificates/
│       ├── docker_compose/
│       └── xray_config/
├── compose/
├── docs/
│   └── usage.md
├── terraform/
│   └── examples/
└── specs.md
```

## Getting Started
See [`docs/usage.md`](docs/usage.md) for prerequisites, required variables, and detailed run instructions.

## Status
Work in progress – follow [`specs.md`](specs.md) for the evolving plan and implementation notes.

