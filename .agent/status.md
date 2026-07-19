# Status — smart-home-charts

> MàJ : 2026-07-19

**État :** Library chart `common` en 4.10.1 — addon `externalSecrets` avec **groupes
par consommateur** (`groups.<nom>` → un ExternalSecret `<fullname>-<nom>-secrets`,
auto-câblé sur l'`additionalContainers` homonyme) : borne l'atomicité de synchro ESO
au conteneur concerné (feature née du revert alfred-voice du 2026-07-19). La 4.10.1
corrige la 4.10.0 : séparateurs `---` désormais émis explicitement (le chomping les
collait à la ligne précédente → documents fusionnés par YAML, objet silencieusement
pruné par Helm). Déployé en prod via agent-pod 0.3.1 (alfred).

**Prochaines étapes :**
- [ ] Migrer les charts en retard vers common 4.10.0 quand on les touche (règle n°1)
