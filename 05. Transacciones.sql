/* 
Esta transaccion se encarga de recibir el id_del usuario, y con eso crear las entradas correspondientes primero en
la tabla envio_info, y con el trigger trigger_insertar_factura se inserta automaticamente una entrada en la tabla 
factura. Luego toma el id_envio de la entrada recien insertada y actualiza el valor id_usuario en  la tupla 
correspondiente en la tabla factura. A su vez, devuelve el id_envio para utilizarlo en la transaccion emitir_factura. 
*/
create or replace procedure crear_factura (idusuario int, idmercadopago varchar, inout id_envio int default null)
language plpgsql 
as $$
declare 
	id_ef int;
begin
	insert into envio_info default values returning id_envioinfo into id_ef;
	update factura set id_usuario = idusuario where id_envioinfo = id_ef;
	update factura set id_mercadopago = idmercadopago where id_envioinfo = id_ef;
	select id_envioinfo from envio_info where id_envioinfo = id_ef into id_envio;
end;
$$;

------------------------------------------------------------------------------------------------------

/* Esta transaccion se encarga de tomar la informacion que se encuentra almacenada en el carrito (no vacio) y 
transformarla en una factura, luego de la creacion de la entrada correspondiente en envio_info con la transaccion 
crear_factura. Si el carrito está vacio, muestra un mensaje indicandolo. */

create or replace procedure emitir_factura (
	idusuario int,
	idmercadopago varchar,
	codpost int default null, 
	direc varchar default null, 
	retirolocal boolean default null)
language plpgsql 
as $$
declare 
	idenvio int;
	idfactura int;
	idcarrito int;
	idproducto int;
	cant int;
	prec t_precio;
	registro info_lineacarrito;
	costoenvio t_precio := 500;
begin
	idcarrito = (select c.id_carrito from carrito c where c.id_usuario = idusuario);
	
	-- Esta condición se asegura que el carrito no esté vacio, verificando que el id_carrito aparezca en linea_carrito.
	if idcarrito in (select id_carrito from linea_carrito) then
		call crear_factura(idusuario, idmercadopago, idenvio);
		idfactura = (select f.id_fact from factura f where f.id_envioinfo = idenvio);
		if (retirolocal = false) then
			update envio_info set cp = codpost, direccion = direc, retiro_local = false where id_envioinfo = idenvio;
		end if;
		for registro in (select lc.id_producto, lc.cantidad, lc.precio from linea_carrito lc, carrito c 
						 where c.id_usuario = idusuario and lc.id_carrito = c.id_carrito)
		loop
			insert into linea_factura (cantidad, precio, id_fact, id_producto) 
			values (registro.cantidad, registro.precio, idfactura, registro.idproducto);
			update producto set stock = stock - registro.cantidad where id_producto = registro.idproducto;
		end loop;
		delete from linea_carrito where id_carrito = idcarrito;

		update factura set total = (select sum(l.precio) from linea_factura l where l.id_fact = idfactura) where id_fact = idfactura;

		if (select total from factura where id_fact = idfactura) < 20000 and retirolocal = false then
			update envio_info set costo_envio = costoenvio where id_envioinfo = idenvio;
		end if;
		RAISE NOTICE 'La factura se emitio correctamente.'; 
		--commit;
	else 
		RAISE NOTICE 'El carrito está vacio.'; 
	end if;
	
end;
$$;

------------------------------------------------------------------------------------------------------

/* Esta transaccion se encarga de cancelar una compra teniendo en cuenta que el envio aun no haya sido realizado 
o que no haya sido cancelada todavia la factura para ejecutar o no la transaccion. Despues crea la entrada 
correspondiente en la tabla cancelacion y vuelve a sumarle el stock a los productos correspondientes.*/

create or replace procedure cancelar_factura (idfactura int)
language plpgsql 
as $$
declare 
	registro info_lineafactura;
begin
	if (idfactura in (select c.id_fact from cancelacion c)) then
		RAISE NOTICE 'La factura ya ha sido cancelada.'; 		
	elseif (select ef.fecha_despacho from envio_info ef, factura f 
			where ef.id_envioinfo = f.id_envioinfo and f.id_fact = idfactura) is not null then
		RAISE NOTICE 'El envío ya fue realizado o se retiró por el local. La compra no se puede cancelar.'; 
	else
		insert into cancelacion (id_fact) values (idfactura);
		for registro in (select lf.id_producto, lf.cantidad from linea_factura lf 
						 where lf.id_fact = idfactura)
		loop
			update producto set stock = (stock + registro.cantidad) where id_producto = registro.idproducto;
		end loop;
		--commit;
	end if;
	
end;
$$;

-------------------------------------------------------------------------------------------------------
/* Procedimiento que se encarga de controlar que cuando se agregan mas unidades de un producto que ya
esta en el carrito, estas unidades se agregen a la entrada de linea_carrito correspondiente en vez de duplicar.*/
 
create or replace procedure verifica_duplicados_carrito (idcarrito int, idproducto int, idlinea int, cant int)
language plpgsql 
as $$
declare 
	
begin
	if (select cantidad from linea_carrito where id_linea = idlinea) > 
	(
		(select p.stock from producto p where idproducto = p.id_producto)
		-
		(select lc.cantidad from linea_carrito lc where idproducto = lc.id_producto and lc.id_carrito = idcarrito and lc.id_linea != idlinea)
	) then
		RAISE EXCEPTION 'La cantidad de unidades seleccionada supera el stock disponible del producto.';
	else
		update linea_carrito set 
		cantidad = (cant + (select cantidad from linea_carrito where id_carrito = idcarrito and id_producto = idproducto and id_linea != idlinea))
		where id_carrito = idcarrito and id_linea != idlinea and id_producto = idproducto;
		update linea_carrito set precio = 
		(
		 (select cantidad from linea_carrito where idcarrito = id_carrito and id_linea <> idlinea and id_producto = idproducto) 
		 * (select precio_unitario from producto where id_producto = idproducto)
		)
		where id_linea != idlinea and id_producto = idproducto and id_carrito = idcarrito;
		delete from linea_carrito where idlinea = id_linea;
	end if;

end;
$$;

