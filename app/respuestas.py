"""Arma el JSON de respuesta. Todos los endpoints responden con los mismos campos."""
from datetime import date, datetime
from decimal import Decimal

from fastapi.responses import JSONResponse


def _a_json(valor):
    """JSON no acepta Decimal ni date, así que se convierten aquí."""
    if isinstance(valor, Decimal):
        # SUM/COUNT de enteros llegan como Decimal sin decimales -> int
        return int(valor) if valor == valor.to_integral_value() and valor.as_tuple().exponent >= 0 else float(valor)
    if isinstance(valor, (date, datetime)):
        return valor.isoformat()
    return valor


def respuesta_ok(endpoint, descripcion, filas, parametros=None):
    """200 con datos, o 404 si la consulta no devolvió registros."""
    datos = [{k: _a_json(v) for k, v in fila.items()} for fila in filas]
    if not datos:
        return respuesta_error(404, endpoint, "La consulta no devolvió registros.")
    return JSONResponse(status_code=200, content={
        "estado": "ok",
        "codigo": 200,
        "endpoint": endpoint,
        "descripcion": descripcion,
        "parametros": parametros or {},
        "total_registros": len(datos),
        "datos": datos,
    })


def respuesta_error(codigo, endpoint, mensaje):
    """Respuesta de error con la misma estructura (400, 404, 500)."""
    return JSONResponse(status_code=codigo, content={
        "estado": "error",
        "codigo": codigo,
        "endpoint": endpoint,
        "mensaje": mensaje,
        "total_registros": 0,
        "datos": [],
    })
