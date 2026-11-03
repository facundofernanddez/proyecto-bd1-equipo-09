# Triggers de auditoría

## 1. Definición y objetivo

Un **trigger** (disparador) es un objeto de base de datos que se ejecuta automáticamente cuando ocurre un evento DML (`INSERT`, `UPDATE` o `DELETE`) sobre una tabla. A diferencia de un procedimiento almacenado, no se invoca explícitamente: el motor lo ejecuta como parte de la operación que lo activa.

En este proyecto, el objetivo es **auditar los cambios sobre `dbo.Producto`**: registrar qué producto se vio afectado, qué operación se realizó, cuándo ocurrió, qué usuario de la base la ejecutó y cuáles eran los valores anteriores y nuevos. De esta manera, el auditor puede consultar el historial del catálogo sin depender de la aplicación que originó el cambio.

## 2. Ventajas y aplicaciones

- **Auditoría centralizada:** registra cambios aunque se realicen desde distintas aplicaciones, scripts o SQL Server Management Studio.
- **Sin cambios en la aplicación:** las operaciones DML habituales activan el registro automáticamente.
- **Historial independiente del producto:** `dbo.auditoria_producto` no tiene una clave foránea a `Producto`; por eso conserva la evidencia aunque se elimine el producto.
- **Trazabilidad:** almacena la operación, el usuario de base de datos, la fecha y hora, y los valores anteriores y nuevos.
- **Aplicaciones:** control de cambios de precios, auditoría del catálogo, análisis de modificaciones y revisión de cambios no esperados.

El trigger agrega trabajo a cada operación DML sobre `Producto`. Además, debe procesar conjuntos de filas: una única sentencia puede afectar más de un producto.

## 3. Implementación en SQL Server Express

El script [auditoria_producto.sql](../../../sql/tecnico/triggers/auditoria_producto.sql) crea la tabla `dbo.auditoria_producto` y el trigger `dbo.tr_auditoria_producto`.

La tabla almacena el identificador del evento y del producto, el tipo de operación, la fecha y hora, el usuario de base de datos y los valores anteriores y nuevos de nombre, precio, requisito de receta, categoría y laboratorio. El trigger es `AFTER INSERT, UPDATE, DELETE`: usa las tablas virtuales `inserted` y `deleted`, unidas por `id_producto`, para identificar la operación y guardar sus valores. El procesamiento por conjuntos permite registrar tanto cambios de una fila como cambios de varias filas.

## 4. Caso concreto aplicado al sistema

El gerente puede actualizar el precio de un producto. Si, por ejemplo, cambia el precio de un producto de `$100,00` a `$125,00`, el trigger inserta automáticamente un registro de auditoría con el precio anterior, el precio nuevo, el usuario y la fecha y hora. El auditor puede revisar ese registro posteriormente. El mismo mecanismo deja constancia cuando se agrega un producto al catálogo o se elimina uno existente.

## 5. Demostración y resultados

### Pasos de ejecución

1. Ejecutar el DDL y el DML del proyecto.
2. Ejecutar [auditoria_producto.sql](../../../sql/tecnico/triggers/auditoria_producto.sql) para crear la tabla de auditoría y el trigger.
3. Ejecutar [demo_triggers_auditoria.sql](../../../sql/tecnico/triggers/demo_triggers_auditoria.sql).

La demostración toma una categoría y un laboratorio existentes, inserta un producto de prueba, actualiza su precio y luego lo elimina. Consulta los eventos generados dentro de la transacción y finalmente hace `ROLLBACK`. Así, tanto el producto de prueba como sus registros de auditoría se revierten y no quedan datos permanentes.

### Resultado esperado

La consulta final debe mostrar tres filas para el mismo `id_producto`. Los valores de `id_auditoria`, `fecha_hora` y `usuario_bd` dependen de la ejecución; los campos relevantes deben corresponder a este resultado:

| Orden | `operacion` | `precio_anterior` | `precio_nuevo` | Interpretación |
|---:|---|---:|---:|---|
| 1 | `INSERT` | `NULL` | 100,00 | Se creó el producto de prueba |
| 2 | `UPDATE` | 100,00 | 125,00 | Se modificó el precio |
| 3 | `DELETE` | 125,00 | `NULL` | Se eliminó el producto |

Cada fila también incluye el usuario y la fecha y hora del evento. Al finalizar, el script informa que la demostración terminó y que los cambios fueron revertidos.

### Captura de resultados

La captura debe agregarse después de ejecutar `demo_triggers_auditoria.sql` en SQL Server Management Studio:

> **Pendiente:** insertar aquí una captura de la grilla de resultados con los tres eventos (`INSERT`, `UPDATE` y `DELETE`) y el mensaje de finalización.

## Orden de ejecución de la etapa técnica

DDL → DML → funciones → procedimientos → triggers → seguridad → índices.
