# Etapa IV – Consultas y Casos de Uso

**Proyecto Integrador: Sistema de Gestión de Ventas para Farmacia**
Bases de Datos 1 – 2026 – Grupo n° 9

## Consideraciones generales

- Motor de base de datos: **SQL Server 2012 o superior** (las consultas también son compatibles con MySQL 8.0 o superior). Se usan funciones de ventana en la consulta 1.
- Los nombres de tablas y columnas corresponden al modelo relacional final del proyecto.
- Las fechas se escriben en formato `AAAAMMDD`, que el motor interpreta de la misma forma sin importar la configuración regional del servidor.
- Los resultados que se muestran fueron obtenidos con datos de prueba. Con otros datos los valores cambian, pero la estructura del resultado es la misma. Los parámetros (número de venta, rango de fechas) pueden modificarse directamente en cada consulta.

## Índice de consultas

| N° | Consulta | Qué resuelve | Documentación | Script SQL |
|---|---|---|---|---|
| 1 | Factura / comprobante de venta | Comprobante completo de una venta, con subtotales y total acumulado | [comprobante-venta.md](comprobante-venta.md) | [comprobante_venta.sql](../consultas/comprobante_venta.sql) |
| 1.b | Control de totales | Detecta ventas cuyo total registrado no coincide con su detalle | [comprobante-venta.md](comprobante-venta.md) | [comprobante_venta.sql](../consultas/comprobante_venta.sql) |
| 2.a | Ventas por vendedor | Cantidad de ventas y monto total por vendedor en un rango de fechas | [informe-ventas.md](informe-ventas.md) | [informe_ventas.sql](../consultas/informe_ventas.sql) |
| 2.b | Ventas por categoría | Monto, unidades y cantidad de ventas por categoría en un rango de fechas | [informe-ventas.md](informe-ventas.md) | [informe_ventas.sql](../consultas/informe_ventas.sql) |
| 3 | Clientes con gasto superior al promedio | Identifica a los clientes más valiosos para fidelización | [consulta-avanzada.md](consulta-avanzada.md) | [consulta_avanzada.sql](../consultas/consulta_avanzada.sql) |

## Estructura de archivos de esta etapa

```
├── etapa-04/
│   ├── casos-uso.md             ← este documento (índice y consideraciones generales)
│   ├── comprobante-venta.md     ← Consulta 1 y 1.b
│   ├── informe-ventas.md        ← Consulta 2.a y 2.b
│   └── consulta-avanzada.md     ← Consulta 3
└── consultas/
    ├── comprobante_venta.sql
    ├── informe_ventas.sql
    └── consulta_avanzada.sql
```

## Cómo ejecutar las consultas

1. Cargar el esquema y los datos de prueba del proyecto en el motor elegido.
2. Abrir el script `.sql` correspondiente desde la carpeta `consultas/`.
3. Ajustar los parámetros si se desea (por ejemplo `v.id_venta = 1` o el rango de fechas).
4. Ejecutar y comparar con el resultado esperado de la documentación.
