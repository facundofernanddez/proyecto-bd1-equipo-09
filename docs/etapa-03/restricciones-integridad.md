# Restricciones de Integridad y Reglas de Negocio

Para proteger la base de datos de anomalías e inserciones inválidas, se aplicaron restricciones físicas directamente en el motor SQL (constraints) sobre las tablas definidas:

* **Integridad Referencial y Reglas de Borrado (ON DELETE):**
  * **CASCADE:** Se aplicó en la herencia de la superclase `persona` hacia `cliente`, `empleado` y `proveedor`. Si se elimina una persona física del sistema, sus roles asociados desaparecen automáticamente. También se utilizó en tablas asociativas como `pago` y `detalle_venta`: si se anula una `venta` entera, se borran sus pagos y detalles en cascada.
  * **RESTRICT:** Se aplicó estrictamente en entidades de catálogo y transaccionales. Un `cargo`, `metodo_pago` o `producto` no puede borrarse si ya tiene registros históricos asociados, protegiendo la consistencia de reportes contables pasados.
* **Restricciones de Dominio (CHECK):**
  * Se validó que ningún atributo numérico crítico acepte valores ilógicos. Se incorporaron reglas `CHECK (precio > 0)`, `CHECK (stock >= 0)`, `CHECK (monto > 0)` y `CHECK (cantidad > 0)` para evitar devoluciones de stock negativas o ventas con precios en cero por error del operario.
* **Unicidad de Datos (UNIQUE):**
  * Se restringieron campos que deben ser irrepetibles en el negocio pero no actúan como clave primaria. Esto incluye el `legajo` del empleado, el `cuit` del proveedor, el `num_receta` físico del documento médico, y la `descripcion` de catálogos (ej. método de pago) para evitar opciones duplicadas en la interfaz de caja.
