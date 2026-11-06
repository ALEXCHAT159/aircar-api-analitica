"""Conexión a MariaDB con PyMySQL.

Aquí no hay ORM: las consultas se mandan tal cual con cursor.execute(sql, parametros).
"""
from contextlib import contextmanager

import pymysql
from pymysql.cursors import DictCursor

from app.config import DB_CONFIG


class DatabaseError(Exception):
    """Error al conectar o al ejecutar una consulta en la base de datos."""


@contextmanager
def obtener_conexion():
    """Abre la conexión y la cierra al final, aunque haya un error."""
    try:
        conexion = pymysql.connect(cursorclass=DictCursor, **DB_CONFIG)
    except pymysql.MySQLError as exc:
        raise DatabaseError(f"No fue posible conectar con la base de datos: {exc}") from exc
    try:
        yield conexion
    finally:
        conexion.close()


def ejecutar_consulta(sql, parametros=None):
    """Ejecuta un SELECT y devuelve las filas como lista de diccionarios.

    Si la consulta lleva valores del usuario, van en la tupla `parametros`
    con %s en el SQL. No se pegan al texto de la consulta.
    """
    with obtener_conexion() as conexion:
        try:
            with conexion.cursor() as cursor:
                cursor.execute(sql, parametros)
                return cursor.fetchall()
        except pymysql.MySQLError as exc:
            raise DatabaseError(f"Error al ejecutar la consulta: {exc}") from exc
