-- =====================================================================
-- Manejo de transacciones: venta con control de stock
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
-- =====================================================================
USE Farmacia_Proyecto;   
GO

-- Se ejecutan dos pruebas sobre el mismo lote:
--   PRUEBA 1: cantidad con stock suficiente   -> COMMIT  (venta registrada, stock descontado)
--   PRUEBA 2: cantidad mayor al stock         -> ROLLBACK (no queda ningun registro parcial)
SET NOCOUNT ON;

DECLARE @dni_empleado VARCHAR(15) = (SELECT TOP 1 dni FROM dbo.Empleado ORDER BY dni);
DECLARE @id_lote      INT         = (SELECT TOP 1 l.id_lote
                                     FROM dbo.lote l
                                     JOIN dbo.Producto p ON p.id_producto = l.id_producto
                                     WHERE l.stock >= 5
                                       AND l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
                                       AND p.requiere_receta = 0
                                     ORDER BY l.id_lote);
DECLARE @limpiar BIT = 1;       -- 1 = al final deshace la venta de la prueba 1 (restituye stock)

IF @id_lote IS NULL
BEGIN
    PRINT 'No hay un lote vigente con stock >= 5 para la prueba.';
    RETURN;
END;

DECLARE @i INT = 1, @cantidad INT, @id_venta INT, @id_venta_ok INT,
        @stock_antes INT, @ventas_antes INT;

WHILE @i <= 2
BEGIN
    SELECT @stock_antes  = stock    FROM dbo.lote WHERE id_lote = @id_lote;
    SELECT @ventas_antes = COUNT(*) FROM dbo.venta;
    SET @cantidad = CASE WHEN @i = 1 THEN 2 ELSE @stock_antes + 1 END;

    PRINT '--- PRUEBA ' + CAST(@i AS VARCHAR(1)) + ': venta de ' + CAST(@cantidad AS VARCHAR(10))
        + ' unidades del lote ' + CAST(@id_lote AS VARCHAR(10))
        + ' (stock actual: ' + CAST(@stock_antes AS VARCHAR(10)) + ')';

    BEGIN TRY
        BEGIN TRANSACTION;

            -- 1) Crear la venta
            INSERT INTO dbo.venta (fecha_hora, total, dni_cliente, dni_empleado)
            VALUES (GETDATE(), 0, NULL, @dni_empleado);
            SET @id_venta = SCOPE_IDENTITY();

            -- 2) Crear el detalle (precio historico del producto)
            INSERT INTO dbo.detalle_venta (id_venta, id_lote, cantidad, precio_unitario, id_receta)
            SELECT @id_venta, l.id_lote, @cantidad, p.precio, NULL
            FROM dbo.lote l
            JOIN dbo.Producto p ON p.id_producto = l.id_producto
            WHERE l.id_lote = @id_lote;

            -- 3) Descontar stock (solo si alcanza)
            UPDATE dbo.lote
               SET stock = stock - @cantidad
             WHERE id_lote = @id_lote
               AND stock >= @cantidad;

            IF @@ROWCOUNT = 0
                THROW 50010, 'Stock insuficiente: se cancela la venta.', 1;

            -- 4) Total de la venta
            UPDATE dbo.venta
               SET total = (SELECT SUM(cantidad * precio_unitario)
                            FROM dbo.detalle_venta WHERE id_venta = @id_venta)
             WHERE id_venta = @id_venta;

        COMMIT TRANSACTION;
        SET @id_venta_ok = @id_venta;
        PRINT 'COMMIT: venta ' + CAST(@id_venta AS VARCHAR(10)) + ' registrada.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'ROLLBACK: ' + ERROR_MESSAGE();
    END CATCH;

    -- Estado resultante: ventas nuevas y stock antes/despues
    SELECT @i AS prueba,
           (SELECT COUNT(*) FROM dbo.venta) - @ventas_antes AS ventas_nuevas,
           @stock_antes AS stock_antes,
           (SELECT stock FROM dbo.lote WHERE id_lote = @id_lote) AS stock_despues;

    SET @i += 1;
END;

-- Limpieza opcional de la venta de la prueba 1
IF @limpiar = 1 AND @id_venta_ok IS NOT NULL
BEGIN
    DELETE FROM dbo.detalle_venta WHERE id_venta = @id_venta_ok;
    DELETE FROM dbo.venta         WHERE id_venta = @id_venta_ok;
    UPDATE dbo.lote SET stock = stock + 2 WHERE id_lote = @id_lote;
    PRINT 'Limpieza: venta de prueba eliminada y stock restituido.';
END;
GO
