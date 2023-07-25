/* Este trigger se encarga de que cada vez que se carga un nuevo usuario, automaticamente se inserte
una nueva entrada a la tabla carrito, para dicho usuario, mientras no sea administrador. */
CREATE OR REPLACE FUNCTION crear_carrito_usuario()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	if new.admin = false then
		insert into carrito (id_usuario) values (new.id_usuario);
	end if;
	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_crear_carrito
	AFTER INSERT
	ON usuario
	FOR EACH ROW
	EXECUTE PROCEDURE crear_carrito_usuario();
 
 
------------------------------------------------------------------------------------------------------

/* Este trigger se encarga de que cuando se inserta algun producto al carrito, la cantidad insertada sea menor o igual
al stock disponible. Ademas, una vez que se comprueba que el stock disponible es suficiente, calcula el precio total
de todas las unidades seleccionadas. */


CREATE OR REPLACE FUNCTION verificar_stock()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	if new.cantidad > (select p.stock from producto p where new.id_producto = p.id_producto) then 
		RAISE EXCEPTION 'La cantidad de unidades seleccionada supera el stock disponible del producto.';
	else
		new.precio = new.cantidad * (select p.precio_unitario from producto p where new.id_producto = p.id_producto);
	end if;
	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_verificar_stock
	BEFORE INSERT
	ON linea_carrito
	FOR EACH ROW
	EXECUTE PROCEDURE verificar_stock();
 
 
 -----------------------------------------------
 /*Actualiza el precio total en base a la cantidad de productos seleccionados cuando se cambia la cantidad original.*/
 
 CREATE OR REPLACE FUNCTION actualizar_lineacarrito()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	if new.cantidad != old.cantidad then
	update linea_carrito set precio = (new.cantidad * (select precio_unitario from producto where id_producto = old.id_producto))
	where id_linea = old.id_linea;
	end if;
	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_actualizar_lineacarrito
	AFTER UPDATE
	ON linea_carrito
	FOR EACH ROW
	EXECUTE PROCEDURE actualizar_lineacarrito();
 
 
 ------------------------------------------
 
 
 /* Este trigger se encarga de que si el stock de un producto se convierte en menor a las cantidades que
 el usuario tenia en su carrito, el producto se va a eliminar de todos los carritos donde haya mayor cantidad
 que stock disponible.*/
CREATE OR REPLACE FUNCTION eliminar_stock_mayor()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	delete from linea_carrito l where l.id_producto = old.id_producto and l.cantidad > new.stock ;
	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_eliminar_stock_mayor
	AFTER UPDATE
	ON producto
	FOR EACH ROW
	EXECUTE PROCEDURE eliminar_stock_mayor();
 
------------------------------------------------------------------------------------------------------
/*Se encarga de actualizar la cantidad de unidades de un producto que ya está en el carrito, si es que
se vuelven a agregar unidades de ese producto al carrito llamando al procedimiento verifica_duplicados_carrito. */
 
CREATE OR REPLACE FUNCTION verificar_linea_carrito()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	if new.id_producto in (select id_producto from linea_carrito where id_carrito = new.id_carrito) 
	and (select count(id_producto) from linea_carrito where id_carrito = new.id_carrito and id_producto = new.id_producto) > 1
	then
		call verifica_duplicados_carrito(new.id_carrito, new.id_producto, new.id_linea, new.cantidad);
	end if;
	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_verificar_linea_carrito
	AFTER INSERT
	ON linea_carrito
	FOR EACH ROW
	EXECUTE PROCEDURE verificar_linea_carrito()
 
 ------------------------------------------------------------------------------------------------------

/* Este trigger se encarga de que cuando se inserta algun producto la factura, la cantidad insertada sea menor o igual
al stock disponible. Ademas, una vez que se comprueba que el stock disponible es suficiente, calcula el precio total
de todas las unidades seleccionadas. */

CREATE OR REPLACE FUNCTION verificar_stock_factura()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	if new.cantidad > (select p.stock from producto p where new.id_producto = p.id_producto) then 
		RAISE EXCEPTION 'La cantidad de unidades seleccionada supera el stock disponible del producto.';
	else
		new.precio = new.cantidad * (select p.precio_unitario from producto p where new.id_producto = p.id_producto);
	end if;
	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_verificar_stock_factura
	BEFORE INSERT
	ON linea_factura
	FOR EACH ROW
	EXECUTE PROCEDURE verificar_stock_factura();
 
------------------------------------------------------------------------------------------------------

/* Este trigger se encarga de verificar que si un usuario ya agrego a favoritos un determinado producto, no pueda
agregarlo de nuevo. */
CREATE OR REPLACE FUNCTION verificar_favorito()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	if new.id_producto in (select id_producto from getfavoritos(new.id_usuario)) then 
		RAISE EXCEPTION 'Este producto ya se encuentra agregado a los favoritos del usuario.';
	end if;
	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_verificar_favorito
	BEFORE INSERT
	ON favorito
	FOR EACH ROW
	EXECUTE PROCEDURE verificar_favorito();
	
------------------------------------------------------------------------------------------------------	
/* Este trigger se encarga de que cada vez que se inserta una entrada a la tabla envio_info, automaticamente se le cree
una factura asociada. Se utiliza en la transaccion crear_factura (idusuario)*/
CREATE OR REPLACE FUNCTION insertar_factura()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	insert into factura (id_envioinfo) values (new.id_envioinfo);
	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_insertar_factura
	AFTER INSERT
	ON envio_info
	FOR EACH ROW
	EXECUTE PROCEDURE insertar_factura();
	
	
------------------------------------------------------------------------------------------------------	
/* Este trigger se encarga de evaluar si un usuario compró el producto que está intentando calificar. 
Si verifica que el producto fue comprado, tambien verifica que el usuario no haya calificado ya el producto.*/

CREATE OR REPLACE FUNCTION verificar_compra()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	if (new.id_producto not in (select pc.id_producto from productoscomprados pc where pc.id_usuario = new.id_usuario)) then 
		RAISE EXCEPTION 'Solo se puede calificar productos que hayan sido previamente comprados.';
	else
		if (new.id_producto in (select o.id_producto from opinionesproductos o where o.id_usuario = new.id_usuario)) then
			RAISE EXCEPTION 'Este producto ya fue calificado.';
		end if;
	end if;
	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_verificar_compra
	BEFORE INSERT
	ON opinion
	FOR EACH ROW
	EXECUTE PROCEDURE verificar_compra();
	

------------------------------------------------------------------------------------------------------	
/*
Este trigger se encarga de actualizar el atributo calificacion en un producto cada vez que se añade una nueva opinion
o se borra una opinion existente.
*/
CREATE OR REPLACE FUNCTION calcular_calificacion()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	IF (TG_OP = 'INSERT') THEN
		update producto set calificacion = (
			(select sum(o.puntuacion) from opinion o where o.id_producto=new.id_producto)/(select count(*) from opinion o where o.id_producto=new.id_producto)
		) where id_producto = new.id_producto;
	ELSIF (TG_OP = 'DELETE') THEN
		update producto set calificacion = (
			(select sum(o.puntuacion) from opinion o where o.id_producto=old.id_producto)/(select count(*) from opinion o where o.id_producto=old.id_producto)
		) where id_producto = old.id_producto;	
	END IF;
	RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_calcular_calificacion
	AFTER INSERT OR DELETE
	ON opinion
	FOR EACH ROW
	EXECUTE PROCEDURE calcular_calificacion();

------------------------------------------------------------------------------------------------------	
