# smart-home-charts

Charts Helm pour la maison, publiés sur https://antorfr.github.io/smart-home-charts.

## Tests

La suite est déclarée dans `.sdlc.yaml` (`tests:`) et jouée par `scripts/suite-attestee.sh` :
pour chaque chart de `charts/*/`, `helm lint` et `helm template` (lint seul pour un chart
`type: library`). Elle ne demande que `helm` et un accès aux dépôts de charts, aucun cluster.
Le rapport est `resultats.tap` (un point par contrôle et par chart).

Pour la jouer à la main : `scripts/suite-attestee.sh` depuis la racine (helm v3 ou v4, accès à
`antorfr.github.io` et `repo.broadcom.com` ; environ 6 min ; elle fait `helm repo add` sur la
config helm de l'hôte et sort en code 2 si helm ou un dépôt manque).

Le vert d'un commit est son attestation : `attester --publier`, outil de la chaîne SDLC (pas du
dépôt), rejoue la suite sur une extraction propre de HEAD (arbre propre exigé) et pose sur la forge
le statut `tests-complets`. Aucun workflow GitHub ne joue la suite, ni sur push ni sur pull request.

Les valeurs minimales d'un rendu qui en exige vivent dans `tests/valeurs/<chart>.yaml`.

## Publication

`.github/workflows/release.yml` publie les charts à chaque push sur `main`.
