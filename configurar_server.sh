#!/bin/bash
# Script de configuração do servidor com Docker Swarm, Traefik e Portainer
# Pergunta email do usuário para configurar o Let's Encrypt no Traefik

set -e

# ===============================
# 2️⃣ Definição do Nome do Servidor
# ===============================
SERVER_NAME="manager1"   # altere aqui se quiser outro nome
echo "[+] Definindo hostname como: $SERVER_NAME"
sudo hostnamectl set-hostname "$SERVER_NAME"

# ===============================
# 3️⃣ Configuração do /etc/hosts
# ===============================
echo "[+] Configurando /etc/hosts..."
sudo sed -i "s/^127\.0\.0\.1.*/127.0.0.1 $SERVER_NAME/" /etc/hosts

# ===============================
# Perguntar email para Traefik
# ===============================
read -p "Digite o e-mail para certificados Let's Encrypt: " USER_EMAIL

# ===============================
# 4️⃣ Instalação do Docker
# ===============================
echo "[+] Instalando Docker..."
curl -fsSL https://get.docker.com | bash

# ===============================
# 5️⃣ Inicialização do Swarm
# ===============================
echo "[+] Iniciando Docker Swarm..."
sudo docker swarm init || true

# ===============================
# 6️⃣ Criação da Rede
# ===============================
echo "[+] Criando rede overlay network_public..."
sudo docker network create --driver=overlay network_public || true

# ===============================
# 7️⃣ Criação do arquivo traefik.yaml
# ===============================
echo "[+] Gerando arquivo traefik.yaml com e-mail: $USER_EMAIL"
cat <<EOF | sudo tee traefik.yaml > /dev/null
version: "3.7"

services:

  traefik:
    image: traefik:2.11.2
    command:
      - "--api.dashboard=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.endpoint=unix:///var/run/docker.sock"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=network_public"
      - "--entrypoints.web.address=:8888"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--entrypoints.websecure.address=:8443"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencryptresolver.acme.email=${USER_EMAIL}"
      - "--certificatesresolvers.letsencryptresolver.acme.storage=/etc/traefik/letsencrypt/acme.json"
      - "--log.level=DEBUG"
      - "--log.format=common"
      - "--log.filePath=/var/log/traefik/traefik.log"
      - "--accesslog=true"
      - "--accesslog.filepath=/var/log/traefik/access-log"
    deploy:
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.middlewares.redirect-https.redirectscheme.scheme=https"
        - "traefik.http.middlewares.redirect-https.redirectscheme.permanent=true"
        - "traefik.http.routers.http-catchall.rule=hostregexp(\`{host:.+}\`)"
        - "traefik.http.routers.http-catchall.entrypoints=web"
        - "traefik.http.routers.http-catchall.middlewares=redirect-https@docker"
        - "traefik.http.routers.http-catchall.priority=1"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "vol_certificates:/etc/traefik/letsencrypt"
    ports:
      - target: 8888
        published: 8888
        mode: host
      - target: 8443
        published: 8443
        mode: host
    networks:
      - network_public

volumes:

  vol_shared:
    external: true
    name: volume_swarm_shared
  vol_certificates:
    external: true
    name: volume_swarm_certificates

networks:
  network_public:
    external: true
    name: network_public
EOF

# ===============================
# 8️⃣ Implantação do Stack
# ===============================
echo "[+] Implantando stack Traefik..."
sudo docker stack deploy --prune --resolve-image always -c traefik.yaml traefik

# ===============================
# 9️⃣ Instalação do Portainer
# ===============================
echo "[+] Instalando Portainer..."
sudo docker run -d \
  -p 9000:9000 \
  --name portainer \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo "[✔] Configuração concluída com sucesso!"
echo "Traefik rodando (porta 8888/8443) e Portainer disponível em http://SEU_IP:9000"
