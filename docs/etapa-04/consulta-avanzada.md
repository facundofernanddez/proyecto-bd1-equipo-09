# Consulta 3 – Consultas de negocio avanzadas

> Script ejecutable: [`sql/consultas/consulta_avanzada.sql`](../../sql/consultas/consulta_avanzada.sql)
> Volver al índice: [casos-uso.md](casos-uso.md)

Esta sección reúne cuatro consultas de negocio avanzadas sobre la base `Farmacia_Proyecto` (SQL Server). Todas combinan al menos 3 tablas mediante `JOIN` y aplican filtros condicionales (subconsultas, filtros por rango de fechas o sobre funciones de ventana).

---

## 3.1 Ranking de productos más vendidos por categoría

### Necesidad de información que resuelve

Conocer los 3 productos más vendidos dentro de cada categoría, para decidir qué priorizar en compras, exhibición y promociones, comparando cada producto solo contra los de su misma categoría.

### Estrategia SQL

- Se combinan cuatro tablas con `JOIN`: `detalle_venta`, `lote`, `producto` y `categoria`. Las ventas se registran por lote, por lo que hay que pasar por `lote` para llegar al producto.
- Una **CTE** (`ventas_producto`) agrupa por producto y suma las unidades vendidas con `SUM(dv.cantidad)`.
- `ROW_NUMBER() OVER (PARTITION BY categoria ORDER BY unidades DESC)` numera los productos dentro de cada categoría de mayor a menor venta.
- Como no se puede filtrar por una función de ventana en el mismo `SELECT` donde se calcula, se envuelve en una subconsulta y se filtra afuera con `WHERE puesto <= 3`.

### Consulta

```sql
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
```

### Resultado esperado

Hasta 3 filas por categoría, ordenadas por categoría y puesto.

| Columna | Descripción |
|---|---|
| `categoria` | Nombre de la categoría. |
| `producto` | Nombre del producto. |
| `unidades` | Unidades vendidas del producto (suma de todos sus lotes). |
| `puesto` | Posición dentro de la categoría (1, 2 o 3). |

**Resultado con los datos de prueba:** cada producto se vendió una sola vez (1 unidad), por lo que todos los productos de una misma categoría empatan.

| categoria | producto | unidades | puesto |
|---|---|---|---|
| Bebés y Maternidad | Champú Nivea Baby | 1 | 1 |
| Dermocosmética | Crema Dermaglós 200g | 1 | 1 |
| Dermocosmética | Protector Solar FPS50 | 1 | 2 |
| Medicamentos | *(uno de los 5 productos empatados)* | 1 | 1 |
| Medicamentos | *(uno de los 5 productos empatados)* | 1 | 2 |
| Medicamentos | *(uno de los 5 productos empatados)* | 1 | 3 |
| Primeros Auxilios | Alcohol en Gel 250ml | 1 | 1 |
| Suplementos y Vitaminas | Vitamina C Redoxon | 1 | 1 |

Las categorías sin ventas (Perfumería, Cuidado Personal, Ortopedia, etc.) no aparecen. En **Medicamentos** hay 5 productos con 1 unidad (Aspirina 500mg, Sertal Compuesto, Ibuprofeno 600mg, Amoxidal 500mg y Tylenol 500mg) y la consulta devuelve solo 3. Con empates, `ROW_NUMBER()` asigna puestos distintos sin un orden garantizado; para que los empatados compartan puesto se podría usar `RANK()`. Las categorías con menos de 3 productos vendidos devuelven menos filas.

---

## 3.2 Stock por producto y lotes próximos a vencer

### Necesidad de información que resuelve

Detectar los lotes con stock que vencen en los próximos 90 días, para rematarlos, devolverlos al proveedor o evitar pérdidas, y ver cuánto stock total tiene cada producto.

### Estrategia SQL

- Se combinan tres tablas con `JOIN`: `lote`, `producto` y `proveedor`.
- El filtro condicional en `WHERE` descarta lotes agotados (`l.stock > 0`) y limita los vencimientos a una ventana de 90 días con `BETWEEN` y `DATEADD`. `CAST(GETDATE() AS DATE)` compara solo fechas, sin hora, y excluye los lotes ya vencidos.
- `DATEDIFF(DAY, ...)` calcula los días que faltan para el vencimiento.
- `SUM(l.stock) OVER (PARTITION BY p.id_producto)` muestra el stock total del producto sin colapsar las filas, de modo que se ve el detalle por lote y el total en la misma fila.

### Consulta

```sql
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
```

### Resultado esperado

Una fila por lote con stock que vence dentro de los próximos 90 días, ordenada por fecha de vencimiento.

| Columna | Descripción |
|---|---|
| `producto` | Nombre del producto. |
| `id_lote` | Identificador del lote. |
| `fecha_vencimiento` | Fecha de vencimiento del lote. |
| `dias_para_vencer` | Días restantes hasta el vencimiento. |
| `stock` | Unidades que quedan en el lote. |
| `stock_total_producto` | Stock sumado de los lotes del producto que cumplen el filtro. |
| `proveedor` | Razón social del proveedor del lote. |

**Resultado con los datos de prueba** (ejecutada el 15/10/2026):

| producto | id_lote | fecha_vencimiento | dias_para_vencer | stock | stock_total_producto | proveedor |
|---|---|---|---|---|---|---|
| Aspirina 500mg | 1 | 2026-12-31 | 77 | 100 | 100 | Droguería Sur S.A. |
| Crema Dermaglós 200g | 5 | 2027-01-10 | 87 | 40 | 40 | Droguería del Litoral |

El resto de los lotes no aparece porque ya está vencido o vence después de los 90 días (el lote 8, por ejemplo, vence en 2027-05-18). Como la consulta usa `GETDATE()`, el resultado cambia según el día en que se ejecute. Cada producto tiene un solo lote, por eso `stock_total_producto` coincide con `stock`.

