-- Indices de optimizacion sobre las tablas del sistema
USE Farmacia_Proyecto; 
GO
-- Ventas por rango de fechas (reportes). INCLUDE evita volver a la tabla (indice "cubriente").
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_venta_fecha_hora' AND object_id = OBJECT_ID('dbo.venta'))
    CREATE NONCLUSTERED INDEX IX_venta_fecha_hora
        ON dbo.venta (fecha_hora) INCLUDE (dni_empleado, dni_cliente, total);

-- Compras de un cliente (funcion de descuento, consulta de clientes frecuentes)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_venta_dni_cliente' AND object_id = OBJECT_ID('dbo.venta'))
    CREATE NONCLUSTERED INDEX IX_venta_dni_cliente
        ON dbo.venta (dni_cliente) INCLUDE (total, fecha_hora);

-- Ventas de un vendedor en un periodo (reporte por vendedor)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_venta_dni_empleado_fecha' AND object_id = OBJECT_ID('dbo.venta'))
    CREATE NONCLUSTERED INDEX IX_venta_dni_empleado_fecha
        ON dbo.venta (dni_empleado, fecha_hora) INCLUDE (total);

-- Renglones de una venta (factura y todos los reportes que unen venta con detalle)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_detalle_venta_id_venta' AND object_id = OBJECT_ID('dbo.detalle_venta'))
    CREATE NONCLUSTERED INDEX IX_detalle_venta_id_venta
        ON dbo.detalle_venta (id_venta) INCLUDE (id_lote, cantidad, precio_unitario);

-- Ventas que consumieron un lote (trazabilidad de lotes)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_detalle_venta_id_lote' AND object_id = OBJECT_ID('dbo.detalle_venta'))
    CREATE NONCLUSTERED INDEX IX_detalle_venta_id_lote
        ON dbo.detalle_venta (id_lote);

-- Lotes de un producto ordenados por vencimiento (stock disponible, control de vencimientos)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_lote_producto_vencimiento' AND object_id = OBJECT_ID('dbo.lote'))
    CREATE NONCLUSTERED INDEX IX_lote_producto_vencimiento
        ON dbo.lote (id_producto, fecha_vencimiento) INCLUDE (stock);

-- Reporte de ventas por categoria
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Producto_id_categoria' AND object_id = OBJECT_ID('dbo.Producto'))
    CREATE NONCLUSTERED INDEX IX_Producto_id_categoria
        ON dbo.Producto (id_categoria);

-- Busqueda de personas por apellido y nombre en el mostrador
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Persona_apellido_nombre' AND object_id = OBJECT_ID('dbo.Persona'))
    CREATE NONCLUSTERED INDEX IX_Persona_apellido_nombre
        ON dbo.Persona (apellido, nombre);
GO

-- Verificacion: indices creados
SELECT OBJECT_NAME(object_id) AS tabla, name AS indice, type_desc AS tipo
FROM sys.indexes
WHERE name LIKE 'IX[_]%'
ORDER BY tabla, indice;
GO
