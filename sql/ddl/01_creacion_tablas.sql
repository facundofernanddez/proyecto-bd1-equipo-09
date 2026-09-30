-- =========================================================================
-- ETAPA 3: SCRIPT DDL - CREACIÓN DE BASE DE DATOS Y TABLAS
-- =========================================================================

CREATE DATABASE Farmacia_Proyecto
GO

USE Farmacia_Proyecto


-- 2. TABLAS PERIFÉRICAS Y CATÁLOGOS BASE

CREATE TABLE Localidad (
    id_localidad INT IDENTITY (1,1) PRIMARY KEY,
    provincia VARCHAR(50) NOT NULL,
    ciudad VARCHAR(50) NOT NULL,
    codigo_postal VARCHAR(10) NOT NULL
);

CREATE TABLE Direccion (
    id_direccion INT IDENTITY (1,1) PRIMARY KEY,
    calle VARCHAR(100) NOT NULL,
    altura INT NOT NULL,
    piso VARCHAR(20),
    id_localidad INT NOT NULL,
    CONSTRAINT FK_direccion_localidad FOREIGN KEY (id_localidad) REFERENCES Localidad(id_localidad) 
);

CREATE TABLE Categoria (
    id_categoria INT IDENTITY (1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Laboratorio (
    id_laboratorio INT IDENTITY (1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Metodo_Pago (
    id_metodo INT IDENTITY (1,1) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE receta (
    id_receta INT IDENTITY (1,1) PRIMARY KEY,
    num_receta VARCHAR(50) NOT NULL UNIQUE,
    matricula_medico VARCHAR(50) NOT NULL,
    fecha_emision DATE NOT NULL,
    descripcion VARCHAR (200)
);

CREATE TABLE cargo (
    id_cargo INT IDENTITY (1,1) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL UNIQUE
);


-- 3. ACTORES (SUPERCLASE Y SUBCLASES - HERENCIA 1:1)


CREATE TABLE Persona (
    dni INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(100) UNIQUE
);

CREATE TABLE Cliente (
    dni INT PRIMARY KEY,
    id_direccion INT,
    FOREIGN KEY (dni) REFERENCES persona(dni) ON DELETE CASCADE,
    FOREIGN KEY (id_direccion) REFERENCES direccion(id_direccion) ON DELETE SET NULL
);

CREATE TABLE Empleado (
    dni INT PRIMARY KEY,
    legajo VARCHAR(20) NOT NULL UNIQUE,
    fecha_ingreso DATE NOT NULL,
    id_cargo INT NOT NULL,
    CONSTRAINT FK_empleado_persona FOREIGN KEY (dni) REFERENCES persona(dni) ON DELETE CASCADE,
    CONSTRAINT FK_empleado_cargo FOREIGN KEY (id_cargo) REFERENCES Cargo (id_cargo)
);

CREATE TABLE Proveedor (
    dni INT PRIMARY KEY,
    cuit VARCHAR(15) NOT NULL UNIQUE,
    razon_social VARCHAR(100) NOT NULL,
    CONSTRAINT FK_proveedor_persona FOREIGN KEY (dni) REFERENCES persona(dni) ON DELETE CASCADE
);

-- 4. PRODUCTOS, CATÁLOGO Y STOCK


CREATE TABLE Producto (
    id_producto INT IDENTITY (1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL CHECK (precio > 0),
    requiere_receta BIT NOT NULL DEFAULT 0,
    id_categoria INT NOT NULL,
    id_laboratorio INT NOT NULL,
    CONSTRAINT FK_producto_categoria FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria),
    CONSTRAINT FK_producto_laboratorio FOREIGN KEY (id_laboratorio) REFERENCES laboratorio(id_laboratorio)
);

-- Tabla intermedia N:M (Catálogo de proveedores habilitados por producto)
CREATE TABLE proveedor_producto (
    dni_proveedor INT,
    id_producto INT,
    CONSTRAINT PK_proveedor_producto PRIMARY KEY (dni_proveedor, id_producto),
    CONSTRAINT FK_proveerdor_producto_proveedor FOREIGN KEY (dni_proveedor) REFERENCES proveedor(dni) ON DELETE CASCADE,
    CONSTRAINT FK_proveerdor_producto_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto) ON DELETE CASCADE
);

-- Stock físico transaccional
CREATE TABLE lote (
    id_lote INT IDENTITY (1,1) PRIMARY KEY,
    fecha_creacion DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    stock INT NOT NULL CHECK (stock >= 0),
    id_producto INT NOT NULL,
    dni_proveedor INT NOT NULL, 
    CONSTRAINT FK_lote_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
    CONSTRAINT FK_lote_proveerdor FOREIGN KEY (dni_proveedor) REFERENCES proveedor(dni) 
);


-- 5. TRANSACCIONES (VENTAS Y PAGOS)


CREATE TABLE venta (
    id_venta INT IDENTITY (1,1) PRIMARY KEY,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
    dni_cliente INT NOT NULL,
    dni_empleado INT NOT NULL,
    CONSTRAINT FK_venta_cliente FOREIGN KEY (dni_cliente) REFERENCES cliente(dni) ,
    CONSTRAINT FK_venta_empleado FOREIGN KEY (dni_empleado) REFERENCES empleado(dni) 
);

-- Tabla intermedia N:M para métodos de pago (RN.05)
CREATE TABLE pago (
    id_pago INT IDENTITY (1,1) PRIMARY KEY,
    id_venta INT NOT NULL,
    id_metodo INT NOT NULL,
    monto DECIMAL(10, 2) NOT NULL CHECK (monto > 0),
    CONSTRAINT FK_pago_venta FOREIGN KEY (id_venta) REFERENCES venta(id_venta) ON DELETE CASCADE,
    CONSTRAINT FK_venta_metodo_pago FOREIGN KEY (id_metodo) REFERENCES metodo_pago(id_metodo)
);

-- Trazabilidad de cada ítem vendido
CREATE TABLE detalle_venta (
    id_detalle INT IDENTITY (1,1) PRIMARY KEY,
    id_venta INT NOT NULL,
    id_lote INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario >= 0),
    id_receta INT NULL, -- Opcional: Solo para productos que lo requieran (RN.06)
    CONSTRAINT FK_detalle_venta_venta FOREIGN KEY (id_venta) REFERENCES venta(id_venta) ON DELETE CASCADE,
    CONSTRAINT FK_detalle_venta_lote FOREIGN KEY (id_lote) REFERENCES lote(id_lote),
    CONSTRAINT FK_detalle_venta_receta FOREIGN KEY (id_receta) REFERENCES receta(id_receta)
);