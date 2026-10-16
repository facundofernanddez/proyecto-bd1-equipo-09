# Consulta 1 – Factura / Comprobante de venta

## Necesidad de información que resuelve

Obtener el comprobante completo de una venta, consolidando el encabezado (número, fecha, cliente y vendedor) con el detalle de cada renglón (producto, cantidad y precio unitario), e informando el subtotal de cada renglón y el total acumulado de la factura.

## Estrategia SQL

- Se parte de `venta` (encabezado) y se une con `detalle_venta` (renglones). Para obtener el nombre del producto se recorre `detalle_venta` → `lote` → `producto`.
- El vendedor se obtiene recorriendo `venta` → `empleado` → `persona`, y el cliente con `LEFT JOIN` a `cliente` y `persona`, de modo que una venta sin cliente registrado (consumidor final) también se muestre; en ese caso un `CASE` informa "Consumidor final" (se usa `CASE` en lugar de concatenar directamente porque el manejo de valores nulos en `CONCAT` varía según el motor).
- El subtotal de cada renglón se calcula como `cantidad * precio_unitario`, usando el precio guardado en el detalle (el precio histórico de la venta, no el actual del catálogo), tal como indica la regla de negocio RN.04.
- El total acumulado se calcula con la función de ventana `SUM() OVER (PARTITION BY id_venta ORDER BY id_detalle)`, que va sumando renglón a renglón; la columna `total_factura` repite el total final de la venta en cada fila.

## Consulta

```sql
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
```

## Resultado esperado (venta N° 1)

| nro_comprobante | fecha | cliente | vendedor | producto | cantidad | precio_unitario | subtotal_renglon | total_acumulado | total_factura |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-09-01 10:15:00 | Gimenez, Martina | Sosa, Lucia | Paracetamol 500mg x20 | 2 | 1200.00 | 2400.00 | 2400.00 | 3900.00 |
| 1 | 2026-09-01 10:15:00 | Gimenez, Martina | Sosa, Lucia | Loratadina 10mg x10 | 1 | 1500.00 | 1500.00 | 3900.00 | 3900.00 |

El último valor de `total_acumulado` coincide con `total_factura`. Si se cambia el filtro a `v.id_venta = 3`, la columna `cliente` muestra "Consumidor final".

---

## Consulta de control (1.b)

Verifica que el campo `venta.total` coincida con la suma real de los renglones de cada venta. Devuelve únicamente las ventas con diferencias.

```sql
SELECT
    v.id_venta,
    v.total                               AS total_registrado,
    SUM(dv.cantidad * dv.precio_unitario) AS total_calculado
FROM venta v
JOIN detalle_venta dv ON dv.id_venta = v.id_venta
GROUP BY v.id_venta, v.total
HAVING v.total <> SUM(dv.cantidad * dv.precio_unitario);
```

**Resultado esperado:** sin filas (todas las ventas tienen el total consistente con su detalle).
