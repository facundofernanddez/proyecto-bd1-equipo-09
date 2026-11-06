-- =====================================================================
-- ETAPA V - MANEJO DE TRANSACCIONES: AISLAMIENTO
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
--
-- ATENCION: esta demostracion necesita DOS ventanas de consulta (dos sesiones)
-- abiertas al mismo tiempo en SSMS.
--
-- ORDEN:
--   SESION A: PASO 1 y PASO 4.
--   SESION B: PASO 2, PASO 3 y PASO 5, en ese orden.
--   No cerrar la transaccion de A hasta despues del PASO 3 de B.
-- =====================================================================
USE Farmacia_Proyecto;
GO

-- ---------------------------------------------------------------------
-- PASO 1 - SESION A: abre una transaccion y modifica el stock SIN confirmar
-- ---------------------------------------------------------------------
BEGIN TRANSACTION;
    UPDATE dbo.lote SET stock = stock - 1 WHERE id_lote = 1;

    SELECT 'SESION A' AS sesion, @@TRANCOUNT AS trancount, id_lote, stock
    FROM dbo.lote WHERE id_lote = 1;
-- (NO ejecutar todavia COMMIT ni ROLLBACK: la transaccion queda abierta)

-- ---------------------------------------------------------------------
-- PASO 2 - SESION B: lectura normal (READ COMMITTED, nivel por defecto)
-- ---------------------------------------------------------------------
SET LOCK_TIMEOUT 5000;          -- espera como maximo 5 segundos
SELECT stock FROM dbo.lote WHERE id_lote = 1;
-- (Lock request time out period exceeded): no puede leer un dato sin confirmar.

-- ---------------------------------------------------------------------
-- PASO 3 - SESION B: lectura sucia (NOLOCK), solo para mostrar la diferencia
-- ---------------------------------------------------------------------
SELECT stock FROM dbo.lote WITH (NOLOCK) WHERE id_lote = 1;

-- ---------------------------------------------------------------------
-- PASO 4 - SESION A: deshacer la transaccion
-- ---------------------------------------------------------------------
ROLLBACK TRANSACTION;

-- ---------------------------------------------------------------------
-- PASO 5 - SESION B: repetir la lectura normal
-- ---------------------------------------------------------------------
SELECT stock FROM dbo.lote WHERE id_lote = 1;
GO
