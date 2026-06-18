# 🚀 The Complete Django DevOps Pipeline — Azure Edition

*From a single commit to a self-healing, auto-scaling, fully observable production system — running entirely on Azure.*

## Table of Contents

- [Phase 1: Development](#phase-1-development)
- [Phase 2: CI Pipeline](#phase-2-ci-pipeline)
- [Phase 3: GitOps](#phase-3-gitops)
- [Phase 4: Kubernetes](#phase-4-kubernetes)
- [Phase 5: Monitoring](#phase-5-monitoring)
- [Phase 6: Logging](#phase-6-logging)
- [Phase 7: Alerting](#phase-7-alerting)
- [Phase 8: Security](#phase-8-security)
- [Phase 9: Auto Scaling](#phase-9-auto-scaling)
- [Phase 10: Production Features](#phase-10-production-features)
- [🛠️ Build & Run This Yourself](#️-build--run-this-yourself)

---

## Project Flow

### Phase 1: Development

Developer writes Django code.

```
Developer
    ↓
Bitbucket/Github/Gitlab
```

Repository contains:

```
.
├── app
├── Dockerfile
├── k8s
├── manifests
├── argocd
├── azure-pipelines.yml
└── README.md
```

---

### Phase 2: CI Pipeline

Pipeline triggers automatically after commit.

```
Git Push
   ↓
Azure DevOps Pipeline
```

Pipeline stages:

**Stage 1 — Code Quality Check**

```
SonarQube
```

Checks:

- Bugs
- Vulnerabilities
- Code smells
- Duplications

**Stage 2 — Security Scan**

```
Trivy
```

Scans:

- Docker image
- Dependencies
- CVEs

**Stage 3 — Unit Tests**

```
pytest
```

**Stage 4 — Docker Build**

```
docker build -t django-app:v1 .
```

**Stage 5 — Push Image**

```
docker push acr.azurecr.io/django-app:v1
```

---

### Phase 3: GitOps

Instead of:

```
kubectl apply -f deployment.yaml
```

we use:

```
ArgoCD
```

Flow:

```
ACR
  ↓
Manifest Update
  ↓
Git Repository
  ↓
ArgoCD
  ↓
AKS
```

Benefits:

- Rollback
- Audit trail
- Self-healing
- Drift detection

---

### Phase 4: Kubernetes

AKS runs:

```
Deployment
Service
Ingress
ConfigMaps
Secrets
```

Example:

```
AKS
 ├── Django Pod 1
 ├── Django Pod 2
 └── Django Pod 3
```

---

### Phase 5: Monitoring

**Prometheus**

Collects metrics:

```
CPU
Memory
Network
Pod Status
Request Rate
Response Time
```

**Grafana**

Dashboards:

Infrastructure Dashboard

```
Node CPU
Node Memory
Disk Usage
```

Application Dashboard

```
Request Count
Latency
Errors
Availability
```

Kubernetes Dashboard

```
Pods
Deployments
Namespaces
Ingress
```

---

### Phase 6: Logging

**Fluent Bit**

Collects logs from pods:

```
AKS Pods
   ↓
Fluent Bit
```

**Elasticsearch**

Stores logs:

```
Logs
   ↓
Indexing
```

**Kibana**

Visualizes logs. Search:

```
ERROR
WARN
Timeout
500
```

---

### Phase 7: Alerting

**AlertManager**

Alert examples:

Pod Crash

```
Pod Restart > 5
```

Alert:

```
AKS Pod Restarting Frequently
```

High CPU

```
CPU > 80%
```

Memory Leak

```
Memory > 90%
```

Website Down

```
HTTP 500
```

Certificate Expiry

```
SSL expires in 15 days
```

Notifications:

```
Teams
Slack
Email
```

---

### Phase 8: Security

**Azure Key Vault**

Stores:

```
Database Password
API Keys
Certificates
Secrets
```

No hardcoded passwords.

---

### Phase 9: Auto Scaling

**Horizontal Pod Autoscaler**

```
CPU > 70%
```

Scale:

```
3 Pods
↓
10 Pods
```

Automatically.

---

### Phase 10: Production Features

**Blue-Green Deployment**

```
Blue Version
Green Version
Switch Traffic
```

**Canary Deployment**

```
5%
20%
50%
100%
```

Traffic rollout.

**Backup**

Store:

```
Database Backup
Kubernetes Manifests
Persistent Volumes
```

---

That's the full loop: one `git push` triggers quality gates, security scans, and tests, builds and ships a container, and hands off to GitOps for a self-healing rollout on AKS — with monitoring, logging, alerting, secrets management, autoscaling, and progressive delivery already wired in.

---

**## 🛠️ Build & Run This Yourself**

The phases above are the big picture. This is the part that actually gets a Django app running on Azure Kubernetes Service, with your own domain and HTTPS — start to finish, no skipped steps. End to end it takes 45–60 minutes, mostly spent waiting on cloud resources to provision.

### What you'll need

- An Azure subscription (the free tier covers everything here)
- A domain name registered anywhere — GoDaddy, Namecheap, doesn't matter (this guide uses `yourdomain.com` as a placeholder, swap in your own)
- A Bitbucket or GitHub account for the code repo
- Docker, kubectl, and the Azure CLI — or just run the bootstrap script below and skip the manual installs

### 1️⃣ Bootstrap your machine

Save as `install.sh` and run once on a fresh Ubuntu box or your local dev machine:

```bash
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

```bash
chmod +x install.sh
./install.sh
sudo usermod -aG docker $USER
newgrp docker
```

### 2️⃣ Scaffold the Django app

```bash
django-admin startproject djprod .
python manage.py startapp app
```

`Dockerfile`:

```dockerfile
FROM python:3.12-slim
WORKDIR /code
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

`docker-compose.yml`:

```yaml
services:
  web:
    build: .
    ports:
      - "8000:8000"
```

Two small but easy-to-miss tweaks in `settings.py`:

- Add `"app"` to `INSTALLED_APPS`
- Set `ALLOWED_HOSTS = ["*"]`

Then verify it locally:

```bash
docker compose build
docker compose up
```

Open `http://localhost:8000`. If you see your Django landing page, the app and Docker setup both work — everything from here is about getting this exact container running on Azure instead of your laptop.

### 3️⃣ Push the code to Bitbucket/Github/Gitlab

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://<your-username>@bitbucket.org/<your-username>/djprod.git
git push origin main
```

### 4️⃣ Point your terminal at Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
az group create --name djprod-rg --location centralindia
```

That resource group holds every Azure resource this project creates — registry, cluster, DNS zone, all of it. One resource group means teardown later is a single command instead of a checklist.

### 5️⃣ Build the image and push it to Azure Container Registry (ECR)

```bash
az acr create --resource-group djprod-rg --name djprodacr --sku Basic
az acr login --name djprodacr

docker build -t django-app .
docker tag django-app djprodacr.azurecr.io/django-app:v1
docker push djprodacr.azurecr.io/django-app:v1
```

Your image now lives in Azure, pullable by anything you point at it.

### 6️⃣ Spin up the Kubernetes cluster (AKS)

This is where a managed service pays off. No separate state-storage bucket, no control-plane node to provision by hand, no taints to patch just so system pods can schedule — AKS's control plane is fully managed, and one flag wires up registry access for you:

```bash
az aks create \
  --resource-group djprod-rg \
  --name djprod-aks \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --attach-acr djprodacr \
  --generate-ssh-keys
```

Connect kubectl to it:

```bash
az aks get-credentials --resource-group djprod-rg --name djprod-aks
kubectl get nodes
```

You should see your node(s) as `Ready` — a live Kubernetes cluster on Azure, ready for workloads.

### 7️⃣ Point your domain at Azure

```bash
az network dns zone create --resource-group djprod-rg --name yourdomain.com
az network dns zone show --resource-group djprod-rg --name yourdomain.com --query nameServers --output tsv
```

Copy the nameservers Azure gives you, then go to wherever your domain is registered and replace its default nameservers with those. The domain stays registered where it always was — only DNS resolution moves to Azure.

Verify the change has propagated:

```bash
dig ns yourdomain.com +short
```

This can take a few minutes to a few hours depending on your registrar — good point for that coffee.

### 8️⃣ Deploy the app to the cluster

`deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: django-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: django-app
  template:
    metadata:
      labels:
        app: django-app
    spec:
      containers:
        - name: django-app
          image: djprodacr.azurecr.io/django-app:v1
          ports:
            - containerPort: 8000
```

`service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: django-app-svc
spec:
  selector:
    app: django-app
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 8000
```

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 9️⃣ Expose it with an Ingress

Install the NGINX ingress controller — the same one used on every other cloud:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml
```

Wait for Azure to hand it a public IP:

```bash
kubectl get svc -n ingress-nginx
```

Note the `EXTERNAL-IP` for `ingress-nginx-controller` — on Azure this comes back as a plain IP address rather than a load-balancer hostname. Point a subdomain at it:

```bash
az network dns record-set a add-record \
  --resource-group djprod-rg \
  --zone-name yourdomain.com \
  --record-set-name app \
  --ipv4-address <EXTERNAL-IP>
```

`ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: django-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: app.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: django-app-svc
                port:
                  number: 80
```

```bash
kubectl apply -f ingress.yaml
```

Give DNS a few minutes, then visit `http://app.yourdomain.com` — your Django app, served from inside a Kubernetes cluster, not a laptop.

### 🔒 Lock it down with HTTPS

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl get pods --namespace cert-manager
```

`cluster-issuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: you@yourdomain.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
      - http01:
          ingress:
            class: nginx
```

```bash
kubectl apply -f cluster-issuer.yaml
```

Update `ingress.yaml` to request a certificate and terminate TLS:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: django-app-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.yourdomain.com
      secretName: djprod-tls
  rules:
    - host: app.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: django-app-svc
                port:
                  number: 80
```

```bash
kubectl apply -f ingress.yaml
```

Give it a few minutes for the certificate to issue, then hit `https://app.yourdomain.com`. Padlock and all.

### 🔁 Hand deployments off to ArgoCD (GitOps)

So far you've been running `kubectl apply` by hand. From here, ArgoCD takes over — it watches a folder in your git repo and keeps the cluster matching whatever's committed there, including reverting anyone who tries to change things by hand on the cluster directly.

Install it:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Grab the auto-generated admin password and open the UI:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Visit `https://localhost:8080` and log in as `admin` with that password.

Move `deployment.yaml` and `service.yaml` into a `manifests/` folder in your repo, commit, and push to Bitbucket. Then point ArgoCD at it, `argocd-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: django-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://bitbucket.org/<your-username>/djprod.git
    targetRevision: main
    path: manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      selfHeal: true
      prune: true
```

```bash
kubectl apply -f argocd-app.yaml
```

From now on, a `git push` to `manifests/` is the only deploy step you need — ArgoCD picks it up, applies it, and quietly fixes any drift on its own.

### 📊 Add monitoring: Prometheus + Grafana

The `kube-prometheus-stack` Helm chart bundles both, plus Alertmanager, in one install:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

Open Grafana:

```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

Visit `http://localhost:3000` (default user `admin`; fetch the password with `kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d` if it's not the chart default). The node, pod, and cluster dashboards are pre-loaded — nothing else to configure.

### 📝 Add logging: Fluent Bit → Elasticsearch → Kibana

Stand up the storage and visualization layer first:

```bash
helm repo add elastic https://helm.elastic.co
helm repo update
helm install elasticsearch elastic/elasticsearch --namespace logging --create-namespace
helm install kibana elastic/kibana --namespace logging \
  --set elasticsearchHosts="https://elasticsearch-master:9200"
```

Then point Fluent Bit at it so pod logs actually start flowing in:

```bash
helm repo add fluent https://fluent.github.io/helm-charts
helm install fluent-bit fluent/fluent-bit --namespace logging \
  --set backend.type=es \
  --set backend.es.host=elasticsearch-master.logging.svc.cluster.local
```

(Exact flags can shift a little between chart versions — check `helm show values elastic/elasticsearch` if something doesn't match.)

Open Kibana:

```bash
kubectl port-forward svc/kibana-kibana -n logging 5601:5601
```

Visit `http://localhost:5601`, create an index pattern, and search for `ERROR`, `WARN`, `Timeout`, or `500` — exactly what Phase 6 above describes, now actually running.

### 🚨 Wire up alerting

Alertmanager came along for free with the `kube-prometheus-stack` install above — this step is just telling it what to watch for and where to send notifications. A starter rule for two of the alerts from Phase 7, `django-app-alerts.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: django-app-alerts
  namespace: monitoring
  labels:
    release: monitoring
spec:
  groups:
    - name: django-app.rules
      rules:
        - alert: PodRestartingFrequently
          expr: increase(kube_pod_container_status_restarts_total[15m]) > 5
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "AKS pod restarting frequently"
        - alert: HighCPUUsage
          expr: sum(rate(container_cpu_usage_seconds_total[5m])) by (pod) > 0.8
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "CPU usage above 80%"
```

```bash
kubectl apply -f django-app-alerts.yaml
```

To get notified in Teams, Slack, or by email instead of just watching the Alertmanager UI, add a receiver when you install or upgrade the chart, e.g. for Slack:

```bash
helm upgrade monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set alertmanager.config.receivers[0].name=slack \
  --set alertmanager.config.receivers[0].slack_configs[0].api_url="<your-slack-webhook-url>" \
  --set alertmanager.config.receivers[0].slack_configs[0].channel="#alerts"
```

Teams and email use the same `receivers` structure with `msteams_configs` or `email_configs` instead.

### 🧹 Tear it down

ArgoCD, Prometheus, Grafana, and the EFK stack all run inside the AKS cluster itself — nothing separate to clean up there. And since the registry, the cluster, and the DNS zone all live in `djprod-rg`, one command removes everything else:

```bash
az group delete --name djprod-rg --yes --no-wait
```

No separate cleanup of the registry, the nodes, or the DNS zone needed.

### 🏁 What you just built

```
Git push → ACR → AKS → DNS → HTTPS → ArgoCD → Prometheus/Grafana → EFK → Alertmanager
```

A real, end-to-end deployment flow — no shortcuts, no fake demo. If you can walk through this and explain why each step exists, you're already thinking like a SRE/DevOps/Cloud engineer.
