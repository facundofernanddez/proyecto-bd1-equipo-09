# Seguridad

## 1. Definición y objetivo

La seguridad de una base de datos controla **quién puede entrar** (autenticación) y **qué puede hacer** (autorización). En SQL Server se organiza en capas:

| Concepto | Qué es |
|---|---|
| **Login** | Cuenta para conectarse al **servidor** (autenticación) |
| **Usuario** | Representación del login dentro de **una base de datos** |
| **Rol** | Grupo de permisos que se asigna a varios usuarios |
| **Permiso** | `GRANT` (otorga), `DENY` (prohíbe, tiene prioridad) y `REVOKE` (quita lo otorgado o prohibido) |

**Principio de mínimo privilegio:** cada usuario recibe únicamente los permisos que necesita para su trabajo, y nada más.

## 2. Ventajas y aplicaciones

- **Protección de datos personales** (DNI, teléfono, correo de clientes y empleados).
- **Integridad:** se evita que alguien modifique stock, precios o ventas de forma directa y sin control.
- **Separación de funciones:** el vendedor vende, el gerente controla, el auditor solo consulta.
- **Menos superficie de ataque:** si un usuario se ve comprometido, el daño queda limitado a sus permisos.

## 3. Implementación en SQL Server Express

Se definen tres perfiles, cada uno con su login, su usuario y su rol:

| Perfil | Login / Usuario / Rol |
|---|---|
| Vendedor | `lg_vendedor` / `usr_vendedor` / `rol_vendedor` |
| Gerente | `lg_gerente` / `usr_gerente` / `rol_gerente` |
| Auditor | `lg_auditor` / `usr_auditor` / `rol_auditor` |

Técnicas aplicadas:

- **Vista restrictiva** (`vw_lotes_disponibles`): el vendedor ve solo los lotes vigentes con stock, sin datos personales ni de proveedores.
- **Acceso solo mediante procedimientos:** el vendedor no puede modificar `venta`, `detalle_venta`, `lote` ni `pago` directamente; solo puede ejecutar `sp_RegistrarVentaCompleta`. Funciona por el **encadenamiento de propiedad**: como el procedimiento y las tablas pertenecen al mismo dueño (`dbo`), SQL Server no vuelve a verificar los permisos sobre las tablas que el procedimiento usa.
- **Permiso sobre el tipo tabla:** para usar el parámetro `tipo_detalle_venta` se necesita `EXECUTE` sobre el tipo.
- **Permiso por columna:** el gerente puede modificar únicamente `Producto.precio`.

> **Nota sobre Express:** por defecto SQL Server solo admite autenticación de Windows. Para conectarse con los logins de SQL Server hay que habilitar el modo mixto (Propiedades del servidor → Seguridad). La demostración no lo necesita, porque simula cada sesión con `EXECUTE AS`. Las contraseñas del script son **solo de ejemplo**: en un sistema real deben ser propias y no guardarse en el repositorio.

### Matriz de permisos

| Objeto | `rol_vendedor` | `rol_gerente` | `rol_auditor` |
|---|---|---|---|
| `vw_lotes_disponibles` | SELECT | SELECT | – |
| `sp_RegistrarVentaCompleta` (y tipo `tipo_detalle_venta`) | EXECUTE | EXECUTE | – |
| `sp_ReporteVentasPorVendedor` | – | EXECUTE | – |
| `venta`, `detalle_venta`, `pago`, `lote` | DENY todo | SELECT; DENY DELETE (`venta`, `detalle_venta`) | – |
| `Persona`, `Cliente`, `Empleado` | DENY todo | SELECT | – |
| `Producto` | – | SELECT y UPDATE solo de `precio` | – |
| `auditoria_producto` | – | SELECT | SELECT |

