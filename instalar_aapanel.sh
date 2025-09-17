#!/bin/bash
# Script de instalação não-interativa do aaPanel com AppArmor habilitado
# Todas as perguntas são respondidas automaticamente com "yes"

set -e  # interrompe se houver erro

echo "[+] Atualizando pacotes e instalando dependências..."
sudo apt-get update -y
sudo apt-get install -y apparmor-utils curl wget

URL="https://www.aapanel.com/script/install_7.0_en.sh"

echo "[+] Baixando script de instalação do aaPanel..."
if command -v curl >/dev/null 2>&1; then
    curl -ksSO "$URL"
else
    wget --no-check-certificate -O install_7.0_en.sh "$URL"
fi

chmod +x install_7.0_en.sh

echo "[+] Instalando aaPanel (modo totalmente automático)..."
yes | bash install_7.0_en.sh aapanel

echo "[✔] Instalação concluída com sucesso!"
