-- =====================================================================
-- Seguridad: logins, usuarios, roles y permisos
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
--
-- Requisitos:
--   1. Haber ejecutado el DDL, el DML y los scripts de procedimientos,
--      funciones y triggers. Se usan sp_RegistrarVentaCompleta,
--      sp_ReporteVentasPorVendedor, tipo_detalle_venta y auditoria_producto.
--   2. Ejecutar con un usuario que sea dueno de la base (dbo) para poder
--      crear usuarios, roles, vista y permisos.
--   3. SQL Server 2016 SP1 o superior (por CREATE OR ALTER).
--   4. La demo usa EXECUTE AS USER: se requiere ser dbo o tener IMPERSONATE.
--
-- Portabilidad:
--   Crear LOGINS requiere permisos de sysadmin o ALTER ANY LOGIN. Si el
--   usuario actual no es sysadmin, el script omite los logins y crea los
--   usuarios WITHOUT LOGIN. La demo funciona igual porque simula cada
--   sesion con EXECUTE AS USER.
-- =====================================================================
USE Farmacia_Proyecto;
GO

-- =====================================================================
-- 1) LOGINS (nivel servidor) - solo si hay permisos
--    Contrasenas de ejemplo solo para la demostracion. En un sistema real
--    deben ser propias, secretas y no guardarse en el repositorio.
-- =====================================================================
IF IS_SRVROLEMEMBER('sysadmin') = 1
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'lg_vendedor')
        CREATE LOGIN lg_vendedor WITH PASSWORD = 'Vend#Farmacia2026', CHECK_POLICY = ON;
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'lg_gerente')
        CREATE LOGIN lg_gerente  WITH PASSWORD = 'Gere#Farmacia2026', CHECK_POLICY = ON;
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'lg_auditor')
        CREATE LOGIN lg_auditor  WITH PASSWORD = 'Audi#Farmacia2026', CHECK_POLICY = ON;
    PRINT 'Logins creados o ya existentes.';
END
ELSE
BEGIN
    PRINT 'Sin permisos de sysadmin: se omiten los logins.';
    PRINT 'Los usuarios se crean WITHOUT LOGIN y la demo usa EXECUTE AS.';
END
GO

-- =====================================================================
-- 2) USUARIOS (nivel base de datos) y ROLES
--    Si el login existe, el usuario se mapea a el. Si no existe, se crea
--    WITHOUT LOGIN para que EXECUTE AS USER funcione igual.
-- =====================================================================
IF DATABASE_PRINCIPAL_ID('usr_vendedor') IS NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'lg_vendedor')
        CREATE USER usr_vendedor FOR LOGIN lg_vendedor;
    ELSE
        CREATE USER usr_vendedor WITHOUT LOGIN;
END

IF DATABASE_PRINCIPAL_ID('usr_gerente') IS NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'lg_gerente')
        CREATE USER usr_gerente FOR LOGIN lg_gerente;
    ELSE
        CREATE USER usr_gerente WITHOUT LOGIN;
END

IF DATABASE_PRINCIPAL_ID('usr_auditor') IS NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'lg_auditor')
        CREATE USER usr_auditor FOR LOGIN lg_auditor;
    ELSE
        CREATE USER usr_auditor WITHOUT LOGIN;
END

IF DATABASE_PRINCIPAL_ID('rol_vendedor') IS NULL CREATE ROLE rol_vendedor;
IF DATABASE_PRINCIPAL_ID('rol_gerente')  IS NULL CREATE ROLE rol_gerente;
IF DATABASE_PRINCIPAL_ID('rol_auditor')  IS NULL CREATE ROLE rol_auditor;

IF ISNULL(IS_ROLEMEMBER('rol_vendedor', 'usr_vendedor'), 0) = 0 ALTER ROLE rol_vendedor ADD MEMBER usr_vendedor;
IF ISNULL(IS_ROLEMEMBER('rol_gerente',  'usr_gerente'),  0) = 0 ALTER ROLE rol_gerente  ADD MEMBER usr_gerente;
IF ISNULL(IS_ROLEMEMBER('rol_auditor',  'usr_auditor'),  0) = 0 ALTER ROLE rol_auditor  ADD MEMBER usr_auditor;
GO

-- =====================================================================
-- 3) VISTA que expone solo lo necesario al vendedor
--    Oculta datos personales y costos.
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
GRANT EXECUTE ON TYPE::dbo.tipo_detalle_venta    TO rol_vendedor;   -- necesario para el parametro tipo tabla

DENY SELECT, INSERT, UPDATE, DELETE ON dbo.venta          TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.detalle_venta  TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.pago           TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.lote           TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Persona        TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Cliente        TO rol_vendedor;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Empleado       TO rol_vendedor;

