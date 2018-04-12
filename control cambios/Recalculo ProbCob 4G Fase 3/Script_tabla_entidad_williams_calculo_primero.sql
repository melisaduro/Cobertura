--------------------------------------------------------------------------------------
--Comprobamos que las entidades williams con probCob_NEW ya calculada en marzo
--siguen teniendo la columnas en su tabla de entidad (en caso contrario se han
--reprocesado) --> Salen 7 que NO
--------------------------------------------------------------------------------------

-- Le creamos un identificador a cada ciudad para luego crear un bucle
select identity(int,1,1) id,entity_name
into #iterator
from (select *
	from (select entidad, count(1) as 'Reg', 	sum(case when [LTE_NEW] is null	then 1 else 0 end) as 'Reg_null'
		from [AGGRCoverage].[dbo].[lcc_aggr_sp_MDD_Coverage_All_Curves]
		where report_Type = 'MUN'
			and meas_round = 'FY1718_H1'		
		group by entidad ) t
	where Reg <> Reg_null) t
	inner join [AGRIDS_v2].[dbo].[lcc_ciudades_tipo_Project_V9] t2
	on t.entidad=t2.entity_name
where scope='ADD-ON CITIES WILLIAMS'

--Mostramos las ciudades que se vuelcan
select * from #iterator

print 'Inicio bucle: ' + convert(varchar,getdate())

declare @id int=1
declare @entidad as varchar (256)
declare @Report as varchar (256)
while @id<=(select max(id) from #iterator)
begin
	
	-- Cogemos la informacion de la entidad del Excel en red
	set @entidad = (select entity_name from #iterator where id=@id)
	set @Report = 'MUN'
	print convert(varchar,@id)+'. Entidad: ' +@entidad

	
	exec (' insert into _entidad_ProbCob_new
	select '''+@entidad+''' as entidad	
	from sys.tables t, sys.columns c
	where t.object_id=c.object_id 
		and t.name like ''%lcc_cober4G_50x50_'+@entidad+'_'+@Report +'%''
		and c.name = ''PcobInd_NEW''
		and t.type=''U''')

 	-- Cierre del bucle
	set @id=@id+1
end
print 'Fin bucle: ' + convert(varchar,getdate())

drop table #iterator

select * from _entidad_ProbCob_new order by 1
