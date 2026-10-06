# ADR-0001 : Choix du reverse proxy (Nginx ou Traefik)

- **Statut** : proposé
- **Date** : 2026-10-06
- **Décideurs** : équipe infra

## Contexte

L'équipe héberge une quinzaine de services en conteneurs Docker, répartis sur deux serveurs. Un reverse proxy doit exposer ces services en HTTPS. Les contraintes sont les suivantes :

- de **nouveaux services sont ajoutés chaque mois** : chaque ajout ne doit pas demander de modifier et recharger à la main la configuration du proxy ;
- le **renouvellement des certificats TLS est fait à la main** et a déjà provoqué une coupure : il doit être automatisé ;
- l'équipe infra **connaît bien Nginx, pas Traefik** : le coût de prise en main est à prendre en compte.

Le dépôt utilise aujourd'hui Nginx (`nginx:1.27-alpine` dans `docker-compose.yml`).

## Options envisagées

### Option A : Nginx

- (+) Connu de toute l'équipe, très documenté, performant et stable.
- (+) Aucun coût de formation, aucune migration.
- (−) Chaque nouveau service impose d'écrire un bloc de configuration (`conf.d`) et de recharger Nginx, ce qui est répétitif et source d'erreurs.
- (−) Pas de gestion native des certificats : il faut ajouter Certbot et un cron. Cela reste de la configuration à maintenir et ne supprime pas le risque d'oubli ou de panne silencieuse.

### Option B : Traefik

- (+) **Découverte automatique des conteneurs Docker** via des labels : un nouveau service est exposé en le déclarant dans son `docker-compose.yml`, sans toucher au proxy.
- (+) **Certificats Let's Encrypt gérés nativement** (ACME) : émission et renouvellement automatiques, ce qui répond directement à la coupure déjà subie.
- (+) Rechargement à chaud de la configuration, tableau de bord intégré.
- (−) L'équipe ne le connaît pas : courbe d'apprentissage et risque d'erreurs de configuration au début.
- (−) Les labels répartissent la configuration dans chaque service, ce qui demande des conventions claires.
- (−) Le point de configuration central (entrypoints, resolver ACME) devient critique.

## Décision

Nous retenons **Traefik**, avec une migration progressive.

Les deux problèmes réels de l'équipe (ajout mensuel de services et renouvellement manuel des certificats) sont précisément ceux que Traefik résout nativement, alors que Nginx les laisserait en partie à la charge de l'équipe. Le manque de connaissance de Traefik est un risque réel, mais temporaire et maîtrisable par la formation et une migration par étapes ; la coupure TLS, elle, est un risque d'exploitation récurrent.

## Conséquences

### Positives

- Plus de renouvellement manuel des certificats : fin du risque de coupure liée à une expiration.
- Ajouter un service ne demande plus de modifier le proxy.
- Configuration plus homogène entre les deux serveurs.

### Négatives / risques

- Période d'apprentissage : risque d'erreur de configuration au début.
- Dépendance à Let's Encrypt (limites de taux, nécessité d'un port 80/443 joignable pour le challenge).
- Migration à planifier pour une quinzaine de services : risque de régression pendant la bascule.
- Le `docker-compose.yml` actuel (Nginx) devra être modifié ; le README sera à mettre à jour après la migration.

### Atténuations

- Former l'équipe (documentation officielle, atelier interne) avant la bascule.
- Migrer d'abord un service peu critique sur un serveur, en gardant Nginx en parallèle, puis étendre.
- Prévoir un retour arrière : conserver la configuration Nginx dans l'historique Git.
- Surveiller l'expiration des certificats (alerte à J-14).

## Suivi

- Mettre en place un pilote Traefik sur un service non critique.
- Réévaluer cette décision après la migration des premiers services, dans environ trois mois.
- Mettre à jour `docker-compose.yml`, le README et `AGENTS.md` quand la migration est effective.
