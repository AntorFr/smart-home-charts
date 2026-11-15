# smart-home-charts

Charts Helm pour la maison, publiés sur https://antorfr.github.io/smart-home-charts.

## Tests

La suite est déclarée dans `.sdlc.yaml` (`tests:`) et jouée par `scripts/suite-attestee.sh` :
pour chaque chart de `charts/*/`, `helm lint` et `helm template` (lint seul pour un chart
`type: library`). Elle ne demande que `helm` et un accès aux dépôts de charts, aucun cluster.
Le rapport est `resultats.tap` (un point par contrôle et par chart).

Le vert d'un commit est son attestation : `attester --publier` joue la suite et pose le statut
`tests-complets`. Aucun workflow GitHub ne joue la suite, ni sur push ni sur pull request.

Les valeurs minimales d'un rendu qui en exige vivent dans `tests/valeurs/<chart>.yaml`.

## Publication

`.github/workflows/release.yml` publie les charts à chaque push sur `main`.
