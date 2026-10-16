# Consulta 2 – Informe agregado de ventas

## Necesidad de información que resuelve

Obtener un resumen de las ventas realizadas dentro de un rango de fechas, agrupado por vendedor y por categoría de producto. Los informes permiten comparar el monto vendido y la cantidad de operaciones; el informe por categoría también muestra las unidades vendidas.

## Estrategia SQL

El script contiene dos consultas:

- **2.a Ventas por vendedor:** agrupa las ventas por empleado. El monto se suma desde `venta.total` y la cantidad se obtiene contando las ventas de la cabecera. Así, cada venta se cuenta y suma una sola vez aunque tenga varios renglones.
- **2.b Ventas por categoría:** recorre `venta` → `detalle_venta` → `lote` → `producto` → `categoria`. Suma el subtotal histórico de los renglones (`cantidad * precio_unitario`), cuenta las unidades y usa `COUNT(DISTINCT id_venta)` para no contar varias veces una venta que incluya más de un producto de la misma categoría.
- Ambas consultas reciben un rango de fechas inclusivo mediante `@fecha_desde` y `@fecha_hasta`. El límite superior se implementa como el día siguiente exclusivo para incluir todas las horas del último día.

## Script SQL

El archivo ejecutable es [informe_ventas.sql](../../sql/consultas/informe_ventas.sql). Antes de ejecutarlo, se pueden cambiar las fechas declaradas al comienzo del script.

## Resultado esperado con los datos de prueba

Los datos de prueba incluyen ventas del 1 al 10 de septiembre de 2026. Al usar el rango `20260901`–`20260930`, el informe por vendedor debe devolver:

| dni_vendedor | vendedor         | cantidad_ventas | total_ventas |
| -----------: | ---------------- | --------------: | -----------: |
|     40123456 | Rios, Ana        |               3 |     25000.00 |
|     28999888 | Lopez, Carlos    |               4 |     22200.50 |
|     38777666 | Fernandez, Lucas |               3 |      8850.00 |

El informe por categoría debe devolver:

| id_categoria | categoria               | cantidad_ventas | unidades_vendidas | total_ventas |
| -----------: | ----------------------- | --------------: | ----------------: | -----------: |
|            4 | Dermocosmética          |               2 |                 2 |     23500.00 |
|            1 | Medicamentos            |               5 |                 5 |     18400.50 |
|            6 | Suplementos y Vitaminas |               1 |                 1 |      9800.00 |
|            5 | Bebés y Maternidad      |               1 |                 1 |      3500.00 |
|            7 | Primeros Auxilios       |               1 |                 1 |       850.00 |

Los importes se basan en los precios guardados en el detalle de cada venta; cambiar los datos de prueba o el rango de fechas cambia los valores del resultado.
