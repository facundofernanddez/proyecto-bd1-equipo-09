USE Farmacia_Proyecto;
GO

INSERT INTO Localidad (provincia, ciudad, codigo_postal) VALUES
('Corrientes', 'Corrientes Capital', '3400'),
('Chaco', 'Resistencia', '3500'),
('Corrientes', 'Goya', '3450'),
('Corrientes', 'Paso de los Libres', '3230'),
('Chaco', 'Sáenz Peña', '3700'),
('Corrientes', 'Curuzú Cuatiá', '3460'),
('Misiones', 'Posadas', '3300'),
('Formosa', 'Formosa Capital', '3600'),
('Corrientes', 'Bella Vista', '3432'),
('Corrientes', 'Mercedes', '3470');

INSERT INTO Direccion (calle, altura, piso, id_localidad) VALUES
('Av. Junín', 1234, '1 A', 1),
('Calle San Martín', 567, NULL, 1),
('Av. 9 de Julio', 890, '2 B', 2),
('Calle Belgrano', 432, NULL, 3),
('Calle Colón', 101, 'PB', 4),
('Av. Italia', 220, NULL, 5),
('Calle España', 789, '3 C', 1),
('Av. Libertad', 1500, NULL, 1),
('Calle Sarmiento', 334, NULL, 6),
('Av. Mitre', 90, '1 B', 7);

INSERT INTO Categoria (nombre) VALUES
('Medicamentos'),
('Perfumería'),
('Cuidado Personal'),
('Dermocosmética'),
('Bebés y Maternidad'),
('Suplementos y Vitaminas'),
('Primeros Auxilios'),
('Ortopedia'),
('Higiénicos'),
('Accesorios Médicos');

INSERT INTO Laboratorio (nombre) VALUES
('Bayer'),
('Roemmers'),
('Elea'),
('Bagó'),
('Gador'),
('Novartis'),
('Pfizer'),
('Raffo'),
('Sanofi'),
('GlaxoSmithKline');

INSERT INTO Metodo_Pago (descripcion) VALUES
('Efectivo'),
('Tarjeta de Débito'),
('Tarjeta de Crédito'),
('Mercado Pago'),
('Transferencia Bancaria'),
('Rapipago'),
('Vales'),
('Cuenta Corriente'),
('Cheque'),
('Pagofácil');

INSERT INTO receta (num_receta, matricula_medico, fecha_emision, descripcion) VALUES
('REC-00101', 'MP-88321', '2026-08-30', 'Tomar 1 comprimido cada 8hs'),
('REC-00102', 'MP-12455', '2026-08-31', 'Tomar 1 comprimido cada 12hs'),
('REC-00103', 'MP-99412', '2026-09-01', 'Tomar 1 cápsula cada 24hs'),
('REC-00104', 'MP-33109', '2026-09-02', 'Aplicar cada 12hs'),
('REC-00105', 'MP-77410', '2026-09-03', 'Tomar con comidas'),
('REC-00106', 'MP-88321', '2026-09-04', 'Tomar en ayunas'),
('REC-00107', 'MP-12455', '2026-09-05', 'Tomar 1 gota cada 6hs'),
('REC-00108', 'MP-99412', '2026-09-06', 'Uso externo según necesidad'),
('REC-00109', 'MP-33109', '2026-09-07', '1 comprimido antes de dormir'),
('REC-00110', 'MP-77410', '2026-09-08', 'Tomar cada 8hs durante 7 días');

INSERT INTO cargo (descripcion) VALUES
('Farmacéutico Principal'),
('Cajero'),
('Auxiliar de Farmacia'),
('Encargado de Stock'),
('Administrativo'),
('Gerente de Sucursal'),
('Repartidor'),
('Limpieza y Mantenimiento'),
('Auditor Interno'),
('Pasante de Farmacia');

INSERT INTO Persona (dni, nombre, apellido, telefono, correo) VALUES
(30111222, 'Juan', 'Perez', '3794112233', 'juan.perez@email.com'),
(35444555, 'Maria', 'Gomez', '3794223344', 'maria.gomez@email.com'),
(38777666, 'Lucas', 'Fernandez', '3794123456', 'lucas.f@email.com'),
(31555666, 'Diego', 'Torres', '3794665544', 'diego.torres@email.com'),
(42888999, 'Valeria', 'Rios', '3624112233', 'valeria.rios@email.com'),
(27111333, 'Roberto', 'Gomez', '3794778899', 'roberto.g@email.com'),
(39444222, 'Laura', 'Benitez', '3794332211', 'laura.b@email.com'),
(25333444, 'Sofia', 'Rodriguez', '3624998877', 'sofia.r@email.com'),
(40123456, 'Ana', 'Martinez', '3794889900', 'ana.martinez@email.com'),
(28999888, 'Carlos', 'Lopez', '3794556677', 'carlos.lopez@email.com');

INSERT INTO Cliente (dni, id_direccion) VALUES
(30111222, 1),
(35444555, 2),
(38777666, 3),
(31555666, 4),
(42888999, 5),
(27111333, 6),
(39444222, 7),
(25333444, 8),
(40123456, 9),
(28999888, 10);

