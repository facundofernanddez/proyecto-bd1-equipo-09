# Pasaje del DER al Modelo Relacional

El proceso de transformación del Diagrama Entidad-Relación (DER) al esquema lógico relacional se llevó a cabo aplicando las reglas estándar de mapeo. Este procedimiento asegura la integridad referencial, minimiza la redundancia y prepara la estructura para su posterior implementación en SQL.
A continuación se detalla el tratamiento de cada elemento:

* **1. Mapeo de Entidades Fuertes y Débiles:**
  * Toda entidad fuerte del diagrama se transformó en una tabla relacional independiente.
  * Se asignaron claves primarias (PK) naturales o subrogadas autoincrementales según la conveniencia del dominio. Ejemplos de entidades base generadas: `localidad`, `cargo`, `categoria`, `laboratorio`, `metodo_pago` y `receta`.
  * Los atributos atómicos del DER pasaron a ser columnas directas de sus respectivas tablas. Los atributos compuestos (como la ubicación) se normalizaron separándolos en tablas propias, como es el caso de `direccion` vinculada a `localidad`.

* **2. Resolución de la Jerarquía (Superclase/Subclase):**
  * Para modelar los distintos actores del sistema, se optó por la estrategia de mapeo de **una tabla por cada clase**. 
  * Se creó la tabla principal `persona` que concentra los atributos comunes (nombre, apellido, teléfono, correo) y utiliza el `dni` como Clave Primaria (PK).
  * Se crearon tablas individuales para las subclases `cliente`, `empleado` y `proveedor`. 
  * Para mantener la relación lógica, el `dni` de la tabla `persona` migró hacia las tablas hijas funcionando simultáneamente como Clave Primaria (PK) y Clave Foránea (FK). Esto garantiza una restricción de cardinalidad 1:1 estricta, impidiendo que exista un empleado o cliente sin sus datos base en la tabla persona.

* **3. Resolución de Relaciones 1:N (Uno a Muchos):**
  * La regla fundamental aplicada fue la propagación de la Clave Primaria del lado "1" hacia la tabla del lado "Muchos" (N), donde se instaló como Clave Foránea (FK).
  * **Trazabilidad de Stock:** La PK `id_producto` migró hacia la tabla `lote` como FK, indicando que un producto puede tener múltiples ingresos.
  * **Detalle de Transacciones:** La PK `id_lote` de la tabla `lote` y la PK `id_venta` de la tabla `venta` migraron ambas hacia la tabla `detalle_venta` como foráneas. De esta forma, el detalle actúa como el lado "N" que desglosa los ítems de la venta y descuenta el stock del lote exacto.
  * **Asignación de Actores:** El `dni` del cliente y el `num_empleado` del empleado migraron como FK a la cabecera de la tabla `venta`.

* **4. Resolución de Relaciones N:M (Muchos a Muchos):**
  * Las relaciones de cardinalidad N:M no pueden plasmarse directamente en el modelo relacional, por lo que se generaron tablas intermedias compuestas por las claves foráneas de las tablas que vinculan:
  * **Relación de Pagos:** Dado que una venta puede abonarse con varios métodos y un método se usa en muchas ventas, se creó la tabla transaccional `pago`. Esta tabla absorbe el `id_venta` y el `id_metodo` como foráneas, y añade atributos propios de la relación, como el `monto` abonado.
  * **Relación de Catálogo:** Para determinar qué proveedores están habilitados para suministrar qué medicamentos, se creó la tabla asociativa `proveedor/producto`, cuyas columnas son las claves foráneas `id_proveedor` e `id_producto`, conformando juntas su clave primaria compuesta.

* **5. Gestión de Relaciones Opcionales (Casos Especiales):**
  * La vinculación de la entidad `receta` con la venta se resolvió migrando el `id_receta` hacia `detalle_venta` como una Clave Foránea opcional (que admitirá valores NULL a nivel lógico). Esto permite que el mismo diseño soporte tanto
  * la venta de medicamentos de venta libre como aquellos que exigen el registro obligatorio del profesional médico.
