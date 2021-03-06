--USE [master]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_2G_Query]    Script Date: 25/01/2018 18:22:25 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--ALTER procedure [dbo].[sp_MDD_Coverage_2G_Query] (
--		-- Variables de entrada
--		@provincia as varchar(256),			-- si NED: '%%',	si paso1: valor
--		@ciudad as varchar(256),			-- si NED: valor,	si paso1: '%%'				
--		@simOperator as int,
--		--@umbralIndoor as int, 'Si se quiere normalizar a partir de cierto umbral
--		@Date as varchar (256),
--		@Road as int,
--		@Report as varchar (256)
--		)
--as


-----------------------------
----- Testing Variables -----
-----------------------------
use [FY1718_Coverage_Union_H1]
declare @provincia as varchar(256) = '%%'
declare @ciudad as varchar(256) = 'GRANADA'

declare @simOperator as int = 1

declare @Date as varchar(256) = '%%'

declare @Road as int = 0
declare @Report as varchar (256)= 'MUN'


CREATE TABLE #cuad_50_50(
	[Longitud_50m] [float] NULL,
	[Latitud_50m] [float] NULL,
	[frecuencia] [int] NULL,
	[Band] [varchar] (255) NULL,
	[operator] [varchar](255) NULL,
	[BSIC] [int] NULL,
	[RSSI_Outdoor] [float] NULL,
	[RSSI_Indoor] [float] NULL,
	[PcobInd] [float] NULL,
	[PcobInd_Band] [float] NULL,
	[num_pilots] [int] NULL,
	[num_Pilots_Band] [int] NULL,
	[ind_ord] [bigint] NULL,
	[ind_ord_operator] [bigint] NULL

)


--Declaramos la tabla a usar
declare @GridTable as varchar (256)

If @Report = 'VDF'
begin
	Set @GridTable = 'lcc_position_Entity_List_Vodafone'
end

Else If @Report = 'OSP'
begin
	Set @GridTable = 'lcc_position_Entity_List_Orange'
end

Else If @Report = 'MUN'
begin
	Set @GridTable = 'lcc_position_Entity_List_Municipio_Cerrado'
end

Else If @Report = 'ROAD'
begin
	Set @GridTable = 'lcc_position_Entity_List_Roads'
end
------------------------------------------------------------------------------
--tabla de las frecuencias por cuadrícula
------------------------------------------------------------------------------

--Valores de normalización para la cobertura Indoor respecto a la banda 900
declare @normalizacionBand1800 as float=0 -- normalizando a banda 900:-3   -- Sin simplificar seía -2.8

if @road=0
begin
	insert into #cuad_50_50
	exec('
	select 
		longitude as Longitud_50m,
		latitude as Latitud_50m,
		Channel as frecuencia,
		c.Band,
		sof.ServingOperator as operator,
		bsic,
		RSSI_median as RSSI_Outdoor,

		case when c.Band=''DCS'' then RSSI_median+'+@normalizacionBand1800+'	  --1800
			 else RSSI_median	 	  	  	  	  	  	  	  	  	  		  --900
		end as RSSI_Indoor,
		c.PcobInd as PcobInd,
		c.PcobInd_Band as PcobInd_Band,
		c.num_pilots,
		c.num_Pilots_Band,
		1 as ind_ord,
		c.operator_ord as ind_ord_operator

	
	from ' + @GridTable + ' b,
		lcc_GSMScanner_50x50_ProbCobIndoor_Cerrado c
		LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof 
			on c.Channel=sof.Frequency
	where b.lonid=c.lonid and b.latid=c.latid
	and b.[entity_name] = '''+@ciudad +'''
	and b.[type] in (''Urban'', ''Indoor'')

	group by longitude, latitude, Channel, c.Band, sof.ServingOperator, bsic, RSSI_median,
		case when c.Band=''DCS'' then RSSI_median+'+@normalizacionBand1800+'	  --1800
			 else RSSI_median	 	  	  	  	  	  	  	  	  	  		  --900
		end,
		c.PcobInd, c.PcobInd_Band,
		c.num_pilots, c.num_Pilots_Band,
		c.operator_ord
		'
	)
end

else

begin

	insert into #cuad_50_50
	exec('
	select 
		longitude as Longitud_50m,
		latitude as Latitud_50m,
		Channel as frecuencia,
		c.Band,
		sof.ServingOperator as operator,
		bsic,
		RSSI_median as RSSI_Outdoor,

		case when c.Band=''DCS'' then RSSI_median+'+@normalizacionBand1800+'	  --1800
			 else RSSI_median	 	  	  	  	  	  	  	  	  	  		  --900
		end as RSSI_Indoor,
		c.PcobInd as PcobInd,
		c.PcobInd_Band as PcobInd_Band,
		c.num_pilots,
		c.num_Pilots_Band,
		1 as ind_ord,
		c.operator_ord as ind_ord_operator

	from ' + @GridTable + ' b,
		lcc_GSMScanner_50x50_ProbCobIndoor_Cerrado c
		LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof 
			on c.Channel=sof.Frequency
	where b.lonid=c.lonid and b.latid=c.latid
	and b.[entity_name] = '''+@ciudad +'''
	and b.[type] in (''Road'', ''RW-Road'', ''RW'')

	group by longitude, latitude, Channel, c.Band, sof.ServingOperator, bsic, RSSI_median,
		case when c.Band=''DCS'' then RSSI_median+'+@normalizacionBand1800+'	  --1800
			 else RSSI_median	 	  	  	  	  	  	  	  	  	  		  --900
		end,
		c.PcobInd, c.PcobInd_Band,
		c.num_pilots, c.num_Pilots_Band,
		c.operator_ord
		'
	)

