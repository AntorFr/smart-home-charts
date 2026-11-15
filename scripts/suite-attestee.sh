#!/usr/bin/env bash
# Suite attestée : lint et rendu de chaque chart de charts/*/, rapport TAP dans resultats.tap.
# Requis : helm seul, aucun cluster. Rien n'est sauté : un contrôle est ok ou not ok.
#
# Hors suite, faute de cluster : l'installation (ct install) et le contrôle d'incrément de
# version de ct lint --target-branch (propre à une PR ; release.yml ne publie qu'une version neuve).
#
# Le rendu prend charts/<chart>/ci/*-values.yaml s'il existe, puis tests/valeurs/<chart>.yaml.
# Un chart de type library n'a pas de rendu : lint seul.
set -u
cd "$(dirname "$0")/.."

RAPPORT=resultats.tap
SORTIE=$(mktemp -d)
trap 'rm -rf "$SORTIE"' EXIT

command -v helm >/dev/null 2>&1 || { echo "suite-attestee : helm est absent du PATH" >&2; exit 2; }

echo "suite-attestee : $(helm version --short)"
helm repo add smart-home-charts https://antorfr.github.io/smart-home-charts >/dev/null \
  || { echo "suite-attestee : dépôt smart-home-charts injoignable" >&2; exit 2; }
helm repo add bitnami https://repo.broadcom.com/bitnami-files/ >/dev/null \
  || { echo "suite-attestee : dépôt bitnami injoignable" >&2; exit 2; }
helm repo update >/dev/null \
  || { echo "suite-attestee : mise à jour des dépôts de charts en échec" >&2; exit 2; }

charts=()
for d in charts/*/; do
  [ -f "${d}Chart.yaml" ] && charts+=("${d%/}")
done
[ "${#charts[@]}" -gt 0 ] || { echo "suite-attestee : aucun chart dans charts/*/" >&2; exit 2; }

points=()
rouges=0
n=0
# point <ok|not ok> <nom> <fichier de sortie>
point() {
  n=$((n + 1))
  points+=("$1 $n - $2")
  if [ "$1" = "not ok" ]; then
    rouges=$((rouges + 1))
    echo "NOT OK $2" >&2
    sed 's/^/    /' "$3" | head -40 >&2
    # diagnostic YAML indenté du TAP
    { echo "  ---"; echo "  message: |"; sed 's/^/    /' "$3" | head -40; echo "  ..."; } >"$SORTIE/diag.$n"
    points+=("@diag.$n")
  fi
}

for chart in "${charts[@]}"; do
  nom=$(basename "$chart")
  log="$SORTIE/$nom.log"

  # Dépendances (update : Chart.lock est ignoré par git, l'extraction n'en a pas).
  if grep -q '^dependencies:' "$chart/Chart.yaml"; then
    if ! helm dependency update "$chart" >"$log" 2>&1; then
      point "not ok" "dependances $nom" "$log"
    fi
  fi

  if helm lint "$chart" >"$log" 2>&1; then
    point "ok" "lint $nom" "$log"
  else
    point "not ok" "lint $nom" "$log"
  fi

  if grep -Eq '^type:[[:space:]]*"?library"?[[:space:]]*$' "$chart/Chart.yaml"; then
    continue
  fi
  args=()
  for f in "$chart"/ci/*-values.yaml; do [ -f "$f" ] && args+=(-f "$f"); done
  [ -f "tests/valeurs/$nom.yaml" ] && args+=(-f "tests/valeurs/$nom.yaml")
  if helm template "$nom" "$chart" ${args[@]+"${args[@]}"} >"$log" 2>&1; then
    point "ok" "rendu $nom" "$log"
  else
    point "not ok" "rendu $nom" "$log"
  fi
done

{
  echo "TAP version 13"
  echo "1..$n"
  for p in "${points[@]}"; do
    case "$p" in
      @diag.*) cat "$SORTIE/${p#@}" ;;
      *) echo "$p" ;;
    esac
  done
} >"$RAPPORT"

echo "suite-attestee : $((n - rouges))/$n ok, $rouges rouge(s) — $RAPPORT"
[ "$rouges" -eq 0 ]
