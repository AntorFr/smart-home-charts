# crafty-controller

![Version: 0.0.2](https://img.shields.io/badge/Version-0.0.2-informational?style=flat-square) ![AppVersion: 4](https://img.shields.io/badge/AppVersion-4-informational?style=flat-square)

Crafty Controller 4 — web panel for managing Minecraft Java / Bedrock servers.

## Source Code

* <https://gitlab.com/crafty-controller/crafty-4>
* <https://docs.craftycontrol.com/>

## Requirements

Kubernetes: `>=1.16.0-0`

## Dependencies

| Repository | Name | Version |
|------------|------|---------|
| https://antorfr.github.io/smart-home-charts | common | 4.5.8 |

## Installing the chart

```console
helm install crafty ./charts/crafty-controller
```

## Configuration

Read through [values.yaml](./values.yaml). Everything else is inherited from the
[common library](https://github.com/k8s-at-home/library-charts/tree/main/charts/stable/common).

### Services

Crafty exposes 4 logical services. They're split on purpose — Kubernetes doesn't
mix TCP and UDP cleanly on a single `LoadBalancer`, and users want to expose each
one differently.

| Service | Default | Port(s) | Protocol | Notes |
| --- | --- | --- | --- | --- |
| `main` (panel) | enabled | 8443 | HTTPS (TCP) | ClusterIP, reached via Ingress |
| `bedrock` | enabled | 19132 | UDP | LoadBalancer — MetalLB / klipper-lb |
| `java` | **disabled** | 25565–25574 (range) | TCP | Enable only if you run Java servers |
| `dynmap` | disabled | 8123 | TCP | Optional web map |

#### Java port range

When `service.java.enabled: true`, a range of TCP ports is generated from
`service.java.portRange.start` (default `25565`) for `service.java.portRange.size`
entries (default `10`). Each Minecraft Java server instance you create in the
Crafty panel needs one port — size the range to your number of instances.

### Persistence

Crafty writes to 5 paths under `/crafty`. Each has its own `persistence.*` entry,
all disabled by default (ephemeral). Enable only what you need to persist.

| Key | Mount path | What lives here |
| --- | --- | --- |
| `persistence.config` | `/crafty/app/config` | SQLite DB, users, settings |
| `persistence.servers` | `/crafty/servers` | Worlds, `server.properties`, plugins |
| `persistence.backups` | `/crafty/backups` | Scheduled backups |
| `persistence.logs` | `/crafty/logs` | App + server logs |
| `persistence.imports` | `/crafty/import` | Zip staging for server imports |

All three common persistence modes work:

```yaml
# Auto-provision a PVC (default if you just flip enabled: true)
persistence:
  config:
    enabled: true
    type: pvc
    storageClass: longhorn
    size: 2Gi

# Reuse an existing PVC
persistence:
  config:
    enabled: true
    type: pvc
    existingClaim: crafty-config-pvc

# Use a hostPath (homelab / virtiofs / ZFS-on-hypervisor case)
persistence:
  config:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/crafty/config
```

> `podSecurityContext.fsGroup` defaults to `1000` (the `crafty` group inside the
> image) so the non-root process can write to mounted volumes.

### Ingress — the self-signed cert problem

Crafty serves the web panel over **HTTPS with a self-signed cert** on port 8443
and has no option to disable HTTPS or provide a custom cert. The reverse proxy
must therefore speak HTTPS upstream **and skip certificate verification**.

#### With Traefik (default)

Enable `ingress.main` and keep `traefik.serversTransport.enabled: true`. The
chart then:
1. Generates a namespace-scoped `ServersTransport` CRD with `insecureSkipVerify: true`
2. Injects `traefik.ingress.kubernetes.io/service.serversscheme: https` and
   `...service.serverstransport: <ns>-<release>-insecure@kubernetescrd` onto the
   **panel Service** (Traefik's Kubernetes Ingress provider reads these
   annotations from the Service, not the Ingress)

You only need to declare hosts / TLS on the Ingress itself:

```yaml
ingress:
  main:
    enabled: true
    ingressClassName: traefik
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt
    hosts:
      - host: crafty.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: crafty-tls
        hosts: [crafty.example.com]

traefik:
  serversTransport:
    enabled: true
    insecureSkipVerify: true
```

#### With nginx-ingress

No CRD needed — two annotations are enough. Disable the Traefik ServersTransport
and override the annotations:

```yaml
ingress:
  main:
    enabled: true
    ingressClassName: nginx
    annotations:
      nginx.ingress.kubernetes.io/backend-protocol: HTTPS
      nginx.ingress.kubernetes.io/proxy-ssl-verify: "off"
      cert-manager.io/cluster-issuer: letsencrypt
    hosts:
      - host: crafty.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: crafty-tls
        hosts: [crafty.example.com]

traefik:
  serversTransport:
    enabled: false
```

### Example: homelab profile (Bedrock-only, hostPath, Traefik + cert-manager)

```yaml
image:
  tag: latest

persistence:
  config:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/crafty/config
  servers:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/crafty/servers
  backups:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/crafty/backups
  logs:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/crafty/logs
  imports:
    enabled: true
    type: hostPath
    hostPath: /mnt/data/crafty/import

service:
  java:
    enabled: false
  bedrock:
    type: LoadBalancer

ingress:
  main:
    enabled: true
    ingressClassName: traefik
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    hosts:
      - host: crafty.home.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: crafty-tls
        hosts: [crafty.home.example.com]

traefik:
  serversTransport:
    enabled: true
```

## Notes

- **Single replica only.** Crafty uses a local SQLite DB; running more than one
  replica corrupts state.
- **First boot is slow** — the SQLite DB initialises. The startup probe tolerates
  up to 10 minutes.
- Probes are TCP on 8443 (Crafty has no dedicated HTTP health endpoint).
