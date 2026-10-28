-- =====================================================================
-- Procedimiento: reporte de ventas por vendedor en un rango de fechas
-- Proyecto Integrador Bases de Datos 1 - Grupo 9
-- Sistema de Gestion de Ventas para Farmacia
-- Motor: SQL Server Express
-- =====================================================================
USE Farmacia_Proyecto;
GO

-- Es la consulta 2.a de la Etapa IV convertida en procedimiento con parametros.
CREATE OR ALTER PROCEDURE dbo.sp_ReporteVentasPorVendedor
    @desde DATE,
    @hasta DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT e.legajo,
           pe.apellido + ', ' + pe.nombre         AS vendedor,
           ca.descripcion                          AS cargo,
           COUNT(DISTINCT v.id_venta)              AS cantidad_ventas,
           SUM(dv.cantidad * dv.precio_unitario)   AS total_vendido
    FROM dbo.venta v
    JOIN dbo.detalle_venta dv ON dv.id_venta = v.id_venta
    JOIN dbo.Empleado e       ON e.dni = v.dni_empleado
    JOIN dbo.Persona pe       ON pe.dni = e.dni
    JOIN dbo.cargo ca         ON ca.id_cargo = e.id_cargo
    WHERE v.fecha_hora >= @desde
      AND v.fecha_hora <  DATEADD(DAY, 1, @hasta)   -- incluye todo el ultimo dia
    GROUP BY e.legajo, pe.apellido, pe.nombre, ca.descripcion
    ORDER BY total_vendido DESC;
END;
GO
