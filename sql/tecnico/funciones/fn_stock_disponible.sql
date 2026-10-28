-- =====================================================================
-- Funcion: stock disponible (vendible) de un producto
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
-- =====================================================================
USE Farmacia_Proyecto;
GO

-- El stock se guarda por lote (RN.02). Esta funcion suma el stock de los lotes
-- NO vencidos de un producto, es decir, lo que realmente se puede vender hoy.
CREATE OR ALTER FUNCTION dbo.fn_StockDisponible (@id_producto INT)
RETURNS INT
AS
BEGIN
    RETURN ISNULL((SELECT SUM(stock)
                   FROM dbo.lote
                   WHERE id_producto = @id_producto
                     AND fecha_vencimiento >= CAST(GETDATE() AS DATE)), 0);
END;
GO
