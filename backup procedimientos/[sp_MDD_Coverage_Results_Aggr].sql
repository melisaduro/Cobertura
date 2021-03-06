USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_Results_Aggr]    Script Date: 25/05/2017 10:29:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_MDD_Coverage_Results_Aggr]
(
	@entity as varchar(256),
    @sheet as varchar(256),
    @operatorUmbrales as varchar(256),
	@Report as varchar (256),
	@simOperator as int,
	@monthYearDash as varchar(100),
	@weekDash as varchar(50),
	@aggrType as varchar(256)--,
	--@RoadOrange as bit
)
as

-----------------------------
----- Testing Variables -----
-----------------------------
--use[FY1617_Coverage_Union_H2]
--declare @entity as varchar(256) = 'ALCALALAREAL' 
--declare @sheet as varchar(256) = 'Samples_Outdoor'
--declare @operatorUmbrales as varchar(256) = 'Orange'
--declare @Report as varchar(256) = 'MUN'
--declare @simOperator as int = 3
--declare @monthYearDash as varchar(100)='mes'
--declare @weekDash as varchar(50)='semana'
--declare @aggrType as varchar(256) = 'GRID'
--declare @RoadOrange as bit = 1 -- O = False, 1 = True
-----------------------------
-----------------------------

declare @operator as varchar(256)
set @operator= case when @simOperator=3 then 'Orange'
				when @simOperator=7 then 'Movistar'
				when @simOperator=1 then 'Vodafone'
				when @simOperator=4 then 'Yoigo'
			end

declare @ciudTable as varchar(256)=replace(replace(@entity,' ','_'),'-','_')            
declare @2G as varchar (256) = 'lcc_cober2G_50x50_' + @ciudTable + '_' + @Report
declare @3G as varchar (256) = 'lcc_cober3G_50x50_' + @ciudTable + '_' + @Report
declare @4G as varchar (256) = 'lcc_cober4G_50x50_' + @ciudTable + '_' + @Report

declare @2GThres as varchar(10) ='-110'
declare @3GThres as varchar(10) ='-140'
declare @4GThres as varchar(10) ='-140'

declare @cmd as nvarchar(max)
declare @cmd1 as varchar(max)

--CAC 08/05/2017: identificamos las roads de Orange (bbdd de ROAD pero report-VDF o bbdd normal y report-ROAD)
declare @RoadOrange as bit
set @RoadOrange= case when (db_name() like '%ROAD%' and @Report <> 'VDF') or @Report='ROAD' then 1
				else 0
			end

-- Inicializamos los umbrales
if  (@sheet='Indoor' or @sheet='Samples_Indoor')
begin
	if @RoadOrange=0
	begin
		if @operatorUmbrales = 'Orange' 
		begin
			set @2GThres = '-65'
			set @3GThres = '-72'
			set @4GThres = '-90'
		end
		else if  @operatorUmbrales = 'Vodafone'
		begin
			set @2GThres = '-70'
			set @3GThres = '-80'
			set @4GThres = '-95'
		end		
	end
	else --CAC 08/05/2017: Umbrales de roads de Orange (antes tenían los mismos que el resto de scopes)
	begin
		set @2GThres = '-80'
		set @3GThres = '-85'
		set @4GThres = '-103'
	end
end
else if @sheet='Outdoor' or @sheet='Samples_Outdoor'
begin
	set @2GThres = '-90'
	set @3GThres = '-100'
	set @4GThres = '-113'
end
----------------------------------------------------------------------
------ Metemos en variables algunos campos calculados ----------------
----------------------------------------------------------------------
declare @ParmDefinition nvarchar(500)
declare @tableReport as varchar(50)

if @Report='VDF'
begin
	set @tableReport ='Vodafone'
end
if @Report='OSP'
begin
	set @tableReport ='Orange'
end
if @Report='MUN'
begin
	set @tableReport ='Municipio'
end
If @Report = 'ROAD'
begin
	Set @tableReport = 'Roads'
end

declare @bd as nvarchar(128) = db_name()
declare @mnc as nvarchar(128) = right ('00'+ convert(varchar,@simOperator),2)
declare @Meas_Round as varchar(256)

if left(right(db_name(),3),2) = '_H' --Si acaba en _HX, cogemos la info de la ronda (Tipo:FY1617_Coverage_Union_H2)
begin
	if (db_name() like '%AVE%' or db_name() like '%ROAD%') --Si las bbdd de cobertura son de AVEs y ROADs (Tipo: FY1617_Coverage_Union_AVE_H2)
	begin
		set @Meas_Round= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')
	end

	else
	begin
		set @Meas_Round= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(4, db_name(),'_')
	end
end
else
begin --Será ronda H1 (BBDD: FY1617_Coverage_Union)
	set @Meas_Round= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_H1'
end

