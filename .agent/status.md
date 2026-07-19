# Status — smart-home-charts

> MàJ : 2026-07-19

**État :** Library chart `common` en 4.10.0 — addon `externalSecrets` avec **groupes
par consommateur** (`groups.<nom>` → un ExternalSecret `<fullname>-<nom>-secrets`,
auto-câblé sur l'`additionalContainers` homonyme) : borne l'atomicité de synchro ESO
au conteneur concerné (feature née du revert alfred-voice du 2026-07-19). Charts
applicatifs sur le repo publié `https://antorfr.github.io/smart-home-charts`.

**Prochaines étapes :**
- [ ] Migrer les charts en retard vers common 4.10.0 quand on les touche (règle n°1)
