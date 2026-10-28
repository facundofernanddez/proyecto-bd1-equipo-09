-- =====================================================================
-- Aislamiento de transacciones: bloqueos entre dos sesiones
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
-- =====================================================================
-- Abrir DOS ventanas de consulta (dos sesiones) en SSMS y ejecutar cada bloque
-- en la ventana indicada, respetando el orden de los pasos.

-- ---------------------------------------------------------------------
-- PASO 1 - SESION A: abre una transaccion y modifica el stock SIN confirmar
-- ---------------------------------------------------------------------
USE Farmacia_Proyecto;   -- << REEMPLAZAR por el nombre real de la base de datos
GO
BEGIN TRANSACTION;
    UPDATE dbo.lote SET stock = stock - 1 WHERE id_lote = 1;

    SELECT 'SESION A' AS sesion, @@TRANCOUNT AS trancount, id_lote, stock
    FROM dbo.lote WHERE id_lote = 1;
-- (NO ejecutar todavia COMMIT ni ROLLBACK: la transaccion queda abierta)

-- ---------------------------------------------------------------------
-- PASO 2 - SESION B: lectura normal (READ COMMITTED, nivel por defecto)
-- ---------------------------------------------------------------------
USE Farmacia_Proyecto;
GO
SET LOCK_TIMEOUT 5000;          -- espera como maximo 5 segundos
SELECT stock FROM dbo.lote WHERE id_lote = 1;
-- Resultado: la consulta queda esperando y falla con el error 1222
-- (Lock request time out period exceeded): no puede leer un dato sin confirmar.

-- ---------------------------------------------------------------------
-- PASO 3 - SESION B: lectura sucia (NOLOCK), solo para mostrar la diferencia
-- ---------------------------------------------------------------------
SELECT stock FROM dbo.lote WITH (NOLOCK) WHERE id_lote = 1;
-- Resultado: devuelve el stock modificado por A aunque todavia no esta confirmado.

-- ---------------------------------------------------------------------
-- PASO 4 - SESION A: deshacer la transaccion
-- ---------------------------------------------------------------------
ROLLBACK TRANSACTION;

-- ---------------------------------------------------------------------
-- PASO 5 - SESION B: repetir la lectura normal
-- ---------------------------------------------------------------------
SELECT stock FROM dbo.lote WHERE id_lote = 1;
-- Resultado: responde de inmediato con el valor original.
GO