declare @dateMax varchar(8)
SET @ParmDefinition = N'@dateMaxOut varchar(8) output' 
--set @cmd = 'select @dateMaxOut = max(MeasDate)
--	from dbo.lcc_position_Entity_List_'+@tableReport+'
--	where entity_name like ''%'+@entity+'%'''
set @cmd = 'select @dateMaxOut = max(MeasDate)
	from dbo.lcc_position_Entity_List_'+@tableReport+'
	where entity_name = '''+@entity+''''
print @cmd
exec sp_executesql @cmd,@ParmDefinition,@dateMaxOut = @dateMax output
--print @dateMax

declare @Meas_Date as varchar(256)= (select SUBSTRING(@dateMax,3,2) + '_'	 + SUBSTRING(@dateMax,5,2))

declare @entidad as varchar(256) = @entity

declare @week as varchar(256)
set @week = 'W' +convert(varchar,DATEPART(iso_week, @dateMax))


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Declaramos las tablas necesarias para calculos previos por operador/parcela:
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
declare @cober_2G_All_Samples  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[Samples] [int] NOT NULL
)
declare @cober_2G_BS_Number  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[BS_Number] [int] NOT NULL
)
declare @cober_2G_ProbCob  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[2G_PcobInd_Samples] [int] NULL,
	[2G_PcobInd] [float] NULL
)
declare @cober_2G_Nivel  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[2G_Nivel_Samples] [int] NULL,
	[2G_Nivel] [float] NULL,
	[2G_Nivel_Samples_Umbral] [int] NULL
)
declare @cober_2G_Nivel_Band  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[2G_Nivel_GSM_Samples] [int] NULL,
	[2G_Nivel_DCS_Samples] [int] NULL,
	[2G_Nivel_GSM] [float] NULL,
	[2G_Nivel_DCS] [float] NULL,
	[2G_Nivel_GSM_Samples_Umbral] [int] NULL,
	[2G_Nivel_DCS_Samples_Umbral] [int] NULL
)
declare @cober_2G_ProbCob_Band  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[2G_PcobInd_GSM_Samples] [int] NULL,
	[2G_PcobInd_DCS_Samples] [int] NULL,
	[2G_PcobInd_GSM] [float] NULL,
	[2G_PcobInd_DCS] [float] NULL
)
declare @cober_2G_ProbCob_Band_Both  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[2G_PcobInd_GSM_DCS_Samples] [int] NULL,
	[2G_PcobInd_GSM_DCS] [float] NULL
)
declare @cober_2G_Nivel_Band_Both  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[2G_Nivel_GSM_DCS_Samples_Umbral] [int] NULL
)
declare @cober_3G_All_Samples  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[Samples] [int] NOT NULL
)
declare @cober_3G_BS_Number  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[BS_Number] [int] NOT NULL
)
declare @cober_3G_ProbCob  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[3G_PcobInd_Samples] [int] NULL,
	[3G_PcobInd] [float] NULL
)
declare @cober_3G_ProbCob_Polluter as table(
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[3G_PcobInd_Polluter_BS] [int] NULL
)
declare @cober_3G_Nivel  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[3G_Nivel_Samples] [int] NULL,
	[3G_Nivel] [float] NULL,
	[3G_Nivel_Samples_Umbral] [int] NULL,
	[3G_Nivel_Polluter_BS] [int] NULL
)
declare @cober_3G_Nivel_Band  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[3G_Nivel_U2100_Samples] [int] NULL,
	[3G_Nivel_U900_Samples] [int] NULL,
	[3G_Nivel_U2100] [float] NULL,
	[3G_Nivel_U900] [float] NULL,
	[3G_Nivel_U2100_Samples_Umbral] [int] NULL,
	[3G_Nivel_U900_Samples_Umbral] [int] NULL,
	[3G_Nivel_U2100_Polluter_BS] [int] NULL,
	[3G_Nivel_U900_Polluter_BS] [int] NULL
)
declare @cober_3G_ProbCob_Band  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[3G_PcobInd_U2100_Samples] [int] NULL,
	[3G_PcobInd_U900_Samples] [int] NULL,
	[3G_PcobInd_U2100] [float] NULL,
	[3G_PcobInd_U900] [float] NULL,
	[3G_PcobInd_U2100_Polluter_BS] [int] NULL,
	[3G_PcobInd_U900_Polluter_BS] [int] NULL
)
declare @cober_3G_ProbCob_Carrier as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[3G_PcobInd_U2100_CarrierOnly_Samples] [int] NULL,
	[3G_PcobInd_U2100_F1_Samples] [int] NULL,
	[3G_PcobInd_U2100_F2_Samples] [int] NULL,
	[3G_PcobInd_U2100_F3_Samples] [int] NULL,
	[3G_PcobInd_U2100_DualCarrier_Samples] [int] NULL,
	[3G_PcobInd_U2100_F1_F2_Samples] [int] NULL,
	[3G_PcobInd_U2100_F1_F3_Samples] [int] NULL,
	[3G_PcobInd_U2100_F2_F3_Samples] [int] NULL,
	[3G_PcobInd_U2100_F1_F2_F3_Samples] [int] NULL,
	[3G_PcobInd_U900U2100_CarrierOnly_Samples] [int] NULL,
	[3G_PcobInd_U900U2100_F1_Samples] [int] NULL,
	[3G_PcobInd_U900U2100_F2_Samples] [int] NULL,
	[3G_PcobInd_U900U2100_F3_Samples] [int] NULL,
	[3G_PcobInd_U900U2100_DualCarrier_Samples] [int] NULL,
	[3G_PcobInd_U900U2100_F1_F2_Samples] [int] NULL,
	[3G_PcobInd_U900U2100_F1_F3_Samples] [int] NULL,
	[3G_PcobInd_U900U2100_F2_F3_Samples] [int] NULL,
	[3G_PcobInd_U900U2100_F1_F2_F3_Samples] [int] NULL,
	[3G_PcobInd_U2100_CarrierOnly] [float] NULL,
	[3G_PcobInd_U2100_F1] [float] NULL,
	[3G_PcobInd_U2100_F2] [float] NULL,
	[3G_PcobInd_U2100_F3] [float] NULL,
	[3G_PcobInd_U2100_DualCarrier] [float] NULL,
	[3G_PcobInd_U2100_F1_F2] [float] NULL,
	[3G_PcobInd_U2100_F1_F3] [float] NULL,
	[3G_PcobInd_U2100_F2_F3] [float] NULL,
	[3G_PcobInd_U2100_F1_F2_F3] [float] NULL,
	[3G_PcobInd_U900U2100_CarrierOnly] [float] NULL,
	[3G_PcobInd_U900U2100_F1] [float] NULL,
	[3G_PcobInd_U900U2100_F2] [float] NULL,
	[3G_PcobInd_U900U2100_F3] [float] NULL,
	[3G_PcobInd_U900U2100_DualCarrier] [float] NULL,
	[3G_PcobInd_U900U2100_F1_F2] [float] NULL,
	[3G_PcobInd_U900U2100_F1_F3] [float] NULL,
	[3G_PcobInd_U900U2100_F2_F3] [float] NULL,
	[3G_PcobInd_U900U2100_F1_F2_F3] [float] NULL
)
declare @cober_3G_Nivel_Carrier as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[3G_Nivel_U2100_CarrierOnly] [int] NULL,
	[3G_Nivel_U2100_F1] [int] NULL,
	[3G_Nivel_U2100_F2] [int] NULL,
	[3G_Nivel_U2100_F3] [int] NULL,
	[3G_Nivel_U2100_DualCarrier] [int] NULL,
	[3G_Nivel_U2100_F1_F2] [int] NULL,
	[3G_Nivel_U2100_F1_F3] [int] NULL,
	[3G_Nivel_U2100_F2_F3] [int] NULL,
	[3G_Nivel_U2100_F1_F2_F3] [int] NULL,
	[3G_Nivel_U900U2100_CarrierOnly] [int] NULL,
	[3G_Nivel_U900U2100_F1] [int] NULL,
	[3G_Nivel_U900U2100_F2] [int] NULL,
	[3G_Nivel_U900U2100_F3] [int] NULL,
	[3G_Nivel_U900U2100_DualCarrier] [int] NULL,
	[3G_Nivel_U900U2100_F1_F2] [int] NULL,
	[3G_Nivel_U900U2100_F1_F3] [int] NULL,
	[3G_Nivel_U900U2100_F2_F3] [int] NULL,
	[3G_Nivel_U900U2100_F1_F2_F3] [int] NULL
)
declare @cober_3G_Polluter_Max  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[3G_Polluter] [int] NULL
)
declare @cober_4G_All_Samples  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[Samples] [int] NOT NULL
)
declare @cober_4G_BS_Number  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[BS_Number] [int] NOT NULL
)
declare @cober_4G_ProbCob  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[4G_PcobInd_Samples] [int] NULL,
	[4G_PcobInd] [float] NULL
)
declare @cober_4G_Nivel  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[4G_Nivel_Samples] [int] NULL,
	[4G_Nivel] [float] NULL,
	[4G_Nivel_Samples_Umbral] [int] NULL
)
declare @cober_4G_Nivel_Band  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[4G_Nivel_L2600_Samples] [int] NULL,
	[4G_Nivel_L2100_Samples] [int] NULL,
	[4G_Nivel_L1800_Samples] [int] NULL,
	[4G_Nivel_L800_Samples] [int] NULL,
	[4G_Nivel_L2600] [float] NULL,
	[4G_Nivel_L2100] [float] NULL,
	[4G_Nivel_L1800] [float] NULL,
	[4G_Nivel_L800] [float] NULL,
	[4G_Nivel_L2600_Samples_Umbral] [int] NULL,
	[4G_Nivel_L2100_Samples_Umbral] [int] NULL,
	[4G_Nivel_L2100_BW5_Samples_Umbral] [int] NULL,
	[4G_Nivel_L2100_BW10_Samples_Umbral] [int] NULL,
	[4G_Nivel_L2100_BW15_Samples_Umbral] [int] NULL,
	[4G_Nivel_L1800_Samples_Umbral] [int] NULL,
	[4G_Nivel_L1800_BW10_Samples_Umbral] [int] NULL,
	[4G_Nivel_L1800_BW15_Samples_Umbral] [int] NULL,
	[4G_Nivel_L1800_BW20_Samples_Umbral] [int] NULL,
	[4G_Nivel_L800_Samples_Umbral] [int] NULL
)
declare @cober_4G_ProbCob_Band  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[4G_PcobInd_L800_Samples] [int] NULL,
	[4G_PcobInd_L1800_Samples] [int] NULL,
	[4G_PcobInd_L1800_BW10_Samples] [int] NULL,
	[4G_PcobInd_L1800_BW15_Samples] [int] NULL,
	[4G_PcobInd_L1800_BW20_Samples] [int] NULL,
	[4G_PcobInd_L2100_Samples] [int] NULL,
	[4G_PcobInd_L2100_BW5_Samples] [int] NULL,
	[4G_PcobInd_L2100_BW10_Samples] [int] NULL,
	[4G_PcobInd_L2100_BW15_Samples] [int] NULL,
	[4G_PcobInd_L2600_Samples] [int] NULL,	
	[4G_PcobInd_L800] [float] NULL,
	[4G_PcobInd_L1800] [float] NULL,
	[4G_PcobInd_L1800_BW10] [float] NULL,
	[4G_PcobInd_L1800_BW15] [float] NULL,
	[4G_PcobInd_L1800_BW20] [float] NULL,
	[4G_PcobInd_L2100] [float] NULL,
	[4G_PcobInd_L2100_BW5] [float] NULL,
	[4G_PcobInd_L2100_BW10] [float] NULL,
	[4G_PcobInd_L2100_BW15] [float] NULL,
	[4G_PcobInd_L2600] [float] NULL
)
declare @cober_4G_ProbCob_MixBand as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[4G_PcobInd_LTE800_1800_Samples] [int] NULL,
	[4G_PcobInd_LTE800_2100_Samples] [int] NULL,
	[4G_PcobInd_LTE800_2600_Samples] [int] NULL,
	[4G_PcobInd_LTE1800_2100_Samples] [int] NULL,
	[4G_PcobInd_LTE1800_2600_Samples] [int] NULL,
	[4G_PcobInd_LTE2100_2600_Samples] [int] NULL,
	[4G_PcobInd_LTE800_1800_2100_Samples] [int] NULL,
	[4G_PcobInd_LTE800_1800_2600_Samples] [int] NULL,
	[4G_PcobInd_LTE800_2100_2600_Samples] [int] NULL,
	[4G_PcobInd_LTE1800_2100_2600_Samples] [int] NULL,
	[4G_PcobInd_LTE800_1800] [float] NULL,
	[4G_PcobInd_LTE800_2100] [float] NULL,
	[4G_PcobInd_LTE800_2600] [float] NULL,
	[4G_PcobInd_LTE1800_2100] [float] NULL,
	[4G_PcobInd_LTE1800_2600] [float] NULL,
	[4G_PcobInd_LTE2100_2600] [float] NULL,
	[4G_PcobInd_LTE800_1800_2100] [float] NULL,
	[4G_PcobInd_LTE800_1800_2600] [float] NULL,
	[4G_PcobInd_LTE800_2100_2600] [float] NULL,
	[4G_PcobInd_LTE1800_2100_2600] [float] NULL
)
declare @cober_4G_Nivel_MixBand as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[4G_Nivel_LTE800_1800] [float] NULL,
	[4G_Nivel_LTE800_2100] [float] NULL,
	[4G_Nivel_LTE800_2600] [float] NULL,
	[4G_Nivel_LTE1800_2100] [float] NULL,
	[4G_Nivel_LTE1800_2600] [float] NULL,
	[4G_Nivel_LTE2100_2600] [float] NULL,
	[4G_Nivel_LTE800_1800_2100] [float] NULL,
	[4G_Nivel_LTE800_1800_2600] [float] NULL,
	[4G_Nivel_LTE800_2100_2600] [float] NULL,
	[4G_Nivel_LTE1800_2100_2600] [float] NULL
)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Cargamos las tablas previas:
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
print '@cober_2G_All_Samples'
insert into @cober_2G_All_Samples
exec('
select  '''+@operator+''' as operator,
	parcel,
	count(g.samples) as Samples
from
		(SELECT  1 as enlace,
				lp.nombre as parcel,
				count(1) as samples
								
			FROM '+@2G+' g,
					agrids.dbo.lcc_parcelas lp
			 
					where g.operator is not null
							and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
													
			group by  lp.nombre,g.longitud_50m, g.latitud_50m) g
group by parcel')

print '@cober_2G_BS_Number'
insert into @cober_2G_BS_Number
exec('
select  g.operator,
	g.parcel,		
	count (g.BSIC) as BS_Number
from
(
	select  g.parcel,
			g.operator,
			g.BSIC,
			g.frecuencia
	from
		(
		SELECT  
				lp.nombre as parcel,
				g.latitud_50m,
				g.longitud_50m,
				g.operator,
				g.BSIC,
				g.frecuencia,
				g.RSSI_Outdoor,
				g.pcobInd,
				row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator order by g.pcobInd desc,g.frecuencia desc,g.BSIC desc) as id
			FROM '+@2G+' g,
					agrids.dbo.lcc_parcelas lp
			 
					where g.operator='''+@operator+''' 
							and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											
		) g

	where g.id=1
	group by g.operator, g.BSIC, g.frecuencia,g.parcel --Agrupamos por bsic/frecuencia para contar el nº de pilotos distintos
) g
group by g.parcel, g.operator')

print '@cober_2G_ProbCob'
insert into @cober_2G_ProbCob
exec('
select  g.operator,
	g.parcel,		
	count(g.pcobind) as PcobInd_Samples,
	avg(g.pcobind) as PcobInd
from
		(
		SELECT  lp.nombre as parcel,
				g.latitud_50m,
				g.longitud_50m,
				g.operator,
				g.BSIC,
				g.frecuencia,
				g.band,
				g.RSSI_Outdoor,
				g.pcobInd,
				row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator order by g.pcobInd desc) as id
			FROM '+@2G+' g,
					agrids.dbo.lcc_parcelas lp
			 
					where g.operator='''+@operator+''' 
							and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											

		) g

where g.id=1 --Por parcela, operador nos quedamos con el BS de probabilidad de cobertura
group by g.parcel,g.operator')

print '@cober_2G_Nivel'
insert into @cober_2G_Nivel
exec('
select  g.operator,
	g.parcel,		
	count(g.RSSI_Outdoor) as RSSI_Outdoor_Samples,
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,g.RSSI_Outdoor))/10.0))) as RxLev_2G,
	sum(case when g.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as RSSI_Outdoor_Samples
from
	(
	SELECT  lp.nombre as parcel,
			g.latitud_50m,
			g.longitud_50m,
			g.operator,
			g.BSIC,
			g.frecuencia,
			g.band,
			g.RSSI_Outdoor,
			g.pcobInd,
			row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator order by g.RSSI_Outdoor desc) as id
		FROM '+@2G+' g,
				agrids.dbo.lcc_parcelas lp
			 
				where g.operator='''+@operator+''' 
						and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											

	) g
where g.id=1 --Por parcela 50x50, operador nos quedamos con el BS de nivel de señal
group by g.parcel, g.operator')

print '@cober_2G_Nivel_Band'
insert into @cober_2G_Nivel_Band
exec('
select g.operator,
	g.parcel,	
	sum(case when g.band in (''GSM'',''EGSM'') then 1 else 0 end) as RxLev_GSM_Samples,
	sum(case when g.band = ''DCS'' then 1 else 0 end) as RxLev_DCS_Samples,
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when g.band in (''GSM'', ''EGSM'') then g.RSSI_Outdoor end)))/10.0))) as RxLev_GSM,
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when g.band= ''DCS'' then g.RSSI_Outdoor end)))/10.0))) as RxLev_DCS,
	sum(case when g.band in (''GSM'', ''EGSM'') and G.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as GSM,
	sum(case when g.band = ''DCS'' and G.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as DCS
from
	(
	SELECT  lp.nombre as parcel,
			g.latitud_50m,
			g.longitud_50m,
			g.operator,
			g.BSIC,
			g.frecuencia,
			g.band,
			g.RSSI_Outdoor,
			g.pcobInd,
			row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator, g.band order by g.RSSI_Outdoor desc) as id
		FROM '+@2G+' g,
				agrids.dbo.lcc_parcelas lp
			 
				where g.operator='''+@operator+''' 
						and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											

	) g

where g.id=1 --Por parcela, operador y banda nos quedamos con el BS de nivel de señal
group by g.parcel,g.operator')

print '@cober_2G_ProbCob_Band'
insert into @cober_2G_ProbCob_Band
exec('
select  g.operator,
	g.parcel,	
	sum(case when g.band in (''GSM'',''EGSM'') and g.PcobInd is not null then 1 else 0 end) as GSM_Samples,
	sum(case when g.band = ''DCS'' and g.PcobInd is not null then 1 else 0 end) as DCS_Samples,
	avg(case when g.band in (''GSM'', ''EGSM'') then g.PcobInd end) as GSM,
	avg(case when g.band=''DCS'' then g.PcobInd end) as DCS

from
	(
	SELECT  lp.nombre as parcel,
			g.latitud_50m,
			g.longitud_50m,
			g.operator,
			g.BSIC,
			g.frecuencia,
			g.band,
			g.RSSI_Outdoor,
			g.pcobInd_Band as pcobInd,
			row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator, g.band order by g.pcobInd_Band desc) as id
		FROM '+@2G+' g,
				agrids.dbo.lcc_parcelas lp
			 
				where g.operator='''+@operator+''' 
						and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											

	) g
where g.id=1 --Por parcela, operador y banda nos quedamos con el BS de probabilidad de cobertura
group by g.parcel,g.operator')

print '@cober_2G_ProbCob_Band_Both'
insert into @cober_2G_ProbCob_Band_Both
exec('
select	
	operator,
	parcel,		
	sum(case when isnull(GSM_samples,0)+isnull(DCS_samples,0)= 2 then 1 end) as GSM_DCS_Samples,
	avg (case when isnull(GSM_samples,0)+isnull(DCS_samples,0)= 2 then GSM_DCS end) as GSM_DCS	
from	
(
	select  g.parcel,
		g.operator,						
		min(case when g.band in (''GSM'', ''EGSM'',''DCS'') then g.PcobInd end) as GSM_DCS,						
		min(case when g.band in (''GSM'', ''EGSM'') then 1 end) as GSM_samples,
		min(case when g.band in (''DCS'') then 1 end) as DCS_samples

	from
			(
			SELECT  lp.nombre as parcel,
					g.latitud_50m,
					g.longitud_50m,
					g.operator,
					g.BSIC,
					g.frecuencia,
					g.band,
					g.RSSI_Outdoor,
					g.pcobInd_Band as pcobInd,
					row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator, g.band order by g.pcobInd_Band desc) as id
				FROM '+@2G+' g,
						agrids.dbo.lcc_parcelas lp
			 
						where g.operator='''+@operator+''' 
								and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											

			) g
	where g.id=1 --Por parcela, operador y banda nos quedamos con el BS de probabilidad de cobertura
	group by g.parcel,g.operator,g.latitud_50m, g.longitud_50m	
) t
group by t.parcel,
		t.operator')

print '@cober_2G_Nivel_Band_Both'
insert into @cober_2G_Nivel_Band_Both
exec('
select	
	operator,
	parcel,		
	sum (case when isnull(GSM_samples,0)+isnull(DCS_samples,0)= 2 then GSM_DCS end) as GSM_DCS
from
	(
	select   g.parcel,
		g.operator,
		min(case when g.band in (''GSM'', ''EGSM'',''DCS'') and G.RSSI_Outdoor >= ' + @2GThres + ' then 1 else 0 end) as GSM_DCS,
		min(case when g.band in (''GSM'', ''EGSM'') then 1 end) as GSM_samples,
		min(case when g.band in (''DCS'') then 1 end) as DCS_samples
	from
		(
		SELECT  lp.nombre as parcel,
				g.latitud_50m,
				g.longitud_50m,
				g.operator,
				g.BSIC,
				g.frecuencia,
				g.band,
				g.RSSI_Outdoor,
				g.pcobInd,
				row_number () over (partition by g.latitud_50m,	g.longitud_50m, g.operator, g.band order by g.RSSI_Outdoor desc) as id
			FROM '+@2G+' g,
					agrids.dbo.lcc_parcelas lp
			 
					where g.operator='''+@operator+''' 
							and lp.nombre = master.dbo.fn_lcc_getParcel(g.longitud_50m, g.latitud_50m)
											

		) g

	where g.id=1 --Por parcela, operador y banda nos quedamos con el BS de nivel de señal
	group by g.parcel, g.operator,g.latitud_50m, g.longitud_50m	
	) t
group by t.parcel,
	t.operator')



print '@cober_3G_All_Samples'
insert into @cober_3G_All_Samples
exec('
select  '''+@operator+''' as operator,
		parcel,
		count(u.samples) as Samples
from
	(SELECT  1 as enlace,
		lp.nombre as parcel,
		count(1) as samples								
	FROM '+@3G+' u,
		agrids.dbo.lcc_parcelas lp			 
	where u.operator is not null
		and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)											
	group by lp.nombre, u.longitud_50m, u.latitud_50m
	) u							
group by parcel')

print '@cober_3G_BS_Number'
insert into @cober_3G_BS_Number
exec('
select  u.operator,
	u.parcel,	
	count (u.SC) as BS_Number
from
(
	select  u.parcel,
			u.operator,
			u.SC,
			u.frecuencia
	from
		(
		SELECT  lp.nombre as parcel,
				u.latitud_50m,
				u.longitud_50m,
				u.operator,
				u.SC,
				u.frecuencia,
				u.RSCP_Outdoor,
				row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.PcobInd desc,u.frecuencia desc,u.SC desc) as id
			FROM '+@3G+' u,
					agrids.dbo.lcc_parcelas lp
			 
					where u.operator='''+@operator+''' 
							and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
												
		) u
	where u.id=1
	group by u.parcel,u.operator, u.SC, u.frecuencia --Agrupamos por SC/frecuencia para contar el nº de pilotos distintos
) u
group by u.parcel,u.operator')

print '@cober_3G_ProbCob'
insert into @cober_3G_ProbCob
exec('
select  u.operator,
	u.parcel,	
	1.0*count(u.PcobInd) as PcobInd_Samples,
	avg(u.PcobInd) as PcobInd			
from
	(
	SELECT  lp.nombre as parcel,
			u.latitud_50m,
			u.longitud_50m,
			u.operator,
			u.SC,
			u.frecuencia,
			u.RSCP_Outdoor,
			u.band,
			u.PcobInd,
			u.Cuadricula_Polluter,
			row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.PcobInd desc, u.Cuadricula_Polluter desc) as id
		FROM '+@3G+' u,
				agrids.dbo.lcc_parcelas lp
			 
				where u.operator='''+@operator+''' 
						and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)										

	) u
where u.id=1 --Por parcela y operador nos quedamos con el BS de probabilidad de cobertura
group by u.parcel,
	u.operator')

print '@cober_3G_ProbCob_Polluter'
insert into @cober_3G_ProbCob_Polluter
exec('
select  u.operator,
	u.parcel,
	sum(u.Cuadricula_Polluter) as Cuadricula_Polluter_BS				
from
	(
	SELECT  lp.nombre as parcel,
			u.latitud_50m,
			u.longitud_50m,
			u.operator,
			u.SC,
			u.frecuencia,
			u.RSCP_Outdoor,
			u.band,
			u.PcobInd_Channel,
			u.Cuadricula_Polluter,
			row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.PcobInd_Channel desc, u.Cuadricula_Polluter desc) as id
		FROM '+@3G+' u,
				agrids.dbo.lcc_parcelas lp
			 
				where u.operator='''+@operator+''' 
						and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)										

	) u
where u.id=1 --Por parcela y operador nos quedamos con el BS de probabilidad de cobertura
group by u.parcel,
	u.operator')

print '@cober_3G_Nivel'
insert into @cober_3G_Nivel
exec('
select  u.operator,
	u.parcel,	
	count(u.RSCP_Outdoor) as RSCP_Outdoor_Samples,
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,u.RSCP_Outdoor))/10.0))) as RSCP_UMTS,	
	sum(case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) as RSCP_Outdoor_Samples,
	sum(u.Cuadricula_Polluter) as Cuadricula_Polluter_BS				
from
	(
	SELECT  lp.nombre as parcel,
			u.latitud_50m,
			u.longitud_50m,
			u.operator,
			u.SC,
			u.frecuencia,
			u.RSCP_Outdoor,
			u.band,
			u.PcobInd,
			u.Cuadricula_Polluter,
			row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator order by u.RSCP_Outdoor desc, u.Cuadricula_Polluter desc) as id
		FROM '+@3G+' u,
				agrids.dbo.lcc_parcelas lp
			 
				where u.operator='''+@operator+''' 
						and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
											

	) u
where u.id=1 --Por parcela y operador nos quedamos con el BS de nivel de señal
group by u.parcel,
	u.operator')

print '@cober_3G_Nivel_Band'
insert into @cober_3G_Nivel_Band
exec('
select  u.operator,
	u.parcel,	
	sum(case when u.band= ''UMTS2100'' then 1 else 0 end) as RSCP_UMTS2100_Samples,
	sum(case when u.band= ''UMTS900'' then 1 else 0 end) as RSCP_UMTS900_Samples,
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when u.band= ''UMTS2100'' then u.RSCP_Outdoor end)))/10.0))) as RSCP_UMTS2100,
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when u.band= ''UMTS900'' then u.RSCP_Outdoor end)))/10.0))) as RSCP_UMTS900,	
	sum(case when u.band= ''UMTS2100'' and u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) as UMTS2100,
	sum(case when u.band= ''UMTS900'' and u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) as UMTS900,
	sum(case when u.band= ''UMTS2100'' then u.Cuadricula_Polluter end) as Cuadricula_Polluter_BS_2100,
	sum(case when u.band= ''UMTS900'' then u.Cuadricula_Polluter end) as Cuadricula_Polluter_BS_900
from
		(
		SELECT  lp.nombre as parcel,
				u.latitud_50m,
				u.longitud_50m,
				u.operator,
				u.SC,
				u.frecuencia,
				u.RSCP_Outdoor,
				u.Cuadricula_Polluter,
				u.band,
				u.PcobInd,
				row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band order by u.RSCP_Outdoor desc, u.Cuadricula_Polluter desc) as id
			FROM '+@3G+' u,
					agrids.dbo.lcc_parcelas lp
			 
					where u.operator='''+@operator+''' 
							and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
											

		) u
where u.id=1 --Por parcela, operador y banda nos quedamos con el BS de nivel de señal
group by u.parcel,
	u.operator')

print '@cober_3G_ProbCob_Band'
insert into @cober_3G_ProbCob_Band
exec('
select  u.operator,
	u.parcel,	
	sum(case when u.band= ''UMTS2100'' and u.PcobInd is not null then 1 else 0 end) as UMTS2100_Samples,
	sum(case when u.band= ''UMTS900'' and u.PcobInd is not null then 1 else 0 end) as UMTS900_Samples,
	avg(case when u.band=''UMTS2100'' then u.PcobInd end) as UMTS2100,
	avg(case when u.band=''UMTS900'' then u.PcobInd end) as UMTS900,
	sum(case when u.band= ''UMTS2100'' then u.Cuadricula_Polluter end) as Cuadricula_Polluter_BS_2100,
	sum(case when u.band= ''UMTS900'' then u.Cuadricula_Polluter end) as Cuadricula_Polluter_BS_900
from
	(
	SELECT  lp.nombre as parcel,
			u.latitud_50m,
			u.longitud_50m,
			u.operator,
			u.SC,
			u.frecuencia,
			u.RSCP_Outdoor,
			u.band,
			u.Cuadricula_Polluter,
			u.pcobInd_Band as PcobInd,
			row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band order by u.pcobInd_Band desc, u.Cuadricula_Polluter desc) as id
		FROM '+@3G+' u,
				agrids.dbo.lcc_parcelas lp
			 
				where u.operator='''+@operator+''' 
						and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
											

	) u

where u.id=1 --Por parcela, operador y banda nos quedamos con el BS de probabilidad de cobertura
group by u.parcel,
	u.operator')

print '@cober_3G_ProbCob_Carrier'
insert into @cober_3G_ProbCob_Carrier
exec('
select
	operator,
	parcel,	
	--Solo una portadora
	sum(case when isnull(UMTS2100_F1_Samples_ConCober,0)+isnull(UMTS2100_F2_Samples_ConCober,0)+isnull(UMTS2100_F3_Samples_ConCober,0)= 1 then 1 else 0 end) as UMTS2100_Carrier_only_Samples,
	count(UMTS2100_F1) as UMTS2100_F1_Samples,
	count(UMTS2100_F2) as UMTS2100_F2_Samples,
	count(UMTS2100_F3) as UMTS2100_F3_Samples,
	--Solo dos portadoras
	sum(case when isnull(UMTS2100_F1_F2_Samples_ConCober,0) = 2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then 1
		when isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) = 2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then 1
		when isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)= 2 then 1
		else 0
	end) as UMTS2100_Dual_Carrier_Samples,
	sum(case when UMTS2100_F1_F2_Samples= 2 then 1 end) as UMTS2100_F1_F2_Samples,
	sum(case when UMTS2100_F1_F3_Samples= 2 then 1 end ) as UMTS2100_F1_F3_Samples,
	sum(case when UMTS2100_F2_F3_Samples= 2 then 1 end ) as UMTS2100_F2_F3_Samples,
	sum(case when UMTS2100_F1_F2_F3_Samples= 3 then 1 end ) as UMTS2100_F1_F2_F3_Samples,
	--Solo una portadora
	sum(case when  UMTS900_Samples_ConCober = 1 and isnull(UMTS2100_F1_Samples_ConCober,0)+isnull(UMTS2100_F2_Samples_ConCober,0)+isnull(UMTS2100_F3_Samples_ConCober,0)= 1 then 1 else 0 end) as UMTS900_U2100_Carrier_only_Samples,				
	sum(case when UMTS900_Samples+UMTS2100_F1_Samples= 2 then 1 end) as UMTS900_UMTS2100_F1_Samples,
	sum(case when UMTS900_Samples+UMTS2100_F2_Samples= 2 then 1 end ) as UMTS900_UMTS2100_F2_Samples,
	sum(case when UMTS900_Samples+UMTS2100_F3_Samples= 2 then 1 end ) as UMTS900_UMTS2100_F3_Samples,
	--Solo dos portadoras
	sum(case when UMTS900_Samples_ConCober = 1 and isnull(UMTS2100_F1_F2_Samples_ConCober,0) = 2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then 1
		when UMTS900_Samples_ConCober = 1 and isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) = 2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then 1
		when UMTS900_Samples_ConCober = 1 and isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)= 2 then 1
		else 0
	end) as UMTS900_U2100_Dual_Carrier_Samples,
	sum(case when UMTS900_Samples+UMTS2100_F1_F2_Samples= 3 then 1 end ) as UMTS900_UMTS2100_F1_F2_Samples,
	sum(case when UMTS900_Samples+UMTS2100_F1_F3_Samples= 3 then 1 end ) as UMTS900_UMTS2100_F1_F3_Samples,
	sum(case when UMTS900_Samples+UMTS2100_F2_F3_Samples= 3 then 1 end ) as UMTS900_UMTS2100_F2_F3_Samples,
	sum(case when UMTS900_Samples+UMTS2100_F1_F2_F3_Samples= 4 then 1 end ) as UMTS900_UMTS2100_F1_F2_F3_Samples,
	
	--Solo una portadora
	avg(case when isnull(UMTS2100_F1_Samples_ConCober,0)+isnull(UMTS2100_F2_Samples_ConCober,0)+isnull(UMTS2100_F3_Samples_ConCober,0)= 1 then 
		(case when UMTS2100_F1_ConCober is not null then UMTS2100_F1 
		when UMTS2100_F2_ConCober is not null then UMTS2100_F2
		when UMTS2100_F3_ConCober is not null then UMTS2100_F3
		end)
	end) as UMTS2100_Carrier_only,
	avg(UMTS2100_F1) as UMTS2100_F1,
	avg(UMTS2100_F2) as UMTS2100_F2,
	avg(UMTS2100_F3) as UMTS2100_F3,	
	--Solo dos portadoras
	avg(case when isnull(UMTS2100_F1_F2_Samples_ConCober,0) = 2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then UMTS2100_F1_F2
		when isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) = 2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then UMTS2100_F1_F3
		when isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)= 2 then UMTS2100_F2_F3
	end) as UMTS2100_Dual_Carrier,					
	avg(case when UMTS2100_F1_F2_Samples= 2 then UMTS2100_F1_F2 end) as UMTS2100_F1_F2,
	avg(case when UMTS2100_F1_F3_Samples= 2 then UMTS2100_F1_F3 end ) as UMTS2100_F1_F3,
	avg(case when UMTS2100_F2_F3_Samples= 2 then UMTS2100_F2_F3 end ) as UMTS2100_F2_F3,
	avg(case when UMTS2100_F1_F2_F3_Samples= 3 then UMTS2100_F1_F2_F3 end ) as UMTS2100_F1_F2_F3,

	--Solo una portadora
	avg(case when  UMTS900_Samples_ConCober = 1 and isnull(UMTS2100_F1_Samples_ConCober,0)+isnull(UMTS2100_F2_Samples_ConCober,0)+isnull(UMTS2100_F3_Samples_ConCober,0)= 1 then 
		(case when UMTS900_UMTS2100_F1_ConCober is not null then UMTS900_UMTS2100_F1_ConCober 
		when UMTS900_UMTS2100_F2_ConCober is not null then UMTS900_UMTS2100_F2_ConCober
		when UMTS900_UMTS2100_F3_ConCober is not null then UMTS900_UMTS2100_F3_ConCober
		end)
	end) as UMTS900_U2100_Carrier_only,
	avg(case when UMTS900_Samples+UMTS2100_F1_Samples= 2 then UMTS900_UMTS2100_F1 end) as UMTS900_UMTS2100_F1,
	avg(case when UMTS900_Samples+UMTS2100_F2_Samples= 2 then UMTS900_UMTS2100_F2 end ) as UMTS900_UMTS2100_F2,
	avg(case when UMTS900_Samples+UMTS2100_F3_Samples= 2 then UMTS900_UMTS2100_F3 end ) as UMTS900_UMTS2100_F3,	
	--Solo dos portadoras
	avg(case when UMTS900_Samples_ConCober = 1 and isnull(UMTS2100_F1_F2_Samples_ConCober,0) = 2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then UMTS900_UMTS2100_F1_F2_ConCober
		when UMTS900_Samples_ConCober = 1 and isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) = 2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)<2 then UMTS900_UMTS2100_F1_F3_ConCober
		when UMTS900_Samples_ConCober = 1 and isnull(UMTS2100_F1_F2_Samples_ConCober,0) <2 and isnull(UMTS2100_F1_F3_Samples_ConCober,0) <2 and isnull(UMTS2100_F2_F3_Samples_ConCober,0)= 2 then UMTS900_UMTS2100_F2_F3_ConCober
	end) as UMTS900_U2100_Dual_Carrier,
	avg(case when UMTS900_Samples+UMTS2100_F1_F2_Samples= 3 then UMTS900_UMTS2100_F1_F2 end ) as UMTS900_UMTS2100_F1_F2,
	avg(case when UMTS900_Samples+UMTS2100_F1_F3_Samples= 3 then UMTS900_UMTS2100_F1_F3 end ) as UMTS900_UMTS2100_F1_F3,
	avg(case when UMTS900_Samples+UMTS2100_F2_F3_Samples= 3 then UMTS900_UMTS2100_F2_F3 end ) as UMTS900_UMTS2100_F2_F3,
	avg(case when UMTS900_Samples+UMTS2100_F1_F2_F3_Samples= 4 then UMTS900_UMTS2100_F1_F2_F3 end ) as UMTS900_UMTS2100_F1_F2_F3
from
(
	select 
		u.parcel,
		u.operator, 					
		min(case when u.frecuencia in (10713, 10788, 10638, 10563) then u.PcobInd end) as UMTS2100_F1,
		min(case when u.frecuencia in (10738, 10813, 10663, 10588) then u.PcobInd end) as UMTS2100_F2,
		min(case when u.frecuencia in (10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS2100_F3,
		--Probablidad de cobertura minima en cada una de las combinaciones
		min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) then u.PcobInd end) as UMTS2100_F1_F2,
		min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS2100_F1_F3,
		min(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS2100_F2_F3,
		min(case when u.frecuencia in (10713, 10788, 10638, 10563,10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS2100_F1_F2_F3,
		min(case when u.band= ''UMTS900'' or u.frecuencia in (10713, 10788, 10638, 10563) then u.PcobInd end) as UMTS900_UMTS2100_F1,
		min(case when u.band= ''UMTS900'' or u.frecuencia in (10738, 10813, 10663, 10588) then u.PcobInd end) as UMTS900_UMTS2100_F2,
		min(case when u.band= ''UMTS900'' or u.frecuencia in (10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS900_UMTS2100_F3,
		min(case when u.band= ''UMTS900'' or u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) then u.PcobInd end) as UMTS900_UMTS2100_F1_F2,
		min(case when u.band= ''UMTS900'' or u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS900_UMTS2100_F1_F3,
		min(case when u.band= ''UMTS900'' or u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS900_UMTS2100_F2_F3,
		min(case when u.band= ''UMTS900'' or u.frecuencia in (10713, 10788, 10638, 10563,10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then u.PcobInd end) as UMTS900_UMTS2100_F1_F2_F3,
						
		sum(case when u.frecuencia in (10713, 10788, 10638, 10563) then 1 end) as UMTS2100_F1_Samples,
		sum(case when u.frecuencia in (10738, 10813, 10663, 10588) then 1 end) as UMTS2100_F2_Samples,
		sum(case when u.frecuencia in (10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F3_Samples,
		sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) then 1 end) as UMTS2100_F1_F2_Samples,
		sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F1_F3_Samples,
		sum(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F2_F3_Samples,
		sum(case when u.frecuencia in (10713, 10788, 10638, 10563,10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F1_F2_F3_Samples,
		min(case when u.band= ''UMTS900'' then 1 end) as UMTS900_Samples,


		min(case when u.frecuencia in (10713, 10788, 10638, 10563) and u.PcobInd>0 then u.PcobInd end) as UMTS2100_F1_ConCober,
		min(case when u.frecuencia in (10738, 10813, 10663, 10588) and u.PcobInd>0 then u.PcobInd end) as UMTS2100_F2_ConCober,
		min(case when u.frecuencia in (10763, 10838, 10688, 10613) and u.PcobInd>0 then u.PcobInd end) as UMTS2100_F3_ConCober,
		min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) and u.PcobInd>0 then u.PcobInd end) as UMTS2100_F1_F2_ConCober,
		min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) and u.PcobInd>0 then u.PcobInd end) as UMTS2100_F1_F3_ConCober,
		min(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) and u.PcobInd>0 then u.PcobInd end) as UMTS2100_F2_F3_ConCober,
		min(case when (u.band= ''UMTS900'' or u.frecuencia in (10713, 10788, 10638, 10563)) and u.PcobInd>0 then u.PcobInd end) as UMTS900_UMTS2100_F1_ConCober,
		min(case when (u.band= ''UMTS900'' or u.frecuencia in (10738, 10813, 10663, 10588)) and u.PcobInd>0 then u.PcobInd end) as UMTS900_UMTS2100_F2_ConCober,
		min(case when (u.band= ''UMTS900'' or u.frecuencia in (10763, 10838, 10688, 10613)) and u.PcobInd>0 then u.PcobInd end) as UMTS900_UMTS2100_F3_ConCober,
		min(case when (u.band= ''UMTS900'' or u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588)) and u.PcobInd>0 then u.PcobInd end) as UMTS900_UMTS2100_F1_F2_ConCober,
		min(case when (u.band= ''UMTS900'' or u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613)) and u.PcobInd>0 then u.PcobInd end) as UMTS900_UMTS2100_F1_F3_ConCober,
		min(case when (u.band= ''UMTS900'' or u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613)) and u.PcobInd>0 then u.PcobInd end) as UMTS900_UMTS2100_F2_F3_ConCober,

		sum(case when u.frecuencia in (10713, 10788, 10638, 10563) and u.PcobInd>0 then 1 end) as UMTS2100_F1_Samples_ConCober,
		sum(case when u.frecuencia in (10738, 10813, 10663, 10588) and u.PcobInd>0 then 1 end) as UMTS2100_F2_Samples_ConCober,
		sum(case when u.frecuencia in (10763, 10838, 10688, 10613) and u.PcobInd>0 then 1 end) as UMTS2100_F3_Samples_ConCober,
		sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) and u.PcobInd>0 then 1 end) as UMTS2100_F1_F2_Samples_ConCober,
		sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) and u.PcobInd>0 then 1 end) as UMTS2100_F1_F3_Samples_ConCober,
		sum(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) and u.PcobInd>0 then 1 end) as UMTS2100_F2_F3_Samples_ConCober,
		min(case when u.band= ''UMTS900'' and u.PcobInd>0 then 1 end) as UMTS900_Samples_ConCober
	from
		(

		SELECT  lp.nombre as parcel,
				u.latitud_50m,
				u.longitud_50m,
				u.operator,
				u.SC,
				u.frecuencia,
				u.RSCP_Outdoor,
				u.band,
				u.PcobInd_Channel as PcobInd,
				row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band,frecuencia  order by u.PcobInd_Channel desc) as id
			FROM '+@3G+' u,
					agrids.dbo.lcc_parcelas lp
			 
					where u.operator='''+@operator+''' 
							and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
											

		) u

	where u.id=1 --Por parcela, operador, banda y frecuencia nos quedamos con el BS de probabilidad de cobertura
	group by u.parcel,u.operator,u.latitud_50m,	u.longitud_50m
) t
group by t.parcel,
	t.operator')

print '@cober_3G_Nivel_Carrier'
insert into @cober_3G_Nivel_Carrier
exec('
select
	operator,
	parcel,	
	--Solo una portadora
	sum(case when isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)= 1 then 1 else 0 end) as UMTS2100_Carrier_only,
	sum(UMTS2100_F1) as UMTS2100_F1,
	sum(UMTS2100_F2) as UMTS2100_F2,
	sum(UMTS2100_F3) as UMTS2100_F3,
	--Solo dos portadoras
	sum(case when isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)= 2 then 1 else 0 end) as UMTS2100_Dual_Carrier,
	sum(case when UMTS2100_F1_F2_Samples= 2 then UMTS2100_F1_F2 end) as UMTS2100_F1_F2,
	sum(case when UMTS2100_F1_F3_Samples= 2 then UMTS2100_F1_F3 end ) as UMTS2100_F1_F3,
	sum(case when UMTS2100_F2_F3_Samples= 2 then UMTS2100_F2_F3 end ) as UMTS2100_F2_F3,
	sum(case when UMTS2100_F1_F2_F3_Samples= 3 then UMTS2100_F1_F2_F3 end ) as UMTS2100_F1_F2_F3,
	
	--U900 y solo una portadora
	sum(case when U900>0 and isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)=1
		then 1 else 0 end) as UMTS900_U2100_Carrier_only,
	sum(case when UMTS900_Samples+UMTS2100_F1_Samples= 2 and U900>0 and UMTS2100_F1>0 then 1 else 0 end) as UMTS900_U2100_F1,
	sum(case when UMTS900_Samples+UMTS2100_F2_Samples= 2 and U900>0 and UMTS2100_F2>0 then 1 else 0 end ) as UMTS900_U2100_F2,
	sum(case when UMTS900_Samples+UMTS2100_F3_Samples= 2 and U900>0 and UMTS2100_F3>0 then 1 else 0 end) as UMTS900_U2100_F3,
	--U900 y dos portadoras
	sum(case when U900>0 and isnull(UMTS2100_F1,0)+isnull(UMTS2100_F2,0)+isnull(UMTS2100_F3,0)=2
		then 1 else 0 end) as UMTS900_U2100_Dual_Carrier,
	sum(case when UMTS900_Samples+UMTS2100_F1_F2_Samples= 3 and U900>0 and UMTS2100_F1_F2>0 then 1 else 0 end) as UMTS900_U2100_F1_F2,
	sum(case when UMTS900_Samples+UMTS2100_F1_F3_Samples= 3 and U900>0 and UMTS2100_F1_F3>0 then 1 else 0 end) as UMTS900_U2100_F1_F3,
	sum(case when UMTS900_Samples+UMTS2100_F2_F3_Samples= 3 and U900>0 and UMTS2100_F2_F3>0 then 1 else 0 end) as UMTS900_U2100_F2_F3,
	sum(case when UMTS900_Samples+UMTS2100_F1_F2_F3_Samples= 4 and U900>0 and UMTS2100_F1_F2_F3>0 then 1 else 0 end) as UMTS900_U2100_F1_F2_F3	
from
	(
	select u.parcel,
		u.operator, 					
		min(case when u.frecuencia in (10713, 10788, 10638, 10563) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1,
		min(case when u.frecuencia in (10738, 10813, 10663, 10588) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F2,
		min(case when u.frecuencia in (10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F3,
		--Exista cobertura U2100 en las dos frecuencias de cada desglose
		min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1_F2,
		min(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1_F3,
		min(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F2_F3,
		min(case when u.frecuencia in (10713, 10788, 10638, 10563,10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as UMTS2100_F1_F2_F3,
		--Exista cobertura en alguna de frecuencias de UMTS900
		max(case when u.band= ''UMTS900'' then (case when u.RSCP_Outdoor >= ' + @3GThres + ' then 1 else 0 end) end) as U900,

		sum(case when u.frecuencia in (10713, 10788, 10638, 10563) then 1 end) as UMTS2100_F1_Samples,
		sum(case when u.frecuencia in (10738, 10813, 10663, 10588) then 1 end) as UMTS2100_F2_Samples,
		sum(case when u.frecuencia in (10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F3_Samples,
		sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10738, 10813, 10663, 10588) then 1 end) as UMTS2100_F1_F2_Samples,
		sum(case when u.frecuencia in (10713, 10788, 10638, 10563, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F1_F3_Samples,
		sum(case when u.frecuencia in (10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F2_F3_Samples,
		sum(case when u.frecuencia in (10713, 10788, 10638, 10563,10738, 10813, 10663, 10588, 10763, 10838, 10688, 10613) then 1 end) as UMTS2100_F1_F2_F3_Samples,
		min(case when u.band= ''UMTS900'' then 1 end) as UMTS900_Samples
	from 
		(
		SELECT  lp.nombre as parcel,
				u.latitud_50m,
				u.longitud_50m,
				u.operator,
				u.SC,
				u.frecuencia,
				u.band,
				u.RSCP_Outdoor,
				row_number () over (partition by u.latitud_50m,	u.longitud_50m, u.operator, u.band,frecuencia order by u.RSCP_Outdoor desc) as id
			FROM '+@3G+' u,
					agrids.dbo.lcc_parcelas lp
			 
					where u.operator='''+@operator+''' 
							and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)
										
		) u 
	where u.id=1 --Por parcela, operador, banda y frecuencia nos quedamos con el BS
	group by u.parcel,u.operator,u.latitud_50m,	u.longitud_50m	
	) t
group by t.parcel,
	t.operator')

print '@cober_3G_Polluter_Max'
insert into @cober_3G_Polluter_Max
exec('
select u.operator,
	u.parcel,	
	sum(u.Cuadricula_Polluter) as Cuadricula_Polluter
from
	(
	SELECT  lp.nombre as parcel,
			u.latitud_50m,
			u.longitud_50m,
			u.operator,
			max(u.Cuadricula_Polluter) as Cuadricula_Polluter
		FROM '+@3G+' u,
				agrids.dbo.lcc_parcelas lp			 
		where   u.operator='''+@operator+''' 
				and lp.nombre = master.dbo.fn_lcc_getParcel(u.longitud_50m, u.latitud_50m)								
		group by lp.nombre,u.latitud_50m,	u.longitud_50m, u.operator
	) u
group by u.parcel,
	u.operator')



print '@cober_4G_All_Samples'
insert into @cober_4G_All_Samples
exec('
select  '''+@operator+''' as operator,
	parcel,
	count(l.samples) as Samples
from
	(
	SELECT  1 as enlace,
			lp.nombre as parcel,
			count(1) as samples								
		FROM '+@4G+' l,
			agrids.dbo.lcc_parcelas lp			 
		where l.operator is not null
			and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
											
	group by lp.nombre, l.longitud_50m, l.latitud_50m
	) l
group by parcel')

print '@cober_4G_BS_Number'
insert into @cober_4G_BS_Number
exec('
select l.operator,
	l.parcel,	
	count (l.pci) as BS_Number
from
(
	select  l.parcel,
			l.operator,
			l.pci,
			l.frecuencia
	from
		(
		SELECT  lp.nombre as parcel,
				l.latitud_50m,
				l.longitud_50m,
				l.operator,
				l.pci,
				l.frecuencia,
				l.RSRP_Outdoor,
				row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.pCobInd desc,l.frecuencia desc,l.pci desc) as id
			FROM '+@4G+' l,
					agrids.dbo.lcc_parcelas lp
			 
					where l.operator='''+@operator+''' 
							and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)											
		) l

	where l.id=1
	group by l.parcel,l.operator, l.pci, l.frecuencia --Agrupamos por pci/frecuencia para contar el nº de pilotos distintos
) l

group by l.parcel,
	l.operator')

print '@cober_4G_ProbCob'
insert into @cober_4G_ProbCob
exec('
select l.operator,
	l.parcel,	
	1.0*count(l.PcobInd) as PcobInd_Samples,
	avg(l.pCobInd) as PcobInd
from
	(

	SELECT  lp.nombre as parcel,
			l.latitud_50m,
			l.longitud_50m,
			l.operator,
			l.pci,
			l.frecuencia,
			l.RSRP_Outdoor,
			l.band,
			l.PcobInd,
			row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.pCobInd desc) as id
		FROM '+@4G+' l,
			agrids.dbo.lcc_parcelas lp
			 
			where l.operator='''+@operator+''' 
				and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)								
	) l
where l.id=1 --Por parcela y operador nos quedamos con el BS de probabilidad de cobertura
group by l.parcel,
	l.operator')

print '@cober_4G_Nivel'
insert into @cober_4G_Nivel
exec('
select  l.operator,
	l.parcel,	
	count(l.RSRP_Outdoor) as RSRP_LTE_Samples,
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,l.RSRP_Outdoor))/10.0))) as RSRP_LTE,
	isnull(sum(case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end),0) as RSRP_Outdoor_Samples				
from
	(
	SELECT  lp.nombre as parcel,
			l.latitud_50m,
			l.longitud_50m,
			l.operator,
			l.pci,
			l.frecuencia,
			l.RSRP_Outdoor,
			l.band,
			l.PcobInd,
			row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.RSRP_Outdoor desc) as id
		FROM '+@4G+' l,
				agrids.dbo.lcc_parcelas lp
			 
				where l.operator='''+@operator+''' 
						and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
										

	) l

where l.id=1 --Por parcela y operador nos quedamos con el BS de nivel de señal
group by l.parcel,
	l.operator')

print '@cober_4G_Nivel_Band'
insert into @cober_4G_Nivel_Band
exec('
select l.operator,
	l.parcel,	
	sum(case when l.band =''LTE2600'' then 1 else 0 end) as RSRP_LTE2600_Samples,
	sum(case when l.band =''LTE2100'' then 1 else 0 end) as RSRP_LTE2100_Samples,
	sum(case when l.band =''LTE1800'' then 1 else 0 end) as RSRP_LTE1800_Samples,
	sum(case when l.band =''LTE800'' then 1 else 0 end) as RSRP_LTE800_Samples,	
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE2600'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE2600,
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE2100'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE2100,
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE1800'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE1800,
	10*log10(AVG(POWER(convert(float,10.0), (convert(float,(case when l.band= ''LTE800'' then l.RSRP_Outdoor end)))/10.0))) as RSRP_LTE800,
	sum(case when l.band= ''LTE2600'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2600,
	sum(case when l.band= ''LTE2100'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100,
	sum(case when (l.band= ''LTE2100'' and l.bandwidth=5) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100_BW5,
	sum(case when (l.band= ''LTE2100'' and l.bandwidth=10) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100_BW10,
	sum(case when (l.band= ''LTE2100'' and l.bandwidth=15) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE2100_BW15,
	sum(case when l.band= ''LTE1800'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800,
	sum(case when (l.band= ''LTE1800'' and l.bandwidth=10) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800_BW10,
	sum(case when (l.band= ''LTE1800'' and l.bandwidth=15) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800_BW15,
	sum(case when (l.band= ''LTE1800'' and l.bandwidth=20) and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE1800_BW20,
	sum(case when l.band= ''LTE800'' and l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) as LTE800

from
	(
	SELECT  lp.nombre as parcel,
			l.latitud_50m,
			l.longitud_50m,
			l.operator,
			l.pci,
			l.frecuencia,
			l.bandwidth,
			l.RSRP_Outdoor,
			l.band,
			l.PcobInd,
			row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator, l.band order by l.RSRP_Outdoor desc, l.bandwidth desc) as id
		FROM '+@4G+' l,
				agrids.dbo.lcc_parcelas lp			 
		where l.operator='''+@operator+''' 
				and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
	) l

where l.id=1 --Por parcela, operador y banda nos quedamos con el BS de nivel de señal
group by l.parcel,
	l.operator')

print '@cober_4G_ProbCob_Band'
insert into @cober_4G_ProbCob_Band
exec('
select  l.operator,
	l.parcel,	
	sum(case when l.band =''LTE800'' then 1 end) as LTE800_Samples,
	sum(case when l.band =''LTE1800'' then 1 end) as LTE1800_Samples,
	sum(case when l.band =''LTE1800'' and l.bandwidth = 10 then 1 end) as LTE1800_BW10_Samples,
	sum(case when l.band =''LTE1800'' and l.bandwidth = 15 then 1 end) as LTE1800_BW15_Samples,
	sum(case when l.band =''LTE1800'' and l.bandwidth = 20 then 1 end) as LTE1800_BW20_Samples,
	sum(case when l.band =''LTE2100'' then 1 end) as LTE2100_Samples,
	sum(case when l.band =''LTE2100'' and l.bandwidth = 5 then 1 end) as LTE2100_BW5_Samples,
	sum(case when l.band =''LTE2100'' and l.bandwidth = 10 then 1 end) as LTE2100_BW10_Samples,
	sum(case when l.band =''LTE2100'' and l.bandwidth = 15 then 1 end) as LTE2100_BW15_Samples,
	sum(case when l.band =''LTE2600'' then 1 end) as LTE2600_Samples,
	avg(case when l.band =''LTE800'' then l.pcobind end) as LTE800,
	avg(case when l.band =''LTE1800'' then l.pcobind end) as LTE1800,
	avg(case when l.band =''LTE1800'' and l.bandwidth = 10 then l.pcobind end) as LTE1800_BW10,
	avg(case when l.band =''LTE1800'' and l.bandwidth = 15 then l.pcobind end) as LTE1800_BW15,
	avg(case when l.band =''LTE1800'' and l.bandwidth = 20 then l.pcobind end) as LTE1800_BW20,
	avg(case when l.band =''LTE2100'' then l.pcobind end) as LTE2100,
	avg(case when l.band =''LTE2100'' and l.bandwidth = 5 then l.pcobind end) as LTE2100_BW5,
	avg(case when l.band =''LTE2100'' and l.bandwidth = 10 then l.pcobind end) as LTE2100_BW10,
	avg(case when l.band =''LTE2100'' and l.bandwidth = 15 then l.pcobind end) as LTE2100_BW15,
	avg(case when l.band =''LTE2600'' then l.pcobind end) as LTE2600
from
	(
	SELECT  lp.nombre as parcel,
			l.latitud_50m,
			l.longitud_50m,
			l.operator,
			l.pci,
			l.frecuencia,
			l.RSRP_Outdoor,
			l.band,
			l.bandwidth,
			l.PcobInd,
			row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator, l.band order by l.pCobInd desc, l.bandwidth desc) as id
		FROM '+@4G+' l,
				agrids.dbo.lcc_parcelas lp
			 
				where l.operator='''+@operator+''' 
						and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
										

	) l

where l.id=1 --Por parcela, operador y banda nos quedamos con el BS de probabilidad de cobertura
group by l.parcel,
	l.operator')

print '@cober_4G_ProbCob_MixBand'
insert into @cober_4G_ProbCob_MixBand
exec('
select
	operator,
	parcel,
	sum(case when LTE800_1800_samples= 2 then 1 end) as LTE800_1800_samples,
	sum(case when LTE800_2100_samples= 2 then 1 end ) as LTE800_2100_samples,
	sum(case when LTE800_2600_samples= 2 then 1 end ) as LTE800_2600_samples,
	sum(case when LTE1800_2100_samples= 2 then 1 end ) as LTE1800_2100_samples,
	sum(case when LTE1800_2600_samples= 2 then 1 end) as LTE1800_2600_samples,
	sum(case when LTE2100_2600_samples= 2 then 1 end ) as LTE2100_2600_samples,
	sum(case when LTE800_1800_2100_samples= 3 then 1 end ) as LTE800_1800_2100_samples,
	sum(case when LTE800_1800_2600_samples= 3 then 1 end ) as LTE800_1800_2600_samples,
	sum(case when LTE800_2100_2600_samples= 3 then 1 end ) as LTE800_2100_2600_samples,
	sum(case when LTE1800_2100_2600_samples= 3 then 1 end ) as LTE1800_2100_2600_samples,
					
	avg(case when LTE800_1800_samples= 2 then LTE800_1800 end) as LTE800_1800,
	avg(case when LTE800_2100_samples= 2 then LTE800_2100 end ) as LTE800_2100,
	avg(case when LTE800_2600_samples= 2 then LTE800_2600 end ) as LTE800_2600,
	avg(case when LTE1800_2100_samples= 2 then LTE1800_2100 end ) as LTE1800_2100,
	avg(case when LTE1800_2600_samples= 2 then LTE1800_2600 end) as LTE1800_2600,
	avg(case when LTE2100_2600_samples= 2 then LTE2100_2600 end ) as LTE2100_2600,
	avg(case when LTE800_1800_2100_samples= 3 then LTE800_1800_2100 end ) as LTE800_1800_2100,
	avg(case when LTE800_1800_2600_samples= 3 then LTE800_1800_2600 end ) as LTE800_1800_2600,
	avg(case when LTE800_2100_2600_samples= 3 then LTE800_2100_2600 end ) as LTE800_2100_2600,
	avg(case when LTE1800_2100_2600_samples= 3 then LTE1800_2100_2600 end ) as LTE1800_2100_2600

from
(
	select l.parcel,
		l.operator, 					
		min(case when l.band in (''LTE800'', ''LTE1800'') then l.PcobInd end) as LTE800_1800,
		min(case when l.band in (''LTE800'', ''LTE2100'') then l.PcobInd end) as LTE800_2100,
		min(case when l.band in (''LTE800'', ''LTE2600'') then l.PcobInd end) as LTE800_2600,
		min(case when l.band in (''LTE1800'', ''LTE2100'') then l.PcobInd end) as LTE1800_2100,
		min(case when l.band in (''LTE1800'', ''LTE2600'') then l.PcobInd end) as LTE1800_2600,
		min(case when l.band in (''LTE2100'', ''LTE2600'') then l.PcobInd end) as LTE2100_2600,
		min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then l.PcobInd end) as LTE800_1800_2100,
		min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then l.PcobInd end) as LTE800_1800_2600,
		min(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then l.PcobInd end) as LTE800_2100_2600,
		min(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then l.PcobInd end) as LTE1800_2100_2600,
						
		sum(case when l.band in (''LTE800'', ''LTE1800'') then 1 end) as LTE800_1800_samples,
		sum(case when l.band in (''LTE800'', ''LTE2100'') then 1 end) as LTE800_2100_samples,
		sum(case when l.band in (''LTE800'', ''LTE2600'') then 1 end) as LTE800_2600_samples,
		sum(case when l.band in (''LTE1800'', ''LTE2100'') then 1 end) as LTE1800_2100_samples,
		sum(case when l.band in (''LTE1800'', ''LTE2600'') then 1 end) as LTE1800_2600_samples,
		sum(case when l.band in (''LTE2100'', ''LTE2600'') then 1 end) as LTE2100_2600_samples,
		sum(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then 1 end) as LTE800_1800_2100_samples,
		sum(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then 1 end) as LTE800_1800_2600_samples,
		sum(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then 1 end) as LTE800_2100_2600_samples,
		sum(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then 1 end) as LTE1800_2100_2600_samples

	from
		(
		SELECT  lp.nombre as parcel,
				l.latitud_50m,
				l.longitud_50m,
				l.operator,
				l.pci,
				l.frecuencia,
				l.RSRP_Outdoor,
				l.band,
				l.PcobInd,
				row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator, l.band order by l.pCobInd desc) as id
			FROM '+@4G+' l,
					agrids.dbo.lcc_parcelas lp			 
			where l.operator='''+@operator+''' 
					and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)
		) l

	where l.id=1 --Por parcela, operador y banda nos quedamos con el BS de probabilidad de cobertura
	group by l.parcel, l.operator,l.latitud_50m,	l.longitud_50m
) t
group by t.parcel,
	t.operator')

print '@cober_4G_Nivel_MixBand'
insert into @cober_4G_Nivel_MixBand
exec('
select
	operator,
	parcel,	
	sum(case when LTE800_1800_samples= 2 then LTE800_1800 end) as LTE800_1800,
	sum(case when LTE800_2100_samples= 2 then LTE800_2100 end ) as LTE800_2100,
	sum(case when LTE800_2600_samples= 2 then LTE800_2600 end ) as LTE800_2600,
	sum(case when LTE1800_2100_samples= 2 then LTE1800_2100 end ) as LTE1800_2100,
	sum(case when LTE1800_2600_samples= 2 then LTE1800_2600 end) as LTE1800_2600,
	sum(case when LTE2100_2600_samples= 2 then LTE2100_2600 end ) as LTE2100_2600,
	sum(case when LTE800_1800_2100_samples= 3 then LTE800_1800_2100 end ) as LTE800_1800_2100,
	sum(case when LTE800_1800_2600_samples= 3 then LTE800_1800_2600 end ) as LTE800_1800_2600,
	sum(case when LTE800_2100_2600_samples= 3 then LTE800_2100_2600 end ) as LTE800_2100_2600,
	sum(case when LTE1800_2100_2600_samples= 3 then LTE1800_2100_2600 end ) as LTE1800_2100_2600
	from
	(
	select 
			l.parcel,
			l.operator,					
			min(case when l.band in (''LTE800'', ''LTE1800'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_1800,
			min(case when l.band in (''LTE800'', ''LTE2100'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_2100,
			min(case when l.band in (''LTE800'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_2600,
			min(case when l.band in (''LTE1800'', ''LTE2100'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE1800_2100,
			min(case when l.band in (''LTE1800'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE1800_2600,
			min(case when l.band in (''LTE2100'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE2100_2600,
			min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_1800_2100,
			min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_1800_2600,
			min(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE800_2100_2600,
			min(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then (case when l.RSRP_Outdoor >= ' + @4GThres + ' then 1 else 0 end) end) as LTE1800_2100_2600,
			sum(case when l.band in (''LTE800'', ''LTE1800'') then 1 end) as LTE800_1800_samples,
			sum(case when l.band in (''LTE800'', ''LTE2100'') then 1 end) as LTE800_2100_samples,
			sum(case when l.band in (''LTE800'', ''LTE2600'') then 1 end) as LTE800_2600_samples,
			sum(case when l.band in (''LTE1800'', ''LTE2100'') then 1 end) as LTE1800_2100_samples,
			sum(case when l.band in (''LTE1800'', ''LTE2600'') then 1 end) as LTE1800_2600_samples,
			sum(case when l.band in (''LTE2100'', ''LTE2600'') then 1 end) as LTE2100_2600_samples,
			sum(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then 1 end) as LTE800_1800_2100_samples,
			sum(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then 1 end) as LTE800_1800_2600_samples,
			sum(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then 1 end) as LTE800_2100_2600_samples,
			sum(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then 1 end) as LTE1800_2100_2600_samples
	from 
	(
	SELECT  lp.nombre as parcel,
			l.latitud_50m,
			l.longitud_50m,
			l.operator,
			l.pci,
			l.frecuencia,
			l.band,
			l.bandwidth,
			l.RSRP_Outdoor,
			row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator,l.band order by l.RSRP_Outdoor desc, l.bandwidth desc) as id
		FROM '+@4G+' l,
				agrids.dbo.lcc_parcelas lp			 
		where l.operator='''+@operator+''' 
				and lp.nombre = master.dbo.fn_lcc_getParcel(l.longitud_50m, l.latitud_50m)									
	) l
	where l.id=1 --Por parcela, operador y banda nos quedamos con el BS
	group by l.parcel,l.operator,l.latitud_50m,	l.longitud_50m	
	) t
group by t.parcel,
	t.operator')




-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Calculo final:
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


-- Seleccionamos por el tipo de hoja para mostrar los resultados
if @sheet = 'Curves'
begin

	select
		 @bd  as [Database]
		, @mnc  as mnc
		, 'ALL' as [carrier]
		, NULL as [band],  
		all_parcel.parcel,
		isnull(l_Nivel.[4G_Nivel],-140) as RSRP_LTE,
		isnull(l_Nivel_Band.[4G_Nivel_L2600],-140) as RSRP_LTE2600,
		isnull(l_Nivel_Band.[4G_Nivel_L2100],-140) as RSRP_LTE2100,
		isnull(l_Nivel_Band.[4G_Nivel_L1800],-140) as RSRP_LTE1800,
		isnull(l_Nivel_Band.[4G_Nivel_L800],-140) as RSRP_LTE800,
		isnull(l_all.[Samples],0) as [4G_All_Samples],
		isnull(l_Nivel.[4G_Nivel_Samples],0) as RSRP_LTE_Samples,
		isnull(l_Nivel_Band.[4G_Nivel_L2600_Samples],0) as RSRP_LTE2600_Samples,
		isnull(l_Nivel_Band.[4G_Nivel_L2100_Samples],0) as RSRP_LTE2100_Samples,
		isnull(l_Nivel_Band.[4G_Nivel_L1800_Samples],0) as RSRP_LTE1800_Samples,
		isnull(l_Nivel_Band.[4G_Nivel_L800_Samples],0) as RSRP_LTE800_Samples,

		isnull(l_ProbCob.[4G_PcobInd],0) as LTE,
		isnull(l_ProbCob_Band.[4G_PcobInd_L2600],0) as LTE2600,
		isnull(l_ProbCob_Band.[4G_PcobInd_L2100],0) as LTE2100,
		isnull(l_ProbCob_Band.[4G_PcobInd_L2100_BW5],0) as LTE2100_BW5,
		isnull(l_ProbCob_Band.[4G_PcobInd_L2100_BW10],0) as LTE2100_BW10,
		isnull(l_ProbCob_Band.[4G_PcobInd_L2100_BW15],0) as LTE2100_BW15,
		isnull(l_ProbCob_Band.[4G_PcobInd_L1800],0) as LTE1800,
		isnull(l_ProbCob_Band.[4G_PcobInd_L1800_BW10],0) as LTE1800_BW10,
		isnull(l_ProbCob_Band.[4G_PcobInd_L1800_BW15],0) as LTE1800_BW15,
		isnull(l_ProbCob_Band.[4G_PcobInd_L1800_BW20],0) as LTE1800_BW20,
		isnull(l_ProbCob_Band.[4G_PcobInd_L800],0) as LTE800,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_1800],0) as LTE800_1800,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_2100],0) as LTE800_2100,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_2600],0) as LTE800_2600,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE1800_2100],0) as LTE1800_2100,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE1800_2600],0) as LTE1800_2600,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE2100_2600],0) as LTE2100_2600,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_1800_2100],0) as LTE800_1800_2100,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_1800_2600],0) as LTE800_1800_2600,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_2100_2600],0) as LTE800_2100_2600,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE1800_2100_2600],0) as LTE1800_2100_2600,

		isnull(l_ProbCob.[4G_PcobInd_Samples],0) as LTE_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_L2600_Samples],0) as LTE2600_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_L2100_Samples],0) as LTE2100_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_L2100_BW5_Samples],0) as LTE2100_BW5_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_L2100_BW10_Samples],0) as LTE2100_BW10_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_L2100_BW15_Samples],0) as LTE2100_BW15_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_L1800_Samples],0) as LTE1800_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_L1800_BW10_Samples],0) as LTE1800_BW10_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_L1800_BW15_Samples],0) as LTE1800_BW15_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_L1800_BW20_Samples],0) as LTE1800_BW20_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_L800_Samples],0) as LTE800_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_1800_Samples],0) as LTE800_1800_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_2100_Samples],0) as LTE800_2100_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_2600_Samples],0) as LTE800_2600_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE1800_2100_Samples],0) as LTE1800_2100_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE1800_2600_Samples],0) as LTE1800_2600_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE2100_2600_Samples],0) as LTE2100_2600_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_1800_2100_Samples],0) as LTE800_1800_2100_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_1800_2600_Samples],0) as LTE800_1800_2600_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE800_2100_2600_Samples],0) as LTE800_2100_2600_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_LTE1800_2100_2600_Samples],0) as LTE1800_2100_2600_Samples,
		isnull(l_BS.[BS_Number],0) as BS_LTE,
			
			
		isnull(u_Nivel.[3G_Nivel],-140) as RSCP_UMTS,
		isnull(u_Nivel_Band.[3G_Nivel_U2100],-140) as RSCP_UMTS2100,
		isnull(u_Nivel_Band.[3G_Nivel_U900],-140) as RSCP_UMTS900,
		isnull(u_Polluter.[3G_Polluter],0) as [Pollution],
		isnull(u_ProbCob_Pollut.[3G_PcobInd_Polluter_BS],0) as [Pollution BS Curves],
		isnull(u_Nivel.[3G_Nivel_Polluter_BS],0) as [Pollution BS RSCP],
		isnull(u_all.[Samples],0) as [3G_All_Samples],
		isnull(u_Nivel.[3G_Nivel_Samples],0) as RSCP_UMTS_Samples,
		isnull(u_Nivel_Band.[3G_Nivel_U2100_Samples],0) as RSCP_UMTS2100_Samples,
		isnull(u_Nivel_Band.[3G_Nivel_U900_Samples],0) as RSCP_UMTS900_Samples,


		isnull(u_Nivel_Band.[3G_Nivel_U2100_Polluter_BS],0) as [Pollution BS RSCP U2100],
		isnull(u_Nivel_Band.[3G_Nivel_U900_Polluter_BS],0) as [Pollution BS RSCP U900],
		isnull(u_ProbCob_Band.[3G_PcobInd_U2100_Polluter_BS],0) as [Pollution BS Curves U2100],
		isnull(u_ProbCob_Band.[3G_PcobInd_U900_Polluter_BS],0) as [Pollution BS Curves U900],

		isnull(u_ProbCob.[3G_PcobInd],0) as UMTS,
		isnull(u_ProbCob_Band.[3G_PcobInd_U2100],0) as UMTS2100,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_CarrierOnly],0) as UMTS2100_Carrier_only,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F1],0) as UMTS2100_F1,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F2],0) as UMTS2100_F2,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F3],0) as UMTS2100_F3,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_DualCarrier],0) as UMTS2100_Dual_Carrier,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F1_F2],0) as UMTS2100_F1_F2,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F1_F3],0) as UMTS2100_F1_F3,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F2_F3],0) as UMTS2100_F2_F3,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F1_F2_F3],0) as UMTS2100_F1_F2_F3,
		isnull(u_ProbCob_Band.[3G_PcobInd_U900],0) as UMTS900,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_CarrierOnly],0) as UMTS900_U2100_Carrier_only,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F1],0) as UMTS900_U2100_F1,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F2],0) as UMTS900_U2100_F2,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F3],0) as UMTS900_U2100_F3,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_DualCarrier],0) as UMTS900_U2100_Dual_Carrier,		
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F1_F2],0) as UMTS900_U2100_F1_F2,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F1_F3],0) as UMTS900_U2100_F1_F3,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F2_F3],0) as UMTS900_U2100_F2_F3,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F1_F2_F3],0) as UMTS900_U2100_F1_F2_F3,

		isnull(u_ProbCob.[3G_PcobInd_Samples],0) as UMTS_Samples,
		isnull(u_ProbCob_Band.[3G_PcobInd_U2100_Samples],0) as UMTS2100_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_CarrierOnly_Samples],0) as UMTS2100_Carrier_only_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F1_Samples],0) as UMTS2100_F1_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F2_Samples],0) as UMTS2100_F2_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F3_Samples],0) as UMTS2100_F3_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_DualCarrier_Samples],0) as UMTS2100_Dual_Carrier_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F1_F2_Samples],0) as UMTS2100_F1_F2_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F1_F3_Samples],0) as UMTS2100_F1_F3_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F2_F3_Samples],0) as UMTS2100_F2_F3_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U2100_F1_F2_F3_Samples],0) as UMTS2100_F1_F2_F3_Samples,
		isnull(u_ProbCob_Band.[3G_PcobInd_U900_Samples],0) as UMTS900_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_CarrierOnly_Samples],0) as UMTS900_U2100_Carrier_only_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F1_Samples],0) as UMTS900_U2100_F1_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F2_Samples],0) as UMTS900_U2100_F2_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F3_Samples],0) as UMTS900_U2100_F3_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_DualCarrier_Samples],0) as UMTS900_U2100_Dual_Carrier_Samples,		
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F1_F2_Samples],0) as UMTS900_U2100_F1_F2_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F1_F3_Samples],0) as UMTS900_U2100_F1_F3_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F2_F3_Samples],0) as UMTS900_U2100_F2_F3_Samples,
		isnull(u_ProbCob_Carrier.[3G_PcobInd_U900U2100_F1_F2_F3_Samples],0) as UMTS900_U2100_F1_F2_F3_Samples,
		isnull(u_BS.[BS_Number],0) as BS_UMTS,

		isnull(g_Nivel.[2G_Nivel],-110) as RxLev_2G,
		isnull(g_Nivel_Band.[2G_Nivel_GSM],-110) as RxLev_GSM,
		isnull(g_Nivel_Band.[2G_Nivel_DCS],-110) as RxLev_DCS,
		isnull(g_all.[Samples],0) as [2G_All_Samples],
		isnull(g_Nivel.[2G_Nivel_Samples],0) as RxLev_2G_Samples,
		isnull(g_Nivel_Band.[2G_Nivel_GSM_Samples],0) as RxLev_GSM_Samples,
		isnull(g_Nivel_Band.[2G_Nivel_DCS_Samples],0) as RxLev_DCS_Samples,

		isnull(g_ProbCob.[2G_PcobInd],0) as [2G],
		isnull(g_ProbCob_Band.[2G_PcobInd_GSM],0) as GSM,
		isnull(g_ProbCob_Band.[2G_PcobInd_DCS],0) as DCS,
		isnull(g_ProbCob_BandBoth.[2G_PcobInd_GSM_DCS],0) as GSM_DCS,
		isnull(g_ProbCob.[2G_PcobInd_Samples],0) as [2G_Samples],
		isnull(g_ProbCob_Band.[2G_PcobInd_GSM_Samples],0) as GSM_Samples,
		isnull(g_ProbCob_Band.[2G_PcobInd_DCS_Samples],0) as DCS_Samples,
		isnull(g_ProbCob_BandBoth.[2G_PcobInd_GSM_DCS_Samples],0) as GSM_DCS_Samples,
		isnull(g_BS.[BS_Number],0) as BS_GSM

		,[Region_VF]
		,[Provincia]
		,[Condado]
		,[Turistico]
		,[Entorno]
		,[Vendor_VF]
		,[Suministrador_VF]
		,[Sum_VF_Y_PINZA]
		,[Vendor_2G_MV]
		,[Vendor_3G_MV]
		,[Vendor_OR]
		,[Suministrador_OR]
		,[CodINE]
		,[Ciudad]
		,[Poblacion]
		,[Rango_Pob_Zona]
		,[Rango_Pob]
		,[Zona]
		,[Pob_Urbano]
		,[AVE]
		,[Carretera]
		,[Carretera_P3]
		,[Ciudad_P3]
		,[Entorno_P3]
		, @week as Meas_Week
		, @Meas_Round as [Meas_Round]
		, @Meas_Date as [Meas_Date]
		, @entidad as Entidad
		, NULL as [Num_Medida]
		, @monthYearDash as monthYearDash
		, @weekDash as weekDash
		, @Report as [Report_Type]
		, @aggrType as [Aggr_Type]
		, [Region_OSP]
	from
		(
			select parcel, operator from @cober_2G_All_Samples group by parcel,operator
			union
			select parcel, operator from @cober_3G_All_Samples group by parcel, operator
			union
			select parcel, operator from @cober_4G_All_Samples group by parcel, operator
		) all_parcel
		left join @cober_2G_All_Samples g_all
			on all_parcel.parcel = g_all.parcel and all_parcel.operator = g_all.operator
		left join @cober_2G_BS_Number g_BS
			on all_parcel.parcel = g_BS.parcel and all_parcel.operator = g_BS.operator
		left join @cober_2G_ProbCob g_ProbCob
			on all_parcel.parcel = g_ProbCob.parcel and all_parcel.operator = g_ProbCob.operator
		left join @cober_2G_Nivel g_Nivel
			on all_parcel.parcel = g_Nivel.parcel and all_parcel.operator = g_Nivel.operator
		left join @cober_2G_ProbCob_Band g_ProbCob_Band
			on all_parcel.parcel = g_ProbCob_Band.parcel and all_parcel.operator = g_ProbCob_Band.operator
		left join @cober_2G_ProbCob_Band_Both g_ProbCob_BandBoth
			on all_parcel.parcel = g_ProbCob_BandBoth.parcel and all_parcel.operator = g_ProbCob_BandBoth.operator
		left join @cober_2G_Nivel_Band g_Nivel_Band
			on all_parcel.parcel = g_Nivel_Band.parcel and all_parcel.operator = g_Nivel_Band.operator
		left join @cober_3G_All_Samples u_all
			on all_parcel.parcel = u_all.parcel and all_parcel.operator = u_all.operator
		left join @cober_3G_BS_Number u_BS
			on all_parcel.parcel = u_BS.parcel and all_parcel.operator = u_BS.operator
		left join @cober_3G_ProbCob u_ProbCob
			on all_parcel.parcel = u_ProbCob.parcel and all_parcel.operator = u_ProbCob.operator
		left join @cober_3G_ProbCob_Polluter u_ProbCob_Pollut
			on all_parcel.parcel = u_ProbCob_Pollut.parcel and all_parcel.operator = u_ProbCob_Pollut.operator
		left join @cober_3G_Nivel u_Nivel
			on all_parcel.parcel = u_Nivel.parcel and all_parcel.operator = u_Nivel.operator
		left join @cober_3G_Nivel_Band u_Nivel_Band
			on all_parcel.parcel = u_Nivel_Band.parcel and all_parcel.operator = u_Nivel_Band.operator
		left join @cober_3G_ProbCob_Band u_ProbCob_Band
			on all_parcel.parcel = u_ProbCob_Band.parcel and all_parcel.operator = u_ProbCob_Band.operator
		left join @cober_3G_ProbCob_Carrier u_ProbCob_Carrier
			on all_parcel.parcel = u_ProbCob_Carrier.parcel and all_parcel.operator = u_ProbCob_Carrier.operator
		left join @cober_3G_Polluter_Max u_Polluter
			on all_parcel.parcel = u_Polluter.parcel and all_parcel.operator = u_Polluter.operator
		left join @cober_4G_All_Samples l_all
			on all_parcel.parcel = l_all.parcel and all_parcel.operator = l_all.operator
		left join @cober_4G_BS_Number l_BS
			on all_parcel.parcel = l_BS.parcel and all_parcel.operator = l_BS.operator
		left join @cober_4G_ProbCob l_ProbCob
			on all_parcel.parcel = l_ProbCob.parcel and all_parcel.operator = l_ProbCob.operator
		left join @cober_4G_Nivel l_Nivel
			on all_parcel.parcel = l_Nivel.parcel and all_parcel.operator = l_Nivel.operator
		left join @cober_4G_Nivel_Band l_Nivel_Band
			on all_parcel.parcel = l_Nivel_Band.parcel and all_parcel.operator = l_Nivel_Band.operator
		left join @cober_4G_ProbCob_Band l_ProbCob_Band
			on all_parcel.parcel = l_ProbCob_Band.parcel and all_parcel.operator = l_ProbCob_Band.operator
		left join @cober_4G_ProbCob_MixBand l_ProbCob_MixBand
			on all_parcel.parcel = l_ProbCob_MixBand.parcel and all_parcel.operator = l_ProbCob_MixBand.operator
		 
		left join [AGRIDS].dbo.lcc_parcelas p
			on p.nombre=all_parcel.parcel
	order by case when g_all.operator='Vodafone' then '' else g_all.operator end
	

end


else if @sheet = 'Samples_Indoor' or @sheet = 'Samples_Outdoor'
begin

	select
		 @bd  as [Database]
		, @mnc  as mnc
		, 'ALL' as [carrier]
		, NULL as [band],  
		all_parcel.parcel,
		isnull(l_all.[Samples],0) as LTE_Samples,
		isnull(l_Nivel.[4G_Nivel_Samples_Umbral],0) as LTE,
		isnull(l_Nivel_Band.[4G_Nivel_L2600_Samples_Umbral],0) as LTE2600,
		isnull(l_Nivel_Band.[4G_Nivel_L2100_Samples_Umbral],0) as LTE2100,
		isnull(l_Nivel_Band.[4G_Nivel_L2100_BW5_Samples_Umbral],0) as LTE2100_BW5,
		isnull(l_Nivel_Band.[4G_Nivel_L2100_BW10_Samples_Umbral],0) as LTE2100_BW10,
		isnull(l_Nivel_Band.[4G_Nivel_L2100_BW15_Samples_Umbral],0) as LTE2100_BW15,
		isnull(l_Nivel_Band.[4G_Nivel_L1800_Samples_Umbral],0) as LTE1800,
		isnull(l_Nivel_Band.[4G_Nivel_L1800_BW10_Samples_Umbral],0) as LTE1800_BW10,
		isnull(l_Nivel_Band.[4G_Nivel_L1800_BW15_Samples_Umbral],0) as LTE1800_BW15,
		isnull(l_Nivel_Band.[4G_Nivel_L1800_BW20_Samples_Umbral],0) as LTE1800_BW20,
		isnull(l_Nivel_Band.[4G_Nivel_L800_Samples_Umbral],0) as LTE800,
		isnull(l_Nivel_MixBand.[4G_Nivel_LTE800_1800],0) as LTE800_1800,
		isnull(l_Nivel_MixBand.[4G_Nivel_LTE800_2100],0) as LTE800_2100,
		isnull(l_Nivel_MixBand.[4G_Nivel_LTE800_2600],0) as LTE800_2600,
		isnull(l_Nivel_MixBand.[4G_Nivel_LTE1800_2100],0) as LTE1800_2100,
		isnull(l_Nivel_MixBand.[4G_Nivel_LTE1800_2600],0) as LTE1800_2600,
		isnull(l_Nivel_MixBand.[4G_Nivel_LTE2100_2600],0) as LTE2100_2600,
		isnull(l_Nivel_MixBand.[4G_Nivel_LTE800_1800_2100],0) as LTE800_1800_2100,
		isnull(l_Nivel_MixBand.[4G_Nivel_LTE800_1800_2600],0) as LTE800_1800_2600,
		isnull(l_Nivel_MixBand.[4G_Nivel_LTE800_2100_2600],0) as LTE800_2100_2600,
		isnull(l_Nivel_MixBand.[4G_Nivel_LTE1800_2100_2600],0) as LTE1800_2100_2600,
		
		isnull(u_all.[Samples],0) as UMTS_Samples,
		isnull(u_Nivel.[3G_Nivel_Samples_Umbral],0) as UMTS,
		isnull(u_Nivel_Band.[3G_Nivel_U2100_Samples_Umbral],0) as UMTS2100,				
		isnull(u_Nivel_Carrier.[3G_Nivel_U2100_CarrierOnly],0) as UMTS2100_Carrier_only,
		isnull(u_Nivel_Carrier.[3G_Nivel_U2100_F1],0) as UMTS2100_F1,
		isnull(u_Nivel_Carrier.[3G_Nivel_U2100_F2],0) as UMTS2100_F2,
		isnull(u_Nivel_Carrier.[3G_Nivel_U2100_F3],0) as UMTS2100_F3,			
		isnull(u_Nivel_Carrier.[3G_Nivel_U2100_DualCarrier],0) as UMTS2100_Dual_Carrier,
		isnull(u_Nivel_Carrier.[3G_Nivel_U2100_F1_F2],0) as UMTS2100_F1_F2,
		isnull(u_Nivel_Carrier.[3G_Nivel_U2100_F1_F3],0) as UMTS2100_F1_F3,
		isnull(u_Nivel_Carrier.[3G_Nivel_U2100_F2_F3],0) as UMTS2100_F2_F3,
		isnull(u_Nivel_Carrier.[3G_Nivel_U2100_F1_F2_F3],0) as UMTS2100_F1_F2_F3,
		isnull(u_Nivel_Band.[3G_Nivel_U900_Samples_Umbral],0) as UMTS900,
		isnull(u_Nivel_Carrier.[3G_Nivel_U900U2100_CarrierOnly],0) as UMTS900_U2100_Carrier_only,
		isnull(u_Nivel_Carrier.[3G_Nivel_U900U2100_F1],0) as UMTS900_U2100_F1,
		isnull(u_Nivel_Carrier.[3G_Nivel_U900U2100_F2],0) as UMTS900_U2100_F2,
		isnull(u_Nivel_Carrier.[3G_Nivel_U900U2100_F3],0) as UMTS900_U2100_F3,
		isnull(u_Nivel_Carrier.[3G_Nivel_U900U2100_DualCarrier],0) as UMTS900_U2100_Dual_Carrier,
		isnull(u_Nivel_Carrier.[3G_Nivel_U900U2100_F1_F2],0) as UMTS900_U2100_F1_F2,
		isnull(u_Nivel_Carrier.[3G_Nivel_U900U2100_F1_F3],0) as UMTS900_U2100_F1_F3,
		isnull(u_Nivel_Carrier.[3G_Nivel_U900U2100_F2_F3],0) as UMTS900_U2100_F2_F3,
		isnull(u_Nivel_Carrier.[3G_Nivel_U900U2100_F1_F2_F3],0) as UMTS900_U2100_F1_F2_F3,
		
		isnull(g_all.[Samples],0) as [2G_Samples],
		isnull(g_Nivel.[2G_Nivel_Samples_Umbral],0) as [2G],
		isnull(g_Nivel_Band.[2G_Nivel_GSM_Samples_Umbral],0) as GSM,
		isnull(g_Nivel_Band.[2G_Nivel_DCS_Samples_Umbral],0) as DCS,
		isnull(g_Nivel_BandBoth.[2G_Nivel_GSM_DCS_Samples_Umbral],0) as GSM_DCS,
		
		isnull(l_Nivel.[4G_Nivel],-140) as RSRP_LTE,
		isnull(l_Nivel_Band.[4G_Nivel_L2600],-140) as RSRP_LTE2600,
		isnull(l_Nivel_Band.[4G_Nivel_L2100],-140) as RSRP_LTE2100,
		isnull(l_Nivel_Band.[4G_Nivel_L1800],-140) as RSRP_LTE1800,
		isnull(l_Nivel_Band.[4G_Nivel_L800],-140) as RSRP_LTE800,
		isnull(l_all.[Samples],0) as [4G_All_Samples],
		isnull(l_Nivel.[4G_Nivel_Samples],0) as RSRP_LTE_Samples,
		isnull(l_Nivel_Band.[4G_Nivel_L2600_Samples],0) as RSRP_LTE2600_Samples,
		isnull(l_Nivel_Band.[4G_Nivel_L2100_Samples],0) as RSRP_LTE2100_Samples,
		isnull(l_Nivel_Band.[4G_Nivel_L1800_Samples],0) as RSRP_LTE1800_Samples,
		isnull(l_Nivel_Band.[4G_Nivel_L800_Samples],0) as RSRP_LTE800_Samples,

		isnull(u_Nivel.[3G_Nivel],-140) as RSCP_UMTS,
		isnull(u_Nivel_Band.[3G_Nivel_U2100],-140) as RSCP_UMTS2100,
		isnull(u_Nivel_Band.[3G_Nivel_U900],-140) as RSCP_UMTS900,
		isnull(u_Polluter.[3G_Polluter],0) as [Pollution],
		isnull(u_Nivel.[3G_Nivel_Polluter_BS],0) as [Pollution BS RSCP],
		isnull(u_all.[Samples],0) as [3G_All_Samples],
		isnull(u_Nivel.[3G_Nivel_Samples],0) as RSCP_UMTS_Samples,
		isnull(u_Nivel_Band.[3G_Nivel_U2100_Samples],0) as RSCP_UMTS2100_Samples,
		isnull(u_Nivel_Band.[3G_Nivel_U900_Samples],0) as RSCP_UMTS900_Samples,
		isnull(u_Nivel_Band.[3G_Nivel_U2100_Polluter_BS],0) as [Pollution BS RSCP U2100],
		isnull(u_Nivel_Band.[3G_Nivel_U900_Polluter_BS],0) as [Pollution BS RSCP U900],

		isnull(g_Nivel.[2G_Nivel],-110) as RxLev_2G,
		isnull(g_Nivel_Band.[2G_Nivel_GSM],-110) as RxLev_GSM,
		isnull(g_Nivel_Band.[2G_Nivel_DCS],-110) as RxLev_DCS,

		isnull(g_all.[Samples],0) as [2G_All_Samples],
		isnull(g_Nivel.[2G_Nivel_Samples],0) as RxLev_2G_Samples,
		isnull(g_Nivel_Band.[2G_Nivel_GSM_Samples],0) as RxLev_GSM_Samples,
		isnull(g_Nivel_Band.[2G_Nivel_DCS_Samples],0) as RxLev_DCS_Samples

		,[Region_VF]
		,[Provincia]
		,[Condado]
		,[Turistico]
		,[Entorno]
		,[Vendor_VF]
		,[Suministrador_VF]
		,[Sum_VF_Y_PINZA]
		,[Vendor_2G_MV]
		,[Vendor_3G_MV]
		,[Vendor_OR]
		,[Suministrador_OR]
		,[CodINE]
		,[Ciudad]
		,[Poblacion]
		,[Rango_Pob_Zona]
		,[Rango_Pob]
		,[Zona]
		,[Pob_Urbano]
		,[AVE]
		,[Carretera]
		,[Carretera_P3]
		,[Ciudad_P3]
		,[Entorno_P3]
		, @week as Meas_Week
		, @Meas_Round as [Meas_Round]
		, @Meas_Date as [Meas_Date]
		, @entidad as Entidad
		, NULL as [Num_Medida]
		, @monthYearDash as monthYearDash
		, @weekDash as weekDash
		, @Report as [Report_Type]
		, @aggrType as [Aggr_Type]
		, [Region_OSP]
	from
		(
			select parcel, operator from @cober_2G_All_Samples group by parcel,operator
			union
			select parcel, operator from @cober_3G_All_Samples group by parcel, operator
			union
			select parcel, operator from @cober_4G_All_Samples group by parcel, operator
		) all_parcel
		left join @cober_2G_All_Samples g_all
			on all_parcel.parcel = g_all.parcel and all_parcel.operator = g_all.operator
		left join @cober_2G_Nivel g_Nivel
			on all_parcel.parcel = g_Nivel.parcel and all_parcel.operator = g_Nivel.operator
		left join @cober_2G_Nivel_Band g_Nivel_Band
			on all_parcel.parcel = g_Nivel_Band.parcel and all_parcel.operator = g_Nivel_Band.operator
		left join @cober_2G_Nivel_Band_Both g_Nivel_BandBoth
			on all_parcel.parcel = g_Nivel_BandBoth.parcel and all_parcel.operator = g_Nivel_BandBoth.operator
		left join @cober_3G_All_Samples u_all
			on all_parcel.parcel = u_all.parcel and all_parcel.operator = u_all.operator
		left join @cober_3G_Nivel u_Nivel
			on all_parcel.parcel = u_Nivel.parcel and all_parcel.operator = u_Nivel.operator
		left join @cober_3G_Nivel_Band u_Nivel_Band
			on all_parcel.parcel = u_Nivel_Band.parcel and all_parcel.operator = u_Nivel_Band.operator
		left join @cober_3G_Nivel_Carrier u_Nivel_Carrier
			on all_parcel.parcel = u_Nivel_Carrier.parcel and all_parcel.operator = u_Nivel_Carrier.operator
		left join @cober_4G_All_Samples l_all
			on all_parcel.parcel = l_all.parcel and all_parcel.operator = l_all.operator
		left join @cober_4G_Nivel l_Nivel
			on all_parcel.parcel = l_Nivel.parcel and all_parcel.operator = l_Nivel.operator
		left join @cober_4G_Nivel_Band l_Nivel_Band
			on all_parcel.parcel = l_Nivel_Band.parcel and all_parcel.operator = l_Nivel_Band.operator
		left join @cober_4G_Nivel_MixBand l_Nivel_MixBand
			on all_parcel.parcel = l_Nivel_MixBand.parcel and all_parcel.operator = l_Nivel_MixBand.operator
		left join @cober_3G_Polluter_Max u_Polluter
			on all_parcel.parcel = u_Polluter.parcel and all_parcel.operator = u_Polluter.operator		 

		left join [AGRIDS].dbo.lcc_parcelas p
			on p.nombre=all_parcel.parcel
	order by case when g_all.operator='Vodafone' then '' else g_all.operator end
	

end
