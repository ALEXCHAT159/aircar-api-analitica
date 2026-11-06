# Homologación de entidades de AirCar Manager

AirCar Manager es el sistema del proyecto final, pensado para un taller de aire acondicionado automotriz en Montería.
El taller repara el A/C de carros, buses, camiones y maquinaria, vende repuestos en mostrador y le fía a algunos
clientes. La base de datos se llama `aircar_manager`, corre en MariaDB 10.4 (XAMPP) y tiene las 13 tablas que
se normalizaron en el Avance 1.

## Tabla de homologación

En mi proyecto del taller AirCar, la entidad catálogo es `categoria`, la entidad ítem es `producto`, la entidad
transaccional es `factura` con su `detalle_factura` (y también `abono`), la entidad actor es `cliente` y la
entidad de contexto es el tipo de vehículo que se atiende.

| Rol del taller | Tabla o campo en AirCar | Por qué la escogí |
|---|---|---|
| A. Catálogo | `categoria` | Es la tabla que agrupa los repuestos (compresores, condensadores, gases, filtros...). |
| B. Ítem | `producto` | Cada repuesto que se vende. Tiene su categoría y su precio de venta. |
| C. Transaccional | `factura` y `detalle_factura`; `abono` | Ahí quedan las ventas con cantidades, precios, totales y fechas. Los abonos son los pagos de los créditos. |
| D. Actor | `cliente` | Las personas que traen el vehículo o compran repuestos. |
| E. Contexto | `vehiculo.tipo_vehiculo` | El taller trabaja distinto según el tipo de vehículo (AUTOMOVIL, CAMIONETA, CAMION, BUS, MAQUINARIA). Se llega a él desde la factura por medio de `orden_servicio`. |

Para el endpoint 5 usé como variable operativa `abono.metodo_pago` (EFECTIVO, TRANSFERENCIA o TARJETA). Para el
endpoint 4 tomé como "estado crítico" que el cliente tenga un crédito en estado `VENCIDO`.

## Qué responde cada endpoint

1. `GET /api/reportes/clasificacion-top` dice qué categorías de repuestos venden, en promedio, más plata por
   línea de factura que el promedio de todas las líneas. Con los datos de prueba salen los kits para bus, los
   compresores, los condensadores y los evaporadores, que son los repuestos caros.
2. `GET /api/analitica/actores-estrella` lista los clientes que han facturado más que lo que factura un cliente
   promedio del taller. El promedio incluye a los clientes que no han comprado nada (cuentan como 0).
3. `GET /api/items/desviacion-grupo` muestra los repuestos que se venden menos que los otros de su misma
   categoría. Con `?comparacion=superior` muestra los que se venden más. Sirve para ver qué no vale la pena pedir
   otra vez al proveedor.
4. `GET /api/segmentos/analisis-limpio` suma lo facturado por el taller según el tipo de vehículo, pero sin
   contar a los clientes que tienen créditos vencidos. La idea es ver cuánto deja cada tipo de vehículo con
   clientes que sí pagan.
5. `GET /api/operaciones/resumen-dinamico?min_operaciones=N` agrupa los abonos por medio de pago. Solo aparecen
   los medios que tengan por lo menos N abonos (si no se manda, N = 2) y cuyo abono promedio sea mayor que el
   precio del repuesto más barato del catálogo.
