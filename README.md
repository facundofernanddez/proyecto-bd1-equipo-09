# Base de Datos I (Equipo 09) - Gestor de Farmacia

## FarmAura

![Símbolo farmacéutico](./assets/simbolo_farmaceutico.png)

## Descripción

Este proyecto tiene como objetivo diseñar, normalizar e implementar una base de datos relacional que soporte el ciclo completo de operaciones de una farmacia, garantizando la integridad referencial, la consistencia y la no redundancia de la información.

El sistema permite gestionar clientes, empleados, proveedores, productos, recetas médicas, lotes de stock, direcciones, localidades, métodos de pago y la relación entre proveedores y productos.

## Alcance

- Gestión de clientes y sus direcciones asociadas.
- Gestión de empleados, sus cargos y datos personales.
- Gestión de proveedores y su relación N:M con productos.
- Catálogo de productos con categoría, laboratorio, precio y necesidad de receta médica.
- Control de stock por lotes con fecha de vencimiento y stock disponible (`stock >= 0`).
- Registro de recetas médicas.
- Gestión de métodos de pago.
- Soporte para el ciclo de ventas, garantizando trazabilidad de información.

## Restricciones

- Modelo relacional con entre 6 y 10 entidades principales.
- Alcance de la Tercera Forma Normal (3FN).
- Aplicación de claves primarias, claves foráneas, `UNIQUE`, `NOT NULL`, `CHECK`, `ON DELETE CASCADE` y `ON DELETE SET NULL`.
- Uso obligatorio de SQL Server / T-SQL.

## Estructura del repositorio

```text
proyecto-bd1-equipo-09/
│
├── .atl/        # Artefactos y metadatos locales
├── .gitignore
├── AGENTS.md    # Instrucciones para agentes IA
├── README.md    # Este archivo
├── assets/      # Imágenes y recursos gráficos
├── docs/        # Documentación por etapa del proyecto
│   ├── etapa-01/  # Requerimientos y reglas de negocio
│   ├── etapa-02/  # DER, modelo relacional y normalización
│   ├── etapa-03/  # Implementación física (DDL + DML)
│   ├── etapa-04/  # Consultas y casos de uso
│   └── etapa-05/  # Temas técnicos (SP, funciones, triggers, etc.)
│
└── sql/
    ├── ddl/       # Definición de estructura
    │   └── 01_creacion_tablas.sql
    ├── dml/       # Datos de prueba
    │   └── 02_datos_prueba.sql
    ├── consultas/ # Consultas SQL para casos de uso
    └── tecnico/   # Procedimientos, funciones, triggers, índices, seguridad
```

## Tecnologías

- **Motor:** Microsoft SQL Server (Developer/Express)
- **Lenguaje:** Transact-SQL (T-SQL)
- **Herramienta de modelado:** ERDPlus (notación de Peter Chen)

## Requisitos previos

- Microsoft SQL Server en ejecución
- SQL Server Management Studio (SSMS), Azure Data Studio o `sqlcmd`

## Puesta en marcha

### 1) Crear base de datos y tablas (DDL)

Ejecutar `sql/ddl/01_creacion_tablas.sql`:

```bash
sqlcmd -S <NOMBRE_SERVIDOR> -E -i "sql\ddl\01_creacion_tablas.sql"
```

> Reemplazar `<NOMBRE_SERVIDOR>` por `.\SQLEXPRESS`, `localhost`, `(localdb)\MSSQLLocalDB` u otro.

### 2) Cargar datos de prueba (DML)

Ejecutar `sql/dml/02_datos_prueba.sql`:

```bash
sqlcmd -S <NOMBRE_SERVIDOR> -E -i "sql\dml\02_datos_prueba.sql"
```

También se pueden ejecutar directamente desde SSMS o Azure Data Studio en ese orden.

## Notas importantes

- **Base:** `Farmacia_Proyecto`
- **Orden obligatorio:** DDL → DML. Nunca ejecutar el DML antes del DDL.
- **Re-ejecución del DDL:** Si la base ya existe, `CREATE DATABASE Farmacia_Proyecto` fallará. Verificar el estado de la instancia antes de re-ejecutarlo.
- **Codificación:** Archivos `.sql` están en **UTF-8**. Mantener esa codificación al editarlos.
- **Integridad:** Se aplican `FOREIGN KEY`, `UNIQUE`, `NOT NULL`, `CHECK`, `ON DELETE CASCADE`/`ON DELETE SET NULL`.
- **Stock por lote:** Tabla `lote` con `CHECK (stock >= 0)`.
- **Herencia 1:1:** `Persona` (superclase) → `Cliente`, `Empleado`, `Proveedor`.

## Modelo resumido

- **Catálogos:** `Localidad`, `Direccion`, `Categoria`, `Laboratorio`, `Metodo_Pago`, `cargo`
- **Actores:** `Persona`, `Cliente`, `Empleado`, `Proveedor`
- **Productos:** `Producto` (FK a `Categoria`, `Laboratorio`) — `requiere_receta` (`BIT`)
- **N:M:** `proveedor_producto` (`Proveedor` ↔ `Producto`)
- **Stock:** `lote` (control por lote, vencimiento y stock)
- **Recetas:** `receta` (matrícula médico, fecha emisión, número único)

## Etapas del proyecto

| Etapa | Objetivo | Entregable |
|---|---|---|
| **Etapa I** | Requerimientos y reglas de negocio | `docs/etapa-01/` |
| **Etapa II** | DER, modelo relacional y normalización (1FN→3FN) | `docs/etapa-02/` |
| **Etapa III** | Implementación física (DDL + DML) | `docs/etapa-03/` |
| **Etapa IV** | Consultas y casos de uso (JOIN, GROUP BY, SUM, COUNT, subconsultas/HAVING) | `docs/etapa-04/` |
| **Etapa V** | Temas técnicos (procedimientos, funciones, transacciones, triggers, seguridad, índices) | `docs/etapa-05/` |

## Contribuciones individuales

Cada integrante deberá registrar su aporte por etapa en un archivo `CONTRIBUCION_etapaXX.md` siguiendo el formato indicado en la consigna. Incluir evidencias (archivos modificados, commits, issues, pull requests) y reflexión.

## Referencias

- [AGENTS.md](./AGENTS.md) — Reglas de trabajo para agentes IA en este repositorio
- ERDPlus — Modelado conceptual/lógico
- Microsoft SQL Server / T-SQL

