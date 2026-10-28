-- =====================================================================
-- Demostracion de seguridad con EXECUTE AS
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
-- =====================================================================
USE FarmaciaDB;   -- << REEMPLAZAR por el nombre real de la base de datos
GO

-- Se simula la sesion de cada usuario con EXECUTE AS USER ... REVERT.
SET NOCOUNT ON;

-- Datos necesarios, obtenidos con el usuario actual (dueno de la base)
DECLARE @dni_empleado VARCHAR(15) = (SELECT TOP 1 dni FROM dbo.Empleado ORDER BY dni);
DECLARE @id_metodo    INT         = (SELECT TOP 1 id_metodo FROM dbo.Metodo_Pago ORDER BY id_metodo);
DECLARE @id_lote      INT         = (SELECT TOP 1 l.id_lote
                                     FROM dbo.lote l
                                     JOIN dbo.Producto p ON p.id_producto = l.id_producto
                                     WHERE l.stock >= 1
                                       AND l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
                                       AND p.requiere_receta = 0
                                     ORDER BY l.id_lote);
DECLARE @id_venta INT;
DECLARE @items dbo.tipo_detalle_venta;
INSERT INTO @items (id_lote, cantidad, id_receta) VALUES (@id_lote, 1, NULL);

-- =============== VENDEDOR ===============
EXECUTE AS USER = 'usr_vendedor';
SELECT USER_NAME() AS sesion_actual;

-- 1) Permitido: ver lotes disponibles
BEGIN TRY
    SELECT TOP 3 * FROM dbo.vw_lotes_disponibles;
    PRINT '1) SELECT sobre vw_lotes_disponibles: PERMITIDO';
END TRY
BEGIN CATCH
    PRINT '1) ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 2) Denegado: datos personales
BEGIN TRY
    SELECT TOP 3 * FROM dbo.Persona;
    PRINT '2) SELECT sobre Persona: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '2) SELECT sobre Persona: DENEGADO -> ' + ERROR_MESSAGE();
END CATCH;

-- 3) Denegado: modificar stock directamente (WHERE 1 = 0 por seguridad: no toca filas)
BEGIN TRY
    UPDATE dbo.lote SET stock = 9999 WHERE 1 = 0;
    PRINT '3) UPDATE sobre lote: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '3) UPDATE sobre lote: DENEGADO -> ' + ERROR_MESSAGE();
END CATCH;

-- 4) Denegado: borrar ventas
BEGIN TRY
    DELETE FROM dbo.venta WHERE 1 = 0;
    PRINT '4) DELETE sobre venta: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '4) DELETE sobre venta: DENEGADO -> ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- 5) Permitido: registrar una venta a traves del procedimiento
--    (aunque no tiene permisos sobre las tablas, el procedimiento las usa por encadenamiento
--     de propiedad). Se hace dentro de una transaccion que se deshace.
BEGIN TRANSACTION;
    EXECUTE AS USER = 'usr_vendedor';
    BEGIN TRY
        EXEC dbo.sp_RegistrarVentaCompleta
             @dni_empleado = @dni_empleado, @id_metodo = @id_metodo,
             @detalle = @items, @dni_cliente = NULL, @id_venta = @id_venta OUTPUT;
        PRINT '5) EXEC sp_RegistrarVentaCompleta: PERMITIDO (venta ' + CAST(@id_venta AS VARCHAR(10)) + ')';
    END TRY
    BEGIN CATCH
        PRINT '5) ERROR: ' + ERROR_MESSAGE();
    END CATCH;
    REVERT;
    SELECT 'Venta vista por el dueno antes de deshacer' AS nota, * FROM dbo.venta WHERE id_venta = @id_venta;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

-- =============== GERENTE ===============
EXECUTE AS USER = 'usr_gerente';
SELECT USER_NAME() AS sesion_actual;
BEGIN TRY
    SELECT COUNT(*) AS ventas_visibles FROM dbo.venta;
    PRINT '6) SELECT sobre venta: PERMITIDO';
END TRY
BEGIN CATCH
    PRINT '6) ERROR: ' + ERROR_MESSAGE();
END CATCH;
BEGIN TRY
    DELETE FROM dbo.venta WHERE 1 = 0;
    PRINT '7) DELETE sobre venta: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '7) DELETE sobre venta: DENEGADO -> ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- =============== AUDITOR ===============
EXECUTE AS USER = 'usr_auditor';
SELECT USER_NAME() AS sesion_actual;
BEGIN TRY
    SELECT TOP 5 * FROM dbo.auditoria_producto ORDER BY id_auditoria DESC;
    PRINT '8) SELECT sobre auditoria_producto: PERMITIDO';
END TRY
BEGIN CATCH
    PRINT '8) ERROR: ' + ERROR_MESSAGE();
END CATCH;
BEGIN TRY
    SELECT TOP 1 * FROM dbo.venta;
    PRINT '9) SELECT sobre venta: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '9) SELECT sobre venta: DENEGADO -> ' + ERROR_MESSAGE();
END CATCH;
REVERT;

SELECT USER_NAME() AS sesion_final;   -- vuelve al usuario original
GO
