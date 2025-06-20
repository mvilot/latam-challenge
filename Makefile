# Makefile para LATAM Flight Delay Challenge

# Variables
PROJECT_ID = 283882932517
API_URL = https://flight-delay-api-xyz-uc.a.run.app  # Reemplazar con tu URL real
IMAGE_NAME = gcr.io/$(PROJECT_ID)/flight-delay-api
REGION = us-central1

# Tests del modelo
model-test:
	python -m pytest tests/model -v

# Tests de la API
api-test:
	python -m pytest tests/api -v

# Tests de estrés (requiere API desplegada)
stress-test:
	locust -f tests/stress/test_stress.py --headless -u 100 -r 10 -t 1m --host $(API_URL)

# Construir imagen Docker
build:
	docker build -t $(IMAGE_NAME) .

# Subir imagen a GCR
push:
	gcloud builds submit --tag $(IMAGE_NAME)

# Desplegar en Cloud Run
deploy:
	gcloud run deploy flight-delay-api \
		--image $(IMAGE_NAME) \
		--platform managed \
		--region $(REGION) \
		--allow-unauthenticated \
		--port 8000

# Ejecutar API localmente
run-local:
	docker run -p 8000:8000 $(IMAGE_NAME)

# Comandos combinados
deploy-full: build push deploy

# Instalar dependencias
install:
	pip install -r requirements.txt

.PHONY: model-test api-test stress-test build push deploy run-local deploy-full install
