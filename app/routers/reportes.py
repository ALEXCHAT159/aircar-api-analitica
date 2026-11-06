"""Rutas /api/reportes: reportes por catálogo."""
from fastapi import APIRouter

from app import consultas
from app.database import DatabaseError, ejecutar_consulta
from app.respuestas import respuesta_error, respuesta_ok

router = APIRouter(prefix="/api/reportes", tags=["Reportes por catálogo"])


@router.get("/clasificacion-top")
def clasificacion_top():
    """Categorías de repuestos que venden más por línea que el promedio de todas las líneas."""
    endpoint = "/api/reportes/clasificacion-top"
    try:
        filas = ejecutar_consulta(consultas.SQL_CLASIFICACION_TOP)
    except DatabaseError as exc:
        return respuesta_error(500, endpoint, str(exc))
    except Exception as exc:  # cualquier otro error también sale como 500
        return respuesta_error(500, endpoint, f"Error interno: {exc}")
    return respuesta_ok(endpoint, "Categorías de repuestos que venden más por línea que el promedio de todas las líneas.", filas)
