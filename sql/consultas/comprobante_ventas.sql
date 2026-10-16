
SELECT
    v.id_venta                                   AS nro_comprobante,
    v.fecha_hora                                 AS fecha,
    CASE WHEN pc.dni IS NULL THEN 'Consumidor final'
         ELSE CONCAT(pc.apellido, ', ', pc.nombre) END AS cliente,
    CONCAT(pv.apellido, ', ', pv.nombre)         AS vendedor,
    pr.nombre                                    AS producto,
    dv.cantidad,
    dv.precio_unitario,
    dv.cantidad * dv.precio_unitario             AS subtotal_renglon,
    SUM(dv.cantidad * dv.precio_unitario)
        OVER (PARTITION BY v.id_venta ORDER BY dv.id_detalle) AS total_acumulado,
    SUM(dv.cantidad * dv.precio_unitario)
        OVER (PARTITION BY v.id_venta)           AS total_factura
FROM venta v
JOIN detalle_venta dv ON dv.id_venta = v.id_venta
JOIN lote l           ON l.id_lote = dv.id_lote
JOIN producto pr      ON pr.id_producto = l.id_producto
JOIN empleado e       ON e.dni = v.dni_empleado
JOIN persona pv       ON pv.dni = e.dni
LEFT JOIN cliente c   ON c.dni = v.dni_cliente
LEFT JOIN persona pc  ON pc.dni = c.dni
WHERE v.id_venta = 1
ORDER BY dv.id_detalle;

-- CONSULTA 1.b (control): ventas cuyo total registrado difiere del calculado
-- Resultado esperado: sin filas
SELECT
    v.id_venta,
    v.total                               AS total_registrado,
    SUM(dv.cantidad * dv.precio_unitario) AS total_calculado
FROM venta v
JOIN detalle_venta dv ON dv.id_venta = v.id_venta
GROUP BY v.id_venta, v.total
HAVING v.total <> SUM(dv.cantidad * dv.precio_unitario);
