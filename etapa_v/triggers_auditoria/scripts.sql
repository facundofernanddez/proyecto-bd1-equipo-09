-- =====================================================================
-- ETAPA V - TRIGGERS DE AUDITORIA
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
--
-- REQUISITOS:
--   1. Base Farmacia_Proyecto creada y cargada (DDL + DML).
--   2. SQL Server 2016 SP1 o superior (por CREATE OR ALTER).
--
-- CONTENIDO:
--   Seccion 1: tabla de auditoria + trigger.
--   Seccion 2: demostracion (INSERT, UPDATE y DELETE con ROLLBACK final).
-- =====================================================================
USE Farmacia_Proyecto;
GO

-- =====================================================================
-- SECCION 1: TABLA DE AUDITORIA Y TRIGGER
-- =====================================================================

IF OBJECT_ID('dbo.auditoria_producto', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.auditoria_producto (
        id_auditoria       BIGINT IDENTITY(1,1) PRIMARY KEY,
        id_producto        INT NOT NULL,
        operacion          VARCHAR(6) NOT NULL
            CONSTRAINT CK_auditoria_producto_operacion
            CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE')),
        fecha_hora         DATETIME2(0) NOT NULL
            CONSTRAINT DF_auditoria_producto_fecha_hora DEFAULT SYSDATETIME(),
        usuario_bd         SYSNAME NOT NULL,
        nombre_anterior    VARCHAR(100) NULL,
        precio_anterior    DECIMAL(10,2) NULL,
        receta_anterior    BIT NULL,
        categoria_anterior INT NULL,
        laboratorio_anterior INT NULL,
        nombre_nuevo       VARCHAR(100) NULL,
        precio_nuevo       DECIMAL(10,2) NULL,
        receta_nueva       BIT NULL,
        categoria_nueva    INT NULL,
        laboratorio_nuevo  INT NULL
    );
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_auditoria_producto
ON dbo.Producto
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.auditoria_producto (
        id_producto,
        operacion,
        usuario_bd,
        nombre_anterior,
        precio_anterior,
        receta_anterior,
        categoria_anterior,
        laboratorio_anterior,
        nombre_nuevo,
        precio_nuevo,
        receta_nueva,
        categoria_nueva,
        laboratorio_nuevo
    )
    SELECT
        COALESCE(i.id_producto, d.id_producto),
        CASE
            WHEN d.id_producto IS NULL THEN 'INSERT'
            WHEN i.id_producto IS NULL THEN 'DELETE'
            ELSE 'UPDATE'
        END,
        USER_NAME(),
        d.nombre,
        d.precio,
        d.requiere_receta,
        d.id_categoria,
        d.id_laboratorio,
        i.nombre,
        i.precio,
        i.requiere_receta,
        i.id_categoria,
        i.id_laboratorio
    FROM inserted AS i
    FULL OUTER JOIN deleted AS d
        ON d.id_producto = i.id_producto;
END;
GO

-- =====================================================================
-- SECCION 2: DEMOSTRACION
-- =====================================================================
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

    --     COMMIT TRANSACTION;
    --     PRINT 'Demostracion finalizada: los cambios y sus registros de auditoria fueron confirmados.';
    ROLLBACK TRANSACTION;
    PRINT 'Demostracion finalizada: los cambios y sus registros de auditoria fueron revertidos.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
