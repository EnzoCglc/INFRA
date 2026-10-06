# AGENTS.md

Consignes pour les agents (IA ou humains) qui modifient ce dépôt.

## Contexte du projet

Dépôt d'infrastructure d'une application web conteneurisée, déployée avec Docker Compose :

- `proxy` : Nginx (reverse proxy, ports 80/443) ; une migration vers Traefik est proposée dans `docs/adr/0001-choix-reverse-proxy.md`.
- `web` : application web (port interne 8080).
- `db` : PostgreSQL 16.
- Un serveur VPN WireGuard (`vpn-01`, UDP 51820) pour les télétravailleurs ; un pare-feu `fw-01`.

Fichiers clés : `docker-compose.yml`, `Makefile`, `.env.example`, `scripts/`, `wireguard/`, `docs/adr/`. Voir `README.md` pour le détail.

## Commandes de vérification

À lancer avant tout commit et dans chaque PR :

```bash
make check                 # docker compose config -q + shellcheck
docker compose config -q   # valide docker-compose.yml
shellcheck scripts/*.sh    # lint des scripts shell
```

Ne jamais lancer `make up` ou `docker compose up` contre un environnement de production pour tester.

## Conventions

- **Branches (Gitflow)** : `main` (production) et `develop` (intégration) sont protégées ; on travaille sur `feature/*`, `docs/*`, `release/*` ou `hotfix/*` et on passe par une pull request.
- **Commits** : [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`…), à l'impératif, avec une portée si utile (`docs(readme): …`).
- **PR** : remplir toutes les rubriques du modèle, référencer l'issue (`Closes #N`), merge en Squash and merge.
- **Scripts shell** : commencer par `#!/usr/bin/env bash` et `set -euo pipefail`, quoter les variables.
- **Décisions d'architecture** : consigner dans `docs/adr/` à partir de `0000-modele.md`.
- **Secrets** : uniquement dans `.env` (non versionné) ou dans un gestionnaire de secrets ; seul `.env.example` est versionné, avec des valeurs factices.

## Interdits

- Ne jamais écrire de mot de passe, token, clé privée ou certificat dans un fichier du dépôt, dans un commit ou dans un log.
- Ne jamais pousser directement sur `main` ou `develop`.
- Ne jamais exécuter de commande destructrice (`rm -rf`, `chmod -R 777`, `ufw disable`, `docker system prune`) ni agir directement sur un serveur de production sans accord explicite.
- Ne jamais désactiver une protection de sécurité (`StrictHostKeyChecking=no`, pare-feu, vérification TLS).
- Ne pas modifier les fichiers hors du périmètre demandé ; en cas de doute, demander.
