"""Consultas SQL de los 5 endpoints, escritas a mano (sin ORM).

Tablas que usé para cada rol (ver HOMOLOGACION.md):
  A. Catálogo ........ categoria
  B. Ítem ............ producto (repuesto)
  C. Transaccional ... factura (cabecera) + detalle_factura (detalle); abono
  D. Actor ........... cliente
  E. Contexto ........ vehiculo.tipo_vehiculo (línea de servicio del taller)
"""

# ---------------------------------------------------------------------------
# Endpoint 1  GET /api/reportes/clasificacion-top
# GROUP BY [Catálogo] + subconsulta ESCALAR en HAVING.
# Categorías de repuestos cuyo valor promedio por línea vendida es mayor
# que el promedio de todas las líneas de venta del sistema.
# ---------------------------------------------------------------------------
SQL_CLASIFICACION_TOP = """
    SELECT  c.id_categoria,
            c.nombre                                            AS categoria,
            COUNT(*)                                            AS lineas_vendidas,
            SUM(df.cantidad)                                    AS unidades_vendidas,
            SUM(df.cantidad * df.precio_unitario)               AS total_vendido,
            ROUND(AVG(df.cantidad * df.precio_unitario), 2)     AS promedio_por_linea,
            (SELECT ROUND(AVG(d2.cantidad * d2.precio_unitario), 2)
               FROM detalle_factura d2)                         AS promedio_global
    FROM detalle_factura df
    JOIN producto  p ON p.id_producto  = df.id_producto
    JOIN categoria c ON c.id_categoria = p.id_categoria
    GROUP BY c.id_categoria, c.nombre
    HAVING AVG(df.cantidad * df.precio_unitario) >
           (SELECT AVG(d3.cantidad * d3.precio_unitario)
              FROM detalle_factura d3)
    ORDER BY promedio_por_linea DESC
"""

# ---------------------------------------------------------------------------
# Endpoint 2  GET /api/analitica/actores-estrella
# GROUP BY [Actor] + SUM, cruzado en HAVING con una subconsulta que
# opera sobre una TABLA DERIVADA en el FROM (acumulado de cada cliente).
# El promedio incluye a los clientes sin compras (acumulado 0).
# ---------------------------------------------------------------------------
SQL_ACTORES_ESTRELLA = """
    SELECT  cl.id_cliente,
            cl.documento,
            CONCAT(cl.nombres, ' ', cl.apellidos)   AS cliente,
            COUNT(f.id_factura)                     AS facturas,
            SUM(f.total)                            AS total_acumulado,
            (SELECT ROUND(AVG(t.acumulado), 2)
               FROM (SELECT c2.id_cliente,
                            COALESCE(SUM(f2.total), 0) AS acumulado
                       FROM cliente c2
                       LEFT JOIN factura f2 ON f2.id_cliente = c2.id_cliente
                      GROUP BY c2.id_cliente) AS t)  AS promedio_por_cliente
    FROM cliente cl
    JOIN factura f ON f.id_cliente = cl.id_cliente
    GROUP BY cl.id_cliente, cl.documento, cl.nombres, cl.apellidos
    HAVING SUM(f.total) >
           (SELECT AVG(t.acumulado)
              FROM (SELECT c3.id_cliente,
                           COALESCE(SUM(f3.total), 0) AS acumulado
                      FROM cliente c3
                      LEFT JOIN factura f3 ON f3.id_cliente = c3.id_cliente
                     GROUP BY c3.id_cliente) AS t)
    ORDER BY total_acumulado DESC
"""

# ---------------------------------------------------------------------------
# Endpoint 3  GET /api/items/desviacion-grupo
# GROUP BY [Ítem] + subconsulta CORRELACIONADA en HAVING: compara las
# unidades vendidas de cada repuesto con el promedio de unidades de los
# repuestos de SU MISMA categoría (p2.id_categoria = p.id_categoria).
# Hay dos versiones de la consulta, una con < ("inferior") y otra con > ("superior").
# ---------------------------------------------------------------------------
# Variante 'inferior' (por defecto): menos unidades que el promedio de su categoría.
SQL_DESVIACION_INFERIOR = """
    SELECT  p.id_producto,
            p.codigo,
            p.nombre                            AS producto,
            c.nombre                            AS categoria,
            COALESCE(SUM(df.cantidad), 0)       AS unidades_vendidas,
            (SELECT ROUND(COALESCE(SUM(d2.cantidad), 0) / COUNT(DISTINCT p2.id_producto), 2)
               FROM producto p2
               LEFT JOIN detalle_factura d2 ON d2.id_producto = p2.id_producto
              WHERE p2.id_categoria = p.id_categoria)  AS promedio_categoria
    FROM producto p
    JOIN categoria c ON c.id_categoria = p.id_categoria
    LEFT JOIN detalle_factura df ON df.id_producto = p.id_producto
    GROUP BY p.id_producto, p.codigo, p.nombre, p.id_categoria, c.nombre
    HAVING COALESCE(SUM(df.cantidad), 0) <
           (SELECT COALESCE(SUM(d3.cantidad), 0) / COUNT(DISTINCT p3.id_producto)
              FROM producto p3
              LEFT JOIN detalle_factura d3 ON d3.id_producto = p3.id_producto
             WHERE p3.id_categoria = p.id_categoria)
    ORDER BY c.nombre, unidades_vendidas
"""