-- Retira el permiso amplio de versiones anteriores y limita la lectura a las
-- tablas incluidas en la matriz de permisos.
REVOKE SELECT ON SCHEMA::dbo FROM rol_gerente;
GRANT SELECT  ON dbo.venta                       TO rol_gerente;
GRANT SELECT  ON dbo.detalle_venta               TO rol_gerente;
GRANT SELECT  ON dbo.pago                        TO rol_gerente;
GRANT SELECT  ON dbo.lote                        TO rol_gerente;
GRANT SELECT  ON dbo.Persona                     TO rol_gerente;
GRANT SELECT  ON dbo.Cliente                     TO rol_gerente;
GRANT SELECT  ON dbo.Empleado                    TO rol_gerente;
GRANT SELECT  ON dbo.Producto                    TO rol_gerente;
GRANT UPDATE  ON dbo.Producto (precio)           TO rol_gerente;
GRANT EXECUTE ON dbo.sp_ReporteVentasPorVendedor TO rol_gerente;
GRANT EXECUTE ON dbo.sp_RegistrarVentaCompleta   TO rol_gerente;
GRANT EXECUTE ON TYPE::dbo.tipo_detalle_venta    TO rol_gerente;
DENY  DELETE  ON dbo.venta                       TO rol_gerente;
DENY  DELETE  ON dbo.detalle_venta               TO rol_gerente;

-- Auditor: solo lectura de la tabla de auditoria.
GRANT SELECT ON dbo.auditoria_producto TO rol_auditor;
GO

-- =====================================================================
-- 5) DEMOSTRACION CON EXECUTE AS
--    Se simula la sesion de cada usuario con EXECUTE AS USER ... REVERT.
--    Al final se vuelve al usuario original (dbo).
-- =====================================================================
SET NOCOUNT ON;

-- Datos necesarios, obtenidos con el usuario actual (dueno de la base)
DECLARE @dni_empleado INT = (SELECT TOP 1 dni FROM dbo.Empleado ORDER BY dni);
DECLARE @id_metodo    INT = (SELECT TOP 1 id_metodo FROM dbo.Metodo_Pago ORDER BY id_metodo);
DECLARE @id_lote      INT = (SELECT TOP 1 l.id_lote
                             FROM dbo.lote l
                             JOIN dbo.Producto p ON p.id_producto = l.id_producto
                             WHERE l.stock >= 1
                               AND l.fecha_vencimiento >= CAST(GETDATE() AS DATE)
                               AND p.requiere_receta = 0
                             ORDER BY l.id_lote);
IF @id_lote IS NULL
BEGIN
    PRINT 'No hay un lote vigente con stock para la demostracion.';
    RETURN;
END;

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
    PRINT '1) ERROR -> error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
END CATCH;

-- 2) Denegado: datos personales
BEGIN TRY
    SELECT TOP 3 * FROM dbo.Persona;
    PRINT '2) SELECT sobre Persona: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '2) SELECT sobre Persona: DENEGADO -> error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
END CATCH;

-- 3) Denegado: modificar stock directamente (WHERE 1 = 0 para no tocar filas)
BEGIN TRY
    UPDATE dbo.lote SET stock = 9999 WHERE 1 = 0;
    PRINT '3) UPDATE sobre lote: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '3) UPDATE sobre lote: DENEGADO -> error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
END CATCH;

-- 4) Denegado: borrar ventas
BEGIN TRY
    DELETE FROM dbo.venta WHERE 1 = 0;
    PRINT '4) DELETE sobre venta: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '4) DELETE sobre venta: DENEGADO -> error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- 5) Permitido: registrar una venta a traves del procedimiento.
--    El procedimiento usa las tablas por encadenamiento de propiedad, aunque
--    el vendedor no tenga permisos directos sobre ellas. Se deshace al final.
BEGIN TRANSACTION;
    EXECUTE AS USER = 'usr_vendedor';
    BEGIN TRY
        EXEC dbo.sp_RegistrarVentaCompleta
             @dni_empleado = @dni_empleado, @id_metodo = @id_metodo,
             @detalle = @items, @dni_cliente = NULL, @id_venta = @id_venta OUTPUT;
        PRINT '5) EXEC sp_RegistrarVentaCompleta: PERMITIDO (venta ' + CAST(@id_venta AS VARCHAR(10)) + ')';
    END TRY
    BEGIN CATCH
        PRINT '5) ERROR -> error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
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
    PRINT '6) ERROR -> error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
END CATCH;
BEGIN TRY
    DELETE FROM dbo.venta WHERE 1 = 0;
    PRINT '7) DELETE sobre venta: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '7) DELETE sobre venta: DENEGADO -> error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
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
    PRINT '8) ERROR -> error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
END CATCH;
BEGIN TRY
    SELECT TOP 1 * FROM dbo.venta;
    PRINT '9) SELECT sobre venta: PERMITIDO (no deberia)';
END TRY
BEGIN CATCH
    PRINT '9) SELECT sobre venta: DENEGADO -> error ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + ': ' + ERROR_MESSAGE();
END CATCH;
REVERT;

SELECT USER_NAME() AS sesion_final;   -- vuelve al usuario original
GO
