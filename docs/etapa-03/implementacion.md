# Implementación del Modelo Lógico en el SGBD (`implementacion.md`)

## 1. Mapeo del Modelo Lógico al SGBD (SQL Server)

El paso del modelo lógico al SGBD Microsoft SQL Server se realizó mapeando cada entidad relacional a una estructura física mediante sentencias DDL. Para ello, se seleccionaron los tipos de datos nativos más adecuados según la naturaleza del negocio:

* **Identificadores Autoincrementales (`IDENTITY(1,1)`):** Se utilizaron para generar claves primarias numéricas y sintéticas en las tablas de catálogo y transaccionales (`Localidad`, `Direccion`, `Categoria`, `Laboratorio`, `Metodo_Pago`, `receta`, `cargo`, `Producto`, `lote`, `venta`, `pago` y `detalle_venta`). Esto simplifica las uniones (JOINs) y delega la secuenciación al motor.
* **Precisión Financiera (`DECIMAL(10, 2)`):** Aplicado en campos de moneda (`precio`, `total`, `monto`, `precio_unitario`). Se evitó el uso de tipos de coma flotante (`FLOAT`/`REAL`) para prevenir imprecisiones o redondeos en el cálculo de tickets y pagos.
* **Manejo de Estados Buleanos (`BIT`):** El atributo `requiere_receta` en la tabla `Producto` se definió como `BIT` (`0` para venta libre, `1` para bajo receta), garantizando la máxima eficiencia en memoria.
* **Marcas de Tiempo (`DATETIME` y `DATE`):** En `venta` se utilizó `DATETIME` junto con la restricción `DEFAULT CURRENT_TIMESTAMP` para registrar automáticamente el momento exacto de la transacción. Para `fecha_emision` (en `receta`) y las fechas de `lote` (`fecha_creacion`, `fecha_vencimiento`), se prefirió `DATE` para omitir la hora.
* **Textos y Cadenas (`VARCHAR`):** Se utilizó `VARCHAR` ajustando los límites de caracteres según el dominio (ej. `VARCHAR(50)` para nombres/apellidos y `VARCHAR(100)` para correos y razones sociales).

---

## 2. Implementación de Restricciones y Reglas de Negocio

Para asegurar la validez de los datos introducidos en la base de datos, se aplicaron restricciones directas en la creación de las tablas:

* **Unicidad en Catálogos y Entidades (`UNIQUE`):** 
  Se aplicó en descriptores de tablas maestras (`nombre` en `Categoria` y `Laboratorio`, `descripcion` en `Metodo_Pago` y `cargo`) y en atributos identificadores (`correo` en `Persona`, `legajo` en `Empleado`, `cuit` en `Proveedor`, `num_receta` en `receta`). Esto impide registros redundantes o ambiguos en la interfaz del sistema.
* **Restricciones de Dominio (`CHECK`):**
  * `precio > 0` en `Producto`: Garantiza que ningún artículo del catálogo tenga precio nulo o negativo.
  * `stock >= 0` en `lote`: Previene el stock negativo a nivel de motor.
  * `total >= 0` en `venta` y `monto > 0` en `pago`: Protege la integridad contable del módulo de cobros.
  * `cantidad > 0` y `precio_unitario >= 0` en `detalle_venta`: Asegura el registro correcto de las líneas de compra.

---

## 3. Integridad Referencial y Mapeo de Relaciones

Las relaciones entre entidades se mantuvieron utilizando Claves Foráneas (`CONSTRAINT FK_... FOREIGN KEY`) aplicando reglas explícitas de integridad referencial:

* **Modelo de Herencia (1:1):** 
  Para las tablas `Cliente`, `Empleado` y `Proveedor`, la clave primaria es el `dni` (obtenido de `Persona`). Se definió la regla `ON DELETE CASCADE` hacia `Persona`, garantizando que si se da de baja a una persona, se borren en cadena sus roles asociados sin dejar huérfanos.
* **Relación N:M Catálogo (`proveedor_producto`):** 
  Construida con una clave primaria compuesta `(dni_proveedor, id_producto)`. Posee `ON DELETE CASCADE` respecto a ambas entidades asociadas para mantener limpia la tabla de vinculación si se elimina un producto o proveedor.
* **Relaciones Transaccionales y de Historial:**
  En relaciones críticas como `venta` con `Cliente`/`Empleado`, y `detalle_venta` con `lote`/`receta`, se omitió la regla explícita de borrado en cascada (asumiendo el comportamiento `NO ACTION` / `RESTRICT` de SQL Server). Esto impide borrar lotes, productos o clientes que ya tengan transacciones históricas registradas.
* **Preservación Opción Null (`ON DELETE SET NULL`):** 
  Aplicado en la FK de `Cliente` hacia `Direccion`, permitiendo dar de baja una dirección física sin eliminar el perfil del cliente en el sistema.

---

## 4. Verificación de Datos e Integridad mediante Script DML

La verificación del modelo físico se realizó poblando la base de datos a través del script DML, respetando estrictamente el orden jerárquico de inserción:

1. **Estructuras Independientes:** Inserción de catálogos base (`Localidad`, `Categoria`, `Laboratorio`, `Metodo_Pago`, `receta`, `cargo`).
2. **Entidades con Dependencia Simple:** Inserción en `Direccion`, la superclase `Persona` y sus subclases (`Cliente`, `Empleado`, `Proveedor`).
3. **Catálogo Operativo y Stock:** Carga de registros en `Producto`, vinculación N:M en `proveedor_producto` y generación de lotes en `lote`.
4. **Transacciones de Prueba:** Carga de registros en `venta`, `pago` y `detalle_venta`.

**Resolución de Reglas Especiales:**
Se verificó el cumplimiento de la **RN.03 (Consumidor Final)** creando el registro inicial con `dni = 99999999` en `Persona` y `Cliente`, lo que permite procesar ventas rápidas sin obligar al cajero a registrar datos personales del comprador.