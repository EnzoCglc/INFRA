# Plateforme Infra

Dépôt d'infrastructure d'une application web conteneurisée avec Docker Compose, accompagnée d'un accès VPN WireGuard pour les télétravailleurs.

La pile décrite dans `docker-compose.yml` comprend trois services :

| Service | Image | Rôle |
|---|---|---|
| `proxy` | `nginx:1.27-alpine` | Reverse proxy, expose les ports 80 et 443 |
| `web` | `ghcr.io/example/web:1.4.2` | Application web, port interne 8080 |
| `db` | `postgres:16-alpine` | Base de données PostgreSQL (volume `db-data`) |

> **Hypothèse** : l'image `ghcr.io/example/web` est un exemple, l'application réelle n'est pas fournie dans ce dépôt.

## Prérequis

- Docker et Docker Compose v2 (`docker compose`)
- `make`
- `shellcheck` (vérification des scripts)
- Un fichier `.env` créé à partir de `.env.example`

## Démarrage

```bash
git clone https://github.com/EnzoCglc/INFRA.git
cd INFRA
cp .env.example .env     # puis adapter les valeurs
make check               # valide docker-compose.yml et lint les scripts
make up                  # démarre la pile en arrière-plan
make down                # arrête la pile
```

## Structure du dépôt

```
.
├── .github/                 # modèles d'issues, modèle de PR, CODEOWNERS
├── docs/adr/                # décisions d'architecture (ADR)
├── scripts/backup.sh        # sauvegarde PostgreSQL
├── wireguard/wg0.conf.example  # exemple de configuration du serveur VPN
├── AGENTS.md                # consignes pour les agents IA
├── docker-compose.yml       # définition des services
├── Makefile                 # commandes de vérification et d'exploitation
└── .env.example             # modèle des variables d'environnement
```

> **Hypothèse** : le proxy monte `./nginx/conf.d` et `./certs`, qui ne sont pas versionnés ici (`certs/` est dans `.gitignore`). Ils doivent être fournis sur le serveur.

## Configuration

Les variables se définissent dans `.env` (jamais versionné, voir `.gitignore`) :

| Variable | Rôle | Valeur d'exemple |
|---|---|---|
| `DB_USER` | Utilisateur PostgreSQL | `app` |
| `DB_PASSWORD` | Mot de passe PostgreSQL | `change-me` (à remplacer) |
| `DB_NAME` | Nom de la base | `app` |
| `APP_ENV` | Environnement de l'application | `production` |

Ne jamais commiter de secret : clés privées, certificats et mots de passe restent hors du dépôt.

## Déploiement

Aucun script de déploiement n'est présent sur `main` / `develop`. La mise à jour se fait à la main sur le serveur :

```bash
git pull
docker compose pull
docker compose up -d
```

La sauvegarde de la base est assurée par `scripts/backup.sh` :

- exécute `pg_dump` dans le conteneur `db`, compressé en `db-AAAA-MM-JJ.sql.gz` ;
- écrit dans `BACKUP_DIR` (par défaut `/var/backups/app`) ;
- supprime les sauvegardes de plus de 14 jours ;
- est prévue pour une exécution quotidienne à 02:00 par cron (**supposé** : la tâche cron elle-même n'est pas dans le dépôt).

## VPN WireGuard

Le VPN est un serveur WireGuard sur `vpn-01`. La configuration d'exemple est dans `wireguard/wg0.conf.example` :

- port d'écoute : **UDP 51820** (doit être autorisé par le pare-feu `fw-01`) ;
- réseau du VPN : `10.8.0.0/24`, serveur en `10.8.0.1` ;
- un bloc `[Peer]` par télétravailleur, avec une adresse `/32` dédiée.

Les clés privées ne doivent jamais être versionnées. En cas de problème de connexion, vérifier côté client `wg show` (un `latest handshake: (none)` indique que le serveur n'est pas joignable) puis les règles de pare-feu sur le port UDP 51820.

## Contribuer

- Flux Gitflow : `main` (production) et `develop` (intégration) sont protégées, on y accède par pull request uniquement.
- Branches de travail : `feature/*`, `docs/*`, `release/*`, `hotfix/*`.
- Commits au format [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`…).
- Chaque PR remplit le modèle de description et référence son issue (`Closes #N`).
- Avant d'ouvrir une PR : `make check`.
- Les décisions d'architecture sont consignées dans `docs/adr/` (modèle : `0000-modele.md`).
