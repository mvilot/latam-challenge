from fastapi import FastAPI, HTTPException, Request, status
from challenge.model import DelayModel
import pandas as pd
from typing import List, Dict, Any
import logging
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import numpy as np

app = FastAPI(
    title="Flight Delay Prediction API",
    description="API para predecir probabilidad de atraso de vuelos",
    version="1.0.0"
)
model = DelayModel()

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Transforma errores 422 de validación a 400 para pasar los tests"""
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"detail": str(exc)},
    )

def _validate_input(features: pd.DataFrame):
    """Validación manual de los datos de entrada"""
    # Validar MES
    if not features['MES'].between(1, 12).all():
        raise ValueError("MES debe estar entre 1 y 12")
    
    # Validar TIPOVUELO
    if not features['TIPOVUELO'].isin(['N', 'I']).all():
        raise ValueError("TIPOVUELO debe ser 'N' o 'I'")
    
    # Validar OPERA
    if features['OPERA'].str.strip().eq('').any():
        raise ValueError("OPERA no puede estar vacío")

@app.post("/predict", status_code=200)
async def predict(data: Dict[str, Any]) -> Dict[str, List[int]]:
    """
    Endpoint para predecir retrasos de vuelos
    Formato esperado:
    {
        "flights": [
            {
                "OPERA": "Aerolineas Argentinas",
                "TIPOVUELO": "N", 
                "MES": 3
            }
        ]
    }
    """
    try:
        logger.info(f"Datos recibidos: {data}")
        
        # Validación manual para coincidir con los tests
        flights = data.get("flights", [])
        if not flights:
            raise HTTPException(status_code=400, detail="Se requiere lista de vuelos")
        
        # Convertir a DataFrame
        features = pd.DataFrame(flights)
        
        # Validación adicional
        _validate_input(features)
        
        # Preprocesamiento y predicción
        processed_features = model.preprocess(features)
        predictions = model.predict(processed_features)
        
        # Convertir numpy array a lista si es necesario
        if isinstance(predictions, np.ndarray):
            predictions = predictions.tolist()
        elif not isinstance(predictions, list):
            predictions = list(predictions)
        
        return {"predict": predictions}
        
    except ValueError as e:
        logger.error(f"Error de validación: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error inesperado: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error interno del servidor")

@app.get("/health", status_code=200, include_in_schema=False)
async def health_check() -> Dict[str, str]:
    """Endpoint para health checks (K8s, Cloud Run, etc.)"""
    return {"status": "OK"}