end

------------------------------------------------------------------------------
-- guardar en una tabla por ciudad para que no se sobreescriban los datos
------------------------------------------------------------------------------
--Para las ciudades con más de una palabra
declare @ciudTable as varchar(256)=replace(replace(@ciudad,' ','_'),'-','_')
  
--if OBJECT_ID('lcc_cober2G_50x50_'+@ciudTable) is not null  exec ('drop table lcc_cober2G_50x50_'+@ciudTable)
exec ('sp_lcc_dropifexists ''lcc_cober2G_50x50_'+@ciudTable+'_'+@Report+'_Cerrado''' )

exec (' select * into [lcc_cober2G_50x50_'+@ciudTable+'_'+@Report+'_Cerrado] from #cuad_50_50')



------------------------------------------------------------------------------
-- crear los .txt de cuadriculas de 50x50 para crear los kml
------------------------------------------------------------------------------

declare @directorio as varchar(256)='H:\CoberturaTxt\'--'F:\CoberturaTxt\' 'K:\CoberturaTxt\' -- directorio donde se guardan los txt para los kml

--Txt de cada frecuencia
------------------------
declare @cmd as varchar(8000)

------Exportamos todas las info por frecuancia a txt
----SET @cmd= 'plcc_aux_exportDetailColumnTableToFile ''lcc_cober2G_50x50_'+@ciudTable+''', Band, '''+@directorio+'Scan2G_Max_Ope_'+@provincia+'.txt'''
----exec (@cmd)


 
declare @op as varchar(256)
declare @id as int=1



--Operadores
select 
	identity (int, 1,1) id, 
	operator
into #bucle
from #cuad_50_50
where 
	operator is not null
group by 
	operator



--¿tiene sentido guardar una tabla por operador teniendo una tabla con toda la info?.. PDTE
while @id<=(select MAX(id) from #bucle) 
Begin 
		set @op=(select operator 
				from #bucle 
				where id=@id)
		
	  -- if OBJECT_ID('lcc_cober2G_50x50_KML_'+@ciudTable+'_'+@op+'') is not null  
		 --exec ('drop table lcc_cober2G_50x50_KML_'+@ciudTable+'_'+@op+'')
		 exec ('sp_lcc_dropifexists ''lcc_cober2G_50x50_KML_'+@ciudTable+'_'+@Report+'_'+@op+'_Cerrado''')
		--No es necesario agrupar pero se hace porque de esta forma el resultado final esta ordenado por lat/lon/banda
		--Haciendo order by no hace caso   
		set @cmd=
		'select 
			Latitud_50m as latitud,
			Longitud_50m as longitud,
			operator as Operador,
			Band as banda2G,
			max(frecuencia) as ''Bcch'',
			max(bsic) as ''Bsic'',
			master.dbo.fn_lcc_getParcel_lat (longitud_50m, latitud_50m) as lat_parcela,
			master.dbo.fn_lcc_getParcel_long (longitud_50m, latitud_50m) as long_parcela,
			master.dbo.fn_lcc_getParcel(longitud_50m, latitud_50m) as parcela,
			max(RSSI_Outdoor) as RSSI_Outdoor,
			max(RSSI_Indoor) as RSSI_Indoor,
			max(pcobInd) as Indoor_Coverage_Prob
		into [lcc_cober2G_50x50_KML_'+@ciudTable+'_'+@Report+'_'+@op+'_Cerrado]
		from #cuad_50_50 
		where operator='''+@op+'''
			and ind_ord = 1
		group by 
			Latitud_50m ,
			Longitud_50m ,
			operator ,
			Band,
			master.dbo.fn_lcc_getParcel_lat (longitud_50m, latitud_50m) ,
			master.dbo.fn_lcc_getParcel_long (longitud_50m, latitud_50m) ,
			master.dbo.fn_lcc_getParcel(longitud_50m, latitud_50m)
		'

		exec (@cmd)
		
		SET @cmd= 'sp_plcc_aux_exportTableToFile ''lcc_cober2G_50x50_KML_'+@ciudTable+'_'+@Report+'_'+@op+'_Cerrado'','''+@directorio+'Scan2G_Max_Ope_'+@ciudad+'_'+@op+'_Cerrado.txt'''
		exec (@cmd)
		set @id=@id+1
END

   

drop table	#cuad_50_50, #bucle


select 'TABLE: lcc_cober2G_50x50_'+@ciudad+' created Successfully' as result
