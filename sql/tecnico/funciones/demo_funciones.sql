-- =====================================================================
-- Demostracion de las funciones almacenadas
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
-- =====================================================================
USE Farmacia_Proyecto;
GO

SET NOCOUNT ON;

-- 1) Descuento actual de cada cliente (segun lo que ya compro)
SELECT c.dni,
       p.apellido + ', ' + p.nombre AS cliente,
       ISNULL((SELECT SUM(v.total) FROM dbo.venta v WHERE v.dni_cliente = c.dni), 0) AS acumulado,
       dbo.fn_CalcularDescuentoCliente(c.dni) AS descuento_pct
FROM dbo.Cliente c
JOIN dbo.Persona p ON p.dni = c.dni
ORDER BY acumulado DESC;

-- 2) Simulacion: se agregan compras grandes a un cliente y se observa el descuento.
--    Todo se hace dentro de una transaccion que se deshace al final (no deja datos).
DECLARE @dni INT = (SELECT TOP 1 dni FROM dbo.Cliente  ORDER BY dni);
DECLARE @emp INT = (SELECT TOP 1 dni FROM dbo.Empleado ORDER BY dni);

SELECT 'Antes' AS momento, @dni AS dni_cliente, dbo.fn_CalcularDescuentoCliente(@dni) AS descuento_pct;

BEGIN TRANSACTION;

    INSERT INTO dbo.venta (fecha_hora, total, dni_cliente, dni_empleado)
    VALUES (GETDATE(), 250000, @dni, @emp);
    SELECT '+ $250.000 acumulados' AS momento, @dni AS dni_cliente,
           dbo.fn_CalcularDescuentoCliente(@dni) AS descuento_pct;

    INSERT INTO dbo.venta (fecha_hora, total, dni_cliente, dni_empleado)
    VALUES (GETDATE(), 300000, @dni, @emp);
    SELECT '+ $550.000 acumulados' AS momento, @dni AS dni_cliente,
           dbo.fn_CalcularDescuentoCliente(@dni) AS descuento_pct;

ROLLBACK TRANSACTION;

SELECT 'Despues del ROLLBACK' AS momento, @dni AS dni_cliente,
       dbo.fn_CalcularDescuentoCliente(@dni) AS descuento_pct;

-- 3) Stock vendible por producto (lotes no vencidos)
SELECT p.id_producto, p.nombre, dbo.fn_StockDisponible(p.id_producto) AS stock_disponible
FROM dbo.Producto p
ORDER BY p.id_producto;
GO
