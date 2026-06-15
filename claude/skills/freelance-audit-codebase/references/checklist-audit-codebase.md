# Checklist audit codebase

Rôle : audit payé avant estimation détaillée ou reprise risquée.

Objectif :

- comprendre l’état réel de la codebase
- identifier le travail nécessaire pour atteindre l’objectif client
- qualifier les risques, inconnues et prérequis
- produire une estimation par phase ou par item

---

## Cadrage

- [ ] Objectif business clarifié
- [ ] Résultat attendu défini
- [ ] Scope minimum défini
- [ ] Hors-scope noté
- [ ] Deadline connue
- [ ] Budget ou modèle de facturation connu
- [ ] Décideur identifié

---

## Accès / setup

- [ ] Repo accessible
- [ ] README utile
- [ ] Variables d’environnement documentées
- [ ] Dépendances installables
- [ ] App lançable en local
- [ ] Build exécutable
- [ ] Tests exécutables
- [ ] Lint / typecheck exécutables
- [ ] Base de données locale ou staging disponible
- [ ] Services externes identifiés

---

## Architecture / maintenabilité

- [ ] Structure générale comprise
- [ ] Modules / features principaux identifiés
- [ ] Zone cible localisée
- [ ] Couplage visible noté
- [ ] Logique métier localisée ou dispersée
- [ ] Dépendances circulaires ou risques similaires notés
- [ ] Duplication / fichiers trop larges notés
- [ ] Dette bloquante séparée de la dette non bloquante

---

## Zone cible

Pour chaque demande :

- [ ] fichiers / modules concernés
- [ ] écrans concernés
- [ ] API concernées
- [ ] tables / collections concernées
- [ ] jobs / webhooks / intégrations concernés
- [ ] comportements existants à préserver
- [ ] tests existants
- [ ] tests à ajouter
- [ ] refactor préalable nécessaire
- [ ] inconnues à lever

---

## Données / intégrations / sécurité

- [ ] schéma inspecté
- [ ] migrations inspectées
- [ ] impact données production noté
- [ ] auth / permissions vérifiées dans la zone cible
- [ ] services externes identifiés
- [ ] webhooks / retries / idempotence vérifiés si concernés
- [ ] secrets non exposés dans les fichiers inspectés
- [ ] risques sécurité bloquants notés

---

## Tests / release

- [ ] tests pertinents passants ou état documenté
- [ ] couverture de la zone cible qualifiée
- [ ] risques de régression classés
- [ ] CI/CD compris
- [ ] staging / prod compris
- [ ] rollback possible ou risque noté
- [ ] logs / monitoring utiles ou absents

---

## Classification

Classer chaque zone cible :

- `Sûr à modifier`
- `Modifiable avec prudence`
- `Risque de régression élevé`
- `Tests nécessaires avant implémentation`
- `Inestimable sans accès / décision client`

---

## Sortie attendue

- [ ] `rapport-audit-codebase.md` rempli
- [ ] liste du travail requis
- [ ] risques et inconnues
- [ ] estimation par phase ou item
- [ ] hypothèses et exclusions
- [ ] recommandation : prix fixe / TJM / discovery supplémentaire / no-go