```sql
-- =====================================================================
-- Seguridad: logins, usuarios, roles y permisos
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
-- =====================================================================
USE FarmaciaDB;   -- << REEMPLAZAR por el nombre real de la base de datos
GO

-- Requiere haber ejecutado antes funciones, procedimientos y triggers
-- (se usan sp_RegistrarVentaCompleta, sp_ReporteVentasPorVendedor, tipo_detalle_venta y auditoria_producto).

-- =====================================================================
-- 1) LOGINS (nivel servidor)
--    OJO: contrasenas de ejemplo solo para la demostracion. En un sistema real
--    deben ser propias, secretas y no guardarse en el repositorio.
--    Para conectarse con estos logins, SQL Server debe estar en modo de
--    autenticacion mixta (Windows + SQL Server). La demo no lo necesita (usa EXECUTE AS).
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'lg_vendedor')
    CREATE LOGIN lg_vendedor WITH PASSWORD = 'Vend#Farmacia2026', CHECK_POLICY = ON;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'lg_gerente')
    CREATE LOGIN lg_gerente  WITH PASSWORD = 'Gere#Farmacia2026', CHECK_POLICY = ON;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'lg_auditor')
    CREATE LOGIN lg_auditor  WITH PASSWORD = 'Audi#Farmacia2026', CHECK_POLICY = ON;
GO

-- =====================================================================
-- 2) USUARIOS (nivel base de datos) y ROLES
-- =====================================================================
IF DATABASE_PRINCIPAL_ID('usr_vendedor') IS NULL CREATE USER usr_vendedor FOR LOGIN lg_vendedor;
IF DATABASE_PRINCIPAL_ID('usr_gerente')  IS NULL CREATE USER usr_gerente  FOR LOGIN lg_gerente;
IF DATABASE_PRINCIPAL_ID('usr_auditor')  IS NULL CREATE USER usr_auditor  FOR LOGIN lg_auditor;

IF DATABASE_PRINCIPAL_ID('rol_vendedor') IS NULL CREATE ROLE rol_vendedor;
IF DATABASE_PRINCIPAL_ID('rol_gerente')  IS NULL CREATE ROLE rol_gerente;
IF DATABASE_PRINCIPAL_ID('rol_auditor')  IS NULL CREATE ROLE rol_auditor;

IF ISNULL(IS_ROLEMEMBER('rol_vendedor', 'usr_vendedor'), 0) = 0 ALTER ROLE rol_vendedor ADD MEMBER usr_vendedor;
IF ISNULL(IS_ROLEMEMBER('rol_gerente',  'usr_gerente'),  0) = 0 ALTER ROLE rol_gerente  ADD MEMBER usr_gerente;
IF ISNULL(IS_ROLEMEMBER('rol_auditor',  'usr_auditor'),  0) = 0 ALTER ROLE rol_auditor  ADD MEMBER usr_auditor;
GO

-- =====================================================================
-- 3) VISTA que expone solo lo necesario al vendedor (oculta datos personales y costos)
-- =====================================================================
CREATE OR ALTER VIEW dbo.vw_lotes_disponibles
AS
SELECT l.id_lote,
       p.id_producto,
       p.nombre            AS producto,
       c.nombre            AS categoria,
       p.precio,
       p.requiere_receta,
       l.fecha_vencimiento,
       l.stock
FROM dbo.lote l
JOIN dbo.Producto  p ON p.id_producto  = l.id_producto
JOIN dbo.Categoria c ON c.id_categoria = p.id_categoria
WHERE l.stock > 0
  AND l.fecha_vencimiento >= CAST(GETDATE() AS DATE);
GO

-- =====================================================================
-- 4) PERMISOS
-- =====================================================================
-- Vendedor: consulta lotes vigentes y registra ventas SOLO a traves del procedimiento.
GRANT SELECT  ON dbo.vw_lotes_disponibles        TO rol_vendedor;
GRANT EXECUTE ON dbo.sp_RegistrarVentaCompleta   TO rol_vendedor;
GRANT EXECUTE ON TYPE::dbo.tipo_detalle_venta    TO rol_vendedor;   -- necesario para usar el parametro tipo tabla

DENY SELECT, INSERT, UPDATE, DELETE ON dbo.venta          TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.detalle_venta  TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.pago           TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.lote           TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Persona        TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Cliente        TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Empleado       TO rol_vendedor;

-- Gerente: lee todo el esquema, modifica solo el precio de los productos y ejecuta reportes.
GRANT SELECT  ON SCHEMA::dbo                     TO rol_gerente;
GRANT UPDATE  ON dbo.Producto (precio)           TO rol_gerente;
GRANT EXECUTE ON dbo.sp_ReporteVentasPorVendedor TO rol_gerente;
GRANT EXECUTE ON dbo.sp_RegistrarVentaCompleta   TO rol_gerente;
GRANT EXECUTE ON TYPE::dbo.tipo_detalle_venta    TO rol_gerente;
DENY  DELETE  ON dbo.venta                       TO rol_gerente;
DENY  DELETE  ON dbo.detalle_venta               TO rol_gerente;

-- Auditor: solo lectura de la tabla de auditoria.
GRANT SELECT ON dbo.auditoria_producto TO rol_auditor;
GO
```

