# Pruebas y validación de la implementación física

**Etapa:** III - Implementación física  
**Fecha de validación:** 2026-09-30  
**Motor y herramienta:** Microsoft SQL Server mediante SQL Server Management Studio (SSMS)

## Alcance y método

Ejecuté en SQL Server Management Studio (SSMS) el script DDL `sql/ddl/01_creacion_tablas.sql` para crear la base y sus tablas, y luego el script DML `sql/dml/02_datos_prueba.sql` para cargar los datos de prueba. Después verifiqué las relaciones, restricciones y consistencia de los datos con consultas de validación. No modifiqué los scripts SQL durante estas pruebas.

## Pruebas ejecutadas

| Prueba                                                                                    | Resultado                                                                                |
| ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Creación de tablas y carga de datos del DML en SQL Server                                 | Aprobada: las 17 tablas se crearon y cada una recibió 10 filas.                          |
| Integridad referencial de los registros cargados                                          | Aprobada: no se encontraron relaciones con registros inexistentes.                       |
| Consistencia entre `venta.total` y la suma de sus detalles (`cantidad * precio_unitario`) | Aprobada: no se encontraron diferencias.                                                 |
| Consistencia entre `venta.total` y la suma de pagos                                       | Aprobada: no se encontraron diferencias.                                                 |
| Rechazo de un lote con stock negativo                                                     | Aprobada: el `CHECK (stock >= 0)` rechazó el registro de prueba.                         |
| Rechazo de una categoría duplicada                                                        | Aprobada: la restricción `UNIQUE` rechazó el registro de prueba.                         |
| Rechazo de una dirección con localidad inexistente                                        | Aprobada: la clave foránea rechazó el registro de prueba.                                |
| Correspondencia entre productos que requieren receta y recetas asociadas en los detalles  | Observación: se encontraron 3 detalles incongruentes con el indicador `requiere_receta`. |
| Venta de productos desde lotes vigentes al 2026-09-30                                     | Observación: se encontraron 6 detalles asociados a lotes vencidos.                       |
| Registro de Consumidor Final anunciado en la documentación                                | Observación: no se encontró el DNI `99999999` en `Persona` ni en `Cliente` del DML.      |

## Resultado

La ejecución del DDL y el DML en SQL Server mediante SSMS permitió comprobar la creación de las tablas, la carga de datos y las restricciones básicas. También verifiqué la coherencia de los importes. La validación identificó datos de prueba que requieren revisión: lotes vencidos, recetas asociadas a productos de venta libre y la discrepancia del Consumidor Final.
