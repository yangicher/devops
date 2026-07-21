#!/bin/bash

set -e

echo "Оновлення списку пакетів..."
sudo apt-get update -y

echo "========================================"

INSTALL_PYTHON=false
if command -v python3 &>/dev/null; then
    PY_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
    PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
    
    if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 9 ]; then
        echo "[OK] Встановлено Python версії $PY_MAJOR.$PY_MINOR (задовольняє вимогу 3.9+)"
    else
        echo "[WARN] Поточна версія Python $PY_MAJOR.$PY_MINOR застаріла. Потрібна 3.9+"
        INSTALL_PYTHON=true
    fi
else
    echo "[WARN] Python не знайдено."
    INSTALL_PYTHON=true
fi

if [ "$INSTALL_PYTHON" = true ]; then
    echo "[INSTALL] Встановлення Python 3..."
    sudo apt-get install -y python3 python3-pip
fi

if ! command -v pip3 &>/dev/null && ! python3 -m pip --version &>/dev/null; then
    echo "[INSTALL] Встановлення pip..."
    sudo apt-get install -y python3-pip
else
    echo "[OK] pip вже встановлено."
fi

if command -v docker &>/dev/null; then
    echo "[OK] Docker вже встановлено: $(docker --version)"
else
    echo "[INSTALL] Налаштування репозиторію та встановлення офіційного Docker CE..."
    
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
        sudo apt-get remove -y $pkg || true
    done

    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      
    sudo apt-get update -y
    
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    sudo systemctl start docker
    sudo systemctl enable docker
fi

if docker compose version &>/dev/null; then
    echo "[OK] Docker Compose встановлено: $(docker compose version)"
else
    echo "[INSTALL] Встановлення Docker Compose..."
    sudo apt-get install -y docker-compose-plugin
fi

if python3 -m django --version &>/dev/null; then
    echo "[OK] Django вже встановлено: $(python3 -m django --version)"
else
    echo "[INSTALL] Встановлення Django через pip..."
    python3 -m pip install django --user || python3 -m pip install django --break-system-packages
fi

echo "========================================"
echo "Всі інструменти успішно перевірені та встановлені!"