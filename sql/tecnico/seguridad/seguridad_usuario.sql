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
