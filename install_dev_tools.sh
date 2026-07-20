#!/bin/bash

set -e

echo "Оновлення списку пакетів..."
sudo apt-get update -y

echo "========================================"

if command -v python3 &>/dev/null; then
    echo "[OK] Python 3 вже встановлено: $(python3 --version)"
else
    echo "[INSTALL] Встановлення Python 3 та pip..."
    sudo apt-get install -y python3 python3-pip
fi

if command -v docker &>/dev/null; then
    echo "[OK] Docker вже встановлено: $(docker --version)"
else
    echo "[INSTALL] Встановлення Docker..."
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
fi

if command -v docker-compose &>/dev/null || docker compose version &>/dev/null; then
    echo "[OK] Docker Compose вже встановлено."
else
    echo "[INSTALL] Встановлення Docker Compose..."
    sudo apt-get install -y docker-compose
fi

if python3 -m django --version &>/dev/null; then
    echo "[OK] Django вже встановлено: $(python3 -m django --version)"
else
    echo "[INSTALL] Встановлення Django..."
    python3 -m pip install django --user || python3 -m pip install django --break-system-packages
fi

echo "========================================"
echo "Всі інструменти успішно перевірені та встановлені!"