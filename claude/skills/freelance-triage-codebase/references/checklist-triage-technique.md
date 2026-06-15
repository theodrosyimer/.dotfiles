# Checklist triage technique

Rôle : pré-cadrage gratuit et limité. Ne pas faire d’audit détaillé ici.

Objectif :

- décider si une proposition directe est possible
- identifier les risques évidents
- décider si un audit codebase payé est nécessaire

---

## Entrées minimales

- [ ] Objectif client compris
- [ ] Type de demande identifié : bugfix / feature / reprise / migration / rescue / maintenance
- [ ] Deadline connue
- [ ] Budget ou cadre de facturation évoqué
- [ ] État production connu
- [ ] Accès repo possible si nécessaire
- [ ] Scope minimum exprimé

---

## Revue légère

- [ ] README consulté
- [ ] Stack principale identifiée
- [ ] Package manager identifié
- [ ] Scripts importants repérés : setup / dev / build / test / lint / typecheck
- [ ] Zone cible approximative repérée
- [ ] Tests autour de la zone cible repérés ou absents
- [ ] CI/CD visible ou inconnu
- [ ] Risques évidents notés

Ne pas faire :

- analyse fichier par fichier
- estimation précise par tâche
- recommandations d’architecture détaillées
- debug ou correction gratuite
- rapport complet

---

## Décision

| Situation | Décision |
| --- | --- |
| Petite demande claire + repo sain | Proposition possible après triage |
| Codebase inconnue / rescue / migration / risque production | Audit codebase payé avant estimation détaillée |
| Prix fixe demandé avec trop d’inconnues | Audit codebase payé ou TJM |
| Client refuse l’audit payé mais demande un prix fixe précis | Red flag : TJM ou no-go |

---

## Sortie attendue

- [ ] `note-triage-technique.md` remplie
- [ ] prochaine étape claire : proposition / audit payé / relance / no-go
- [ ] risques et inconnues visibles
