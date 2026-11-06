# Pruebas y validación de la implementación física

**Etapa:** III - Implementación física  
**Fecha de validación:** 2026-09-30  
**Motor y herramienta:** Microsoft SQL Server mediante SQL Server Management Studio (SSMS)

## Alcance y método

Ejecuté en SQL Server Management Studio (SSMS) el script DDL `sql/ddl/01_creacion_tablas.sql` para crear la base y sus tablas, y luego el script DML `sql/dml/02_datos_prueba.sql` para cargar los datos de prueba. Después verifiqué las relaciones, restricciones y consistencia de los datos con consultas de validación. No modifiqué los scripts SQL durante estas pruebas.

## Pruebas ejecutadas

| Prueba                                                                                    | Resultado                                                                                |
| ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Creación de tablas y carga de datos del DML en SQL Server                                 | Aprobada: las 17 tablas se crearon y cada una recibió 10 filas (Persona y Cliente, 11 por el Consumidor Final incorporado después de esta validación). |
| Integridad referencial de los registros cargados                                          | Aprobada: no se encontraron relaciones con registros inexistentes.                       |
| Consistencia entre `venta.total` y la suma de sus detalles (`cantidad * precio_unitario`) | Aprobada: no se encontraron diferencias.                                                 |
| Consistencia entre `venta.total` y la suma de pagos                                       | Aprobada: no se encontraron diferencias.                                                 |
| Rechazo de un lote con stock negativo                                                     | Aprobada: el `CHECK (stock >= 0)` rechazó el registro de prueba.                         |
| Rechazo de una categoría duplicada                                                        | Aprobada: la restricción `UNIQUE` rechazó el registro de prueba.                         |
| Rechazo de una dirección con localidad inexistente                                        | Aprobada: la clave foránea rechazó el registro de prueba.                                |
| Correspondencia entre productos que requieren receta y recetas asociadas en los detalles  | Observación: se encontraron 3 detalles incongruentes con el indicador `requiere_receta`. |
| Venta de productos desde lotes vigentes al 2026-09-30                                     | Observación: se encontraron 6 detalles asociados a lotes vencidos.                       |
| Registro de Consumidor Final anunciado en la documentación                                | Observación resuelta: el DML actual sí incluye el DNI `99999999` en `Persona` y `Cliente`; esta validación corresponde a la versión del 2026-09-30. |

## Resultado

La ejecución del DDL y el DML en SQL Server mediante SSMS permitió comprobar la creación de las tablas, la carga de datos y las restricciones básicas. También verifiqué la coherencia de los importes. La validación identificó datos de prueba que requieren revisión: lotes vencidos y recetas asociadas a productos de venta libre. La discrepancia del Consumidor Final quedó resuelta en la versión actual del DML.

## Nota de actualización (2026-11-04)

El DML actual incorpora el cliente genérico `99999999` (Consumidor Final) en `Persona` y `Cliente`, por lo que ambas tablas tienen 11 filas. Las observaciones sobre lotes vencidos y recetas incongruentes se mantienen: son ventas históricas de los datos de prueba y no se corrigieron para no alterar los totales de las consultas de la Etapa IV. El procedimiento `sp_RegistrarVentaCompleta` impide que se registren nuevas ventas con lotes vencidos o sin receta cuando corresponde.
