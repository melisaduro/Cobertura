USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_Results_Aggr]    Script Date: 05/03/2018 13:21:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[sp_MDD_Coverage_Results_Aggr_Curves4G]
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
--declare @entity as varchar(256) = 'AVILA' 
--declare @sheet as varchar(256) = 'Curves'
--declare @operatorUmbrales as varchar(256) = 'Orange'
--declare @Report as varchar(256) = 'VDF'
--declare @simOperator as int = 1
--declare @monthYearDash as varchar(100)='mes'
--declare @weekDash as varchar(50)='semana'
--declare @aggrType as varchar(256) = 'GRID'
-----------------------------
-----------------------------

declare @operator as varchar(256)
set @operator= case when @simOperator=3 then 'Orange'
				when @simOperator=7 then 'Movistar'
				when @simOperator=1 then 'Vodafone'
				when @simOperator=4 then 'Yoigo'
			end

declare @ciudTable as varchar(256)=replace(replace(@entity,' ','_'),'-','_')            
declare @2G as varchar (256) = '[lcc_cober2G_50x50_' + @ciudTable + '_' + @Report+']'
declare @3G as varchar (256) = '[lcc_cober3G_50x50_' + @ciudTable + '_' + @Report+']'
declare @4G as varchar (256) = '[lcc_cober4G_50x50_' + @ciudTable + '_' + @Report+']'

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
declare @cober_3G_All_Samples  as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[Samples] [int] NOT NULL
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
	[4G_PcobInd_NEW_Samples] [int] NULL,
	[4G_PcobInd_NEW] [float] NULL
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
	[4G_PcobInd_NEW_L800_Samples] [int] NULL,
	[4G_PcobInd_NEW_L1800_Samples] [int] NULL,
	[4G_PcobInd_NEW_L1800_BW10_Samples] [int] NULL,
	[4G_PcobInd_NEW_L1800_BW15_Samples] [int] NULL,
	[4G_PcobInd_NEW_L1800_BW20_Samples] [int] NULL,
	[4G_PcobInd_NEW_L2100_Samples] [int] NULL,
	[4G_PcobInd_NEW_L2100_BW5_Samples] [int] NULL,
	[4G_PcobInd_NEW_L2100_BW10_Samples] [int] NULL,
	[4G_PcobInd_NEW_L2100_BW15_Samples] [int] NULL,
	[4G_PcobInd_NEW_L2600_Samples] [int] NULL,	
	[4G_PcobInd_NEW_L800] [float] NULL,
	[4G_PcobInd_NEW_L1800] [float] NULL,
	[4G_PcobInd_NEW_L1800_BW10] [float] NULL,
	[4G_PcobInd_NEW_L1800_BW15] [float] NULL,
	[4G_PcobInd_NEW_L1800_BW20] [float] NULL,
	[4G_PcobInd_NEW_L2100] [float] NULL,
	[4G_PcobInd_NEW_L2100_BW5] [float] NULL,
	[4G_PcobInd_NEW_L2100_BW10] [float] NULL,
	[4G_PcobInd_NEW_L2100_BW15] [float] NULL,
	[4G_PcobInd_NEW_L2600] [float] NULL
)
declare @cober_4G_ProbCob_MixBand as table (
	[operator] [varchar](50) NOT NULL,
	[parcel] [varchar](50) NOT NULL,
	[4G_PcobInd_NEW_LTE800_1800_Samples] [int] NULL,
	[4G_PcobInd_NEW_LTE800_2100_Samples] [int] NULL,
	[4G_PcobInd_NEW_LTE800_2600_Samples] [int] NULL,
	[4G_PcobInd_NEW_LTE1800_2100_Samples] [int] NULL,
	[4G_PcobInd_NEW_LTE1800_2600_Samples] [int] NULL,
	[4G_PcobInd_NEW_LTE2100_2600_Samples] [int] NULL,
	[4G_PcobInd_NEW_LTE800_1800_2100_Samples] [int] NULL,
	[4G_PcobInd_NEW_LTE800_1800_2600_Samples] [int] NULL,
	[4G_PcobInd_NEW_LTE800_2100_2600_Samples] [int] NULL,
	[4G_PcobInd_NEW_LTE1800_2100_2600_Samples] [int] NULL,
	[4G_PcobInd_NEW_LTE800_1800] [float] NULL,
	[4G_PcobInd_NEW_LTE800_2100] [float] NULL,
	[4G_PcobInd_NEW_LTE800_2600] [float] NULL,
	[4G_PcobInd_NEW_LTE1800_2100] [float] NULL,
	[4G_PcobInd_NEW_LTE1800_2600] [float] NULL,
	[4G_PcobInd_NEW_LTE2100_2600] [float] NULL,
	[4G_PcobInd_NEW_LTE800_1800_2100] [float] NULL,
	[4G_PcobInd_NEW_LTE800_1800_2600] [float] NULL,
	[4G_PcobInd_NEW_LTE800_2100_2600] [float] NULL,
	[4G_PcobInd_NEW_LTE1800_2100_2600] [float] NULL
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
				row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.PcobInd_NEW desc,l.frecuencia desc,l.pci desc) as id
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
	1.0*count(l.PcobInd_NEW) as PcobInd_NEW_Samples,
	avg(l.PcobInd_NEW) as PcobInd_NEW
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
			l.PcobInd_NEW,
			row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator order by l.PcobInd_NEW desc) as id
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
			l.PcobInd_NEW,
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
			l.PcobInd_NEW,
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
	avg(case when l.band =''LTE800'' then l.PcobInd_NEW end) as LTE800,
	avg(case when l.band =''LTE1800'' then l.PcobInd_NEW end) as LTE1800,
	avg(case when l.band =''LTE1800'' and l.bandwidth = 10 then l.PcobInd_NEW end) as LTE1800_BW10,
	avg(case when l.band =''LTE1800'' and l.bandwidth = 15 then l.PcobInd_NEW end) as LTE1800_BW15,
	avg(case when l.band =''LTE1800'' and l.bandwidth = 20 then l.PcobInd_NEW end) as LTE1800_BW20,
	avg(case when l.band =''LTE2100'' then l.PcobInd_NEW end) as LTE2100,
	avg(case when l.band =''LTE2100'' and l.bandwidth = 5 then l.PcobInd_NEW end) as LTE2100_BW5,
	avg(case when l.band =''LTE2100'' and l.bandwidth = 10 then l.PcobInd_NEW end) as LTE2100_BW10,
	avg(case when l.band =''LTE2100'' and l.bandwidth = 15 then l.PcobInd_NEW end) as LTE2100_BW15,
	avg(case when l.band =''LTE2600'' then l.PcobInd_NEW end) as LTE2600
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
			l.PcobInd_NEW,
			row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator, l.band order by l.PcobInd_NEW desc, l.bandwidth desc) as id
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
		min(case when l.band in (''LTE800'', ''LTE1800'') then l.PcobInd_NEW end) as LTE800_1800,
		min(case when l.band in (''LTE800'', ''LTE2100'') then l.PcobInd_NEW end) as LTE800_2100,
		min(case when l.band in (''LTE800'', ''LTE2600'') then l.PcobInd_NEW end) as LTE800_2600,
		min(case when l.band in (''LTE1800'', ''LTE2100'') then l.PcobInd_NEW end) as LTE1800_2100,
		min(case when l.band in (''LTE1800'', ''LTE2600'') then l.PcobInd_NEW end) as LTE1800_2600,
		min(case when l.band in (''LTE2100'', ''LTE2600'') then l.PcobInd_NEW end) as LTE2100_2600,
		min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2100'') then l.PcobInd_NEW end) as LTE800_1800_2100,
		min(case when l.band in (''LTE800'', ''LTE1800'', ''LTE2600'') then l.PcobInd_NEW end) as LTE800_1800_2600,
		min(case when l.band in (''LTE800'', ''LTE2100'', ''LTE2600'') then l.PcobInd_NEW end) as LTE800_2100_2600,
		min(case when l.band in (''LTE1800'', ''LTE2100'', ''LTE2600'') then l.PcobInd_NEW end) as LTE1800_2100_2600,
						
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
				l.PcobInd_NEW,
				row_number () over (partition by l.latitud_50m,	l.longitud_50m, l.operator, l.band order by l.PcobInd_NEW desc) as id
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

		isnull(l_ProbCob.[4G_PcobInd_NEW],0) as LTE,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L2600],0) as LTE2600,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L2100],0) as LTE2100,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L2100_BW5],0) as LTE2100_BW5,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L2100_BW10],0) as LTE2100_BW10,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L2100_BW15],0) as LTE2100_BW15,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L1800],0) as LTE1800,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L1800_BW10],0) as LTE1800_BW10,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L1800_BW15],0) as LTE1800_BW15,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L1800_BW20],0) as LTE1800_BW20,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L800],0) as LTE800,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_1800],0) as LTE800_1800,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_2100],0) as LTE800_2100,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_2600],0) as LTE800_2600,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE1800_2100],0) as LTE1800_2100,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE1800_2600],0) as LTE1800_2600,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE2100_2600],0) as LTE2100_2600,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_1800_2100],0) as LTE800_1800_2100,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_1800_2600],0) as LTE800_1800_2600,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_2100_2600],0) as LTE800_2100_2600,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE1800_2100_2600],0) as LTE1800_2100_2600,

		isnull(l_ProbCob.[4G_PcobInd_NEW_Samples],0) as LTE_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L2600_Samples],0) as LTE2600_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L2100_Samples],0) as LTE2100_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L2100_BW5_Samples],0) as LTE2100_BW5_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L2100_BW10_Samples],0) as LTE2100_BW10_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L2100_BW15_Samples],0) as LTE2100_BW15_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L1800_Samples],0) as LTE1800_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L1800_BW10_Samples],0) as LTE1800_BW10_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L1800_BW15_Samples],0) as LTE1800_BW15_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L1800_BW20_Samples],0) as LTE1800_BW20_Samples,
		isnull(l_ProbCob_Band.[4G_PcobInd_NEW_L800_Samples],0) as LTE800_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_1800_Samples],0) as LTE800_1800_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_2100_Samples],0) as LTE800_2100_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_2600_Samples],0) as LTE800_2600_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE1800_2100_Samples],0) as LTE1800_2100_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE1800_2600_Samples],0) as LTE1800_2600_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE2100_2600_Samples],0) as LTE2100_2600_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_1800_2100_Samples],0) as LTE800_1800_2100_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_1800_2600_Samples],0) as LTE800_1800_2600_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE800_2100_2600_Samples],0) as LTE800_2100_2600_Samples,
		isnull(l_ProbCob_MixBand.[4G_PcobInd_NEW_LTE1800_2100_2600_Samples],0) as LTE1800_2100_2600_Samples,
		isnull(l_BS.[BS_Number],0) as BS_LTE,	
		
		isnull(u_all.[Samples],0) as [3G_All_Samples],
		isnull(g_all.[Samples],0) as [2G_All_Samples]

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
		left join @cober_2G_All_Samples g_all
			on all_parcel.parcel = g_all.parcel and all_parcel.operator = g_all.operator
		left join @cober_3G_All_Samples u_all
			on all_parcel.parcel = u_all.parcel and all_parcel.operator = u_all.operator

		left join [AGRIDS].dbo.lcc_parcelas p
			on p.nombre=all_parcel.parcel
	order by case when g_all.operator='Vodafone' then '' else g_all.operator end
