--USE [master]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_2G_Query]    Script Date: 03/10/2017 15:58:05 ******/
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

--use FY1718_VOICE_REST_4G_H1_27
--declare @ciudad as varchar(256) = 'SITGES'
--use FY1718_VOICE_REST_4G_H1_13
--declare @ciudad as varchar(256) = 'ALCORCON'
use FY1718_VOICE_VALENCIA_4G_H1
declare @ciudad as varchar(256) = 'VALENCIA'
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
	Set @GridTable = 'lcc_position_Entity_List_Municipio'
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
		lcc_GSMScanner_50x50_ProbCobIndoor_VALENCIA_NEW c
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
		lcc_GSMScanner_50x50_ProbCobIndoor_VALENCIA_NEW c
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
exec ('sp_lcc_dropifexists ''lcc_cober2G_50x50_'+@ciudTable+'_'+@Report+'_VALENCIA_NEW''' )

exec (' select * into [lcc_cober2G_50x50_'+@ciudTable+'_'+@Report+'_VALENCIA_NEW] from #cuad_50_50')



drop table	#cuad_50_50


select 'TABLE: lcc_cober2G_50x50_'+@ciudad+' created Successfully' as result
