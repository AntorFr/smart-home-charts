# Project Guidelines

## Architecture

Ce dépôt contient des Helm charts pour un environnement smart-home, basés sur la librairie commune **common** (type `library`, version `4.5.8`).

## Création d'un nouveau chart

Tout nouveau chart **doit** être basé sur le chart `common`. Voici la structure à respecter :

### Chart.yaml

Déclarer la dépendance vers `common` :

```yaml
apiVersion: v2
name: <nom-du-chart>
description: <description>
type: application
version: 0.0.1
appVersion: "<version-applicative>"
keywords:
  - k8s-at-home
dependencies:
  - name: common
    repository: https://antorfr.github.io/smart-home-charts
    version: 4.5.8
```

### templates/common.yaml

Au minimum, le fichier doit inclure l'appel au template commun :

```yaml
{{ include "common.all" . }}
```

Si le chart nécessite une logique spécifique (volumes supplémentaires, annotations calculées, etc.), utiliser le pattern avec `common.values.setup` puis `mergeOverwrite` avant d'appeler `common.all`, comme le fait le chart `frigate`.

### values.yaml

Configurer uniquement les valeurs spécifiques au chart en s'appuyant sur les clés gérées par `common` :

- `image` : repository, tag, pullPolicy
- `env` : variables d'environnement (toujours inclure `TZ: UTC`)
- `service.main.ports` : ports exposés
- `ingress.main` : désactivé par défaut (`enabled: false`)
- `persistence` : volumes nécessaires, désactivés par défaut
- `controller` : type de workload si différent de `deployment`

Ne pas redéfinir les valeurs par défaut déjà fournies par `common` sauf si le chart a besoin de les surcharger.

## Conventions

- Utiliser `charts/<nom-du-chart>/` comme répertoire du chart
- Le `type` dans Chart.yaml est toujours `application` (seul `common` est de type `library`)
- Consulter `charts/common/values.yaml` pour la liste complète des valeurs par défaut disponibles
