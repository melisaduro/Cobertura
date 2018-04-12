--------------------------------------------------------------------------------------
--Comprobamos que todas las entidades tienen la tabla de entidad creada
--------------------------------------------------------------------------------------

-- Le creamos un identificador a cada ciudad para luego crear un bucle
select identity(int,1,1) id,entidad
into #iterator
from _entidades_ProbCob4G_Fase3_2

--Mostramos las ciudades que se vuelcan
select * from #iterator

print 'Inicio bucle: ' + convert(varchar,getdate())

declare @id int=1
declare @entidad as varchar (256)
declare @Report as varchar (256)
while @id<=(select max(id) from #iterator)
begin
	
	-- Cogemos la informacion de la entidad del Excel en red
	set @entidad = (select entidad from #iterator where id=@id)
	set @Report = 'MUN'
	print convert(varchar,@id)+'. Entidad: ' +@entidad

	
	exec (' insert into _entidad_ProbCob_new_2
	select '''+@entidad+''' as entidad	
	from sys.tables t
	where t.name like ''%lcc_cober4G_50x50_'+@entidad+'_'+@Report +'%''
		and t.type=''U''')

 	-- Cierre del bucle
	set @id=@id+1
end
print 'Fin bucle: ' + convert(varchar,getdate())

drop table #iterator

select * from _entidad_ProbCob_new_2 order by 1

--select *
--into _entidad_ProbCob_new_2
--from _entidad_ProbCob_new

--delete _entidad_ProbCob_new_2
