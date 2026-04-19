# Unmined CLI Docker Image

Builds and publishes a containerized `unmined-cli` image to GitHub Container Registry (`ghcr.io`).

## Image Details

- **Base image**: `mcr.microsoft.com/dotnet/runtime:8.0-jammy` (.NET 8 runtime on Debian Jammy)
- **Unmined version**: 0.19.60 (override with build-arg `UNMINED_VERSION`)
- **Architecture**: linux-x64
- **Non-root user**: `unmined` (UID 1000, matches common fsGroup default)
- **Registry**: `ghcr.io/antorfr/smart-home-charts/unmined-cli`

## Build

Automatic on push to `images/unmined/` or `.github/workflows/build-unmined-image.yml`:

```bash
# Manual build
docker build -t ghcr.io/antorfr/smart-home-charts/unmined-cli:0.19.60 \
  --build-arg UNMINED_VERSION=0.19.60 \
  images/unmined/

# With custom version
docker build -t ghcr.io/antorfr/smart-home-charts/unmined-cli:0.20.0 \
  --build-arg UNMINED_VERSION=0.20.0 \
  images/unmined/
```

## Usage in unmined chart

Reference in `values.yaml`:

```yaml
renderer:
  image:
    repository: ghcr.io/antorfr/smart-home-charts/unmined-cli
    tag: "0.19.60"
```

Or just `latest`:

```yaml
renderer:
  image:
    repository: ghcr.io/antorfr/smart-home-charts/unmined-cli
    tag: latest
```

## Publishing

GitHub Actions workflow (`build-unmined-image.yml`):
- Triggers on changes to `images/unmined/` or workflow itself
- Publishes to `ghcr.io/antorfr/smart-home-charts/unmined-cli:latest` on main branch
- Supports manual dispatch with custom tag override

First push requires:
1. GitHub Actions enabled on repository
2. No additional secrets (uses `GITHUB_TOKEN` scoped to `packages: write`)
