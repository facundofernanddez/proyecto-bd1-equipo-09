* **Justificación de la Normalización**

El diseño de la base de datos fue sometido a un riguroso proceso de normalización hasta alcanzar la Tercera Forma Normal (3FN). El objetivo principal de este proceso es garantizar la integridad referencial de los datos, minimizar la redundancia de información y prevenir anomalías de inserción, actualización o borrado durante la operatoria diaria de la farmacia. A continuación se detallan las decisiones tomadas en cada etapa:

* **Primera Forma Normal (1FN): Atomicidad y eliminación de grupos repetitivos**
  * Se aseguró que cada intersección de fila y columna contenga un único valor atómico. No existen listas separadas por comas ni arreglos dentro de los campos.
  * **Desglose de atributos compuestos:** 
  Los datos de ubicación no se almacenan como cadenas de texto libre propensas a errores tipográficos. Se estructuraron en entidades independientes y parametrizadas: la tabla `direccion` maneja de forma atómica la `calle`, `altura` y `piso`, mientras que delega la jerarquía geográfica (provincia, ciudad, código postal) a la tabla `localidad`.
  * **Manejo de atributos multivaluados:** 
  La posibilidad de que una venta tenga múltiples pagos (RN.05)no se resolvió agregando columnas repetitivas en la tabla `venta` (ej. pago_1, pago_2) ni con campos booleanos rígidos. En su lugar, se creó la entidad `pago` para registrar cada transacción de forma atómica e individual.

* **Segunda Forma Normal (2FN): Dependencia funcional completa**
  * Habiendo cumplido la 1FN, se verificó que en las tablas con claves primarias compuestas (tablas asociativas), todos los atributos no clave dependan de la clave completa y no solo de una parte de ella.
  * **Optimización de Recetas (RN.06):** 
  Durante el modelado se detectó y eliminó la tabla transitoria `receta/producto`. Si se mantenía, la receta dependía parcialmente del producto en catálogo, generando un camino redundante y desvinculado de la compra real. Al migrar el `id_receta` directamente a `detalle_venta`, se asegura que el documento médico dependa funcionalmente de la transacción concreta (la venta exacta de ese ítem) garantizando consistencia absoluta.

* **Tercera Forma Normal (3FN): Eliminación de dependencias transitivas**
  * Habiendo alcanzado la 2FN, se aseguró que ningún atributo no clave dependa funcionalmente de otro atributo no clave. Todos los atributos dependen única y directamente de la Clave Primaria de su tabla.
  * **Inmutabilidad del Historial de Precios (RN.04):** 
  Si el sistema dependiera de consultar el precio actual del artículo en la tabla `producto` para calcular una venta pasada, existiría una dependencia transitiva temporal. Para evitar que las actualizaciones de catálogo modifiquen los montos históricos, el atributo `precio_unitario` se independizó y se registra de forma estática en `detalle_venta` al concretarse la operación.
  * **Trazabilidad Física del Stock (RN.01 y RN.02):** 
  El atributo `stock` y la `fecha_vencimiento` no pertenecen lógicamente a la tabla `producto`, ya que son propiedades de un ingreso físico particular y no del medicamento en abstracto. Al modelar la tabla `lote` y alojar allí el stock, se elimina la anomalía de actualización, permitiendo descontar unidades exactas de cajas específicas.
  * **Origen Específico de Mercadería (RN.07):** 
  Incluir la clave `id_proveedor` directamente en la tabla `lote` evita depender transitivamente de la tabla de catálogo general `proveedor/producto` para averiguar quién entregó una caja particular. El proveedor físico depende estrictamente del lote ingresado.