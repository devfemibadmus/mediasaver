# API Deployment

This repo deploys the Rust API from the `api/` folder using GitHub Actions.

Workflow file:

```text
.github/workflows/api.yml
```

Deploy script:

```text
api/api.sh
```

## Workflow Order

The API deployment workflow runs in this order:

1. Check secrets
2. Test VM
3. Check server requirements
4. Cargo build
5. Deploy API service

The workflow runs when:

- Code is pushed to `main` and the changed files are inside `api/**`
- `.github/workflows/api.yml` changes
- It is started manually with `workflow_dispatch`

## Required GitHub Secrets

Add these secrets in GitHub:

```text
Repository -> Settings -> Secrets and variables -> Actions -> New repository secret
```

```text
DEPLOY_SECRET
DEPLOY_APP_ENV
```

`DEPLOY_SECRET` is one env-style file containing deployment settings only.

`DEPLOY_APP_ENV` is the app runtime env file content that will be written to the server.

`DEPLOY_SECRET` example:

```env
VPS_HOST=123.123.123.123
VPS_USER=root
VPS_SSH_PORT=22
SSH_PRIVATE_KEY_B64=base64_encoded_private_key_here

APP_NAME=mediasaver-api
APP_DOMAIN=api.example.com
APP_PORT=8080
APP_HOST=127.0.0.1
CERTBOT_EMAIL=admin@example.com
```

`DEPLOY_APP_ENV` example:

```env
RUST_LOG=info
```

If the API has no extra runtime env values, `DEPLOY_APP_ENV` can be empty.

## DEPLOY_SECRET Keys

| Key | Required | Example | Purpose |
| --- | --- | --- | --- |
| `VPS_HOST` | Yes | `123.123.123.123` | VM public IP address or hostname |
| `VPS_USER` | Yes | `root` | SSH username for the VM |
| `SSH_PRIVATE_KEY_B64` | Yes | Base64 private key | Base64 of the SSH private key used by GitHub Actions |
| `VPS_SSH_PORT` | No | `22` | SSH port. Defaults to `22` if empty |
| `APP_NAME` | Yes | `mediasaver-api` | Service name used for systemd, `/opt`, and `/etc` paths |
| `APP_DOMAIN` | Yes | `api.example.com` | Domain used for nginx and SSL |
| `APP_PORT` | Yes | `8080` | Port the Rust API listens on |
| `APP_HOST` | Yes | `127.0.0.1` | Host/interface the Rust API binds to |
| `CERTBOT_EMAIL` | Yes | `admin@example.com` | Email used by Certbot/Let's Encrypt |

## SSH Key Base64

On Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\private_key")) | Set-Clipboard
```

On macOS/Linux:

```bash
base64 < ~/.ssh/id_rsa | tr -d '\n'
```

## App Runtime Env Format

Runtime app env values should be plain `KEY=value` lines inside `DEPLOY_APP_ENV`:

```env
RUST_LOG=info
```

Do not repeat deployment keys like `VPS_HOST`, `APP_DOMAIN`, or `SSH_PRIVATE_KEY_B64` inside `DEPLOY_APP_ENV`.

Do not wrap the full value in quotes. Each variable should be on its own line.

The workflow uploads `DEPLOY_APP_ENV` as the app env file.

The deploy script writes the final environment file on the VM here:

```text
/etc/<APP_NAME>/<APP_NAME>.env
```

The script also adds these values automatically:

```env
APP_NAME=<APP_NAME>
APP_DOMAIN=<APP_DOMAIN>
APP_HOST=<APP_HOST>
APP_PORT=<APP_PORT>
```

## VM Requirements

The deploy script manages the VM requirements directly.

It checks or installs:

- `ufw`
- `nginx`
- `certbot`

It enables firewall access for:

- Any TCP/UDP ports already listening on the VM at deploy time
- OpenSSH
- Port `80`
- Port `443`

If `APP_HOST` is not `127.0.0.1` or `localhost`, it also allows the configured `APP_PORT`.

Before enabling UFW, the script checks existing listening ports using `ss` and adds matching UFW allow rules. This is to avoid blocking other apps already running on the same VM.

The script does not force-enable UFW. If UFW is already active, rules are updated. If UFW is not active, rules are added but UFW is left disabled to avoid locking down or interrupting an existing VM.

It also starts and enables `nginx` if needed.

## Shared VM Safety

The deploy script is designed to avoid interrupting other apps on the same VM.

It only manages app-scoped files:

```text
/opt/<APP_NAME>/
/etc/<APP_NAME>/
/etc/systemd/system/<APP_NAME>.service
/etc/nginx/sites-available/<APP_NAME>.conf
/etc/nginx/sites-enabled/<APP_NAME>.conf
```

Before writing nginx config, it checks whether another nginx site already owns `APP_DOMAIN`. If another config already uses that domain, deployment stops instead of overwriting or hijacking the domain.

The script reloads nginx only after `nginx -t` passes.

## SSL Behavior

The deploy script uses Certbot standalone mode for `APP_DOMAIN`.

For a new certificate, port `80` must point to this VM and must be available for Certbot.

If port `80` is held by nginx, the script temporarily stops nginx, requests the certificate, then starts nginx again.

If port `80` is held by a non-nginx process, the script stops and refuses to continue so it does not interrupt another app.

Certificate path:

```text
/etc/letsencrypt/live/<APP_DOMAIN>/fullchain.pem
```

If the certificate already exists, the script does not request a new one.

## Service Install Paths

For `APP_NAME=mediasaver-api`, the deploy script uses:

```text
/opt/mediasaver-api/mediasaver-api
/etc/mediasaver-api/mediasaver-api.env
/etc/systemd/system/mediasaver-api.service
```

The Rust binary is built from:

```text
api/target/release/mediascraper
```

During deployment, GitHub Actions uploads it to the VM and the script installs it under `/opt/<APP_NAME>/`.

## Service Commands On VM

Check status:

```bash
sudo systemctl status <APP_NAME>.service
```

Restart:

```bash
sudo systemctl restart <APP_NAME>.service
```

View logs:

```bash
sudo journalctl -u <APP_NAME>.service -f
```

## Notes

The deploy script creates one nginx reverse proxy config for `APP_DOMAIN` and forwards traffic to `APP_HOST:APP_PORT`.

For multiple Rust apps on one VM, use a different `APP_NAME`, `APP_DOMAIN`, and `APP_PORT` for each app.
