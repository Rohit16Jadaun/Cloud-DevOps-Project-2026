#!/bin/bash
set -e

echo "------------------------------------"
echo "Installing prerequisites"
echo "------------------------------------"
sudo apt-get update
sudo apt-get install -y unzip curl gnupg lsb-release ca-certificates python3-venv python3-pip build-essential libpq-dev

# ---------------------
# Azure CLI
# ---------------------
echo "Installing Azure CLI"
if ! command -v az >/dev/null 2>&1; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
else
  echo "Updating existing Azure CLI..."
  sudo apt-get update && sudo apt-get install --only-upgrade -y azure-cli
fi
az version

# ---------------------
# kubectl
# ---------------------
echo "Installing kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# ---------------------
# Terraform
# ---------------------
echo "Installing Terraform"
if ! command -v terraform >/dev/null 2>&1; then
  TF_VER="1.9.5"
  curl -fsSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip"
  sudo unzip -o /tmp/terraform.zip -d /usr/local/bin
  rm -f /tmp/terraform.zip
fi
terraform -version

# ---------------------
# Helm
# ---------------------
echo "Installing Helm"
if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
helm version

# ---------------------
# Docker + Compose (last)
# ---------------------
echo "Installing Docker Engine and Compose"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
echo "⚠️ Log out and back in (or run 'newgrp docker') for group changes to take effect."
docker --version || echo "Docker will work after re-login."
docker compose version || echo "Docker Compose will work after re-login."

echo "-------------------------"
echo "✅✅ All tools installed successfully ✅✅"
echo "-------------------------"
#END