---

## 3.3 Clientes con gasto acumulado y su porcentaje sobre el total

### Necesidad de información que resuelve

Identificar a los mejores clientes: cuántas compras hizo cada uno, cuánto gastó y qué porcentaje representa sobre la facturación total. Sirve para programas de fidelización y para analizar la concentración de ventas.

### Estrategia SQL

- Se combinan tres tablas con `JOIN`: `venta`, `cliente` y `persona` (nombre y apellido).
- Se agrupa por cliente con `GROUP BY`, calculando `COUNT(v.id_venta)` y `SUM(v.total)`.
- `SUM(SUM(v.total)) OVER ()` obtiene el total general de ventas sin una subconsulta aparte; al dividir el gasto de cada cliente por ese total se obtiene su porcentaje, redondeado con `CAST(... AS DECIMAL(5,2))`.
- `RANK() OVER (ORDER BY SUM(v.total) DESC)` asigna el puesto de cada cliente; los clientes con el mismo gasto comparten posición.

### Consulta

```sql
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
```

### Resultado esperado

Una fila por cliente con al menos una compra, ordenada del mayor al menor gasto.

| Columna | Descripción |
|---|---|
| `dni` | DNI del cliente. |
| `cliente` | Nombre y apellido. |
| `compras` | Cantidad de ventas realizadas. |
| `gasto_total` | Monto total gastado. |
| `pct_del_total` | Porcentaje del gasto del cliente sobre el total de ventas (la columna suma 100%, salvo redondeos). |
| `ranking` | Posición según el gasto. |

**Resultado con los datos de prueba** (total general de ventas: 56050.50):

| dni | cliente | compras | gasto_total | pct_del_total | ranking |
|---|---|---|---|---|---|
| 42888999 | Valeria Rios | 1 | 12000.00 | 21.41 | 1 |
| 28999888 | Carlos Lopez | 1 | 11500.00 | 20.52 | 2 |
| 25333444 | Sofia Rodriguez | 1 | 9800.00 | 17.48 | 3 |
| 39444222 | Laura Benitez | 1 | 6400.00 | 11.42 | 4 |
| 38777666 | Lucas Fernandez | 1 | 4500.00 | 8.03 | 5 |
| 40123456 | Ana Martinez | 1 | 3500.00 | 6.24 | 6 |
| 35444555 | Maria Gomez | 1 | 3200.00 | 5.71 | 7 |
| 31555666 | Diego Torres | 1 | 2800.00 | 5.00 | 8 |
| 30111222 | Juan Perez | 1 | 1500.50 | 2.68 | 9 |
| 27111333 | Roberto Gomez | 1 | 850.00 | 1.52 | 10 |

Los 10 clientes tienen exactamente una compra. La columna `pct_del_total` suma 100.01 por redondeo.

---

## 3.4 Productos que nunca se vendieron

### Necesidad de información que resuelve

Detectar productos sin ninguna venta registrada, para revisar si conviene dejar de comprarlos, promocionarlos o retirarlos del catálogo y evitar capital inmovilizado.

### Estrategia SQL

- Subconsulta correlacionada con `NOT EXISTS`: para cada producto se verifica si existe al menos un renglón de venta asociado, vinculando ambas consultas con `l.id_producto = p.id_producto`.
- Dentro de la subconsulta se unen `lote` y `detalle_venta` con `JOIN`, porque `detalle_venta` referencia lotes y no productos. Junto con `producto` en la consulta externa participan 3 tablas.
- Se usa `NOT EXISTS` y no `NOT IN` porque se detiene al encontrar la primera coincidencia y no da resultados erróneos si hay valores `NULL`.

### Consulta

```sql
SELECT p.id_producto, p.nombre, p.precio
FROM producto p
WHERE NOT EXISTS (
    SELECT 1
    FROM lote l
    JOIN detalle_venta dv ON dv.id_lote = l.id_lote
    WHERE l.id_producto = p.id_producto
);
```

### Resultado esperado

Una fila por cada producto del catálogo sin ventas.

| Columna | Descripción |
|---|---|
| `id_producto` | Identificador del producto. |
| `nombre` | Nombre del producto. |
| `precio` | Precio de lista. |

**Resultado con los datos de prueba:** la consulta devuelve **0 filas**, porque los 10 productos tienen al menos una venta registrada (cada lote del 1 al 10 figura en un renglón de `detalle_venta`). Para ver la consulta en acción alcanza con insertar un producto nuevo sin ventas, por ejemplo:

```sql
INSERT INTO Producto (nombre, precio, requiere_receta, id_categoria, id_laboratorio)
VALUES ('Producto sin ventas', 1000.00, 0, 1, 1);
```

Al volver a ejecutarla aparece ese producto con su `id_producto`, `nombre` y `precio`.

---

## Resumen

| # | Necesidad de negocio | Tablas | Técnica principal |
|---|---|---|---|
| 3.1 | Top 3 de productos más vendidos por categoría | `detalle_venta`, `lote`, `producto`, `categoria` | CTE + `ROW_NUMBER() OVER (PARTITION BY ...)` |
| 3.2 | Lotes por vencer en 90 días y stock total del producto | `lote`, `producto`, `proveedor` | Filtro por rango de fechas + `SUM() OVER` |
| 3.3 | Ranking de clientes por gasto y porcentaje del total | `venta`, `cliente`, `persona` | `GROUP BY` + `SUM(SUM()) OVER ()` + `RANK()` |
| 3.4 | Productos sin ventas | `producto`, `lote`, `detalle_venta` | Subconsulta correlacionada `NOT EXISTS` |
