# Etapa IV – Consultas y Casos de Uso

**Proyecto Integrador: Sistema de Gestión de Ventas para Farmacia**
Bases de Datos 1 – 2026 – Grupo n° 9

## Consideraciones generales

- Motor de base de datos: **SQL Server 2012 o superior**. Algunas de las consultas utilizan funciones de ventana.
- Los nombres de tablas y columnas corresponden al modelo relacional final del proyecto.
- Las fechas se escriben en formato `AAAAMMDD`, que el motor interpreta de la misma forma sin importar la configuración regional del servidor.
- Los resultados que se muestran fueron obtenidos con datos de prueba. Con otros datos los valores cambian, pero la estructura del resultado es la misma. Los parámetros (número de venta, rango de fechas) pueden modificarse directamente en cada consulta.

## Actores

| Actor | Rol en el sistema |
|---|---|
| **Empleado (vendedor)** | Opera el punto de venta: registra las ventas y emite el comprobante. |
| **Administrador / Encargado** | Supervisa la operatoria: controla la consistencia de las ventas y analiza el desempeño comercial. |

## Casos de uso

Cada caso de uso se resuelve mediante una consulta documentada en `docs/etapa-04/` y su script correspondiente en `sql/consultas/`.

| CU | Caso de uso | Actor | Consulta | ¿Qué resuelve? | Documentación | Script |
|---|---|---|---|---|---|---|
| CU-01 | Emitir comprobante de venta | Empleado (vendedor) | 1 | Comprobante completo de una venta, con subtotales y total acumulado | [comprobante.de.venta.md](comprobante.de.venta.md) | [comprobante_ventas.sql](../../sql/consultas/comprobante_ventas.sql) |
| CU-02 | Controlar la consistencia del total de una venta | Administrador | 1.b | Detecta ventas cuyo total registrado no coincide con su detalle | [comprobante.de.venta.md](comprobante.de.venta.md) | [comprobante_ventas.sql](../../sql/consultas/comprobante_ventas.sql) |
| CU-03 | Consultar ventas por vendedor | Administrador | 2.a | Cantidad de ventas y monto total por vendedor en un rango de fechas | [informe-ventas.md](informe-ventas.md) | [informe_ventas.sql](../../sql/consultas/informe_ventas.sql) |
| CU-04 | Consultar ventas por categoría | Administrador | 2.b | Monto, unidades y cantidad de ventas por categoría en un rango de fechas | [informe-ventas.md](informe-ventas.md) | [informe_ventas.sql](../../sql/consultas/informe_ventas.sql) |
| CU-05 | Analizar los clientes más valiosos | Administrador | 3 | Clientes con mayor gasto acumulado, para acciones de fidelización | [consulta-avanzada.md](consulta-avanzada.md) | [consulta_avanzada.sql](../../sql/consultas/consulta_avanzada.sql) |

### CU-01 – Emitir comprobante de venta

- **Actor:** Empleado (vendedor).
- **Objetivo:** Obtener el comprobante completo de una venta, consolidando el encabezado (número, fecha, cliente y vendedor) con el detalle de cada renglón.
- **Precondición:** La venta existe y tiene al menos un renglón registrado.
- **Consulta:** 1.
- **Resultado:** Una fila por renglón, con el subtotal del renglón, el total acumulado y el total de la factura.

### CU-02 – Controlar la consistencia del total de una venta

- **Actor:** Administrador.
- **Objetivo:** Verificar que el total registrado en cada venta coincida con la suma real de sus renglones.
- **Precondición:** Existen ventas registradas.
- **Consulta:** 1.b.
- **Resultado:** Únicamente las ventas con diferencias (sin filas si todo es consistente).

### CU-03 – Consultar ventas por vendedor

- **Actor:** Administrador.
- **Objetivo:** Medir el desempeño de cada vendedor en un rango de fechas.
- **Precondición:** Existen ventas registradas en el período consultado.
- **Consulta:** 2.a.
- **Resultado:** Cantidad de ventas y monto total por vendedor.

### CU-04 – Consultar ventas por categoría

- **Actor:** Administrador.
- **Objetivo:** Analizar qué categorías de productos generan más actividad comercial.
- **Precondición:** Existen ventas registradas en el período consultado.
- **Consulta:** 2.b.
- **Resultado:** Monto, unidades vendidas y cantidad de ventas por categoría.

### CU-05 – Analizar los clientes más valiosos

- **Actor:** Administrador.
- **Objetivo:** Identificar a los clientes de mayor gasto para acciones de fidelización.
- **Precondición:** Existen ventas registradas con cliente asociado.
- **Consulta:** 3.
- **Resultado:** Ranking de clientes según su gasto acumulado.

## Estructura de archivos de esta etapa

```text
docs/etapa-04/
├── casos-uso.md             ← este documento (casos de uso e índice de consultas)
├── comprobante.de.venta.md  ← Consultas 1 y 1.b
├── informe-ventas.md        ← Consultas 2.a y 2.b
└── consulta-avanzada.md     ← Consulta 3

sql/consultas/
├── comprobante_ventas.sql
├── informe_ventas.sql
└── consulta_avanzada.sql
```

## Cómo ejecutar las consultas

1. Cargar el esquema y los datos de prueba del proyecto en el motor elegido.
2. Abrir el script `.sql` correspondiente desde la carpeta `sql/consultas/`.
3. Ajustar los parámetros si se desea (por ejemplo `v.id_venta = 1` o el rango de fechas).
4. Ejecutar y comparar con el resultado esperado de la documentación.
