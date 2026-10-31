# Triggers de auditoría

## Objetivo

Registrar los cambios realizados sobre `dbo.Producto` para que un usuario con permisos de auditor pueda consultar qué producto se modificó, qué operación se realizó, cuándo ocurrió, quién la ejecutó y cuáles eran los valores anteriores y nuevos.

## Implementación

El script [auditoria_producto.sql](../../../sql/tecnico/triggers/auditoria_producto.sql) crea la tabla `dbo.auditoria_producto` y el trigger `dbo.tr_auditoria_producto`. El trigger registra inserciones, modificaciones y eliminaciones. Conserva los valores anteriores y nuevos de nombre, precio, requisito de receta, categoría y laboratorio. La tabla de auditoría no tiene una clave foránea a `Producto`, de modo que el historial permanece aunque se elimine el producto.

La lógica usa las tablas virtuales `inserted` y `deleted` mediante una operación por conjuntos, por lo que también registra correctamente sentencias que afectan varios productos. `USER_NAME()` identifica el usuario de base de datos que ejecutó la operación.

## Ejecución y prueba

1. Ejecutar el DDL y el DML del proyecto.
2. Ejecutar [auditoria_producto.sql](../../../sql/tecnico/triggers/auditoria_producto.sql).
3. Ejecutar [demo_triggers_auditoria.sql](../../../sql/tecnico/triggers/demo_triggers_auditoria.sql).

La demostración inserta, modifica y elimina un producto dentro de una transacción. Muestra los tres registros de auditoría y luego revierte tanto los cambios de prueba como sus registros, sin dejar datos de prueba permanentes. Para validar la integración con seguridad, ejecutar después los scripts de la carpeta `sql/tecnico/seguridad/`; el rol auditor recibe permiso de lectura sobre `dbo.auditoria_producto`.

## Orden de ejecución de la etapa técnica

DDL → DML → funciones → procedimientos → triggers → seguridad → índices.
