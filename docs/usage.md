# Usage Guide

This guide explains how to run the Ansible playbook that configures and starts Xray with VLESS `flow=xtls-rprx-vision` using Docker Compose.

## Prerequisites
- A Linux host with root privileges (Ansible `become: true` is used).
- Docker Engine with the Compose plugin (`docker compose` command available).
- Open TCP ports 80 (temporary for certificate issuance) and the public TLS port you choose (default 443).
- DNS A record pointing your domain to the host.
- Ansible 2.14+ on the control machine triggering the playbook.
- `openssl` available on the target host for certificate validation.

## Required Variables
Pass the following variables via `--extra-vars` or inventory:

| Variable | Description |
|----------|-------------|
| `xray_domain` | Fully qualified domain name serving Xray. |
| `xray_email` | Email address used for Let’s Encrypt registration and expiry notices. |
| `xray_uuid` | UUID for the VLESS client. Generate with `uuidgen`. |

### Optional Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `project_root` | `/opt/xray` | Root directory for generated assets. |
| `certificates_dir` | `{{ project_root }}/certificates` | Host directory where certificates are stored. |
| `letsencrypt_image` | `certbot/certbot:latest` | Container image used to request certificates. |
| `letsencrypt_staging` | `false` | Use Let’s Encrypt staging API to avoid rate limits. |
| `force_regenerate_certs` | `false` | Set to `true` to force a new certificate request. |
| `xray_inbound_port` | `443` | Public TLS port exposed by Xray. |
| `xray_service_port` | `443` | Internal container port (defaults to same as inbound). |
| `xray_certificate_path` | `{{ certificates_dir }}/live/{{ xray_domain }}/fullchain.pem` | Host path of the Let’s Encrypt certificate. |
| `xray_private_key_path` | `{{ certificates_dir }}/live/{{ xray_domain }}/privkey.pem` | Host path of the Let’s Encrypt private key. |
| `xray_flow` | `xtls-rprx-vision` | Flow value for the VLESS client. |
| `xray_client_email` | `client@example.com` | Identifier stored in the Xray client list. |
| `xray_log_level` | `warning` | Log level for Xray. |
| `compose_project_directory` | `{{ project_root }}/compose` | Directory containing rendered Docker Compose assets. |
| `xray_config_dir` | `{{ project_root }}/xray` | Directory where `config.json` is rendered. |
| `xray_image` | `ghcr.io/xtls/xray-core:25.10.15` | Docker image used for the Xray service. |
| `xray_container_user` | `0:0` | UID:GID that the Xray container runs as. Set to an empty string to use the image default. |
| `xray_container_name` | `xray` | Container name used for stability checks and manual troubleshooting. |
| `xray_stability_check_count` | `3` | Number of post-deployment stability samples collected by the playbook. |
| `xray_stability_check_delay` | `30` | Seconds to wait before each automatic stability sample. |
| `xray_container_certificate_path` | `/etc/ssl/live/{{ xray_domain }}/fullchain.pem` | Certificate path inside the container referenced by Xray config. |
| `xray_container_private_key_path` | `/etc/ssl/live/{{ xray_domain }}/privkey.pem` | Private key path inside the container referenced by Xray config. |
| `xray_alpn` | `["h2", "http/1.1"]` | ALPN values advertised to TLS clients. |
| `docker_compose_up` | `true` | Disable if you only want to render files without starting containers. |

## Running the Playbook
Create or reuse an inventory file such as `ansible/inventory/hosts.ini`:

```
[local]
127.0.0.1 ansible_connection=local
```

Run the playbook (the bundled `ansible.cfg` already points to the local inventory and roles directory):

```
ansible-playbook ansible/playbooks/site.yml \
  --extra-vars "xray_domain=example.com xray_email=admin@example.com xray_uuid=$(uuidgen)"
```

To validate changes without touching the host, add `--check` and `docker_compose_up=false`. Certificate issuance and container management automatically skip when Ansible runs in check mode.

### Forcing Certificate Re-Issuance
To bypass existing certificates:

```
ansible-playbook ansible/playbooks/site.yml \
  --extra-vars "xray_domain=example.com xray_email=admin@example.com xray_uuid=$(uuidgen) force_regenerate_certs=true"
```

### Running from Terraform
An end-to-end example is located at [`terraform/examples/main.tf`](../terraform/examples/main.tf). It connects over SSH to a remote host where this repository is checked out and executes the playbook with the variables provided by Terraform:

```
resource "null_resource" "xray" {
  provisioner "remote-exec" {
    connection {
      type    = "ssh"
      host    = var.host
      user    = var.user
      agent   = true
      timeout = "5m"
    }

    inline = [
      "sudo ansible-playbook -i /opt/less-vision/ansible/inventory/hosts.ini /opt/less-vision/ansible/playbooks/site.yml --extra-vars 'xray_domain=${var.domain} xray_email=${var.email} xray_uuid=${var.uuid}'"
    ]
  }
}
```

Adjust the inline commands to fit your provisioning flow (for example, install Ansible on the remote host or run the playbook locally with `local-exec`).

### Deploying from GitHub Actions
Manual deployments can be triggered with the [`Deploy service`](../.github/workflows/deploy.yml) workflow. It validates that the requested GitHub Environment exists, checks for the required secrets (`HOST_SSH_PRIVATE_KEY`, `EMAIL`, `UUID`) and environment variables (`REMOTE_SERVER_IP_ADDRESS`, `REMOTE_SERVER_USER`, `TARGET_DOMAIN_NAME`, optional `XRAY_INBOUND_PORT`), then dynamically builds an inventory file before running the same playbook via SSH. Successful runs print ready-to-import client connection URIs for popular applications.

## Continuous Integration
The [`CI`](../.github/workflows/ci.yml) workflow installs Ansible and runs `ansible-playbook --syntax-check` for every push, pull request, or manual dispatch. Use it as a guardrail before promoting infrastructure changes.

## Verification Steps
The playbook now samples the Docker status of the Xray container three times at 30-second intervals immediately after startup. If any sample reports a restarting state, the run fails to highlight an unstable deployment.

1. Verify containers are running: `docker compose -f /opt/xray/compose/docker-compose.yml ps`.
2. Test TLS certificate: `openssl s_client -connect example.com:443 -servername example.com`.
3. Validate Xray config inside container: `docker compose -f /opt/xray/compose/docker-compose.yml exec xray xray -test -confdir /usr/local/etc/xray`.

## Troubleshooting
- **Port 80 in use**: Stop any service occupying port 80 before requesting certificates.
- **DNS propagation**: Ensure your domain resolves to the host before issuance.
- **Rate limits**: Use `letsencrypt_staging=true` during initial testing.
- **Permission issues**: Run playbook with sudo/become if writing under `/opt`.
