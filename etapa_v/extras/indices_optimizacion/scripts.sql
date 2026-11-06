-- =====================================================================
-- Indices (optimizacion)
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
--
-- Contenido:
--   Seccion 1: crea 8 indices no agrupados sobre las tablas reales.
--   Seccion 2: demo de rendimiento con tablas de prueba (300.000 ventas
--              y 900.000 renglones) para comparar consultas sin y con indice.
--
-- Requisitos:
--   Haber ejecutado el DDL y el DML del proyecto.
--
-- ADVERTENCIA:
--   La seccion 2 genera 1.200.000 filas y puede tardar varios minutos en
--   SQL Server Express. Necesita espacio en disco. Al final elimina las
--   tablas de prueba. Si la ejecucion se interrumpe, volver a correr el
--   script: el inicio de la seccion 2 hace DROP de las tablas si existen.
-- =====================================================================
USE Farmacia_Proyecto;
GO

-- =====================================================================
-- SECCION 1: INDICES SOBRE LAS TABLAS REALES
-- SQL Server crea indices automaticamente para PRIMARY KEY y UNIQUE,
-- pero NO para FOREIGN KEY. Estos indices cubren los accesos frecuentes
-- de las consultas de la Etapa IV y de los objetos de la Etapa V.
-- =====================================================================

-- Ventas por rango de fechas (reportes). INCLUDE evita volver a la tabla.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_venta_fecha_hora' AND object_id = OBJECT_ID('dbo.venta'))
    CREATE NONCLUSTERED INDEX IX_venta_fecha_hora
        ON dbo.venta (fecha_hora) INCLUDE (dni_empleado, dni_cliente, total);

-- Compras de un cliente (funcion de descuento, consulta de clientes frecuentes).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_venta_dni_cliente' AND object_id = OBJECT_ID('dbo.venta'))
    CREATE NONCLUSTERED INDEX IX_venta_dni_cliente
        ON dbo.venta (dni_cliente) INCLUDE (total, fecha_hora);

-- Ventas de un vendedor en un periodo (reporte por vendedor).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_venta_dni_empleado_fecha' AND object_id = OBJECT_ID('dbo.venta'))
    CREATE NONCLUSTERED INDEX IX_venta_dni_empleado_fecha
        ON dbo.venta (dni_empleado, fecha_hora) INCLUDE (total);

-- Renglones de una venta (factura y reportes que unen venta con detalle).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_detalle_venta_id_venta' AND object_id = OBJECT_ID('dbo.detalle_venta'))
    CREATE NONCLUSTERED INDEX IX_detalle_venta_id_venta
        ON dbo.detalle_venta (id_venta) INCLUDE (id_lote, cantidad, precio_unitario);

-- Ventas que consumieron un lote (trazabilidad de lotes).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_detalle_venta_id_lote' AND object_id = OBJECT_ID('dbo.detalle_venta'))
    CREATE NONCLUSTERED INDEX IX_detalle_venta_id_lote
        ON dbo.detalle_venta (id_lote);

-- Lotes de un producto ordenados por vencimiento (stock y vencimientos).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_lote_producto_vencimiento' AND object_id = OBJECT_ID('dbo.lote'))
    CREATE NONCLUSTERED INDEX IX_lote_producto_vencimiento
        ON dbo.lote (id_producto, fecha_vencimiento) INCLUDE (stock);

-- Reporte de ventas por categoria.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Producto_id_categoria' AND object_id = OBJECT_ID('dbo.Producto'))
    CREATE NONCLUSTERED INDEX IX_Producto_id_categoria
        ON dbo.Producto (id_categoria);

-- Busqueda de personas por apellido y nombre en el mostrador.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Persona_apellido_nombre' AND object_id = OBJECT_ID('dbo.Persona'))
    CREATE NONCLUSTERED INDEX IX_Persona_apellido_nombre
        ON dbo.Persona (apellido, nombre);
GO

-- Verificacion: indices creados.
SELECT OBJECT_NAME(object_id) AS tabla, name AS indice, type_desc AS tipo
FROM sys.indexes
WHERE name LIKE 'IX[_]%'
ORDER BY tabla, indice;
GO

-- =====================================================================
-- SECCION 2: DEMOSTRACION DE RENDIMIENTO
-- Las tablas reales tienen pocos registros y los indices casi no se notan.
-- Por eso se crean tablas de prueba con volumen y se comparan las mismas
-- consultas SIN y CON indices. Activar "Incluir plan de ejecucion real"
-- (Ctrl+M) para ver Table Scan vs Index Seek.
-- =====================================================================

