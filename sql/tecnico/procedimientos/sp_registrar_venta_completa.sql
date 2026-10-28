-- =====================================================================
-- Procedimiento: registrar una venta completa
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
-- =====================================================================
USE Farmacia_Proyecto;
GO

-- Requiere que exista dbo.fn_CalcularDescuentoCliente (ejecutar primero la carpeta funciones).

-- Tipo de tabla para enviar los renglones de la venta en una sola llamada (parametro tipo tabla).
IF TYPE_ID('dbo.tipo_detalle_venta') IS NULL
    CREATE TYPE dbo.tipo_detalle_venta AS TABLE
    (
        id_lote   INT NOT NULL,
        cantidad  INT NOT NULL CHECK (cantidad > 0),
        id_receta INT NULL
    );
GO

CREATE OR ALTER PROCEDURE dbo.sp_RegistrarVentaCompleta
    @dni_empleado INT,
    @id_metodo    INT,
    @detalle      dbo.tipo_detalle_venta READONLY,
    @dni_cliente  INT         = NULL,      -- NULL = consumidor final (se resuelve al cliente generico)
    @id_venta     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @descuento DECIMAL(5,2) = 0,
            @total     DECIMAL(12,2),
            @lotes     INT,
            @filas     INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ---------- Consumidor final ----------
        -- venta.dni_cliente es NOT NULL (FK a cliente). Si no se indica cliente,
        -- se usa el cliente generico "Consumidor Final" (dni 99999999).
        IF @dni_cliente IS NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE dni = 99999999)
                THROW 50009, 'Consumidor final sin registrar: falta el cliente generico dni 99999999 en los datos de prueba.', 1;
            SET @dni_cliente = 99999999;
        END;

        -- ---------- Validaciones de entrada ----------
        IF NOT EXISTS (SELECT 1 FROM @detalle)
            THROW 50001, 'La venta no tiene renglones.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE dni = @dni_empleado)
            THROW 50002, 'El vendedor indicado no existe.', 1;

        IF @dni_cliente IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE dni = @dni_cliente)
            THROW 50003, 'El cliente indicado no esta registrado.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.Metodo_Pago WHERE id_metodo = @id_metodo)
            THROW 50004, 'El metodo de pago indicado no existe.', 1;

        IF EXISTS (SELECT 1 FROM @detalle d
                   LEFT JOIN dbo.lote l ON l.id_lote = d.id_lote
                   WHERE l.id_lote IS NULL)
            THROW 50005, 'Alguno de los lotes indicados no existe.', 1;

        -- RN.02: no se vende un lote vencido
        IF EXISTS (SELECT 1 FROM @detalle d
                   JOIN dbo.lote l ON l.id_lote = d.id_lote
                   WHERE l.fecha_vencimiento < CAST(GETDATE() AS DATE))
            THROW 50006, 'No se puede vender un lote vencido.', 1;

        -- RN.06: un producto bajo receta exige el dato de la receta
        IF EXISTS (SELECT 1 FROM @detalle d
                   JOIN dbo.lote l ON l.id_lote = d.id_lote
                   JOIN dbo.Producto p ON p.id_producto = l.id_producto
                   WHERE p.requiere_receta = 1 AND d.id_receta IS NULL)
            THROW 50007, 'Un producto bajo receta requiere el numero de receta.', 1;

        -- ---------- Descuento por cliente frecuente ----------
        IF @dni_cliente IS NOT NULL
            SET @descuento = dbo.fn_CalcularDescuentoCliente(@dni_cliente);

        -- ---------- 1) Encabezado de la venta ----------
        INSERT INTO dbo.venta (fecha_hora, total, dni_cliente, dni_empleado)
        VALUES (GETDATE(), 0, @dni_cliente, @dni_empleado);

        SET @id_venta = SCOPE_IDENTITY();

        -- ---------- 2) Detalle con precio historico (RN.04) ----------
        -- El descuento se refleja en el precio_unitario efectivamente cobrado, asi
        -- venta.total sigue siendo igual a la suma de los renglones.
        INSERT INTO dbo.detalle_venta (id_venta, id_lote, cantidad, precio_unitario, id_receta)
        SELECT @id_venta, d.id_lote, d.cantidad,
               ROUND(p.precio * (1 - @descuento / 100.0), 2),
               d.id_receta
        FROM @detalle d
        JOIN dbo.lote l     ON l.id_lote = d.id_lote
        JOIN dbo.Producto p ON p.id_producto = l.id_producto;

        -- ---------- 3) Descuento de stock (RN.01) ----------
        -- UPDATE condicionado: solo descuenta si alcanza el stock. Es atomico, por lo
        -- que dos ventas simultaneas no pueden vender la misma ultima unidad.
        SELECT @lotes = COUNT(DISTINCT id_lote) FROM @detalle;

        UPDATE l
           SET l.stock = l.stock - x.cant
        FROM dbo.lote l
        JOIN (SELECT id_lote, SUM(cantidad) AS cant
              FROM @detalle
              GROUP BY id_lote) x ON x.id_lote = l.id_lote
        WHERE l.stock >= x.cant;

        SET @filas = @@ROWCOUNT;

        IF @filas <> @lotes
            THROW 50008, 'Stock insuficiente en alguno de los lotes. Venta cancelada.', 1;

        -- ---------- 4) Total de la venta ----------
        SELECT @total = SUM(cantidad * precio_unitario)
        FROM dbo.detalle_venta
        WHERE id_venta = @id_venta;

        UPDATE dbo.venta SET total = @total WHERE id_venta = @id_venta;

        -- ---------- 5) Pago (RN.05) ----------
        INSERT INTO dbo.pago (id_venta, id_metodo, monto)
        VALUES (@id_venta, @id_metodo, @total);

        -- ---------- 6) Confirmar ----------
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @id_venta = NULL;
        THROW;   -- vuelve a lanzar el error original al que llamo
    END CATCH
END;
GO
