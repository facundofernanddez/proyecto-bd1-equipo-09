-- Demostracion de rendimiento: consultas con y sin indices
USE Farmacia_Proyecto;
GO
-- ---------- 1) Tablas y datos de prueba (300.000 ventas, 900.000 renglones) ----------
IF OBJECT_ID('dbo.perf_detalle') IS NOT NULL DROP TABLE dbo.perf_detalle;
IF OBJECT_ID('dbo.perf_venta')   IS NOT NULL DROP TABLE dbo.perf_venta;

CREATE TABLE dbo.perf_venta
(
    id_venta     INT           NOT NULL PRIMARY KEY,
    fecha_hora   DATETIME      NOT NULL,
    total        DECIMAL(10,2) NOT NULL,
    dni_cliente  INT NULL,
    dni_empleado INT NOT NULL
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
       DATEADD(MINUTE, -(n % 525600), GETDATE()),                 -- repartidas en el ultimo anio
       (n % 9000) + 100,
       CAST(30000000 + (n % 20000) AS VARCHAR(15)),
       CAST(31000000 + (n % 8)     AS VARCHAR(15))
FROM n;

INSERT INTO dbo.perf_detalle (id_venta, id_lote, cantidad, precio_unitario)
SELECT v.id_venta, 1 + ((v.id_venta + t.k) % 10), 1 + (v.id_venta % 3), 500 + (v.id_venta % 5000)
FROM dbo.perf_venta v
CROSS JOIN (VALUES (1), (2), (3)) AS t(k);
GO

-- ---------- 2) Consultas SIN indices ----------
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
SELECT id_venta, fecha_hora, total FROM dbo.perf_venta WHERE dni_cliente = '30001234';

PRINT '--- SIN INDICE: renglones de una venta ---';
SELECT id_detalle, id_lote, cantidad, precio_unitario FROM dbo.perf_detalle WHERE id_venta = 123456;
GO

-- ---------- 3) Creacion de los indices ----------
CREATE NONCLUSTERED INDEX IX_perf_venta_fecha   ON dbo.perf_venta (fecha_hora)  INCLUDE (dni_empleado, total);
CREATE NONCLUSTERED INDEX IX_perf_venta_cliente ON dbo.perf_venta (dni_cliente) INCLUDE (fecha_hora, total);
CREATE NONCLUSTERED INDEX IX_perf_detalle_venta ON dbo.perf_detalle (id_venta)  INCLUDE (id_lote, cantidad, precio_unitario);
GO

-- ---------- 4) Las mismas consultas CON indices ----------
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
SELECT id_venta, fecha_hora, total FROM dbo.perf_venta WHERE dni_cliente = '30001234';

PRINT '--- CON INDICE: renglones de una venta ---';
SELECT id_detalle, id_lote, cantidad, precio_unitario FROM dbo.perf_detalle WHERE id_venta = 123456;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- ---------- 5) Limpieza de las tablas de prueba ----------
DROP TABLE dbo.perf_detalle;
DROP TABLE dbo.perf_venta;
GO