# Variante 'superior': más unidades que el promedio de su categoría.
SQL_DESVIACION_SUPERIOR = """
    SELECT  p.id_producto,
            p.codigo,
            p.nombre                            AS producto,
            c.nombre                            AS categoria,
            COALESCE(SUM(df.cantidad), 0)       AS unidades_vendidas,
            (SELECT ROUND(COALESCE(SUM(d2.cantidad), 0) / COUNT(DISTINCT p2.id_producto), 2)
               FROM producto p2
               LEFT JOIN detalle_factura d2 ON d2.id_producto = p2.id_producto
              WHERE p2.id_categoria = p.id_categoria)  AS promedio_categoria
    FROM producto p
    JOIN categoria c ON c.id_categoria = p.id_categoria
    LEFT JOIN detalle_factura df ON df.id_producto = p.id_producto
    GROUP BY p.id_producto, p.codigo, p.nombre, p.id_categoria, c.nombre
    HAVING COALESCE(SUM(df.cantidad), 0) >
           (SELECT COALESCE(SUM(d3.cantidad), 0) / COUNT(DISTINCT p3.id_producto)
              FROM producto p3
              LEFT JOIN detalle_factura d3 ON d3.id_producto = p3.id_producto
             WHERE p3.id_categoria = p.id_categoria)
    ORDER BY c.nombre, unidades_vendidas DESC
"""

# ---------------------------------------------------------------------------
# Endpoint 4  GET /api/segmentos/analisis-limpio
# GROUP BY [Contexto] + subconsulta de EXCLUSIÓN (NOT IN) en WHERE.
# Facturación del taller por tipo de vehículo, excluyendo a los clientes
# que tienen al menos un crédito en estado VENCIDO (cartera en mora).
# ---------------------------------------------------------------------------
SQL_ANALISIS_LIMPIO = """
    SELECT  v.tipo_vehiculo                  AS segmento,
            COUNT(DISTINCT f.id_cliente)     AS clientes,
            COUNT(f.id_factura)              AS facturas,
            SUM(f.total)                     AS total_facturado,
            ROUND(AVG(f.total), 2)           AS promedio_por_factura
    FROM factura f
    JOIN orden_servicio o ON o.id_orden    = f.id_orden
    JOIN vehiculo       v ON v.id_vehiculo = o.id_vehiculo
    WHERE f.id_cliente NOT IN (
            SELECT fa.id_cliente
              FROM factura fa
              JOIN credito cr ON cr.id_factura = fa.id_factura
             WHERE cr.estado = 'VENCIDO')
    GROUP BY v.tipo_vehiculo
    ORDER BY total_facturado DESC
"""

# ---------------------------------------------------------------------------
# Endpoint 5  GET /api/operaciones/resumen-dinamico?min_operaciones=N
# GROUP BY [Atributo operativo: abono.metodo_pago] + parámetro dinámico en
# HAVING (COUNT(*) >= %s) + subconsulta escalar MIN() contra el catálogo
# de ítems (precio de venta del repuesto más económico).
# ---------------------------------------------------------------------------
SQL_RESUMEN_DINAMICO = """
    SELECT  a.metodo_pago,
            COUNT(*)                                    AS operaciones,
            SUM(a.monto)                                AS total_recaudado,
            ROUND(AVG(a.monto), 2)                      AS promedio_por_operacion,
            (SELECT MIN(p.precio_venta) FROM producto p) AS precio_minimo_catalogo
    FROM abono a
    GROUP BY a.metodo_pago
    HAVING COUNT(*) >= %s
       AND AVG(a.monto) > (SELECT MIN(p2.precio_venta) FROM producto p2)
    ORDER BY operaciones DESC
"""