INSERT INTO Empleado (dni, legajo, fecha_ingreso, id_cargo) VALUES
(28999888, 'LEG-001', '2020-01-15', 1),
(40123456, 'LEG-002', '2021-03-01', 2),
(38777666, 'LEG-003', '2022-06-10', 3),
(25333444, 'LEG-004', '2019-11-20', 4),
(31555666, 'LEG-005', '2023-02-01', 5),
(42888999, 'LEG-006', '2020-08-15', 6),
(27111333, 'LEG-007', '2018-05-12', 7),
(39444222, 'LEG-008', '2022-09-01', 8),
(30111222, 'LEG-009', '2017-04-10', 9),
(35444555, 'LEG-010', '2024-01-05', 10);

INSERT INTO Proveedor (dni, cuit, razon_social) VALUES
(40123456, '30-40123456-7', 'Droguería Sur S.A.'),
(38777666, '30-38777666-8', 'Distribuidora Farma S.R.L.'),
(25333444, '30-25333444-9', 'Droguería del Litoral'),
(31555666, '30-31555666-0', 'Pharma Group Argentina'),
(42888999, '30-42888999-2', 'Suministros Médicos Corrientes'),
(27111333, '30-27111333-3', 'Droguería Resistencia'),
(39444222, '30-39444222-4', 'Logística Salud S.A.'),
(30111222, '30-30111222-5', 'Distribuidora Global Farma'),
(35444555, '30-35444555-6', 'Droguería Central'),
(28999888, '30-28999888-7', 'Proveedor Farmacéutico del Norte');

INSERT INTO Producto (nombre, precio, requiere_receta, id_categoria, id_laboratorio) VALUES
('Aspirina 500mg', 1500.50, 0, 1, 1),
('Sertal Compuesto', 3200.00, 1, 1, 2),
('Ibuprofeno 600mg', 4500.00, 1, 1, 3),
('Amoxidal 500mg', 2800.00, 1, 1, 4),
('Crema Dermaglós 200g', 12000.00, 0, 4, 3),
('Alcohol en Gel 250ml', 850.00, 0, 7, 5),
('Tylenol 500mg', 6400.00, 0, 1, 6),
('Vitamina C Redoxon', 9800.00, 0, 6, 1),
('Champú Nivea Baby', 3500.00, 0, 5, 7),
('Protector Solar FPS50', 11500.00, 0, 4, 3);

INSERT INTO proveedor_producto (dni_proveedor, id_producto) VALUES
(40123456, 1),
(40123456, 2),
(38777666, 3),
(38777666, 4),
(25333444, 5),
(31555666, 6),
(42888999, 7),
(27111333, 8),
(39444222, 9),
(30111222, 10);

INSERT INTO lote (fecha_creacion, fecha_vencimiento, stock, id_producto, dni_proveedor) VALUES
('2024-01-10', '2026-12-31', 100, 1, 40123456),
('2024-02-01', '2025-10-15', 50, 2, 40123456),
('2024-03-15', '2026-08-20', 200, 3, 38777666),
('2024-04-10', '2025-12-01', 80, 4, 38777666),
('2024-05-05', '2027-01-10', 40, 5, 25333444),
('2024-06-12', '2026-06-30', 150, 6, 31555666),
('2024-07-01', '2025-11-11', 90, 7, 42888999),
('2024-07-20', '2027-05-18', 60, 8, 27111333),
('2024-08-02', '2026-04-25', 30, 9, 39444222),
('2024-08-15', '2026-09-30', 75, 10, 30111222);

INSERT INTO venta (fecha_hora, total, dni_cliente, dni_empleado) VALUES
('2026-09-01 09:30:00', 1500.50, 30111222, 28999888),
('2026-09-02 10:15:00', 3200.00, 35444555, 40123456),
('2026-09-03 11:00:00', 4500.00, 38777666, 38777666),
('2026-09-04 12:45:00', 2800.00, 31555666, 28999888),
('2026-09-05 15:20:00', 12000.00, 42888999, 40123456),
('2026-09-06 16:10:00', 850.00, 27111333, 38777666),
('2026-09-07 17:00:00', 6400.00, 39444222, 28999888),
('2026-09-08 18:30:00', 9800.00, 25333444, 40123456),
('2026-09-09 19:15:00', 3500.00, 40123456, 38777666),
('2026-09-10 20:00:00', 11500.00, 28999888, 28999888);

INSERT INTO pago (id_venta, id_metodo, monto) VALUES
(1, 1, 1500.50),
(2, 2, 3200.00),
(3, 3, 4500.00),
(4, 4, 2800.00),
(5, 1, 12000.00),
(6, 2, 850.00),
(7, 3, 6400.00),
(8, 4, 9800.00),
(9, 5, 3500.00),
(10, 6, 11500.00);

INSERT INTO detalle_venta (id_venta, id_lote, cantidad, precio_unitario, id_receta) VALUES
(1, 1, 1, 1500.50, 1),
(2, 2, 1, 3200.00, 2),
(3, 3, 1, 4500.00, 3),
(4, 4, 1, 2800.00, 4),
(5, 5, 1, 12000.00, NULL),
(6, 6, 1, 850.00, NULL),
(7, 7, 1, 6400.00, 7),
(8, 8, 1, 9800.00, NULL),
(9, 9, 1, 3500.00, NULL),
(10, 10, 1, 11500.00, 10);
