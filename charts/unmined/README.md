# Unmined Web Map Renderer

Unmined renders Minecraft Bedrock world maps to web-viewable tiles via a scheduled CronJob, with nginx serving the tiles and an interactive map viewer.

## Requirements

- Kubernetes >= 1.21 (batch/v1 CronJob)
- Minecraft Bedrock worlds mounted on hostPath (read-only access)
- Output directory for tiles (read-write)

## Installation

```bash
helm install unmined ./charts/unmined \
  -f values-custom.yaml
```

## Configuration

### Worlds

Define worlds to render in `values.yaml`:

```yaml
worlds:
  - name: survival
    worldPath: /worlds/bedrock-01/worlds/Bedrock level
    extraArgs: []
  - name: creative
    worldPath: /worlds/bedrock-02/worlds/Creative world
```

Each world gets its own output directory: `/output/<name>/unmined.html` + tiles.

### Renderer Schedule

Cron expression for map updates (default: every 30 min):

```yaml
renderer:
  schedule: "*/30 * * * *"
  concurrencyPolicy: Forbid  # Don't overlap renders
```

### Resource Pack

Bedrock requires a resource pack for proper textures (optional but recommended):

```yaml
resourcePack:
  enabled: true
  url: https://github.com/Mojang/bedrock-samples/archive/refs/tags/v1.26.0.2.zip
  mountPath: /resourcepack
```

Downloaded once on first CronJob run, cached in PVC/hostPath.

### Persistence

Mount your worlds and output directories:

```yaml
persistence:
  worlds:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/crafty/servers
    readOnly: true
  output:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/unmined
  resourcepack:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/unmined-resourcepack
```

### Ingress

Expose the map viewer:

```yaml
ingress:
  main:
    enabled: true
    ingressClassName: traefik
    hosts:
      - host: maps.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: unmined-tls
        hosts:
          - maps.example.com
```

## Example: Homelab Setup

```yaml
renderer:
  schedule: "0 */6 * * *"  # Every 6 hours
  concurrencyPolicy: Forbid

persistence:
  worlds:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/crafty/servers
    readOnly: true
  output:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/unmined
  resourcepack:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/unmined-resourcepack

ingress:
  main:
    enabled: true
    ingressClassName: traefik
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    hosts:
      - host: maps.home.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: unmined-tls
        hosts:
          - maps.home.example.com
```

## Workloads

- **Renderer CronJob** (`<release>-unmined`): Executes `unmined-cli web render` per world on schedule. Mounts worlds (RO) + output (RW) + resource pack (RO).
- **Web Deployment** (`<release>-unmined-web`): Single nginx replica serving `/output/` at http://:80. Mounts output (RO).

## Notes

- **Idempotent rendering**: Each CronJob run overwrites the output tiles. There is no incremental rendering.
- **Resource pack download**: First CronJob run downloads the resource pack. Subsequent runs reuse the cached zip.
- **Storage estimate**: ~500 MB tiles per 10k×10k block world (varies by biome complexity).
- **No probes on CronJob**: Renderer is a batch job; it has no readiness/liveness probes.
