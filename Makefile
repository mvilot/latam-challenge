# Configuración de Cloud Run
PROJECT_ID = latam-challenge-2025
IMAGE_NAME = flight-delay-api
REGION = us-central1
API_URL = https://flight-delay-api-vbub4dnmdq-uc.a.run.app  # <<< TU URL AQUÍ

# Comandos principales
.PHONY: deploy test all

deploy:
    @echo "Desplegando la API..."
    gcloud run deploy $(IMAGE_NAME) \
        --image gcr.io/$(PROJECT_ID)/$(IMAGE_NAME) \
        --platform managed \
        --region $(REGION) \
        --allow-unauthenticated \
        --memory 512Mi \
        --timeout 300

test:
    @echo "Ejecutando TODAS las pruebas..."
    python -m pytest tests/ -v

stress-test:
    @echo "Ejecutando prueba de estrés con Locust..."
    locust -f tests/stress_test.py --host=$(API_URL) --users 100 --spawn-rate 10

# Monitoreo
logs:
    gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$(IMAGE_NAME)" --limit 100

# Utilidades
clean:
    @echo "Limpiando recursos..."
    docker system prune -f
