/* =====================================================================
   AIRCAR MANAGER - Taller 2 (API REST de Analítica)
   dump_proyecto.sql : estructura (DDL) + datos (DML) de la base aircar_manager
   Motor: MariaDB 10.4+ (XAMPP / phpMyAdmin) o MySQL 8.0+
   - 13 tablas normalizadas (3FN) definidas en el Avance 1.
   - 15 o más registros consistentes por tabla.
   - Con estos datos los 5 endpoints de la API devuelven registros.
   ATENCIÓN: el script borra y recrea la base de datos aircar_manager.
   (Los procedimientos y triggers del Avance 2 se pueden volver a crear
    después ejecutando 05_Avance2_Automatizacion.sql; la API no los usa.)
   ===================================================================== */



SET NAMES utf8mb4;

DROP DATABASE IF EXISTS aircar_manager;
CREATE DATABASE aircar_manager
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE aircar_manager;

/* ---------------------------------------------------------------------
   1. USUARIO: personal del taller con acceso al sistema (login por rol)
   --------------------------------------------------------------------- */
CREATE TABLE usuario (
    id_usuario      INT           NOT NULL AUTO_INCREMENT,
    documento       VARCHAR(15)   NOT NULL,
    nombres         VARCHAR(60)   NOT NULL,
    apellidos       VARCHAR(60)   NOT NULL,
    rol             VARCHAR(15)   NOT NULL,
    nombre_usuario  VARCHAR(30)   NOT NULL,
    clave_hash      CHAR(64)      NOT NULL,      -- SHA-256 en hexadecimal
    telefono        VARCHAR(15),
    fecha_ingreso   DATE          NOT NULL,
    activo          TINYINT       NOT NULL DEFAULT 1,
    CONSTRAINT pk_usuario PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuario_documento UNIQUE (documento),
    CONSTRAINT uq_usuario_login UNIQUE (nombre_usuario),
    CONSTRAINT ck_usuario_rol CHECK (rol IN ('ADMINISTRADOR','CAJERO','TECNICO','ALMACENISTA','VENDEDOR')),
    CONSTRAINT ck_usuario_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   2. CLIENTE: propietarios de los vehículos y compradores del almacén
   --------------------------------------------------------------------- */
CREATE TABLE cliente (
    id_cliente      INT           NOT NULL AUTO_INCREMENT,
    tipo_documento  VARCHAR(2)    NOT NULL,
    documento       VARCHAR(15)   NOT NULL,
    nombres         VARCHAR(60)   NOT NULL,
    apellidos       VARCHAR(60)   NOT NULL,
    telefono        VARCHAR(15),
    correo          VARCHAR(80),
    direccion       VARCHAR(100),
    limite_credito  DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_registro  DATE          NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cliente_documento UNIQUE (tipo_documento, documento),
    CONSTRAINT ck_cliente_tipodoc CHECK (tipo_documento IN ('CC','CE')),
    CONSTRAINT ck_cliente_limite CHECK (limite_credito >= 0)
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   3. VEHICULO: un cliente puede tener varios vehículos (1:N)
   --------------------------------------------------------------------- */
CREATE TABLE vehiculo (
    id_vehiculo     INT           NOT NULL AUTO_INCREMENT,
    placa_serie     VARCHAR(15)   NOT NULL,      -- placa, o serie si es maquinaria
    marca           VARCHAR(30)   NOT NULL,
    modelo          VARCHAR(40)   NOT NULL,
    anio            INT           NOT NULL,
    tipo_vehiculo   VARCHAR(15)   NOT NULL,
    id_cliente      INT           NOT NULL,
    CONSTRAINT pk_vehiculo PRIMARY KEY (id_vehiculo),
    CONSTRAINT uq_vehiculo_placa UNIQUE (placa_serie),
    CONSTRAINT ck_vehiculo_anio CHECK (anio BETWEEN 1980 AND 2030),
    CONSTRAINT ck_vehiculo_tipo CHECK (tipo_vehiculo IN ('AUTOMOVIL','CAMIONETA','CAMION','BUS','MAQUINARIA')),
    CONSTRAINT fk_vehiculo_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   4. CATEGORIA: clasificación de los repuestos
   --------------------------------------------------------------------- */
CREATE TABLE categoria (
    id_categoria    INT           NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(50)   NOT NULL,
    descripcion     VARCHAR(150),
    CONSTRAINT pk_categoria PRIMARY KEY (id_categoria),
    CONSTRAINT uq_categoria_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   5. PROVEEDOR: empresas que abastecen el almacén
   --------------------------------------------------------------------- */
CREATE TABLE proveedor (
    id_proveedor    INT           NOT NULL AUTO_INCREMENT,
    nit             VARCHAR(15)   NOT NULL,
    razon_social    VARCHAR(80)   NOT NULL,
    telefono        VARCHAR(15),
    correo          VARCHAR(80),
    ciudad          VARCHAR(40),
    CONSTRAINT pk_proveedor PRIMARY KEY (id_proveedor),
    CONSTRAINT uq_proveedor_nit UNIQUE (nit)
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   6. PRODUCTO: inventario de repuestos y consumibles
   --------------------------------------------------------------------- */
CREATE TABLE producto (
    id_producto     INT           NOT NULL AUTO_INCREMENT,
    codigo          VARCHAR(20)   NOT NULL,
    nombre          VARCHAR(80)   NOT NULL,
    id_categoria    INT           NOT NULL,
    id_proveedor    INT           NOT NULL,
    precio_compra   DECIMAL(12,2) NOT NULL,
    precio_venta    DECIMAL(12,2) NOT NULL,
    stock_actual    INT           NOT NULL DEFAULT 0,
    stock_minimo    INT           NOT NULL DEFAULT 0,
    CONSTRAINT pk_producto PRIMARY KEY (id_producto),
    CONSTRAINT uq_producto_codigo UNIQUE (codigo),
    CONSTRAINT ck_producto_precios CHECK (precio_compra >= 0 AND precio_venta >= precio_compra),
    CONSTRAINT ck_producto_stock CHECK (stock_actual >= 0 AND stock_minimo >= 0),
    CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria)
        REFERENCES categoria (id_categoria) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_producto_proveedor FOREIGN KEY (id_proveedor)
        REFERENCES proveedor (id_proveedor) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   7. SERVICIO: catálogo de servicios de mano de obra del taller
   --------------------------------------------------------------------- */
CREATE TABLE servicio (
    id_servicio     INT           NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(60)   NOT NULL,
    descripcion     VARCHAR(150),
    precio_base     DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_servicio PRIMARY KEY (id_servicio),
    CONSTRAINT uq_servicio_nombre UNIQUE (nombre),
    CONSTRAINT ck_servicio_precio CHECK (precio_base >= 0)
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   8. ORDEN_SERVICIO: ingreso de un vehículo al taller, atendido por un técnico
   --------------------------------------------------------------------- */
CREATE TABLE orden_servicio (
    id_orden        INT           NOT NULL AUTO_INCREMENT,
    id_vehiculo     INT           NOT NULL,
    id_usuario      INT           NOT NULL,      -- técnico responsable
    fecha_ingreso   DATE          NOT NULL,
    fecha_entrega   DATE,
    diagnostico     VARCHAR(200),
    estado          VARCHAR(15)   NOT NULL DEFAULT 'RECIBIDO',
    CONSTRAINT pk_orden_servicio PRIMARY KEY (id_orden),
    CONSTRAINT ck_orden_estado CHECK (estado IN ('RECIBIDO','EN_PROCESO','ENTREGADO')),
    CONSTRAINT ck_orden_fechas CHECK (fecha_entrega IS NULL OR fecha_entrega >= fecha_ingreso),
    CONSTRAINT fk_orden_vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orden_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   9. DETALLE_ORDEN_SERVICIO: servicios realizados en una orden (N:M)
   --------------------------------------------------------------------- */
CREATE TABLE detalle_orden_servicio (
    id_orden        INT           NOT NULL,
    id_servicio     INT           NOT NULL,
    cantidad        INT           NOT NULL DEFAULT 1,
    precio_aplicado DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_detalle_orden PRIMARY KEY (id_orden, id_servicio),
    CONSTRAINT ck_detorden_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detorden_precio CHECK (precio_aplicado >= 0),
    CONSTRAINT fk_detorden_orden FOREIGN KEY (id_orden)
        REFERENCES orden_servicio (id_orden) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_detorden_servicio FOREIGN KEY (id_servicio)
        REFERENCES servicio (id_servicio) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   10. FACTURA: venta de repuestos y/o cobro de una orden de servicio.
       id_orden es NULL cuando es una venta de mostrador (solo repuestos).
   --------------------------------------------------------------------- */
CREATE TABLE factura (
    id_factura      INT           NOT NULL AUTO_INCREMENT,
    numero_factura  VARCHAR(12)   NOT NULL,
    fecha_emision   DATE          NOT NULL,
    id_cliente      INT           NOT NULL,
    id_usuario      INT           NOT NULL,      -- cajero o vendedor que factura
    id_orden        INT,
    tipo_pago       VARCHAR(10)   NOT NULL,
    total           DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_factura PRIMARY KEY (id_factura),
    CONSTRAINT uq_factura_numero UNIQUE (numero_factura),
    CONSTRAINT uq_factura_orden UNIQUE (id_orden),
    CONSTRAINT ck_factura_pago CHECK (tipo_pago IN ('CONTADO','CREDITO')),
    CONSTRAINT ck_factura_total CHECK (total >= 0),
    CONSTRAINT fk_factura_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_factura_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_factura_orden FOREIGN KEY (id_orden)
        REFERENCES orden_servicio (id_orden) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   11. DETALLE_FACTURA: repuestos vendidos o instalados en una factura (N:M)
   --------------------------------------------------------------------- */
CREATE TABLE detalle_factura (
    id_factura      INT           NOT NULL,
    id_producto     INT           NOT NULL,
    cantidad        INT           NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_detalle_factura PRIMARY KEY (id_factura, id_producto),
    CONSTRAINT ck_detfactura_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detfactura_precio CHECK (precio_unitario >= 0),
    CONSTRAINT fk_detfactura_factura FOREIGN KEY (id_factura)
        REFERENCES factura (id_factura) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_detfactura_producto FOREIGN KEY (id_producto)
        REFERENCES producto (id_producto) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   12. CREDITO: financiación de una factura (1 factura -> 0 ó 1 crédito)
   --------------------------------------------------------------------- */
CREATE TABLE credito (
    id_credito      INT           NOT NULL AUTO_INCREMENT,
    id_factura      INT           NOT NULL,
    fecha_inicio    DATE          NOT NULL,
    fecha_limite    DATE          NOT NULL,
    monto_total     DECIMAL(12,2) NOT NULL,
    saldo_pendiente DECIMAL(12,2) NOT NULL,
    estado          VARCHAR(10)   NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_credito PRIMARY KEY (id_credito),
    CONSTRAINT uq_credito_factura UNIQUE (id_factura),
    CONSTRAINT ck_credito_estado CHECK (estado IN ('ACTIVO','PAGADO','VENCIDO')),
    CONSTRAINT ck_credito_montos CHECK (monto_total > 0 AND saldo_pendiente >= 0 AND saldo_pendiente <= monto_total),
    CONSTRAINT ck_credito_fechas CHECK (fecha_limite >= fecha_inicio),
    CONSTRAINT fk_credito_factura FOREIGN KEY (id_factura)
        REFERENCES factura (id_factura) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ---------------------------------------------------------------------
   13. ABONO: pagos parciales realizados a un crédito
   --------------------------------------------------------------------- */
CREATE TABLE abono (
    id_abono        INT           NOT NULL AUTO_INCREMENT,
    id_credito      INT           NOT NULL,
    id_usuario      INT           NOT NULL,      -- cajero que recibe el pago
    fecha_abono     DATE          NOT NULL,
    monto           DECIMAL(12,2) NOT NULL,
    metodo_pago     VARCHAR(15)   NOT NULL,
    CONSTRAINT pk_abono PRIMARY KEY (id_abono),
    CONSTRAINT ck_abono_monto CHECK (monto > 0),
    CONSTRAINT ck_abono_metodo CHECK (metodo_pago IN ('EFECTIVO','TRANSFERENCIA','TARJETA')),
    CONSTRAINT fk_abono_credito FOREIGN KEY (id_credito)
        REFERENCES credito (id_credito) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_abono_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ====================== DATOS (DML) ====================== */

USE aircar_manager;

-- 1. USUARIO (15)
INSERT INTO usuario (id_usuario, documento, nombres, apellidos, rol, nombre_usuario, clave_hash, telefono, fecha_ingreso, activo) VALUES
    (1, '1067890123', 'Carlos Andrés', 'Pérez Londoño', 'ADMINISTRADOR', 'cperez', 'b2dc4b0517ba4d2d1ba2c82caa5d874655f0d93d48a27efc32a85b04a6a47824', '3001100001', '2019-02-01', 1),
    (2, '1067890124', 'María Fernanda', 'Ortega Díaz', 'ADMINISTRADOR', 'mortega', 'eacc832b1688f5a4ab3a243beebaaa5550b6c7273f352199858114d4a00e90f0', '3001100002', '2019-02-01', 1),
    (3, '50901234', 'Luis Eduardo', 'Barrios Mestra', 'CAJERO', 'lbarrios', '1c79d1c2d53718cc11f5865095f15f79fb6763b3c59da240a27d2abba2b0ce7f', '3001100003', '2020-03-16', 1),
    (4, '1067345678', 'Sandra Milena', 'Hoyos Pastrana', 'CAJERO', 'shoyos', '79620044896523440df389df8717f385f2d7f63f9775e8f5b75c9a2d7682288b', '3001100004', '2021-07-05', 1),
    (5, '1003456789', 'Daniela Paola', 'Vergara Ruiz', 'CAJERO', 'dvergara', '6876faaeb04d035aafc1912383ddddba179934d5fbe5d61f48ef87cd56f1f990', '3001100005', '2023-01-09', 1),
    (6, '78345678', 'José Miguel', 'Cogollo Martínez', 'TECNICO', 'jcogollo', '2e83898c1c6215f62865ff193aa6b9c7f9c6b22f017c8e17f19a0a8adc43701e', '3001100006', '2019-05-20', 1),
    (7, '1067456789', 'Andrés Felipe', 'Sierra Padilla', 'TECNICO', 'asierra', '6885aabcd020477259aa31998a35ff71b76584b1047c6827c967df97a6372cfd', '3001100007', '2020-08-10', 1),
    (8, '78456789', 'Ramiro Antonio', 'Zabaleta Lugo', 'TECNICO', 'rzabaleta', 'b93a67123110b089e874260a7f72fa5c6c0af2de7cf74fd2b18a163f9461fb37', '3001100008', '2020-11-02', 1),
    (9, '1067567890', 'Kevin Alexander', 'Doria Banquez', 'TECNICO', 'kdoria', '18e7d9f0bf77aabc5d5e57e5e359a1e26846f175279275083aac8d37a7417d24', '3001100009', '2022-02-14', 1),
    (10, '78567890', 'Wilmer Enrique', 'Pastrana Gómez', 'TECNICO', 'wpastrana', 'f541b3107853bd06b34324cdb63f5580e2e2377615cc242bd11e9aba8a706647', '3001100010', '2022-09-26', 1),
    (11, '1067678901', 'Yeison David', 'Montes Argel', 'TECNICO', 'ymontes', 'f3892fffc45b8839750f82603c3d0aeb2f1465953922fa067b0af39902e77b83', '3001100011', '2024-04-01', 1),
    (12, '1067789012', 'Paola Andrea', 'Mercado Salgado', 'ALMACENISTA', 'pmercado', '2dc9c649ebdc8f3416cc4276e1131805623f98e8a7f88d33e9b4f20d68478fe2', '3001100012', '2021-01-18', 1),
    (13, '50123456', 'Hernán Darío', 'Oviedo Tapia', 'ALMACENISTA', 'hoviedo', 'b0929a649827c026216c20703a532b9be3732c808b4ec24f8328e24668f6f8a8', '3001100013', '2022-06-06', 1),
    (14, '1067890125', 'Juliana Marcela', 'Berrío Cárdenas', 'VENDEDOR', 'jberrio', 'ff4fa6b51664080926ec95c9346d2a69652677480b55f6ef0b36dd2784d013aa', '3001100014', '2023-03-13', 1),
    (15, '78678901', 'Orlando José', 'Castaño Suárez', 'VENDEDOR', 'ocastano', 'b9aa89aafc8eb969507af3441bfb723a89870b71144cea5a131e011726eab062', '3001100015', '2024-01-22', 1);

-- 2. CLIENTE (15)
INSERT INTO cliente (id_cliente, tipo_documento, documento, nombres, apellidos, telefono, correo, direccion, limite_credito, fecha_registro) VALUES
    (1, 'CC', '1067111001', 'Jorge Luis', 'Hernández Pacheco', '3012000001', 'jorge.hernandez@example.com', 'Calle 29 # 3-45, Montería', 5000000.00, '2023-02-10'),
    (2, 'CC', '1067111002', 'Marta Elena', 'Bula Gómez', '3012000002', 'marta.bula@example.com', 'Cra 6 # 45-12, Montería', 6000000.00, '2023-04-18'),
    (3, 'CC', '78111003', 'Pedro Pablo', 'Ramos Vitola', '3012000003', 'pedro.ramos@example.com', 'Av. Circunvalar # 20-18, Montería', 15000000.00, '2022-09-05'),
    (4, 'CC', '50111004', 'Rosario del Carmen', 'Álvarez Lora', '3012000004', 'rosario.alvarez@example.com', 'Cra 14 # 22-30, Cereté', 3000000.00, '2024-01-12'),
    (5, 'CC', '1067111005', 'Édgar Alonso', 'Negrete Sánchez', '3012000005', 'edgar.negrete@example.com', 'Calle 12 # 7-20, Lorica', 8000000.00, '2023-06-30'),
    (6, 'CC', '78111006', 'Fabio Nelson', 'Contreras Ibáñez', '3012000006', 'fabio.contreras@example.com', 'Cra 9 # 31-05, Sahagún', 20000000.00, '2021-11-22'),
    (7, 'CC', '1067111007', 'Lina Marcela', 'Arrieta Palencia', '3012000007', 'lina.arrieta@example.com', 'Calle 41 # 12-08, Montería', 5000000.00, '2024-03-03'),
    (8, 'CC', '50111008', 'Gloria Inés', 'Mendoza Villadiego', '3012000008', 'gloria.mendoza@example.com', 'Cra 3 # 8-15, Montelíbano', 6000000.00, '2023-08-14'),
    (9, 'CC', '78111009', 'Tomás Rafael', 'Guerra Tordecilla', '3012000009', 'tomas.guerra@example.com', 'Km 5 Vía Cereté, Montería', 20000000.00, '2021-05-17'),
    (10, 'CC', '1067111010', 'Ana Sofía', 'Padilla Montalvo', '3012000010', 'ana.padilla@example.com', 'Calle 5 # 11-40, Planeta Rica', 4000000.00, '2024-05-27'),
    (11, 'CE', '8100011', 'Ricardo Alberto', 'Fuentes Camacho', '3012000011', 'ricardo.fuentes@example.com', 'Cra 2 # 25-60, Montería', 6000000.00, '2024-02-19'),
    (12, 'CC', '78111012', 'Hugo Armando', 'Lacharme Peña', '3012000012', 'hugo.lacharme@example.com', 'Calle 18 # 4-33, Tierralta', 12000000.00, '2022-12-01'),
    (13, 'CC', '1067111013', 'Verónica Isabel', 'Tapia Ortiz', '3012000013', 'veronica.tapia@example.com', 'Cra 7 # 52-14, Montería', 5000000.00, '2025-01-20'),
    (14, 'CC', '50111014', 'Nelly Esther', 'Cura Rivera', '3012000014', 'nelly.cura@example.com', 'Calle 33 # 9-27, Montería', 2000000.00, '2025-03-11'),
    (15, 'CC', '78111015', 'Samuel David', 'Soto Burgos', '3012000015', 'samuel.soto@example.com', 'Vía Arboletes Km 3, Montería', 15000000.00, '2022-07-08');

-- 3. CATEGORIA (15)
INSERT INTO categoria (id_categoria, nombre, descripcion) VALUES
    (1, 'Compresores', 'Compresores de A/C para vehículos livianos y pesados'),
    (2, 'Condensadores', 'Condensadores y radiadores de A/C'),
    (3, 'Evaporadores', 'Evaporadores y núcleos de cabina'),
    (4, 'Gases refrigerantes', 'Gas R134a, R1234yf y recargas'),
    (5, 'Filtros deshidratadores', 'Filtros secadores y acumuladores'),
    (6, 'Válvulas de expansión', 'Válvulas de expansión y orificios'),
    (7, 'Mangueras y líneas', 'Mangueras, tuberías y conexiones del circuito'),
    (8, 'Embragues magnéticos', 'Embragues y poleas de compresor'),
    (9, 'Motoventiladores', 'Electroventiladores del condensador'),
    (10, 'Sensores y presostatos', 'Presostatos, termostatos y sensores'),
    (11, 'Aceites y lubricantes', 'Aceites PAG/POE para compresor'),
    (12, 'Empaques y o-rings', 'Sellos, empaques y kits de o-rings'),
    (13, 'Herramientas y consumibles', 'Tintes UV, selladores y consumibles de taller'),
    (14, 'Filtros de cabina', 'Filtros de aire de habitáculo'),
    (15, 'Kits de instalación', 'Kits completos de instalación de A/C');

-- 4. PROVEEDOR (15)
INSERT INTO proveedor (id_proveedor, nit, razon_social, telefono, correo, ciudad) VALUES
    (1, '900123401-1', 'Frío Caribe Repuestos S.A.S.', '6053001001', 'ventas@frio1.example.com', 'Barranquilla'),
    (2, '900123402-2', 'Climatización Andina Ltda.', '6043001002', 'ventas@climatizacion2.example.com', 'Medellín'),
    (3, '900123403-3', 'Radiadores y Condensadores del Norte S.A.S.', '6053001003', 'ventas@radiadores3.example.com', 'Barranquilla'),
    (4, '900123404-4', 'Evaporadores Colombia S.A.S.', '6013001004', 'ventas@evaporadores4.example.com', 'Bogotá'),
    (5, '900123405-5', 'Gases Refrigerantes del Caribe S.A.', '6053001005', 'ventas@gases5.example.com', 'Cartagena'),
    (6, '900123406-6', 'Filtros y Secadores Industriales S.A.S.', '6023001006', 'ventas@filtros6.example.com', 'Cali'),
    (7, '900123407-7', 'Válvulas y Controles AC Ltda.', '6013001007', 'ventas@valvulas7.example.com', 'Bogotá'),
    (8, '900123408-8', 'Mangueras y Conexiones Pacífico S.A.S.', '6023001008', 'ventas@mangueras8.example.com', 'Cali'),
    (9, '900123409-9', 'Motoventiladores Tropicales S.A.S.', '6043001009', 'ventas@motoventiladores9.example.com', 'Medellín'),
    (10, '900123410-0', 'Sensores y Controles Electrónicos S.A.S.', '6073001010', 'ventas@sensores10.example.com', 'Bucaramanga'),
    (11, '900123411-1', 'Lubricantes Técnicos de Colombia S.A.', '6013001011', 'ventas@lubricantes11.example.com', 'Bogotá'),
    (12, '900123412-2', 'Sellos y Empaques Industriales Ltda.', '6043001012', 'ventas@sellos12.example.com', 'Medellín'),
    (13, '900123413-3', 'Herramientas para Refrigeración S.A.S.', '6053001013', 'ventas@herramientas13.example.com', 'Barranquilla'),
    (14, '900123414-4', 'Filtración Automotriz del Sinú S.A.S.', '6047771014', 'ventas@filtracion14.example.com', 'Montería'),
    (15, '900123415-5', 'Kits y Sistemas de A/C para Buses S.A.S.', '6023001015', 'ventas@kits15.example.com', 'Cali');

-- 5. SERVICIO (15)
INSERT INTO servicio (id_servicio, nombre, descripcion, precio_base) VALUES
    (1, 'Diagnóstico de fallas A/C', 'Revisión de presiones, fugas y componentes', 60000.00),
    (2, 'Recarga de gas R134a', 'Vacío y recarga de refrigerante R134a', 90000.00),
    (3, 'Recarga de gas R1234yf', 'Vacío y recarga de refrigerante R1234yf', 180000.00),
    (4, 'Detección de fugas', 'Prueba con nitrógeno y tinte UV', 80000.00),
    (5, 'Reparación de compresor', 'Reparación y ajuste del compresor', 350000.00),
    (6, 'Cambio de compresor', 'Mano de obra de cambio de compresor', 220000.00),
    (7, 'Cambio de condensador', 'Mano de obra de cambio de condensador', 180000.00),
    (8, 'Cambio de evaporador', 'Desmonte de tablero y cambio de evaporador', 380000.00),
    (9, 'Cambio de filtro deshidratador', 'Reemplazo del filtro secador', 70000.00),
    (10, 'Cambio de válvula de expansión', 'Reemplazo de válvula de expansión', 160000.00),
    (11, 'Limpieza del sistema (flushing)', 'Lavado interno del circuito', 150000.00),
    (12, 'Mantenimiento preventivo A/C', 'Revisión general y limpieza', 120000.00),
    (13, 'Reparación de mangueras', 'Fabricación y cambio de mangueras', 100000.00),
    (14, 'Cambio de embrague magnético', 'Reemplazo del embrague del compresor', 140000.00),
    (15, 'Instalación de A/C en bus', 'Mano de obra de instalación completa', 900000.00);

-- 6. VEHICULO (18)
INSERT INTO vehiculo (id_vehiculo, placa_serie, marca, modelo, anio, tipo_vehiculo, id_cliente) VALUES
    (1, 'TPX421', 'Chevrolet', 'Spark GT', 2018, 'AUTOMOVIL', 1),
    (2, 'UYB305', 'Renault', 'Logan', 2019, 'AUTOMOVIL', 2),
    (3, 'WNR118', 'Hino', '500 FC', 2017, 'CAMION', 3),
    (4, 'XDT664', 'Chevrolet', 'NKR', 2016, 'CAMION', 3),
    (5, 'TBA209', 'Mercedes-Benz', 'OF 1721', 2015, 'BUS', 6),
    (6, 'UFG483', 'Hyundai', 'County', 2014, 'BUS', 6),
    (7, 'KMZ951', 'Kia', 'Picanto', 2020, 'AUTOMOVIL', 4),
    (8, 'SNH037', 'Toyota', 'Fortuner', 2022, 'CAMIONETA', 5),
    (9, 'MQ-CAT3201', 'Caterpillar', '320D', 2012, 'MAQUINARIA', 9),
    (10, 'MQ-KOM2007', 'Komatsu', 'PC200', 2014, 'MAQUINARIA', 9),
    (11, 'VJC580', 'Mazda', '3 Sedán', 2019, 'AUTOMOVIL', 7),
    (12, 'RTP126', 'Ford', 'Ranger', 2020, 'CAMIONETA', 8),
    (13, 'ZLA745', 'Kenworth', 'T800', 2013, 'CAMION', 12),
    (14, 'PQD392', 'Nissan', 'Frontier', 2018, 'CAMIONETA', 10),
    (15, 'BGH861', 'Volvo', 'B7R', 2011, 'BUS', 15),
    (16, 'MQ-JDR3100', 'John Deere', '310SJ', 2016, 'MAQUINARIA', 15),
    (17, 'HRX274', 'Renault', 'Duster', 2021, 'CAMIONETA', 11),
    (18, 'LCY659', 'Chevrolet', 'Tracker', 2022, 'AUTOMOVIL', 13);

-- 7. PRODUCTO (20)
INSERT INTO producto (id_producto, codigo, nombre, id_categoria, id_proveedor, precio_compra, precio_venta, stock_actual, stock_minimo) VALUES
    (1, 'CMP-SD7H15', 'Compresor SD7H15 12V', 1, 1, 720000.00, 980000.00, 2, 3),
    (2, 'CMP-DEN10S17', 'Compresor Denso 10S17', 1, 2, 810000.00, 1100000.00, 3, 2),
    (3, 'CMP-BUS-TM31', 'Compresor TM31 para buses', 1, 1, 1450000.00, 1900000.00, 1, 2),
    (4, 'CND-UNI-18', 'Condensador universal paralelo 18 pulgadas', 2, 3, 210000.00, 320000.00, 5, 2),
    (5, 'CND-HINO500', 'Condensador para camión Hino 500', 2, 3, 380000.00, 560000.00, 2, 2),
    (6, 'EVP-UNI-AUT', 'Evaporador universal para automóvil', 3, 4, 260000.00, 390000.00, 4, 2),
    (7, 'GAS-R134A-450', 'Gas refrigerante R134a lata 450 g', 4, 5, 24000.00, 38000.00, 85, 30),
    (8, 'GAS-R134A-13K', 'Gas refrigerante R134a cilindro 13.6 kg', 4, 5, 430000.00, 580000.00, 4, 3),
    (9, 'FLT-DSH-UNI', 'Filtro deshidratador universal', 5, 6, 28000.00, 55000.00, 20, 10),
    (10, 'FLT-DSH-PES', 'Filtro deshidratador camión/bus', 5, 6, 42000.00, 80000.00, 6, 8),
    (11, 'VLV-EXP-BLQ', 'Válvula de expansión tipo bloque', 6, 7, 65000.00, 120000.00, 9, 5),
    (12, 'MNG-R134-MT', 'Manguera R134a por metro', 7, 8, 18000.00, 32000.00, 40, 20),
    (13, 'EMB-MAG-SD7', 'Embrague magnético para compresor SD7', 8, 2, 150000.00, 240000.00, 3, 2),
    (14, 'MTV-12V-UNI', 'Motoventilador 12V universal', 9, 9, 120000.00, 195000.00, 6, 3),
    (15, 'SEN-PRS-TRI', 'Presostato trinario', 10, 10, 45000.00, 90000.00, 11, 5),
    (16, 'ACE-PAG46-250', 'Aceite PAG 46 frasco 250 ml', 11, 11, 16000.00, 30000.00, 30, 15),
    (17, 'ORG-KIT-HNBR', 'Kit de o-rings HNBR', 12, 12, 22000.00, 45000.00, 12, 6),
    (18, 'CNS-TINTE-UV', 'Tinte UV detector de fugas', 13, 13, 20000.00, 42000.00, 14, 5),
    (19, 'FLT-CAB-CARB', 'Filtro de cabina carbón activado', 14, 14, 25000.00, 52000.00, 18, 8),
    (20, 'KIT-INST-BUS', 'Kit de instalación A/C para bus', 15, 15, 1650000.00, 2300000.00, 1, 1);

-- 8. ORDEN_SERVICIO (18)
INSERT INTO orden_servicio (id_orden, id_vehiculo, id_usuario, fecha_ingreso, fecha_entrega, diagnostico, estado) VALUES
    (1, 1, 6, '2026-06-02', '2026-06-03', 'Baja presión por pérdida de gas', 'ENTREGADO'),
    (2, 2, 7, '2026-06-09', '2026-06-10', 'Compresor con ruido y vibración', 'ENTREGADO'),
    (3, 3, 8, '2026-06-17', '2026-06-19', 'Condensador obstruido en camión Hino', 'ENTREGADO'),
    (4, 5, 9, '2026-07-01', '2026-07-04', 'Bus sin enfriamiento, compresor fallado', 'ENTREGADO'),
    (5, 7, 10, '2026-07-08', '2026-07-08', 'Mantenimiento preventivo programado', 'ENTREGADO'),
    (6, 8, 6, '2026-07-15', '2026-07-16', 'Fuga en evaporador', 'ENTREGADO'),
    (7, 9, 11, '2026-07-22', '2026-07-25', 'Excavadora sin enfriar, embrague dañado', 'ENTREGADO'),
    (8, 11, 7, '2026-08-04', '2026-08-04', 'Válvula de expansión obstruida', 'ENTREGADO'),
    (9, 12, 8, '2026-08-12', '2026-08-13', 'Manguera de alta presión rota', 'ENTREGADO'),
    (10, 13, 9, '2026-08-20', '2026-08-24', 'Camión Kenworth con condensador roto', 'ENTREGADO'),
    (11, 6, 10, '2026-09-02', '2026-09-04', 'Fugas en bus por o-rings resecos', 'ENTREGADO'),
    (12, 15, 11, '2026-09-10', '2026-09-14', 'Instalación de A/C en bus Volvo', 'ENTREGADO'),
    (13, 16, 6, '2026-09-22', '2026-09-24', 'Retroexcavadora con embrague patinando', 'ENTREGADO'),
    (14, 1, 7, '2026-10-05', '2026-10-06', 'Mantenimiento preventivo y cambio de filtro', 'ENTREGADO'),
    (15, 4, 8, '2026-10-14', NULL, 'Camión NKR sin enfriamiento', 'EN_PROCESO'),
    (16, 10, 9, '2026-10-16', NULL, 'Excavadora con baja presión de gas', 'EN_PROCESO'),
    (17, 17, 10, '2026-10-19', NULL, 'Ruido al encender el aire', 'RECIBIDO'),
    (18, 14, 11, '2026-10-20', NULL, 'Aire sale caliente', 'RECIBIDO');

-- 9. DETALLE_ORDEN_SERVICIO (47)
INSERT INTO detalle_orden_servicio (id_orden, id_servicio, cantidad, precio_aplicado) VALUES
    (1, 1, 1, 60000.00),
    (1, 4, 1, 80000.00),
    (1, 2, 1, 90000.00),
    (2, 1, 1, 60000.00),
    (2, 6, 1, 220000.00),
    (3, 1, 1, 60000.00),
    (3, 7, 1, 180000.00),
    (3, 2, 1, 90000.00),
    (4, 1, 1, 60000.00),
    (4, 6, 1, 220000.00),
    (4, 11, 1, 150000.00),
    (4, 2, 1, 90000.00),
    (5, 12, 1, 120000.00),
    (5, 2, 1, 90000.00),
    (6, 1, 1, 60000.00),
    (6, 4, 1, 80000.00),
    (6, 8, 1, 380000.00),
    (6, 2, 1, 90000.00),
    (7, 1, 1, 60000.00),
    (7, 14, 1, 140000.00),
    (7, 2, 1, 90000.00),
    (8, 1, 1, 60000.00),
    (8, 10, 1, 160000.00),
    (8, 2, 1, 90000.00),
    (9, 1, 1, 60000.00),
    (9, 13, 1, 100000.00),
    (9, 2, 1, 90000.00),
    (10, 1, 1, 60000.00),
    (10, 7, 1, 180000.00),
    (10, 9, 1, 70000.00),
    (10, 2, 1, 90000.00),
    (11, 1, 1, 60000.00),
    (11, 5, 1, 350000.00),
    (11, 2, 1, 90000.00),
    (12, 1, 1, 60000.00),
    (12, 15, 1, 900000.00),
    (13, 1, 1, 60000.00),
    (13, 14, 1, 140000.00),
    (13, 2, 1, 90000.00),
    (14, 12, 1, 120000.00),
    (14, 2, 1, 90000.00),
    (15, 1, 1, 60000.00),
    (15, 7, 1, 180000.00),
    (16, 1, 1, 60000.00),
    (16, 5, 1, 350000.00),
    (17, 1, 1, 60000.00),
    (18, 1, 1, 60000.00);

-- 10. FACTURA (20)
INSERT INTO factura (id_factura, numero_factura, fecha_emision, id_cliente, id_usuario, id_orden, tipo_pago, total) VALUES
    (1, 'AC-000001', '2026-06-03', 1, 3, 1, 'CREDITO', 348000.00),
    (2, 'AC-000002', '2026-06-10', 2, 4, 2, 'CREDITO', 1345000.00),
    (3, 'AC-000003', '2026-06-19', 3, 5, 3, 'CREDITO', 1084000.00),
    (4, 'AC-000004', '2026-07-04', 6, 3, 4, 'CREDITO', 3140000.00),
    (5, 'AC-000005', '2026-07-08', 4, 4, 5, 'CONTADO', 300000.00),
    (6, 'AC-000006', '2026-07-16', 5, 5, 6, 'CREDITO', 1151000.00),
    (7, 'AC-000007', '2026-07-25', 9, 3, 7, 'CREDITO', 772000.00),
    (8, 'AC-000008', '2026-08-04', 7, 4, 8, 'CONTADO', 523000.00),
    (9, 'AC-000009', '2026-08-13', 8, 5, 9, 'CREDITO', 429000.00),
    (10, 'AC-000010', '2026-08-24', 12, 3, 10, 'CREDITO', 1380000.00),
    (11, 'AC-000011', '2026-09-04', 6, 4, 11, 'CREDITO', 689000.00),
    (12, 'AC-000012', '2026-09-14', 15, 5, 12, 'CREDITO', 3260000.00),
    (13, 'AC-000013', '2026-09-24', 15, 3, 13, 'CREDITO', 606000.00),
    (14, 'AC-000014', '2026-10-06', 1, 4, 14, 'CONTADO', 300000.00),
    (15, 'AC-000015', '2026-09-28', 14, 14, NULL, 'CONTADO', 226000.00),
    (16, 'AC-000016', '2026-10-02', 2, 15, NULL, 'CREDITO', 740000.00),
    (17, 'AC-000017', '2026-10-07', 3, 3, NULL, 'CREDITO', 1660000.00),
    (18, 'AC-000018', '2026-10-10', 9, 14, NULL, 'CREDITO', 580000.00),
    (19, 'AC-000019', '2026-10-13', 6, 15, NULL, 'CREDITO', 1900000.00),
    (20, 'AC-000020', '2026-10-19', 1, 14, NULL, 'CONTADO', 118000.00);

-- 11. DETALLE_FACTURA (51)
INSERT INTO detalle_factura (id_factura, id_producto, cantidad, precio_unitario) VALUES
    (1, 7, 2, 38000.00),
    (1, 18, 1, 42000.00),
    (2, 1, 1, 980000.00),
    (2, 16, 1, 30000.00),
    (2, 9, 1, 55000.00),
    (3, 5, 1, 560000.00),
    (3, 10, 1, 80000.00),
    (3, 7, 3, 38000.00),
    (4, 3, 1, 1900000.00),
    (4, 10, 1, 80000.00),
    (4, 16, 2, 30000.00),
    (4, 8, 1, 580000.00),
    (5, 19, 1, 52000.00),
    (5, 7, 1, 38000.00),
    (6, 6, 1, 390000.00),
    (6, 17, 1, 45000.00),
    (6, 7, 2, 38000.00),
    (6, 16, 1, 30000.00),
    (7, 13, 1, 240000.00),
    (7, 7, 4, 38000.00),
    (7, 15, 1, 90000.00),
    (8, 11, 1, 120000.00),
    (8, 9, 1, 55000.00),
    (8, 7, 1, 38000.00),
    (9, 12, 3, 32000.00),
    (9, 7, 1, 38000.00),
    (9, 17, 1, 45000.00),
    (10, 4, 1, 320000.00),
    (10, 10, 1, 80000.00),
    (10, 8, 1, 580000.00),
    (11, 17, 1, 45000.00),
    (11, 16, 1, 30000.00),
    (11, 7, 3, 38000.00),
    (12, 20, 1, 2300000.00),
    (13, 13, 1, 240000.00),
    (13, 7, 2, 38000.00),
    (14, 19, 1, 52000.00),
    (14, 7, 1, 38000.00),
    (15, 7, 3, 38000.00),
    (15, 16, 2, 30000.00),
    (15, 19, 1, 52000.00),
    (16, 8, 1, 580000.00),
    (16, 12, 5, 32000.00),
    (17, 2, 1, 1100000.00),
    (17, 5, 1, 560000.00),
    (18, 15, 2, 90000.00),
    (18, 11, 2, 120000.00),
    (18, 10, 2, 80000.00),
    (19, 3, 1, 1900000.00),
    (20, 7, 2, 38000.00),
    (20, 18, 1, 42000.00);

-- 12. CREDITO (15)
INSERT INTO credito (id_credito, id_factura, fecha_inicio, fecha_limite, monto_total, saldo_pendiente, estado) VALUES
    (1, 1, '2026-06-03', '2026-07-03', 348000.00, 0.00, 'PAGADO'),
    (2, 2, '2026-06-10', '2026-07-10', 1345000.00, 0.00, 'PAGADO'),
    (3, 3, '2026-06-19', '2026-08-03', 1084000.00, 0.00, 'PAGADO'),
    (4, 4, '2026-07-04', '2026-09-02', 3140000.00, 628000.00, 'VENCIDO'),
    (5, 6, '2026-07-16', '2026-08-30', 1151000.00, 460000.00, 'VENCIDO'),
    (6, 7, '2026-07-25', '2026-09-23', 772000.00, 0.00, 'PAGADO'),
    (7, 9, '2026-08-13', '2026-09-27', 429000.00, 257000.00, 'VENCIDO'),
    (8, 10, '2026-08-24', '2026-10-23', 1380000.00, 552000.00, 'VENCIDO'),
    (9, 11, '2026-09-04', '2026-10-04', 689000.00, 482000.00, 'VENCIDO'),
    (10, 12, '2026-09-14', '2026-12-13', 3260000.00, 1630000.00, 'ACTIVO'),
    (11, 13, '2026-09-24', '2026-11-23', 606000.00, 424000.00, 'ACTIVO'),
    (12, 16, '2026-10-02', '2026-11-01', 740000.00, 740000.00, 'ACTIVO'),
    (13, 17, '2026-10-07', '2026-11-21', 1660000.00, 996000.00, 'ACTIVO'),
    (14, 18, '2026-10-10', '2026-11-09', 580000.00, 580000.00, 'ACTIVO'),
    (15, 19, '2026-10-13', '2026-12-12', 1900000.00, 1520000.00, 'ACTIVO');

-- 13. ABONO (22)
INSERT INTO abono (id_abono, id_credito, id_usuario, fecha_abono, monto, metodo_pago) VALUES
    (1, 1, 3, '2026-06-13', 174000.00, 'EFECTIVO'),
    (2, 1, 3, '2026-06-28', 174000.00, 'TRANSFERENCIA'),
    (3, 2, 4, '2026-06-18', 538000.00, 'TRANSFERENCIA'),
    (4, 2, 4, '2026-07-07', 807000.00, 'EFECTIVO'),
    (5, 3, 5, '2026-07-04', 542000.00, 'TRANSFERENCIA'),
    (6, 3, 5, '2026-07-29', 542000.00, 'TRANSFERENCIA'),
    (7, 4, 3, '2026-07-14', 942000.00, 'TRANSFERENCIA'),
    (8, 4, 4, '2026-08-08', 942000.00, 'TRANSFERENCIA'),
    (9, 4, 3, '2026-08-31', 628000.00, 'EFECTIVO'),
    (10, 5, 5, '2026-07-28', 403000.00, 'EFECTIVO'),
    (11, 5, 5, '2026-08-15', 288000.00, 'TARJETA'),
    (12, 6, 3, '2026-08-14', 386000.00, 'TRANSFERENCIA'),
    (13, 6, 3, '2026-09-18', 386000.00, 'TRANSFERENCIA'),
    (14, 7, 4, '2026-09-02', 172000.00, 'EFECTIVO'),
    (15, 8, 5, '2026-09-08', 414000.00, 'TRANSFERENCIA'),
    (16, 8, 5, '2026-10-03', 414000.00, 'EFECTIVO'),
    (17, 9, 3, '2026-09-16', 207000.00, 'EFECTIVO'),
    (18, 10, 4, '2026-09-29', 815000.00, 'TRANSFERENCIA'),
    (19, 10, 4, '2026-10-14', 815000.00, 'TRANSFERENCIA'),
    (20, 11, 5, '2026-10-08', 182000.00, 'EFECTIVO'),
    (21, 13, 3, '2026-10-12', 664000.00, 'TRANSFERENCIA'),
    (22, 15, 4, '2026-10-19', 380000.00, 'TARJETA');
