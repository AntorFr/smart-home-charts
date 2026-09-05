# Status — smart-home-charts

> MàJ : 2026-07-19

**État :** Library chart `common` en 4.10.1 — addon `externalSecrets` avec **groupes
par consommateur** (`groups.<nom>` → un ExternalSecret `<fullname>-<nom>-secrets`,
auto-câblé sur l'`additionalContainers` homonyme) : borne l'atomicité de synchro ESO
au conteneur concerné (feature née du revert alfred-voice du 2026-07-19). La 4.10.1
corrige la 4.10.0 : séparateurs `---` désormais émis explicitement (le chomping les
collait à la ligne précédente → documents fusionnés par YAML, objet silencieusement
pruné par Helm). Déployé en prod via agent-pod 0.3.1 (alfred).

**Chart `adestia` 0.1.0 (05/09)** — remplace `agent-pod` pour les trois corps
(alfred, skippy, nestor). `agent-pod` portait encore le nom et la description de
l'architecture débranchée le 05/09 (agent-gw + claude-pod) et pointait vers le repo
`agent-pods`, alors que l'image déployée est `ghcr.io/antorfr/adestia`. Le chart est
un passe-plat vers `common` 4.10.1 : mêmes templates, values réécrites sur la forme
réelle (port 8730, volumes `workspace`/`home`/`data`, `enableServiceLinks: false`).
⚠️ **Le rendu est identique à un détail près : `app.kubernetes.io/name` passe de
`agent-pod` à `adestia`, et ce label est dans le `selector` — immuable.** Vérifié par
parsing des deux rendus avec les vraies values de skippy : 5 objets, mêmes kinds et
mêmes noms (`fullnameOverride` protège tout le reste), seul le selector diffère. La
bascule impose donc de **supprimer les 3 Deployments** pour qu'ils soient recréés ;
aucune donnée en jeu (hostPath, et le seul PVC — `alfred-memoire-perso`, NFS — est en
`existingClaim`, hors périmètre du chart).

**Prochaines étapes :**
- [ ] Migrer les charts en retard vers common 4.10.0 quand on les touche (règle n°1)
- [ ] `agent-pod` : plus aucun consommateur après la bascule — le déprécier ou le
      supprimer du repo (les versions déjà publiées restent dans l'index)
