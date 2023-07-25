/* Esta vista se crea para poder evaluar si un usuario compro un producto, y en base a eso permitirle (o no) opinar 
sobre dicho producto con un trigger before insert en la tabla opinion. Se evalua tambien que la factura no haya
sido cancelada. */

create view productoscomprados as (
	select lf.id_producto, f.id_usuario from factura f, linea_factura lf 
	where f.id_fact = lf.id_fact and (f.id_fact not in (select id_fact from cancelacion))
);


------------------------------------------------------------------------------------------------------

/* Esta vista contiene todas las opiniones existentes de los productos.*/
create view opinionesproductos as (
	select p.id_producto, p.nombre, o.puntuacion, o.comentario, o.id_opinion, o.id_usuario from opinion o, producto p 
	where o.id_producto = p.id_producto
);


------------------------------------------------------------------------------------------------------
/* Esta vista devuelve aquellas facturas que no fueron canceladas. Incluye el valor del costo del envio. */

create view facturasnocanceladas as(
	select f.id_fact, f.id_usuario, f.fecha_fac, f.total, e.costo_envio from factura f, envio_info e 
	where (f.id_fact not in (select id_fact from cancelacion)) and f.id_envioinfo = e.id_envioinfo
);

------------------------------------------------------------------------------------------------------
/* Crea una vista con todos los productos cuya visibilidad es true.*/
create view productos as (
	select p.nombre, p.precio_unitario, p.stock, c.nombre as categoria, p.descripcion from producto p, categoria c 
	where p.id_cat = c.id_cat and p.visibilidad = 'true'
	order by categoria, p.stock
)