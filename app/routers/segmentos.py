"""Rutas /api/segmentos: segmentos."""
from fastapi import APIRouter

from app import consultas
from app.database import DatabaseError, ejecutar_consulta
from app.respuestas import respuesta_error, respuesta_ok

router = APIRouter(prefix="/api/segmentos", tags=["Segmentos"])


@router.get("/analisis-limpio")
def analisis_limpio():
    """Lo facturado por tipo de vehículo sin contar clientes con créditos vencidos."""
    endpoint = "/api/segmentos/analisis-limpio"
    try:
        filas = ejecutar_consulta(consultas.SQL_ANALISIS_LIMPIO)
    except DatabaseError as exc:
        return respuesta_error(500, endpoint, str(exc))
    except Exception as exc:  # cualquier otro error también sale como 500
        return respuesta_error(500, endpoint, f"Error interno: {exc}")
    return respuesta_ok(endpoint, "Lo facturado por tipo de vehículo sin contar clientes con créditos vencidos.", filas)
