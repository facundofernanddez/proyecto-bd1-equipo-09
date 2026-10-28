-- =====================================================================
-- Demostracion de los procedimientos almacenados
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
-- =====================================================================
USE Farmacia_Proyecto;
GO

SET NOCOUNT ON;

-- Parametros tomados de datos reales de la base
DECLARE @dni_empleado INT = (SELECT TOP 1 dni FROM dbo.Empleado ORDER BY dni);
DECLARE @dni_cliente  INT = (SELECT TOP 1 dni FROM dbo.Cliente  ORDER BY dni);
DECLARE @id_metodo    INT         = (SELECT TOP 1 id_metodo FROM dbo.Metodo_Pago ORDER BY id_metodo);
DECLARE @id_lote      INT         = (SELECT TOP 1 l.id_lote
                                     FROM dbo.lote l
                                     JOIN dbo.Producto p ON p.id_producto = l.id_producto
                                     WHERE l.stock >= 3
                                       AND l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
                                       AND p.requiere_receta = 0
                                     ORDER BY l.id_lote);
DECLARE @id_venta INT;
DECLARE @limpiar  BIT = 1;      -- 1 = deshace la venta de prueba al final; 0 = la deja registrada

IF @id_lote IS NULL
BEGIN
    PRINT 'No hay un lote vigente con stock suficiente para la prueba.';
    RETURN;
END;

-- Renglones de la venta (dos unidades del lote elegido)
DECLARE @items dbo.tipo_detalle_venta;
INSERT INTO @items (id_lote, cantidad, id_receta) VALUES (@id_lote, 2, NULL);

SELECT 'ANTES' AS momento, id_lote, stock FROM dbo.lote WHERE id_lote = @id_lote;

-- Llamada al procedimiento: una sola instruccion registra toda la venta
EXEC dbo.sp_RegistrarVentaCompleta
     @dni_empleado = @dni_empleado,
     @id_metodo    = @id_metodo,
     @detalle      = @items,
     @dni_cliente  = @dni_cliente,
     @id_venta     = @id_venta OUTPUT;

PRINT 'Venta registrada con id ' + CAST(@id_venta AS VARCHAR(10));

SELECT * FROM dbo.venta         WHERE id_venta = @id_venta;
SELECT * FROM dbo.detalle_venta WHERE id_venta = @id_venta;
SELECT * FROM dbo.pago          WHERE id_venta = @id_venta;
SELECT 'DESPUES' AS momento, id_lote, stock FROM dbo.lote WHERE id_lote = @id_lote;

-- Limpieza de la venta de prueba (devuelve el stock)
IF @limpiar = 1
BEGIN
    DELETE FROM dbo.pago          WHERE id_venta = @id_venta;
    DELETE FROM dbo.detalle_venta WHERE id_venta = @id_venta;
    DELETE FROM dbo.venta         WHERE id_venta = @id_venta;
    UPDATE dbo.lote SET stock = stock + 2 WHERE id_lote = @id_lote;
    PRINT 'Venta de prueba eliminada y stock restituido.';
END;

-- Procedimiento de reporte
EXEC dbo.sp_ReporteVentasPorVendedor @desde = '20260101', @hasta = '20261231';
GO
