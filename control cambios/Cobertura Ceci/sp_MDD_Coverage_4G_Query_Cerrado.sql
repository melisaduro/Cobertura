--USE [master]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_4G_Query]    Script Date: 25/01/2018 18:40:35 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
--ALTER procedure [dbo].[sp_MDD_Coverage_4G_Query] (
--	-- Variables de entrada
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
	[operator] [varchar](255) NULL,
	[PCI] [int] NULL,
	[RSRP_Outdoor] [float] NULL,
	[RSRP_Indoor] [float] NULL,
	[RSRQ_max] [float] NULL,
	[CINR_max] [float] NULL,
	[PcobInd] [float] NULL,
	[ind_ord] [bigint] NULL,
	[band] [varchar] (255) NULL,
	[bandwidth] int null
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
declare @normalizacionBand800 as float=0     -- Sin simplificar sería +0.5
declare @normalizacionBand1800 as float=0 -- normalizando a banda 900:-3   -- Sin simplificar sería -2.8
declare @normalizacionBand2600 as float=0 -- normalizando a banda 900:-4   -- Sin simplificar sería -4.2
declare @normalizacionBand2100 as float=0 -- normalizando a banda 900:-3   -- Sin simplificar seía -3.3


--Valores maximos por earfcn en parcelas 50x50
IF @road = 0
begin
	insert into #cuad_50_50
	exec ('
	select 
		c.longitude as Longitud_50m,
		c.latitude as Latitud_50m,
		c.Channel as frecuencia,
		c.operator,
		c.PhCId as PCI,
		c.RSRP_median as RSRP_Outdoor,
		case when sof.Band = ''LTE1800'' then c.RSRP_median+'+@normalizacionBand1800+'                   --LTE1800
			 when sof.Band = ''LTE2600'' and c.Channel<4000 then RSRP_median+'+@normalizacionBand2600+'  --LTE2600
			 when sof.Band = ''LTE800'' then c.RSRP_median+'+@normalizacionBand800+'			        --LTE800	
			 when sof.Band = ''LTE2100'' then c.RSRP_median+'+@normalizacionBand2100+'				    --LTE2100
		end as RSRP_Indoor,
		c.RSRQ_median as RSRQ_max,
		c.CINR_median as CINR_max,
		c.PcobInd,
		c.operator_band_channel_ord as ind_ord,
		c.band,
		c.bandwidth

	from '+ @GridTable +' b,
		 lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord_Cerrado c
	 
		 LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof 
			on c.Channel=sof.Frequency

	where c.operator_band_channel_ord = 1
	and b.lonid=c.lonid and b.latid=c.latid
	and b.[entity_name] = '''+@ciudad+'''
	and b.[type] in (''Urban'', ''Indoor'')

	group by c.longitude, c.latitude, c.Channel, c.operator, c.PhCId, c.RSRP_median,
			case when sof.Band = ''LTE1800'' then c.RSRP_median+'+@normalizacionBand1800+'                   --LTE1800
			 when sof.Band = ''LTE2600'' and c.Channel<4000 then RSRP_median+'+@normalizacionBand2600+'  --LTE2600
			 when sof.Band = ''LTE800'' then c.RSRP_median+'+@normalizacionBand800+'				        --LTE800	
			 when sof.Band = ''LTE2100'' then c.RSRP_median+'+@normalizacionBand2100+'				    --LTE2100
			end,
			c.RSRQ_median, c.CINR_median, c.PcobInd, c.operator_band_channel_ord, c.band,
			c.bandwidth'
	)
end
else
begin

	insert into #cuad_50_50
	exec ('
	select 
		c.longitude as Longitud_50m,
		c.latitude as Latitud_50m,
		c.Channel as frecuencia,
		c.operator,
		c.PhCId as PCI,
		c.RSRP_median as RSRP_Outdoor,
		case when sof.Band = ''LTE1800'' then c.RSRP_median+'+@normalizacionBand1800+'                   --LTE1800
			 when sof.Band = ''LTE2600'' and c.Channel<4000 then RSRP_median+'+@normalizacionBand2600+'  --LTE2600
			 when sof.Band = ''LTE800'' then c.RSRP_median+'+@normalizacionBand800+'				        --LTE800	
			 when sof.Band = ''LTE2100'' then c.RSRP_median+'+@normalizacionBand2100+'				    --LTE2100
		end as RSRP_Indoor,
		c.RSRQ_median as RSRQ_max,
		c.CINR_median as CINR_max,
		c.PcobInd,
		c.operator_band_channel_ord as ind_ord,
		c.band,
		c.bandwidth

	from '+ @GridTable +' b,
		 lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord_Cerrado c
	 
		 LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof 
			on c.Channel=sof.Frequency

	where c.operator_band_channel_ord = 1
	and b.lonid=c.lonid and b.latid=c.latid
	and b.[entity_name] = '''+@ciudad+''' 
	and b.[type] in (''Road'', ''RW-Road'', ''RW'')

	group by c.longitude, c.latitude, c.Channel, c.operator, c.PhCId, c.RSRP_median,
			case when sof.Band = ''LTE1800'' then c.RSRP_median+'+@normalizacionBand1800+'                   --LTE1800
			 when sof.Band = ''LTE2600'' and c.Channel<4000 then RSRP_median+'+@normalizacionBand2600+'  --LTE2600
			 when sof.Band = ''LTE800'' then c.RSRP_median+'+@normalizacionBand800+'				        --LTE800	
			 when sof.Band = ''LTE2100'' then c.RSRP_median+'+@normalizacionBand2100+'				    --LTE2100
			end,
			c.RSRQ_median, c.CINR_median, c.PcobInd, c.operator_band_channel_ord, c.band,
			c.bandwidth'
	)
end


 ---------------------------------------------------------------------------------
 --Eliminamos las tablas ahora en lugar de al final para liberar espacio en tempdb
 ----------------------------------------------------------------------------------
 --drop table #allFreqs_allPCIS_50x50_order
 --drop table #allFreqs_allPCIS_50x50
 --drop table #t
 
  
------------------------------------------------------------------------------
-- guardar en una tabla por ciudad para que no se sobreescriban los datos
------------------------------------------------------------------------------
--Para las provincias con más de una palabra
declare @ciudTable as varchar(256)=replace(replace(@ciudad,' ','_'),'-','_')
  
--if OBJECT_ID('lcc_cober4G_50x50_'+@ciudTable) is not null  exec ('drop table lcc_cober4G_50x50_'+@ciudTable)
exec ('sp_lcc_dropifexists ''lcc_cober4G_50x50_'+@ciudTable+'_'+@Report+'_Cerrado''' )

exec (' select * into [lcc_cober4G_50x50_'+@ciudTable+'_'+@Report+'_Cerrado] from #cuad_50_50')



------------------------------------------------------------------------------
-- crear los .txt de cuadriculas de 50x50 para crear los kml
------------------------------------------------------------------------------

declare @directorio as varchar(256)='H:\CoberturaTxt\'--'F:\CoberturaTxt\' 'K:\CoberturaTxt\' -- directorio donde se guardan los txt para los kml

--Txt de cada frecuencia
------------------------
declare @cmd as varchar(8000)

--Exportamos todas las info por frecuancia a txt

SET @cmd= 'sp_plcc_aux_exportDetailColumnTableToFile ''lcc_cober4G_50x50_'+@ciudTable+'_'+@Report+'_Cerrado'', frecuencia, '''+@directorio+'Scan4G_Max_Ope_'+@ciudad+'_Cerrado.txt'''
exec (@cmd)


 
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
		
	  -- if OBJECT_ID('lcc_cober4G_50x50_KML_'+@ciudTable+'_'+@op+'') is not null  
		 --exec ('drop table lcc_cober4G_50x50_KML_'+@ciudTable+'_'+@op+'')
		 exec ('sp_lcc_dropifexists ''lcc_cober4G_50x50_KML_'+@ciudTable+'_'+@Report+'_'+@op+'_Cerrado''')
		--No es necesario agrupar pero se hace porque de esta forma el resultado final esta ordenado por lat/lon/banda
		--Haciendo order by no hace caso
		set @cmd=
		'select 
			Latitud_50m as latitud,
			Longitud_50m as longitud,
			operator as Operador,
			sof.Band as banda4G,
			max(frecuencia) as ''EARFCN'',
			max(PCI) as ''PCI'',
			master.dbo.fn_lcc_getParcel_lat (longitud_50m, latitud_50m) as lat_parcela,
			master.dbo.fn_lcc_getParcel_long (longitud_50m, latitud_50m) as long_parcela,
			master.dbo.fn_lcc_getParcel(longitud_50m, latitud_50m) as parcela,
			max(RSRP_Outdoor) as RSRP_Outdoor,
			max(RSRP_Indoor) as RSRP_Indoor,
			max(rsrq_max) as RSRQ,
			max(cinr_max) as CINR,
			max(pcobInd) as Indoor_Coverage_Prob,
			c.bandwidth
		into [lcc_cober4G_50x50_KML_'+@ciudTable+'_'+@Report+'_'+@op+'_Cerrado]
		from #cuad_50_50 c
			LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof 
				on c.frecuencia=sof.Frequency
		where operator='''+@op+''' 
			and c.ind_ord = 1
		group by 
			Latitud_50m ,
			Longitud_50m ,
			operator ,
			sof.Band,
			c.bandwidth,
			master.dbo.fn_lcc_getParcel_lat (longitud_50m, latitud_50m) ,
			master.dbo.fn_lcc_getParcel_long (longitud_50m, latitud_50m) ,
			master.dbo.fn_lcc_getParcel(longitud_50m, latitud_50m)
		'

		exec (@cmd)
		
		--SET @cmd= 'sp_plcc_aux_exportTableToFileOrder ''lcc_cober4G_50x50_KML_'+@ciudTable+'_'+@op+''','''+@directorio+'Scan4G_Max_Ope_'+@ciudad+'_'+@op+'.txt'',''1,2,4'''
		SET @cmd= 'sp_plcc_aux_exportTableToFile ''lcc_cober4G_50x50_KML_'+@ciudTable+'_'+@Report+'_'+@op+'_Cerrado'','''+@directorio+'Scan4G_Max_Ope_'+@ciudad+'_'+@op+'_Cerrado.txt'''
		exec (@cmd)
		--print @cmd
		set @id=@id+1
END

   

drop table	#cuad_50_50, #bucle


select 'TABLE: lcc_cober4G_50x50_'+@ciudad+' created Successfully' as result
