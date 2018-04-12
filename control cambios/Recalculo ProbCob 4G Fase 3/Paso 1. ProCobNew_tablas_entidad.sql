exec sp_lcc_dropifexists '_entidades_volcar'
exec  [dbo].[sp_importExcelFileAsText] 'F:\VDF_Invalidate\aggr_coverage_CECI.xlsx', 'cities','_entidades'

-- Le creamos un identificador a cada ciudad para luego crear un bucle
select identity(int,1,1) id,*
into #iterator
from [dbo]._entidades

--Mostramos las ciudades que se vuelcan
select * from #iterator

print 'Inicio bucle: ' + convert(varchar,getdate())

declare @id int=1
declare @entidad as varchar (256)
declare @Report as varchar (256)
declare @bbddOrigen as varchar (256)
while @id<=(select max(id) from #iterator)
begin
	
	-- Cogemos la informacion de la entidad del Excel en red
	set @entidad = (select Entidades from #iterator where id=@id)
	set @bbddOrigen = (select BBDDOrigen from #iterator where id=@id)
	set @Report = (select Report from #iterator where id=@id)
	print convert(varchar,@id)+'. Entidad: ' +@entidad

	exec ('alter table ['+@bbddOrigen+'].dbo.[lcc_cober4G_50x50_'+@entidad+'_'+@Report+'] add PcobInd_NEW [float]')
	--Se mete una nueva columna como comparativa por el posible impacto de longitu/latitud a lonid/latid
	exec ('alter table ['+@bbddOrigen+'].dbo.[lcc_cober4G_50x50_'+@entidad+'_'+@Report+'] add PcobInd_OLD [float]')

	exec (' Update ['+@bbddOrigen+'].dbo.[lcc_cober4G_50x50_'+@entidad+'_'+@Report+']
		set PcobInd_NEW = master.dbo.fn_lcc_ProbindoorCoverage_new(RSRP_Outdoor, Band, 
	                            case i.mob_type when 3 then ''DU'' when 2 then ''U'' else ''SU'' end, ''voice''),
			PcobInd_OLD = master.dbo.fn_lcc_ProbindoorCoverage(RSRP_Outdoor, Band, 
	                            case i.mob_type when 3 then ''DU'' when 2 then ''U'' else ''SU'' end, ''voice'')
		from ['+@bbddOrigen+'].dbo.[lcc_cober4G_50x50_'+@entidad+'_'+@Report+'] t
		LEFT OUTER JOIN AGRIDS_V2.dbo.lcc_G2K5Absolute_INDEX_new i	
			on dbo.fn_lcc_longitude2lonid (t.longitud_50m, t.latitud_50m)=i.lonid and dbo.fn_lcc_latitude2latid (t.latitud_50m)=i.latid')

 	-- Cierre del bucle
	set @id=@id+1
end
print 'Fin bucle: ' + convert(varchar,getdate())

drop table #iterator