## 4. Caso concreto aplicado al sistema de ventas

En la farmacia, el **vendedor** atiende en el mostrador: necesita ver qué lotes hay y registrar la venta, pero no debería poder cambiar el stock a mano, borrar ventas ni ver los datos personales de clientes y empleados (RN.01, RN.03 y RN.08). El **gerente** controla el negocio y puede ajustar precios, pero no borrar ventas. El **auditor** solo revisa la tabla de auditoría de la Etapa V.

## 5. Script de demostración y resultados

### `sql/tecnico/seguridad/demo_seguridad.sql`

```sql
USE FarmaciaDB;   -- reemplazar por el nombre real de la base
GO
-- Se simula la sesion de cada usuario con EXECUTE AS USER ... REVERT.
SET NOCOUNT ON;

-- Datos necesarios, obtenidos con el usuario actual (dueno de la base)
DECLARE @dni_empleado VARCHAR(15) = (SELECT TOP 1 dni FROM dbo.Empleado ORDER BY dni);
DECLARE @id_metodo    INT         = (SELECT TOP 1 id_metodo FROM dbo.Metodo_Pago ORDER BY id_metodo);
DECLARE @id_lote      INT         = (SELECT TOP 1 l.id_lote
                                     FROM dbo.lote l
                                     JOIN dbo.Producto p ON p.id_producto = l.id_producto
                                     WHERE l.stock >= 1
                                       AND l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
                                       AND p.requiere_receta = 0
                                     ORDER BY l.id_lote);
DECLARE @id_venta INT;
DECLARE @items dbo.tipo_detalle_venta;
INSERT INTO @items (id_lote, cantidad, id_receta) VALUES (@id_lote, 1, NULL);

-- =============== VENDEDOR ===============
EXECUTE AS USER = 'usr_vendedor';
SELECT USER_NAME() AS sesion_actual;

-- 1) Permitido: ver lotes disponibles
BEGIN TRY
    SELECT TOP 3 * FROM dbo.vw_lotes_disponibles;
    PRINT '1) SELECT sobre vw_lotes_disponibles: PERMITIDO';
END TRY
BEGIN CATCH
    PRINT '1) ERROR: ' + ERROR_MESSAGE();
END CATCH;

-- 2) Denegado: datos personales
BEGIN TRY
    SELECT TOP 3 * FROM dbo.Persona;
    PRINT '2) SELECT sobre Persona: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '2) SELECT sobre Persona: DENEGADO -> ' + ERROR_MESSAGE();
END CATCH;

-- 3) Denegado: modificar stock directamente (WHERE 1 = 0 por seguridad: no toca filas)
BEGIN TRY
    UPDATE dbo.lote SET stock = 9999 WHERE 1 = 0;
    PRINT '3) UPDATE sobre lote: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '3) UPDATE sobre lote: DENEGADO -> ' + ERROR_MESSAGE();
END CATCH;

-- 4) Denegado: borrar ventas
BEGIN TRY
    DELETE FROM dbo.venta WHERE 1 = 0;
    PRINT '4) DELETE sobre venta: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '4) DELETE sobre venta: DENEGADO -> ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- 5) Permitido: registrar una venta a traves del procedimiento
--    (aunque no tiene permisos sobre las tablas, el procedimiento las usa por encadenamiento
--     de propiedad). Se hace dentro de una transaccion que se deshace.
BEGIN TRANSACTION;
    EXECUTE AS USER = 'usr_vendedor';
    BEGIN TRY
        EXEC dbo.sp_RegistrarVentaCompleta
             @dni_empleado = @dni_empleado, @id_metodo = @id_metodo,
             @detalle = @items, @dni_cliente = NULL, @id_venta = @id_venta OUTPUT;
        PRINT '5) EXEC sp_RegistrarVentaCompleta: PERMITIDO (venta ' + CAST(@id_venta AS VARCHAR(10)) + ')';
    END TRY
    BEGIN CATCH
        PRINT '5) ERROR: ' + ERROR_MESSAGE();
    END CATCH;
    REVERT;
    SELECT 'Venta vista por el dueno antes de deshacer' AS nota, * FROM dbo.venta WHERE id_venta = @id_venta;
IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

-- =============== GERENTE ===============
EXECUTE AS USER = 'usr_gerente';
SELECT USER_NAME() AS sesion_actual;
BEGIN TRY
    SELECT COUNT(*) AS ventas_visibles FROM dbo.venta;
    PRINT '6) SELECT sobre venta: PERMITIDO';
END TRY
BEGIN CATCH
    PRINT '6) ERROR: ' + ERROR_MESSAGE();
END CATCH;
BEGIN TRY
    DELETE FROM dbo.venta WHERE 1 = 0;
    PRINT '7) DELETE sobre venta: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '7) DELETE sobre venta: DENEGADO -> ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- =============== AUDITOR ===============
EXECUTE AS USER = 'usr_auditor';
SELECT USER_NAME() AS sesion_actual;
BEGIN TRY
    SELECT TOP 5 * FROM dbo.auditoria_producto ORDER BY id_auditoria DESC;
    PRINT '8) SELECT sobre auditoria_producto: PERMITIDO';
END TRY
BEGIN CATCH
    PRINT '8) ERROR: ' + ERROR_MESSAGE();
END CATCH;
BEGIN TRY
    SELECT TOP 1 * FROM dbo.venta;
    PRINT '9) SELECT sobre venta: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '9) SELECT sobre venta: DENEGADO -> ' + ERROR_MESSAGE();
END CATCH;
REVERT;

SELECT USER_NAME() AS sesion_final;   -- vuelve al usuario original
GO
```

### Resultados obtenidos

> **Completar:** pegar acá la captura de pantalla (o el texto) del resultado de ejecutar `demo_seguridad.sql` en SQL Server Management Studio.

### Resultado esperado

| Prueba | Resultado |
|---|---|
| 1) Vendedor consulta `vw_lotes_disponibles` | PERMITIDO |
| 2) Vendedor consulta `Persona` | DENEGADO (error 229: permiso SELECT denegado) |
| 3) Vendedor hace `UPDATE` sobre `lote` | DENEGADO |
| 4) Vendedor hace `DELETE` sobre `venta` | DENEGADO |
| 5) Vendedor ejecuta `sp_RegistrarVentaCompleta` | PERMITIDO (la venta se registra y luego se deshace) |
| 6) Gerente consulta `venta` | PERMITIDO |
| 7) Gerente hace `DELETE` sobre `venta` | DENEGADO |
| 8) Auditor consulta `auditoria_producto` | PERMITIDO |
| 9) Auditor consulta `venta` | DENEGADO |

Al final, `sesion_final` vuelve al usuario original (`dbo`).

---
*Proyecto Integrador Bases de Datos 1 – Grupo 9 – Sistema de Gestión de Ventas para Farmacia – Motor: SQL Server Express.*
