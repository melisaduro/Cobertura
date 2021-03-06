
-- TESTING VARIABLES
declare @ruta_entidades as varchar (4000)='F:\VDF_Invalidate\aggr_coverage_CECI.xlsx'

-- Importamos el excel que contiene el nombre de todas las ciudades a agregar

exec sp_lcc_dropifexists '_ciudades'

-- Cogemos la informacion de la entidad del Excel en red
exec  [dbo].[sp_importExcelFileAsText] @ruta_entidades, 'cities','_ciudades'


-- Le creamos un identificador a cada ciudad para luego crear un bucle

select identity(int,1,1) id,*
into #iterator
from [dbo].[_ciudades]


--Mostramos las ciudades que se agregaran

 select * from #iterator

 --Comenzamos el bucle con todas las ciudades a agregar

 declare @id int=1
 declare @date_Ini as datetime = getdate()


	 while @id<=(select max(id) from #iterator)
	 begin

		declare @BBDDorigen as varchar (256)= (select BBDDorigen from #iterator  where id=@id)	
  		declare @ciudad as varchar(256) = (select Entidades from #iterator where id=@id)
		declare @pattern as varchar (256) = (select Entidades from #iterator where id=@id)
		declare @Report as varchar (256) = (select Report from #iterator where id=@id)

		-- 20171214-@MDM: Actualización para no permitir el agregado por Vodafone
		if @Report = 'VDF'
		begin
			select 'Agregado VDF no permitido'
			GOTO salto
		end

		declare @Methodology as varchar (50) = 'D16'

		--Declaramos las variables monthyeardash, weekdash en función de la fecha de ejecución (no impactan en el resto de procedimientos)
		declare @monthYearDash as varchar(100) = (select right(convert(varchar(256),datepart(yy, getdate())),2) + '_'	 + convert(varchar(256),format(getdate(),'MM')))
		declare @weekDash as varchar(50) = 'W' +convert(varchar,DATEPART(iso_week, getdate()))

		declare @camposLlave as varchar(1024) = 'MNC-Parcel-Meas_Round-[Database]-carrier-Report_Type-Entidad'
		declare @operator as varchar(256)
		declare @aggrType as varchar(256)='GRID'

		print @monthYearDash
		print @weekDash

		begin
			set @operator='1'

			exec('
			exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Coverage_Aggr_D16_FY1718
			'''+@ciudad+''', '+@operator+', 0,'''', 0, 1, '''+@pattern+''', ''Y'', '''+@camposLlave+''', '''+@monthYearDash+''', '''+@weekDash+''','''+@Methodology+''','''+@Report+''','''+@aggrType+'''
			')
		end

		begin
			set @operator='7'

			exec('
			exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Coverage_Aggr_D16_FY1718
			'''+@ciudad+''', '+@operator+', 0,'''', 0, 1, '''+@pattern+''', ''Y'', '''+@camposLlave+''', '''+@monthYearDash+''', '''+@weekDash+''','''+@Methodology+''','''+@Report+''','''+@aggrType+'''
			')
		end

		begin
			set @operator='3'

			exec('
			exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Coverage_Aggr_D16_FY1718
			'''+@ciudad+''', '+@operator+', 0,'''', 0, 1, '''+@pattern+''', ''Y'', '''+@camposLlave+''', '''+@monthYearDash+''', '''+@weekDash+''','''+@Methodology+''','''+@Report+''','''+@aggrType+'''
			')
		end

		begin
			set @operator='4'

			exec('
			exec '+@BBDDorigen+'.dbo.sp_lcc_create_tables_Coverage_Aggr_D16_FY1718
			'''+@ciudad+''', '+@operator+', 0,'''', 0, 1, '''+@pattern+''', ''Y'', '''+@camposLlave+''', '''+@monthYearDash+''', '''+@weekDash+''','''+@Methodology+''','''+@Report+''','''+@aggrType+'''
			')
		end

	
		
	set @id=@id+1 --Siguiente entidad

	end --Fin del while


--Limpieza de tablas temporales
drop table #iterator



