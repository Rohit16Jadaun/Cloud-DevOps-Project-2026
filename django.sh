
Now below is the second .sh file that will create a django project on your machine
Create a file named django.sh, paste all the code in it, and save it.
Make it executable by doing chmod +x django.sh
Run it with ./django.sh

#!/usr/bin/env bash
set -euo pipefail

# ---- Config ----
PROJECT_NAME="${PROJECT_NAME:-proj}"
APP_NAME="${APP_NAME:-app}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
DJANGO_VERSION="${DJANGO_VERSION:-4.2}"
VENV_DIR="${VENV_DIR:-venv}"
REQUIREMENTS_FILE="${REQUIREMENTS_FILE:-requirements.txt}"
OVERWRITE_FILES="${OVERWRITE_FILES:-false}"   # set to "true" to overwrite Docker files

echo "==> Using:"
echo "    PROJECT_NAME=${PROJECT_NAME}"
echo "    APP_NAME=${APP_NAME}"
echo "    PYTHON_BIN=${PYTHON_BIN}"
echo "    DJANGO_VERSION=${DJANGO_VERSION}"
echo "    VENV_DIR=${VENV_DIR}"
echo "    REQUIREMENTS_FILE=${REQUIREMENTS_FILE}"
echo "    OVERWRITE_FILES=${OVERWRITE_FILES}"
echo

# ---- Checks ----
command -v "${PYTHON_BIN}" >/dev/null 2>&1 || { echo "ERROR: ${PYTHON_BIN} not found."; exit 1; }

# ---- Create & activate venv ----
if [ ! -d "${VENV_DIR}" ]; then
  echo "==> Creating virtualenv: ${VENV_DIR}"
  "${PYTHON_BIN}" -m venv "${VENV_DIR}"
fi

echo "==> Activating virtualenv"
# shellcheck disable=SC1090
source "${VENV_DIR}/bin/activate"

# ---- Upgrade pip ----
python -m pip install --upgrade pip wheel setuptools

# ---- Create requirements.txt if not exists ----
if [ ! -f "${REQUIREMENTS_FILE}" ]; then
  echo "==> Creating ${REQUIREMENTS_FILE}"
  cat > "${REQUIREMENTS_FILE}" <<EOF
asgiref==3.8.1
Django==4.2
sqlparse==0.5.3
typing_extensions==4.14.0
django-prometheus==2.2.0
psycopg2-binary==2.9.9
requests
Pillow
azure-storage-blob
django-storages
EOF
fi

# ---- Install requirements ----
echo "==> Installing from ${REQUIREMENTS_FILE}"
pip install -r "${REQUIREMENTS_FILE}"

# ---- Start project ----
if [ ! -f "manage.py" ]; then
  echo "==> Creating Django project: ${PROJECT_NAME}"
  django-admin startproject "${PROJECT_NAME}" .
else
  echo "==> manage.py exists; skipping startproject."
fi

# ---- Create app ----
if [ ! -d "${APP_NAME}" ]; then
  echo "==> Creating Django app: ${APP_NAME}"
  python manage.py startapp "${APP_NAME}"
else
  echo "==> App '${APP_NAME}' already exists; skipping startapp."
fi

# ---- Ensure app/views.py has a 'first' view ----
VIEWS_FILE="${APP_NAME}/views.py"
if ! grep -q "^def first(" "${VIEWS_FILE}" 2>/dev/null; then
  echo "==> Adding 'first' view to ${VIEWS_FILE}"
  cat >> "${VIEWS_FILE}" <<'EOF'

from django.http import HttpResponse

def first(request):
    return HttpResponse("Hello from DjProd! 🚀")
EOF
else
  echo "==> 'first' view already present; skipping."
fi

# ---- Create app/urls.py ----
APP_URLS_FILE="${APP_NAME}/urls.py"
if [ ! -f "${APP_URLS_FILE}" ]; then
  echo "==> Creating ${APP_URLS_FILE}"
  cat > "${APP_URLS_FILE}" <<EOF
from django.urls import path
from .views import first

urlpatterns = [
    path('', first, name='first')
]
EOF
else
  echo "==> ${APP_URLS_FILE} already exists; leaving as-is."
fi

# ---- Replace project urls.py ----
PROJECT_URLS_FILE="${PROJECT_NAME}/urls.py"
echo "==> Writing ${PROJECT_URLS_FILE}"
cat > "${PROJECT_URLS_FILE}" <<EOF
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('${APP_NAME}.urls')),
]
EOF

# -----------------------------
# Docker bits (create if missing; overwrite with OVERWRITE_FILES=true)
# -----------------------------

write_file() {
  local path="$1"
  local content="$2"
  if [ -f "$path" ] && [ "${OVERWRITE_FILES}" != "true" ]; then
    echo "==> $path exists; skipping (set OVERWRITE_FILES=true to overwrite)."
  else
    echo "==> Writing $path"
    printf "%s" "$content" > "$path"
  fi
}

# docker-compose.yml (using your provided content)
compose_content=$(cat <<'YAML'
version: '3.9'

services:
  web:
    build: .
    container_name: devtoprod_web
    ports:
      - "8000:8000"
    volumes:
      - .:/app
YAML
)
write_file "docker-compose.yml" "$compose_content"

# Dockerfile (sane default; adjust if your attached Dockerfile differs)
dockerfile_content=$(cat <<'DOCKER'
FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip install --upgrade pip

# Use your local requirements
COPY requirements.txt /app/requirements.txt
RUN pip install -r /app/requirements.txt

# Copy project
COPY . /app

# Ensure entrypoint is executable inside image
RUN chmod +x /app/entrypoint.sh || true

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
DOCKER
)
write_file "Dockerfile" "$dockerfile_content"

# entrypoint.sh (minimal dev entrypoint)
entrypoint_content=$(cat <<'SH'
#!/usr/bin/env sh
set -e

# Apply migrations (sqlite by default)
python manage.py migrate --noinput

# Hand off to the CMD (runserver by default)
exec "$@"
SH
)
write_file "entrypoint.sh" "$entrypoint_content"
chmod +x entrypoint.sh || true

# ---- Create .dockerignore ----
if [ -f ".dockerignore" ] && [ "${OVERWRITE_FILES:-false}" != "true" ]; then
  echo "==> .dockerignore exists; skipping (set OVERWRITE_FILES=true to overwrite)."
else
  echo "==> Writing .dockerignore"
  cat > .dockerignore <<'EOF'
venv
__pycache__/
*.pyc
*.log
.git
.gitignore
.DS_Store
EOF
fi

# ---- Migrations ----
echo "==> Running makemigrations & migrate"
python manage.py makemigrations
python manage.py migrate

echo
echo "✅ Done!"
echo "You're in the venv. Start the dev server directly with:"
echo "  python manage.py runserver 0.0.0.0:8000"
echo
echo "…or build & run via Docker:"
echo "  docker compose build"
echo "  docker compose up"


