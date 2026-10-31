USE Farmacia_Proyecto;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @id_categoria INT,
        @id_laboratorio INT,
        @nombre_demo VARCHAR(100) = CONCAT('TRIGGER_DEMO_', CONVERT(VARCHAR(36), NEWID())),
        @id_producto INT;

SELECT TOP 1
    @id_categoria = id_categoria,
    @id_laboratorio = id_laboratorio
FROM dbo.Producto
ORDER BY id_producto;

IF @id_categoria IS NULL OR @id_laboratorio IS NULL
    THROW 50020, 'Se necesita al menos un producto para ejecutar la demostracion.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO dbo.Producto (
        nombre,
        precio,
        requiere_receta,
        id_categoria,
        id_laboratorio
    )
    VALUES (
        @nombre_demo,
        100.00,
        0,
        @id_categoria,
        @id_laboratorio
    );

    SET @id_producto = SCOPE_IDENTITY();

    UPDATE dbo.Producto
       SET precio = 125.00
     WHERE id_producto = @id_producto;

    DELETE FROM dbo.Producto
    WHERE id_producto = @id_producto;

    SELECT
        id_auditoria,
        id_producto,
        operacion,
        fecha_hora,
        usuario_bd,
        nombre_anterior,
        precio_anterior,
        nombre_nuevo,
        precio_nuevo
    FROM dbo.auditoria_producto
    WHERE id_producto = @id_producto
    ORDER BY id_auditoria;

    ROLLBACK TRANSACTION;
    PRINT 'Demostracion finalizada: los cambios y sus registros de auditoria fueron revertidos.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
