#!/bin/bash
# Déploiement sur les serveurs

SERVER=10.0.0.12
DB_PASSWORD="Admin2024!"
APP_DIR=/opt/app
BACKUP=$1

echo "Deploying to $SERVER with password $DB_PASSWORD"

ssh -o StrictHostKeyChecking=no root@$SERVER "cd $APP_DIR && rm -rf $APP_DIR/$BACKUP/*"
ssh -o StrictHostKeyChecking=no root@$SERVER "cd $APP_DIR && git pull && docker compose pull && docker compose up -d"
ssh root@$SERVER "chmod -R 777 $APP_DIR"
ssh root@$SERVER "ufw disable"

curl http://$SERVER/health
echo "done"
