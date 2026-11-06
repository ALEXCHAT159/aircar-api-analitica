"""Punto de entrada de la API REST de analítica de AirCar Manager.

Ejecutar:  uvicorn app.main:app --reload
Docs:      http://127.0.0.1:8000/docs
"""
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.respuestas import respuesta_error
from app.routers import analitica, items, operaciones, reportes, segmentos

app = FastAPI(
    title="AirCar Manager - API de Analítica",
    description="5 endpoints de analítica sobre la base aircar_manager (SQL nativo, sin ORM).",
    version="1.0.0",
)

app.include_router(reportes.router)
app.include_router(analitica.router)
app.include_router(items.router)
app.include_router(segmentos.router)
app.include_router(operaciones.router)


@app.get("/", tags=["Inicio"])
def inicio():
    return {
        "api": "AirCar Manager - Analítica",
        "endpoints": [
            "/api/reportes/clasificacion-top",
            "/api/analitica/actores-estrella",
            "/api/items/desviacion-grupo?comparacion=inferior",
            "/api/segmentos/analisis-limpio",
            "/api/operaciones/resumen-dinamico?min_operaciones=2",
        ],
    }


@app.exception_handler(StarletteHTTPException)
async def manejar_http(request: Request, exc: StarletteHTTPException):
    """Rutas inexistentes (404) con el mismo formato JSON."""
    mensaje = "Recurso no encontrado." if exc.status_code == 404 else str(exc.detail)
    return respuesta_error(exc.status_code, request.url.path, mensaje)


@app.exception_handler(RequestValidationError)
async def manejar_validacion(request: Request, exc: RequestValidationError):
    """Parámetros inválidos (ej. min_operaciones=abc o 0) -> 400."""
    detalle = "; ".join(f"{'.'.join(map(str, e['loc']))}: {e['msg']}" for e in exc.errors())
    return respuesta_error(400, request.url.path, f"Parámetro inválido. {detalle}")


@app.exception_handler(Exception)
async def manejar_general(request: Request, exc: Exception):
    """Cualquier error no controlado -> 500."""
    return respuesta_error(500, request.url.path, "Error interno del servidor.")
