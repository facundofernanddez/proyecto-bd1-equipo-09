# Extras de la Etapa V

Temas complementarios que no forman parte de los tres temas de la consigna, pero que se incluyen con la misma estructura (`investigacion.md`, `scripts.sql`, `evidencias/`) por si la cátedra los pide.

| Tema | Carpeta | Qué muestra |
|---|---|---|
| Seguridad | `seguridad/` | Logins, usuarios, roles, permisos y demo con `EXECUTE AS` |
| Índices y optimización | `indices_optimizacion/` | 8 índices no agrupados y demo de rendimiento con tablas de prueba |

## Requisitos

- Base `Farmacia_Proyecto` creada y cargada con el DDL y el DML del proyecto.
- Para **seguridad**, haber ejecutado antes `etapa_v/procedimientos_funciones/scripts.sql` y `etapa_v/triggers_auditoria/scripts.sql`: la demo de permisos invoca el procedimiento de venta y consulta `auditoria_producto`.
- Para **índices**, alcanza con el DDL y el DML.

## Orden recomendado para seguridad

1. `sql/ddl/01_creacion_tablas.sql`.
2. `sql/dml/02_datos_prueba.sql`.
3. `etapa_v/procedimientos_funciones/scripts.sql`.
4. `etapa_v/triggers_auditoria/scripts.sql`.
5. `etapa_v/extras/seguridad/scripts.sql`.

Índices es independiente de procedimientos, triggers y seguridad; puede ejecutarse después del DDL y el DML.

## Notas de ejecución

- **Seguridad:** si el usuario no es `sysadmin`, el script omite la creación de logins y crea los usuarios `WITHOUT LOGIN`; la demo funciona igual con `EXECUTE AS`. Ejecutar como `dbo` o con permiso `IMPERSONATE`.
- **Índices:** la sección 2 genera 500 ventas y 1.500 renglones, se ejecuta en segundos y al final elimina las tablas de prueba.
