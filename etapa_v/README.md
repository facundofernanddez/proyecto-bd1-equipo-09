# Etapa V: temas técnicos

Cada carpeta reúne el concepto, el código ejecutable y las evidencias de un tema.

| Tema | Carpeta | Qué muestra |
|---|---|---|
| Procedimientos y funciones | `procedimientos_funciones/` | Funciones de descuento y stock, procedimiento de venta completa y reporte por vendedor |
| Transacciones | `transacciones/` | Atomicidad con `COMMIT`/`ROLLBACK` y aislamiento entre dos sesiones |
| Triggers de auditoría | `triggers_auditoria/` | Auditoría automática de `INSERT`, `UPDATE` y `DELETE` sobre `Producto` |

## Extras (complementarios)

No forman parte de los tres temas de la consigna, pero se incluyen con la misma estructura por si la cátedra los pide:

| Tema | Carpeta | Qué muestra |
|---|---|---|
| Seguridad | `extras/seguridad/` | Logins, usuarios, roles, permisos y demo con `EXECUTE AS` |
| Índices y optimización | `extras/indices_optimizacion/` | 8 índices no agrupados y demo de rendimiento con tablas de prueba |

Los extras requieren la base `Farmacia_Proyecto` creada y cargada. Seguridad usa los procedimientos y la tabla creada por el trigger de auditoría, así que se ejecuta después de esos temas. Índices puede ejecutarse después del DDL y el DML; su demo de rendimiento genera 2.000 filas y se ejecuta en segundos.

## Cómo evaluar cada tema

1. **Localizar:** abrir la carpeta del tema.
2. **Ejecutar:** correr el `scripts.sql` indicado.
3. **Verificar:** comparar los resultados con `investigacion.md` y revisar `evidencias/`.

## Orden de ejecución recomendado

1. DDL: `sql/ddl/01_creacion_tablas.sql`.
2. DML: `sql/dml/02_datos_prueba.sql`.
3. `procedimientos_funciones/scripts.sql`.
4. `triggers_auditoria/scripts.sql`.
5. `transacciones/scripts.sql`.
6. `transacciones/scripts_aislamiento.sql` (requiere dos ventanas de SSMS).
7. `extras/seguridad/scripts.sql` (después de procedimientos y triggers).
8. `extras/indices_optimizacion/scripts.sql` (independiente; alcanza con DDL y DML).

> Los temas de seguridad e índices están en `etapa_v/extras/` con la misma estructura. Los scripts de origen siguen disponibles en `sql/tecnico/`.
