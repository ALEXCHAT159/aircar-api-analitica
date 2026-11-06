"""Configuración de la conexión, leída de variables de entorno (.env)."""
import os

from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", ""),   # XAMPP trae root sin clave
    "database": os.getenv("DB_NAME", "aircar_manager"),
    "charset": "utf8mb4",
}
