#!/bin/bash
# Master script: baixa os outros .sh e dá permissão

set -e

# URL base do GitHub (substitua pelo seu repositório)
BASE_URL="https://raw.githubusercontent.com/JrMCZ2023/config_vps/main"

# Lista de scripts que o master deve baixar
FILES=(
  "instalar_aapanel.sh"
  "configurar_server.sh"
)

for file in "${FILES[@]}"; do
  echo "[+] Baixando $file..."
  wget -q "$BASE_URL/$file" -O "$file"
  chmod +x "$file"
done

echo "[✔] Todos os scripts foram baixados e preparados!"
echo ""
echo "Agora você pode rodar:"
echo "   ./instalar_aapanel.sh"
echo "   ./configurar_server.sh"
