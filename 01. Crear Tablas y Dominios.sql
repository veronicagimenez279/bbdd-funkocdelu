CREATE DOMAIN t_precio AS numeric 
	CHECK (0 <= value and value <= 9999999);

CREATE DOMAIN t_dni AS varchar 
	CHECK (length (value) = 8);
	
CREATE DOMAIN t_comentario AS varchar 
	CHECK (length (value) <= 240);
	
CREATE DOMAIN t_stock AS int 
	CHECK (0 <= value and value <= 9999);
	
CREATE DOMAIN t_puntuacion AS int 
	CHECK (0 <= value and value <= 5);
	
-- Estos 2 tipos se utilizan en las transacciones emitir_factura y cancelar_factura respectivamente.
CREATE TYPE info_lineacarrito AS (idproducto int, cantidad int, precio t_precio);

CREATE TYPE info_lineafactura AS (idproducto int, cantidad int); 


CREATE TABLE usuario
(
	id_usuario serial primary key,
	nombre varchar (50) not null,
	dni t_dni not null,
	mail varchar (45) unique not null,
	password varchar (40) not null,
	admin boolean default false
);

CREATE TABLE categoria (
	id_cat serial primary key,
	nombre varchar (30) not null unique
);

CREATE TABLE producto
(
	id_producto serial primary key,
	nombre varchar (150) not null unique,
	stock t_stock not null,
	visibilidad varchar default 'true',
	precio_unitario t_precio not null,
	descripcion varchar (500) default null,
	fecha_carga TIMESTAMP(0) DEFAULT now(),
	calificacion t_puntuacion default null,
	img_url varchar default null, 
	id_cat int not null,
	foreign key ("id_cat") references categoria ("id_cat")
);

CREATE TABLE carrito 
(
	id_carrito serial primary key, 
	id_usuario int,
	foreign key ("id_usuario") references usuario ("id_usuario")
);

CREATE TABLE linea_carrito 
(
	id_linea serial primary key,
	id_carrito int not null,
	id_producto int not null, 
	cantidad t_stock not null,
	precio t_precio default 0,
	foreign key ("id_carrito") references carrito ("id_carrito"),
	foreign key ("id_producto") references producto ("id_producto")
);

CREATE TABLE opinion (
	id_opinion serial primary key,
	id_usuario int, 
	id_producto int, 
	puntuacion t_puntuacion not null,
	comentario t_comentario default null,
	foreign key ("id_usuario") references usuario ("id_usuario"),
	foreign key ("id_producto") references producto ("id_producto")
);

CREATE TABLE favorito (
	id_favorito serial primary key,
	id_usuario int,
	id_producto int,
	foreign key ("id_usuario") references usuario ("id_usuario"),
	foreign key ("id_producto") references producto ("id_producto")
);


CREATE TABLE ciudad (
	cp int primary key,
	nombre varchar (50) not null
);

CREATE TABLE envio_info (
	id_envioinfo serial primary key,
	cp int default null,
	direccion varchar (200) default null,
	retiro_local boolean default true,
	fecha_despacho date default null,
	costo_envio t_precio default 0,
	foreign key ("cp") references ciudad ("cp")
);

CREATE TABLE factura (
	id_fact serial primary key,
	id_usuario int,
	id_envioinfo int, 
	fecha_fac TIMESTAMP(0) DEFAULT now(),
	total t_precio,
	id_mercadopago varchar default null unique,
	foreign key ("id_usuario") references usuario ("id_usuario"),
	foreign key ("id_envioinfo") references envio_info ("id_envioinfo")
);

CREATE TABLE linea_factura (
	id_linea serial primary key,
	cantidad t_stock not null,
	precio t_precio not null,
	id_fact int not null,
	id_producto int not null,
	foreign key ("id_fact") references factura ("id_fact"),
	foreign key ("id_producto") references producto ("id_producto")	
);

CREATE TABLE cancelacion (
	id_cancelacion serial primary key,
	id_fact int,
	fecha_can TIMESTAMP(0) DEFAULT now(),
	foreign key ("id_fact") references factura ("id_fact")
);


