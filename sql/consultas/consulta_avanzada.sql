USE Farmacia_Proyecto;
GO

-- 1. Ranking de productos más vendidos dentro de cada categoría
WITH ventas_producto AS (
    SELECT
        p.id_producto,
        p.nombre                AS producto,
        c.nombre                AS categoria,
        SUM(dv.cantidad)        AS unidades
    FROM detalle_venta dv
    JOIN lote      l ON l.id_lote     = dv.id_lote
    JOIN producto  p ON p.id_producto = l.id_producto
    JOIN categoria c ON c.id_categoria = p.id_categoria
    GROUP BY p.id_producto, p.nombre, c.nombre
)
SELECT *
FROM (
    SELECT
        categoria, producto, unidades,
        ROW_NUMBER() OVER (PARTITION BY categoria ORDER BY unidades DESC) AS puesto
    FROM ventas_producto
) r
WHERE puesto <= 3
ORDER BY categoria, puesto;

-- 2. Stock total por producto y lotes que vencen en los próximos 90 días
SELECT
    p.nombre                                AS producto,
    l.id_lote,
    l.fecha_vencimiento,
    DATEDIFF(DAY, GETDATE(), l.fecha_vencimiento) AS dias_para_vencer,
    l.stock,
    SUM(l.stock) OVER (PARTITION BY p.id_producto) AS stock_total_producto,
    pr.razon_social                         AS proveedor
FROM lote l
JOIN producto  p  ON p.id_producto = l.id_producto
JOIN proveedor pr ON pr.dni        = l.dni_proveedor
WHERE l.stock > 0
  AND l.fecha_vencimiento BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 90, CAST(GETDATE() AS DATE))
ORDER BY l.fecha_vencimiento;

-- 3. Clientes con gasto acumulado y su porcentaje sobre el total
SELECT
    p.dni,
    p.nombre + ' ' + p.apellido             AS cliente,
    COUNT(v.id_venta)                       AS compras,
    SUM(v.total)                            AS gasto_total,
    CAST(100.0 * SUM(v.total) / SUM(SUM(v.total)) OVER () AS DECIMAL(5,2)) AS pct_del_total,
    RANK() OVER (ORDER BY SUM(v.total) DESC) AS ranking
FROM venta v
JOIN cliente c ON c.dni = v.dni_cliente
JOIN persona p ON p.dni = c.dni
GROUP BY p.dni, p.nombre, p.apellido
ORDER BY ranking;

-- 4. Productos que nunca se vendieron
SELECT p.id_producto, p.nombre, p.precio
FROM producto p
WHERE NOT EXISTS (
    SELECT 1
    FROM lote l
    JOIN detalle_venta dv ON dv.id_lote = l.id_lote
    WHERE l.id_producto = p.id_producto
);
GO