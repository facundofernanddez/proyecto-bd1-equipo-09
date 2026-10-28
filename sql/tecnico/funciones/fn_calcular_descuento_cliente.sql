-- =====================================================================
-- Funcion: calcular descuento para clientes frecuentes
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
-- =====================================================================
USE Farmacia_Proyecto;
GO

-- Devuelve el porcentaje de descuento segun el monto acumulado de compras del cliente.
--   Mas de $500.000 acumulados -> 10 %
--   Mas de $200.000 acumulados ->  5 %
--   Caso contrario             ->  0 %
CREATE OR ALTER FUNCTION dbo.fn_CalcularDescuentoCliente (@dni_cliente INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @acumulado DECIMAL(14,2);

    SELECT @acumulado = ISNULL(SUM(total), 0)
    FROM dbo.venta
    WHERE dni_cliente = @dni_cliente;

    RETURN CASE
               WHEN @acumulado > 500000 THEN 10.00
               WHEN @acumulado > 200000 THEN  5.00
               ELSE 0.00
           END;
END;
GO
