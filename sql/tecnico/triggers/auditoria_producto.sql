USE Farmacia_Proyecto;
GO

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