-- ---------- 2.1) Tablas y datos de prueba (300.000 ventas, 900.000 renglones) ----------
IF OBJECT_ID('dbo.perf_detalle') IS NOT NULL DROP TABLE dbo.perf_detalle;
IF OBJECT_ID('dbo.perf_venta')   IS NOT NULL DROP TABLE dbo.perf_venta;

CREATE TABLE dbo.perf_venta
(
    id_venta     INT           NOT NULL PRIMARY KEY,
    fecha_hora   DATETIME      NOT NULL,
    total        DECIMAL(10,2) NOT NULL,
    dni_cliente  INT           NULL,
    dni_empleado INT           NOT NULL
);
CREATE TABLE dbo.perf_detalle
(
    id_detalle      INT IDENTITY(1,1) PRIMARY KEY,
    id_venta        INT           NOT NULL,
    id_lote         INT           NOT NULL,
    cantidad        INT           NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL
);
GO

;WITH n AS (
    SELECT TOP (300000) CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT) AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.perf_venta (id_venta, fecha_hora, total, dni_cliente, dni_empleado)
SELECT n,
       DATEADD(MINUTE, -(n % 525600), GETDATE()),   -- repartidas en el ultimo anio
       (n % 9000) + 100,
       30000000 + (n % 20000),                      -- DNI de cliente (INT)
       31000000 + (n % 8)                           -- DNI de empleado (INT)
FROM n;

INSERT INTO dbo.perf_detalle (id_venta, id_lote, cantidad, precio_unitario)
SELECT v.id_venta, 1 + ((v.id_venta + t.k) % 10), 1 + (v.id_venta % 3), 500 + (v.id_venta % 5000)
FROM dbo.perf_venta v
CROSS JOIN (VALUES (1), (2), (3)) AS t(k);
GO

-- ---------- 2.2) Consultas SIN indices ----------
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DECLARE @desde DATETIME = DATEADD(DAY, -30, GETDATE()), @hasta DATETIME = DATEADD(DAY, -23, GETDATE());

PRINT '--- SIN INDICE: ventas de una semana agrupadas por vendedor ---';
SELECT dni_empleado, COUNT(*) AS ventas, SUM(total) AS total
FROM dbo.perf_venta
WHERE fecha_hora >= @desde AND fecha_hora < @hasta
GROUP BY dni_empleado
OPTION (RECOMPILE);

PRINT '--- SIN INDICE: compras de un cliente ---';
SELECT id_venta, fecha_hora, total
FROM dbo.perf_venta
WHERE dni_cliente = 30001234;

PRINT '--- SIN INDICE: renglones de una venta ---';
SELECT id_detalle, id_lote, cantidad, precio_unitario
FROM dbo.perf_detalle
WHERE id_venta = 123456;
GO

-- ---------- 2.3) Creacion de los indices de prueba ----------
CREATE NONCLUSTERED INDEX IX_perf_venta_fecha   ON dbo.perf_venta (fecha_hora)  INCLUDE (dni_empleado, total);
CREATE NONCLUSTERED INDEX IX_perf_venta_cliente ON dbo.perf_venta (dni_cliente) INCLUDE (fecha_hora, total);
CREATE NONCLUSTERED INDEX IX_perf_detalle_venta ON dbo.perf_detalle (id_venta)  INCLUDE (id_lote, cantidad, precio_unitario);
GO

-- ---------- 2.4) Las mismas consultas CON indices ----------
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DECLARE @desde DATETIME = DATEADD(DAY, -30, GETDATE()), @hasta DATETIME = DATEADD(DAY, -23, GETDATE());

PRINT '--- CON INDICE: ventas de una semana agrupadas por vendedor ---';
SELECT dni_empleado, COUNT(*) AS ventas, SUM(total) AS total
FROM dbo.perf_venta
WHERE fecha_hora >= @desde AND fecha_hora < @hasta
GROUP BY dni_empleado
OPTION (RECOMPILE);

PRINT '--- CON INDICE: compras de un cliente ---';
SELECT id_venta, fecha_hora, total
FROM dbo.perf_venta
WHERE dni_cliente = 30001234;

PRINT '--- CON INDICE: renglones de una venta ---';
SELECT id_detalle, id_lote, cantidad, precio_unitario
FROM dbo.perf_detalle
WHERE id_venta = 123456;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- ---------- 2.5) Limpieza de las tablas de prueba ----------
DROP TABLE dbo.perf_detalle;
DROP TABLE dbo.perf_venta;
GO
