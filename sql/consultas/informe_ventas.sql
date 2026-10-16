USE Farmacia_Proyecto;
GO

-- Rango inclusivo: modificar estas fechas para consultar otro período.
DECLARE @fecha_desde DATE = '20260901';
DECLARE @fecha_hasta DATE = '20260930';

-- 2.a Ventas por vendedor.
-- Se consulta el total de venta desde la cabecera para evitar duplicarlo
-- cuando una venta tiene varios renglones de detalle.
SELECT
    e.dni                                      AS dni_vendedor,
    CONCAT(p.apellido, ', ', p.nombre)         AS vendedor,
    COUNT(v.id_venta)                          AS cantidad_ventas,
    SUM(v.total)                               AS total_ventas
FROM venta v
JOIN empleado e ON e.dni = v.dni_empleado
JOIN persona p  ON p.dni = e.dni
WHERE v.fecha_hora >= @fecha_desde
  AND v.fecha_hora < DATEADD(DAY, 1, @fecha_hasta)
GROUP BY e.dni, p.apellido, p.nombre
ORDER BY total_ventas DESC, vendedor;

-- 2.b Ventas por categoría.
-- El importe se calcula con el precio histórico de cada renglón vendido.
SELECT
    c.id_categoria                           AS id_categoria,
    c.nombre                                  AS categoria,
    COUNT(DISTINCT v.id_venta)               AS cantidad_ventas,
    SUM(dv.cantidad)                          AS unidades_vendidas,
    SUM(dv.cantidad * dv.precio_unitario)     AS total_ventas
FROM venta v
JOIN detalle_venta dv ON dv.id_venta = v.id_venta
JOIN lote l           ON l.id_lote = dv.id_lote
JOIN producto pr      ON pr.id_producto = l.id_producto
JOIN categoria c      ON c.id_categoria = pr.id_categoria
WHERE v.fecha_hora >= @fecha_desde
  AND v.fecha_hora < DATEADD(DAY, 1, @fecha_hasta)
GROUP BY c.id_categoria, c.nombre
ORDER BY total_ventas DESC, categoria;
GO
