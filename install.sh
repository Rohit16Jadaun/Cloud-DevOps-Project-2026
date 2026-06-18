#!/bin/bash
set -e

echo "📦 Installing Docker + Docker Compose..."
sudo apt-get update -y
sudo apt-get install -y docker.io docker-compose-plugin

echo "☁️ Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "☸️ Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "⎈ Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "🏗️ Installing Terraform (optional)..."
sudo apt-get install -y terraform

echo "✅ Done. Log out and back in for the docker group to take effect."
```
