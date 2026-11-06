"""Ruta /api/items: repuestos comparados con su categoría."""
from enum import Enum

from fastapi import APIRouter, Query

from app import consultas
from app.database import DatabaseError, ejecutar_consulta
from app.respuestas import respuesta_error, respuesta_ok

router = APIRouter(prefix="/api/items", tags=["Ítems"])


class Comparacion(str, Enum):
    inferior = "inferior"
    superior = "superior"


# El parámetro no entra al SQL: solo escoge cuál de las dos consultas se corre.
SENTENCIAS = {
    Comparacion.inferior: consultas.SQL_DESVIACION_INFERIOR,
    Comparacion.superior: consultas.SQL_DESVIACION_SUPERIOR,
}


@router.get("/desviacion-grupo")
def desviacion_grupo(
    comparacion: Comparacion = Query(
        Comparacion.inferior,
        description="inferior (por defecto) o superior al promedio de su categoría",
    ),
):
    """Repuestos que se venden menos (o más) que los otros de su categoría."""
    endpoint = "/api/items/desviacion-grupo"
    try:
        filas = ejecutar_consulta(SENTENCIAS[comparacion])
    except DatabaseError as exc:
        return respuesta_error(500, endpoint, str(exc))
    except Exception as exc:
        return respuesta_error(500, endpoint, f"Error interno: {exc}")
    return respuesta_ok(
        endpoint,
        "Repuestos que venden menos unidades que el promedio de su categoría." if comparacion == Comparacion.inferior else "Repuestos que venden más unidades que el promedio de su categoría.",
        filas,
        {"comparacion": comparacion.value},
    )
