# Unmined CLI Docker Image

Builds and publishes a containerized `unmined-cli` image to GitHub Container Registry (`ghcr.io`).

## Image Details

- **Base image**: `mcr.microsoft.com/dotnet/runtime:8.0-jammy` (.NET 8 runtime on Debian Jammy)
- **Unmined version**: `dev` (latest development build from unmined.net)
- **Architecture**: linux-x64 (glibc)
- **Non-root user**: `unmined` (UID 1000, matches common fsGroup default)
- **Registry**: `ghcr.io/antorfr/smart-home-charts/unmined-cli`

## Build

Automatic on push to `images/unmined/` or `.github/workflows/build-unmined-image.yml`:

```bash
# Manual build (downloads latest dev version)
docker build -t ghcr.io/antorfr/smart-home-charts/unmined-cli:dev \
  --build-arg UNMINED_VERSION=dev \
  images/unmined/
```

## Usage in unmined chart

Reference in `values.yaml`:

```yaml
renderer:
  image:
    repository: ghcr.io/antorfr/smart-home-charts/unmined-cli
    tag: "dev"
```

Tags available:
- `dev` — latest development build (auto-updated on each push)
- `latest` — most recent build from main branch
- `main` — build from current main branch

## Publishing

GitHub Actions workflow (`build-unmined-image.yml`):
- Triggers on changes to `images/unmined/` or workflow itself
- Publishes to `ghcr.io/antorfr/smart-home-charts/unmined-cli:dev` (and `:latest` on main branch)
- Supports manual dispatch with custom tag override via workflow_dispatch

First push requires:
1. GitHub Actions enabled on repository
2. No additional secrets (uses `GITHUB_TOKEN` scoped to `packages: write`)
