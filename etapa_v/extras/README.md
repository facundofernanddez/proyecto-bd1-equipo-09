# Extras de la Etapa V

Temas complementarios que no forman parte de los tres temas de la consigna, pero que se incluyen con la misma estructura (`investigacion.md`, `scripts.sql`, `evidencias/`) por si la cátedra los pide.

| Tema | Carpeta | Qué muestra |
|---|---|---|
| Seguridad | `seguridad/` | Logins, usuarios, roles, permisos y demo con `EXECUTE AS` |
| Índices y optimización | `indices_optimizacion/` | 8 índices no agrupados y demo de rendimiento con tablas de prueba |

## Requisitos

- Base `Farmacia_Proyecto` creada y cargada con el DDL y el DML del proyecto.
- Para **seguridad**, haber ejecutado antes `etapa_v/procedimientos_funciones/scripts.sql` y `etapa_v/triggers_auditoria/scripts.sql`.
- Para **índices**, alcanza con el DDL y el DML.

## Notas de ejecución

- **Seguridad:** si el usuario no es `sysadmin`, el script omite la creación de logins y crea los usuarios `WITHOUT LOGIN`; la demo funciona igual con `EXECUTE AS`. Ejecutar como `dbo` o con permiso `IMPERSONATE`.
- **Índices:** la sección 2 genera 300.000 ventas y 900.000 renglones, puede tardar varios minutos y ocupa espacio en disco. Al final elimina las tablas de prueba.
