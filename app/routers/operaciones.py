"""Ruta /api/operaciones: resumen de abonos por medio de pago."""
from fastapi import APIRouter, Query

from app import consultas
from app.database import DatabaseError, ejecutar_consulta
from app.respuestas import respuesta_error, respuesta_ok

router = APIRouter(prefix="/api/operaciones", tags=["Operaciones"])


@router.get("/resumen-dinamico")
def resumen_dinamico(
    min_operaciones: int = Query(2, ge=1, description="Mínimo de abonos que debe tener cada medio de pago"),
):
    """Abonos por medio de pago, solo los que tienen N abonos o más y un promedio
    mayor que el precio del repuesto más barato."""
    endpoint = "/api/operaciones/resumen-dinamico"
    try:
        # min_operaciones va en la tupla y PyMySQL lo pone en el %s.
        filas = ejecutar_consulta(consultas.SQL_RESUMEN_DINAMICO, (min_operaciones,))
    except DatabaseError as exc:
        return respuesta_error(500, endpoint, str(exc))
    except Exception as exc:
        return respuesta_error(500, endpoint, f"Error interno: {exc}")
    return respuesta_ok(
        endpoint,
        "Medios de pago con al menos N abonos y promedio mayor que el repuesto más barato.",
        filas,
        {"min_operaciones": min_operaciones},
    )
