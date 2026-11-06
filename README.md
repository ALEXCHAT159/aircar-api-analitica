# AirCar Manager: API de analítica (Taller 2)

API hecha en Python con FastAPI que se conecta a la base de datos del proyecto final, AirCar Manager
(`aircar_manager` en MariaDB 10.4 de XAMPP). Tiene 5 endpoints GET que devuelven JSON.

No usé ORM. Las cinco consultas están escritas en SQL a mano en `app/consultas.py` y se ejecutan con
`cursor.execute()` de PyMySQL. Los promedios, las agrupaciones y los filtros los calcula MariaDB; Python solo
recibe la petición y devuelve lo que trae la consulta.

La explicación de qué tabla cumple cada rol y qué responde cada endpoint está en [HOMOLOGACION.md](HOMOLOGACION.md).

## Carpetas

```
aircar-api-analitica/
├── app/
│   ├── main.py            crea la app, registra las rutas y maneja los errores
│   ├── config.py          lee los datos de conexión del archivo .env
│   ├── database.py        abre la conexión y ejecuta las consultas
│   ├── consultas.py       el SQL de los 5 endpoints
│   ├── respuestas.py      arma el JSON de respuesta (igual para todos)
│   └── routers/           una ruta por archivo
├── sql/dump_proyecto.sql  estructura y datos de la base
├── pruebas/               test_endpoints.http, colección de Postman y respuestas guardadas
├── HOMOLOGACION.md
├── requirements.txt
└── .env.example
```

## Cómo correrlo

1. En XAMPP prenda MySQL, entre a phpMyAdmin, vaya a Importar y cargue `sql/dump_proyecto.sql`. El script borra
   y vuelve a crear `aircar_manager`.
2. Cree un entorno virtual e instale lo necesario (Python 3.10 o más reciente):
   ```bash
   python -m venv venv
   venv\Scripts\activate          # en Linux o Mac: source venv/bin/activate
   pip install -r requirements.txt
   ```
3. Copie `.env.example` con el nombre `.env`. Si XAMPP está como viene, el usuario es `root` sin contraseña y no
   hay que cambiar nada.
4. Levante la API con `uvicorn app.main:app --reload`. Queda en http://127.0.0.1:8000 y en
   http://127.0.0.1:8000/docs se pueden probar los endpoints desde el navegador.
5. Para las pruebas abra `pruebas/test_endpoints.http` con la extensión REST Client de VS Code, o importe en
   Postman el archivo `pruebas/AirCar_API_Analitica.postman_collection.json`.

## Endpoints

| Ruta | Parámetros | Qué tipo de consulta usa |
|---|---|---|
| `/api/reportes/clasificacion-top` | ninguno | GROUP BY por categoría y subconsulta escalar en el HAVING |
| `/api/analitica/actores-estrella` | ninguno | GROUP BY por cliente y HAVING contra una tabla derivada en el FROM |
| `/api/items/desviacion-grupo` | `comparacion`: `inferior` (por defecto) o `superior` | GROUP BY por producto y subconsulta correlacionada en el HAVING |
| `/api/segmentos/analisis-limpio` | ninguno | GROUP BY por tipo de vehículo y `NOT IN` en el WHERE |
| `/api/operaciones/resumen-dinamico` | `min_operaciones`: entero desde 1, por defecto 2 | GROUP BY por medio de pago, `HAVING COUNT(*) >= %s` y subconsulta con `MIN()` |

## Sobre las reglas del taller

El único parámetro que llega a una consulta es `min_operaciones`, y se pasa con `%s` dentro de una tupla:
`ejecutar_consulta(SQL_RESUMEN_DINAMICO, (min_operaciones,))`. Nunca se pega al texto del SQL. El parámetro
`comparacion` del endpoint 3 no entra al SQL; solo decide cuál de las dos consultas ya escritas se ejecuta.

Todas las respuestas traen los mismos campos. Una respuesta correcta se ve así:

```json
{ "estado": "ok", "codigo": 200, "endpoint": "/api/...", "descripcion": "...",
  "parametros": {}, "total_registros": 4, "datos": [ ... ] }
```

Los errores traen `"estado": "error"`, el código y un mensaje. Devuelve 200 cuando hay datos, 404 cuando la
consulta no trae nada o la ruta no existe, 400 cuando el parámetro está mal (por ejemplo `min_operaciones=abc`)
y 500 si se cae la conexión o falla el SQL.

## Lo que devolvió con los datos del dump

Cuando probé la API con `dump_proyecto.sql` cargado:

| Endpoint | Resultado |
|---|---|
| clasificacion-top | 4 categorías |
| actores-estrella | 5 clientes (el promedio por cliente da $1.370.066,67) |
| desviacion-grupo | 5 repuestos con `inferior` y 4 con `superior` |
| analisis-limpio | 4 tipos de vehículo; CAMIONETA no sale porque sus clientes tienen créditos vencidos |
| resumen-dinamico | 3 medios de pago con N=2, 2 con N=5 y un 404 con N=50 |
