-- =====================================================================
-- ETAPA V - PROCEDIMIENTOS Y FUNCIONES
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
--
-- REQUISITOS:
--   1. Base Farmacia_Proyecto creada (sql/ddl/01_creacion_tablas.sql).
--   2. Datos de prueba cargados (sql/dml/02_datos_prueba.sql).
--   3. SQL Server 2016 SP1 o superior (por CREATE OR ALTER).
--
-- ORDEN DE EJECUCION:
--   Seccion 1: funciones
--   Seccion 2: procedimientos
--   Seccion 3: demostracion
-- =====================================================================
USE Farmacia_Proyecto;
GO

-- =====================================================================
-- SECCION 1: FUNCIONES ALMACENADAS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1.1 fn_CalcularDescuentoCliente
-- Devuelve el porcentaje de descuento segun el monto acumulado de compras.
--   Mas de $500.000 acumulados -> 10 %
--   Mas de $200.000 acumulados ->  5 %
--   Caso contrario             ->  0 %
-- ---------------------------------------------------------------------
CREATE OR ALTER FUNCTION dbo.fn_CalcularDescuentoCliente (@dni_cliente INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @acumulado DECIMAL(14,2);

    SELECT @acumulado = ISNULL(SUM(total), 0)
    FROM dbo.venta
    WHERE dni_cliente = @dni_cliente;

    RETURN CASE
               WHEN @acumulado > 500000 THEN 10.00
               WHEN @acumulado > 200000 THEN  5.00
               ELSE 0.00
           END;
END;
GO

-- ---------------------------------------------------------------------
-- 1.2 fn_StockDisponible
-- Suma el stock de los lotes NO vencidos de un producto (RN.02).
-- ---------------------------------------------------------------------
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

-- =====================================================================
-- SECCION 2: PROCEDIMIENTOS ALMACENADOS
-- =====================================================================

-- ---------------------------------------------------------------------
-- 2.1 sp_RegistrarVentaCompleta
-- Requiere dbo.fn_CalcularDescuentoCliente (seccion 1).
-- ---------------------------------------------------------------------

-- Tipo de tabla para enviar los renglones de la venta en una sola llamada.
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

-- ---------------------------------------------------------------------
-- 2.2 sp_ReporteVentasPorVendedor
-- Es la consulta 2.a de la Etapa IV convertida en procedimiento.
-- ---------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_ReporteVentasPorVendedor
    @desde DATE,
    @hasta DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT e.legajo,
           pe.apellido + ', ' + pe.nombre         AS vendedor,
           ca.descripcion                          AS cargo,
           COUNT(DISTINCT v.id_venta)              AS cantidad_ventas,
           SUM(dv.cantidad * dv.precio_unitario)   AS total_vendido
    FROM dbo.venta v
    JOIN dbo.detalle_venta dv ON dv.id_venta = v.id_venta
    JOIN dbo.Empleado e       ON e.dni = v.dni_empleado
    JOIN dbo.Persona pe       ON pe.dni = e.dni
    JOIN dbo.cargo ca         ON ca.id_cargo = e.id_cargo
    WHERE v.fecha_hora >= @desde
      AND v.fecha_hora <  DATEADD(DAY, 1, @hasta)   -- incluye todo el ultimo dia
    GROUP BY e.legajo, pe.apellido, pe.nombre, ca.descripcion
    ORDER BY total_vendido DESC;
END;
GO

-- =====================================================================
-- SECCION 3: DEMOSTRACION
-- =====================================================================

-- ---------------------------------------------------------------------
-- 3.1 Demostracion de las funciones
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- 3.2 Demostracion de los procedimientos
-- ---------------------------------------------------------------------
SET NOCOUNT ON;

-- Parametros tomados de datos reales de la base
DECLARE @dni_empleado INT = (SELECT TOP 1 dni FROM dbo.Empleado ORDER BY dni);
DECLARE @dni_cliente  INT = (SELECT TOP 1 dni FROM dbo.Cliente  ORDER BY dni);
DECLARE @id_metodo    INT = (SELECT TOP 1 id_metodo FROM dbo.Metodo_Pago ORDER BY id_metodo);
DECLARE @id_lote      INT = (SELECT TOP 1 l.id_lote
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
