#!/usr/bin/env bash
# Tests d'ensemble de la feature « suite déclarée et attestée » (hors suite attestée : ils
# jouent la suite elle-même sur une copie réduite du dépôt, et demandent le réseau).
# Usage : tests/suite-attestee.test.sh   (depuis n'importe où ; sort non nul au premier échec)
set -u
RACINE=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fails=0
verifie() { # <nom> <commande...>
  local nom=$1; shift
  if "$@"; then echo "ok - $nom"; else echo "not ok - $nom"; fails=$((fails+1)); fi
}
# copie réduite : le script, les valeurs, quatre charts (library, dépendances, valeurs requises)
copie() { # <dossier>
  mkdir -p "$1/scripts" "$1/tests" "$1/charts"
  cp "$RACINE/scripts/suite-attestee.sh" "$1/scripts/"
  cp -r "$RACINE/tests/valeurs" "$1/tests/"
  for c in common adminer engarde kurrier; do cp -r "$RACINE/charts/$c" "$1/charts/$c"; done
}

# --- nominal : un point par contrôle et par chart, library sans rendu, sortie 0
N="$TMP/nominal"; copie "$N"
(cd "$N" && scripts/suite-attestee.sh >"$TMP/nominal.out" 2>&1); code=$?
tap="$N/resultats.tap"
verifie "nominal : sortie 0" test "$code" -eq 0
verifie "nominal : plan 1..7" grep -qx '1\.\.7' "$tap"
for p in "lint common" "lint adminer" "rendu adminer" "lint engarde" "rendu engarde" "lint kurrier" "rendu kurrier"; do
  verifie "nominal : ok - $p" grep -Eq "^ok [0-9]+ - $p\$" "$tap"
done
verifie "bord : chart library sans point de rendu" bash -c "! grep -q 'rendu common' '$tap'"
verifie "nominal : aucun not ok" bash -c "! grep -q '^not ok' '$tap'"

# --- échec : Chart.yaml invalide -> rouge nommant le chart, les autres sont quand même rapportés
C="$TMP/casse"; copie "$C"
printf 'apiVersion: v2\nname: [cassé\n' >"$C/charts/adminer/Chart.yaml"
(cd "$C" && scripts/suite-attestee.sh >"$TMP/casse.out" 2>&1); code=$?
tap="$C/resultats.tap"
verifie "chart cassé : sortie non nulle" test "$code" -ne 0
verifie "chart cassé : not ok - lint adminer" grep -Eq '^not ok [0-9]+ - lint adminer$' "$tap"
verifie "chart cassé : la suite continue (ok - lint kurrier)" grep -Eq '^ok [0-9]+ - lint kurrier$' "$tap"
verifie "chart cassé : ok - rendu engarde rapporté" grep -Eq '^ok [0-9]+ - rendu engarde$' "$tap"
verifie "chart cassé : le chart sain n'est pas accusé" bash -c "! grep -Eq '^not ok [0-9]+ - (lint|rendu) (engarde|kurrier|common)\$' '$tap'"

# --- échec : gabarit qui ne se rend pas -> lint ok ou non, mais rendu not ok nommant le chart
G="$TMP/gabarit"; copie "$G"
printf '{{ required "valeur absente" .Values.nexistepas.tout }}\n' >"$G/charts/kurrier/templates/zz-casse.yaml"
(cd "$G" && scripts/suite-attestee.sh >"$TMP/gabarit.out" 2>&1); code=$?
tap="$G/resultats.tap"
verifie "gabarit cassé : sortie non nulle" test "$code" -ne 0
verifie "gabarit cassé : not ok - rendu kurrier" grep -Eq '^not ok [0-9]+ - rendu kurrier$' "$tap"
verifie "gabarit cassé : ok - rendu engarde" grep -Eq '^ok [0-9]+ - rendu engarde$' "$tap"

# --- échec : helm absent -> sortie 2, sans rapport menteur
H="$TMP/sanshelm"; copie "$H"
(cd "$H" && PATH=/usr/bin:/bin; command -v helm >/dev/null && exit 99; scripts/suite-attestee.sh >"$TMP/sanshelm.out" 2>&1); code=$?
if [ "$code" -eq 99 ]; then echo "ok - helm absent : sauté, helm est dans /usr/bin (cas non joué)"; else
  verifie "helm absent : sortie 2" test "$code" -eq 2
fi

# --- exclusions : aucune forge ne joue la suite, déclaration présente
verifie "lint-test.yaml supprimé" test ! -e "$RACINE/.github/workflows/lint-test.yaml"
verifie "aucun workflow ne lance lint/rendu/suite" bash -c "! grep -Eq 'helm lint|ct lint|ct install|chart-testing|suite-attestee' '$RACINE'/.github/workflows/*.y*ml"
verifie "aucun workflow sur pull_request ne joue la suite (create-cluster seul)" bash -c "for f in '$RACINE'/.github/workflows/*.y*ml; do grep -q 'pull_request' \"\$f\" && echo \"\$f\"; done | grep -v create-cluster.yml | wc -l | grep -qx 0"
verifie ".sdlc.yaml déclare tests: et local:" bash -c "grep -q '^tests:' '$RACINE/.sdlc.yaml' && grep -Eq '^  local: scripts/suite-attestee.sh' '$RACINE/.sdlc.yaml' && grep -Eq '^  rapport: resultats.tap' '$RACINE/.sdlc.yaml'"
verifie "resultats.tap ignoré par git" bash -c "cd '$RACINE' && git check-ignore -q resultats.tap"

[ "$fails" -eq 0 ]
