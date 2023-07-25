/* La funcion getfavoritos(id_usuario) se encarga de obtener los favoritos de un determinado usuario, mostrando
su nombre, el nombre del producto, y el id de dicho producto. */
create or replace function getfavoritos (id_usuario int)
returns table 
(
	idusuario int, nombre_usuario varchar, nombre_producto varchar, id_producto int
)
language plpgsql
as
$$
begin 
return query 
	select u.id_usuario, u.nombre, p.nombre, p.id_producto from usuario u, producto p, favorito f
	where u.id_usuario = f.id_usuario and p.id_producto = f.id_producto and u.id_usuario = $1;
end;
$$;

-- select * from getfavoritos(1);

------------------------------------------------------------------------------------------------------

/* La funcion getcarrito devuelve una tabla con la informacion del carrito de un usuario */
create or replace function getcarrito (id_carrito int)
returns table 
(
	id_usuario int, nombre_usuario varchar, id_producto int, 
	nombre_producto varchar, cantidad_producto t_stock, precio_unitario t_precio, precio_total t_precio
)
language plpgsql
as
$$
begin 
return query 
	select u.id_usuario, u.nombre, p.id_producto, p.nombre, lc.cantidad, p.precio_unitario, lc.precio from usuario u, producto p, linea_carrito lc, carrito c
	where u.id_usuario = c.id_usuario and lc.id_carrito = c.id_carrito and lc.id_producto = p.id_producto and c.id_carrito = $1;
end;
$$;

-- select * from getcarrito(2);


------------------------------------------------------------------------------------------------------

/* La funcion buscarproductos(buscado) busca todos los productos que en su nombre contengan el valor 'buscado'
utilizando ilike para que no distinga entre mayusculas y minusculas. */
create or replace function buscarproductos(buscado varchar)
returns table 
(
	nombre varchar, precio t_precio, stock t_stock, categoria varchar, descripcion varchar
)
language plpgsql
as
$$
begin 
return query 
	select * from productos p where p.nombre ilike ('%' || $1 || '%');
end;
$$;


-- select * from buscarproductos('sTar wArs')


------------------------------------------------------------------------------------------------------
/* Esta funcion se encarga de obtener todos los productos de una categoria dada.*/
create or replace function getproductosporcategoria (cat varchar)
returns table 
(
	id_producto int, nombre varchar, precio t_precio
)
language plpgsql
as
$$
begin 
return query 
	select p.id_producto, p.nombre, p.precio_unitario from producto p, categoria c 
	where p.id_cat = c.id_cat and c.nombre = upper($1);
end;
$$;

-- select * from getproductosporcategoria('mcu');


------------------------------------------------------------------------------------------------------
/*Esta funcion se utiliza para obtener todas las facturas asociadas a un usuario, para poder utilizar los 
ids de las facturas para obtener el detalle de facturas en particular con getdetallefactura */
create or replace function getfacturasusuario (idusuario int)
returns table 
(
	idfactura int, totalfactura t_precio, costo_envio t_precio, fecha_despacho date, idenvio int
)
language plpgsql
as
$$
begin 
return query 
	select f.id_fact, f.total, ei.costo_envio, ei.fecha_despacho, ei.id_envioinfo from factura f, envio_info ei 
	where f.id_usuario = $1 and f.id_envioinfo = ei.id_envioinfo;
end;
$$;

-- select * from getfacturasusuario (9)

------------------------------------------------------------------------------------------------------
/* Esta funcion devuelve los productos comprados por el usuario en base a una factura dada. */

create or replace function getdetallefactura (idfactura int)
returns table 
(
	nombre varchar, cantidad t_stock, precio_unitario t_precio, preciototal t_precio
)
language plpgsql
as
$$
begin 
return query 
	select p.nombre, lf.cantidad, p.precio_unitario, lf.precio from linea_factura lf, producto p
	where lf.id_fact = idfactura and p.id_producto = lf.id_producto;
end;
$$;

-- select * from getdetallefactura (1)

------------------------------------------------------------------------------------------------------
/* Devuelve la informacion de envio en base a un id_factura dado. */

create or replace function getenvioinfo (idfactura int)
returns table 
(
	id_envio int, 
	direccion varchar, 
	ciudad varchar, 
	fecha_despacho date, 
	totalfactura t_precio, 
	costoenvio t_precio
)
language plpgsql
as
$$
begin
return query
	select ei.id_envioinfo, ei.direccion, c.nombre, ei.fecha_despacho, f.total, ei.costo_envio 
	from envio_info ei, ciudad c, factura f 
	where ei.cp = c.cp and ei.id_envioinfo = f.id_envioinfo and f.id_fact = idfactura;

end;
$$;