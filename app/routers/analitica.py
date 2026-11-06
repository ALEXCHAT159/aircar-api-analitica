"""Rutas /api/analitica: analítica de clientes."""
from fastapi import APIRouter

from app import consultas
from app.database import DatabaseError, ejecutar_consulta
from app.respuestas import respuesta_error, respuesta_ok

router = APIRouter(prefix="/api/analitica", tags=["Analítica de clientes"])


@router.get("/actores-estrella")
def actores_estrella():
    """Clientes que han facturado más que el cliente promedio."""
    endpoint = "/api/analitica/actores-estrella"
    try:
        filas = ejecutar_consulta(consultas.SQL_ACTORES_ESTRELLA)
    except DatabaseError as exc:
        return respuesta_error(500, endpoint, str(exc))
    except Exception as exc:  # cualquier otro error también sale como 500
        return respuesta_error(500, endpoint, f"Error interno: {exc}")
    return respuesta_ok(endpoint, "Clientes que han facturado más que el cliente promedio.", filas)
