USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_MDD_Coverage_4G_Wrapped_FY1617_NEW]    Script Date: 29/05/2017 12:05:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[sp_MDD_Coverage_4G_Wrapped_FY1617_NEW] 
(
		@provincia as varchar(256),			
		@ciudad as varchar(256),							
		@simOperator as int,
		@tech as varchar(256), 
		@umbralIndoor varchar(256), 
		@monthYearDash as varchar(100),
		@weekDash as varchar(50),
		@Report as varchar (256)			
)
as

-----------------------------
----- Testing Variables -----
-----------------------------

--declare @tech as varchar(256)='total' -- nombre de la pestaña: Frecs 4G, Total
--declare @provincia as varchar(256) = 'BILBAO'
--declare @ciudad as varchar(256) = '%%'
----declare @tipoCober as varchar(256) = 'Indooor'
----Si se quisiera filrar, sustituir max(RSCP_Outdoor) as avg_rscp,  
----por 
----max(RSCP_'+ @tipoCober +') as avg_rscp, 

--declare @simOperator as int = 1
--declare @umbralIndoor as varchar(256) = -70
--declare @Pillot as bit = 1 -- O = False, 1 = True
--declare @monthYearDash as varchar(100)='mes'
--declare @weekDash as varchar(50)='semana'
--declare @Report as varchar (256)='MUN'

-----------------------------
----- Date Declarations -----
-----------------------------
SET NOCOUNT ON;

declare @operator as varchar(256)
set @operator= case when @simOperator=3 then 'Orange'
				when @simOperator=7 then 'Movistar'
				when @simOperator=1 then 'Vodafone'
				when @simOperator=4 then 'Yoigo'
			end
			
declare @band as varchar(256)					
set @band= case 
			 when @tech='Total' then '%%'
             else @tech
           end

declare @provTable as varchar(256)=replace(replace(@provincia,' ','_'),'-','_')  
declare @band_freq as integer
declare @frequency_band as varchar(50)

declare @idx as integer = 1
declare @idx_max as integer  

declare @4GThresIndoor as varchar(10)

if @Report = 'VDF' --Umbral indoor Vodafone
begin
	set @4GThresIndoor = '-95'
end
else  --OSP o MUN: Umbral indoor Orange
begin
	set @4GThresIndoor = '-90'
end
    
------ Metemos en variables algunos campos calculados ----------------
declare @cmd nvarchar(max)
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

declare @bd as nvarchar(128) = db_name()
declare @mnc as nvarchar(128) = right ('00'+ convert(varchar,@simOperator),2)
declare @Meas_Round as varchar(256)= [master].dbo.fn_lcc_getElement(1, db_name(),'_') + '_' + [master].dbo.fn_lcc_getElement(5, db_name(),'_')

declare @dateMax varchar(8)
SET @ParmDefinition = N'@dateMaxOut varchar(8) output' 
set @cmd = 'select @dateMaxOut = max(MeasDate)
	from dbo.lcc_position_Entity_List_'+@tableReport+'
	where entity_name like ''%'+@provincia+'%'''
--print @cmd
exec sp_executesql @cmd,@ParmDefinition,@dateMaxOut = @dateMax output
--print @dateMax

declare @Meas_Date as varchar(256)= (select SUBSTRING(@dateMax,3,2) + '_'	 + SUBSTRING(@dateMax,5,2))

--declare @Meas_Date as varchar(256)= (select right(convert(varchar(256),datepart(yy, endTime)),2) + '_'	 + convert(varchar(256),format(endTime,'MM'))+ '_'	 + convert(varchar(256),format(endTime,'dd'))
--	from lcc_Scanner_LTE_Detailed where sessionid=(select max(c.sessionid) from lcc_Scanner_UMTS_Detailed c where c.collectionname like '%' + @provincia + '%'))

declare @entidad as varchar(256) = @provincia

declare @week as varchar(256)
declare @tmpDateFirst int 
declare @tmpWeek int 

--select @tmpDateFirst = @@DATEFIRST
--if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
--	SELECT @tmpWeek =DATEPART(week, (select endTime
--						from lcc_Scanner_LTE_Detailed 
--						where sessionid=(select max(c.sessionid) from lcc_Scanner_LTE_Detailed c where c.collectionname like '%' + @provincia + '%')))
--else
--	begin
--		SET DATEFIRST 1;  --Primer dia de la semana lunes
--		SELECT @tmpWeek =DATEPART(week, (select endTime
--						from lcc_Scanner_LTE_Detailed 
--						where sessionid=(select max(c.sessionid) from lcc_Scanner_LTE_Detailed c where c.collectionname like '%' + @provincia + '%')))
--		SET DATEFIRST @tmpDateFirst; --dejamos como primer dia de la semana que el que estaba configurado

--	end

select @tmpDateFirst = @@DATEFIRST
if @tmpDateFirst = 1 --Si el primer dia de la semana lunes
	set @tmpWeek =DATEPART(week, @dateMax)
else
	begin
		SET DATEFIRST 1;  --Primer dia de la semana lunes
		set @tmpWeek =DATEPART(week, @dateMax)
		SET DATEFIRST @tmpDateFirst; --dejamos como primer dia de la semana que el que estaba configurado

	end

set @week = 'W' + convert(varchar, @tmpWeek)

------Tabla con las frecuencias de LTE------------
select *,
CASE ServingOperator 
	WHEN 'Vodafone' then '01'
	WHEN 'Movistar' then '07'
	WHEN 'Orange'	then '03'
	WHEN 'Yoigo'	then '04'
END as mnc,
ROW_NUMBER() OVER(order by ServingOperator) as freq_idx
into #FREQ_TABLE
from [AGRIDS].[dbo].[lcc_ref_servingOperator_Freq] where  band like 'LTE%' 

set @idx_max = (select MAX(freq_idx) from #FREQ_TABLE)

------ Tabla con resultado final ----------------
CREATE TABLE #results(
	[Database] [nvarchar](128) NULL,
	[mnc] [varchar](50) NULL,
	[parcel] [varchar](50) NULL,
	[carrier] [varchar](50) NULL,
	[band] [varchar](50) NULL,
	[muestras] [int] NULL,
	[cobertura AVG] [float] NULL,
	[<-120] [int] NULL,
	[<=-120 a <-117] [int] NULL,
	[<=-117 a <-115] [int] NULL,
	[<=-115 a <-113] [int] NULL,
	[<=-113 a <-110] [int] NULL,
	[<=-110 a <-107] [int] NULL,
	[<=-107 a <-105] [int] NULL,
	[<=-105 a <-103] [int] NULL,
	[<=-103 a <-100] [int] NULL,
	[<=-100 a <-97] [int] NULL,
	[<=-97 a <-95] [int] NULL,
	[<=-95 a <-93] [int] NULL,
	[<=-93 a <-92] [int] NULL,
	[<=-92 a <-90] [int] NULL,
	[<=-90 a <-87] [int] NULL,
	[<=-87 a <-85] [int] NULL,
	[<=-85 a <-84] [int] NULL,
	[<=-84 a <-82] [int] NULL,
	[<=-82 a <-81] [int] NULL,
	[<=-81 a <-80] [int] NULL,
	[<=-80 a <-77] [int] NULL,
	[<=-77 a <-75] [int] NULL,
	[<=-75 a <-72] [int] NULL,
	[<=-72 a <-70] [int] NULL,
	[<=-70 a <-67] [int] NULL,
	[<=-67 a <-66] [int] NULL,
	[<=-66 a <-65] [int] NULL,
	[<=-65 a <-62] [int] NULL,
	[<=-62 a <-60] [int] NULL,
	[>=-60] [int] NULL,
	[avg_rsrq] [float] NULL,
	[>-3] [int] NULL,
	[-3 a -9] [int] NULL,
	[-9 a -12] [int] NULL,
	[-12 a -20] [int] NULL,
	[avg_CINR] [float] NULL,
	[< -10] [int] NULL,
	[-10 a 0] [int] NULL,
	[0 a 10] [int] NULL,
	[10 a 20] [int] NULL,
	[20 a 30] [int] NULL,
	[> 30] [int] NULL,
	[Indoor_Coverage_Prob] [float] NULL,
	[BW_5_Cutoff] [int] NULL,
	[BW_10_Cutoff] [int] NULL,
	[BW_15_Cutoff] [int] NULL,
	[BW_20_Cutoff] [int] NULL,
	Count_LTE2100_BW5 [int] NULL,
	Count_LTE2100_BW10 [int] NULL,
	Count_LTE2100_BW15 [int] NULL,
	Count_LTE1800_BW10 [int] NULL,
	Count_LTE1800_BW15 [int] NULL,
	Count_LTE1800_BW20 [int] NULL,
	avg_LTE2100_BW5 [float] NULL,
	avg_LTE2100_BW10 [float] NULL,
	avg_LTE2100_BW15 [float] NULL,
	avg_LTE1800_BW10 [float] NULL,
	avg_LTE1800_BW15 [float] NULL,
	avg_LTE1800_BW20 [float] NULL,
	Count_LTE2100_BW5_Ind [int] NULL,
	Count_LTE2100_BW10_Ind [int] NULL,
	Count_LTE2100_BW15_Ind [int] NULL,
	Count_LTE1800_BW10_Ind [int] NULL,
	Count_LTE1800_BW15_Ind [int] NULL,
	Count_LTE1800_BW20_Ind [int] NULL,
	Count_LTE2100_BW5_Out [int] NULL,
	Count_LTE2100_BW10_Out [int] NULL,
	Count_LTE2100_BW15_Out [int] NULL,
	Count_LTE1800_BW10_Out [int] NULL,
	Count_LTE1800_BW15_Out [int] NULL,
	Count_LTE1800_BW20_Out [int] NULL,
	[Region] [nvarchar](255) NULL,
	[Provincia] [nvarchar](255) NULL,
	[Condado] [nvarchar](255) NULL,
	[Turistico] [float] NULL,
	[Entorno] [nvarchar](255) NULL,
	[Vendor_VF] [nvarchar](255) NULL,
	[Suministrador_VF] [nvarchar](255) NULL,
	[Sum_VF_Y_PINZA] [nvarchar](255) NULL,
	[Vendor_2G_MV] [nvarchar](255) NULL,
	[Vendor_3G_MV] [nvarchar](255) NULL,
	[Vendor_OR] [nvarchar](255) NULL,
	[Suministrador_OR] [nvarchar](255) NULL,
	[CodINE] [float] NULL,
	[Ciudad] [nvarchar](255) NULL,
	[Poblacion] [float] NULL,
	[Rango_Pob_Zona] [nvarchar](255) NULL,
	[Rango_Pob] [nvarchar](255) NULL,
	[Zona] [nvarchar](255) NULL,
	[Pob_Urbano] [nvarchar](255) NULL,
	[AVE] [nvarchar](255) NULL,
	[Carretera] [nvarchar](255) NULL,
	[Carretera_P3] [nvarchar](255) NULL,
	[Ciudad_P3] [nvarchar](255) NULL,
	[Entorno_P3] [nvarchar](255) NULL,
	[Meas_Week] [varchar](3) NULL,
	[Meas_Round] [varchar](256) NULL,
	[Meas_Date] [varchar](256) NULL,
	[Entidad] [varchar](256) NULL,
	[Num_Medida] [varchar](256) NULL,
	[monthYearDash] [varchar](256) NULL,
	[weekDash] [varchar](256) NULL
)

insert into #results
	exec ('select 
			'''+ @bd +''' as [Database]
			,'''+ @mnc +''' as mnc
			,master.dbo.fn_lcc_getParcel(longitud_50m,latitud_50m) as parcel
			, ''ALL'' as [carrier]
			, NULL as [band]  
			, SUM(1) as muestras
			, 10*log10(AVG(POWER(convert(float,10.0), (convert(float,avg_rsrp))/10.0))) as [cobertura AVG]
			, SUM( case when avg_rsrp<-120 then 1  end) as  [<-120]
			, SUM( case when avg_rsrp >= -120 and avg_rsrp< -117 then 1 end) as [<=-120 a <-117]
			, SUM( case when avg_rsrp >= -117 and avg_rsrp< -115 then 1 end) as [<=-117 a <-115]
			, SUM( case when avg_rsrp >= -115 and avg_rsrp< -113 then 1 end) as [<=-115 a <-113]
			, SUM( case when avg_rsrp >= -113 and avg_rsrp< -110 then 1 end) as  [<=-113 a <-110]
			, SUM( case when avg_rsrp >= -110 and avg_rsrp< -107 then 1 end) as [<=-110 a <-107]
			, SUM( case when avg_rsrp >= -107 and avg_rsrp< -105 then 1 end) as [<=-107 a <-105]
			, SUM( case when avg_rsrp >= -105 and avg_rsrp< -103 then 1 end) as  [<=-105 a <-103]
			, SUM( case when avg_rsrp >= -103 and avg_rsrp< -100 then 1 end) as  [<=-103 a <-100]
			, SUM( case when avg_rsrp >= -100 and avg_rsrp< -97 then 1 end) as [<=-100 a <-97]
			, SUM( case when avg_rsrp >= -97 and avg_rsrp< -95 then 1 end) as [<=-97 a <-95]
			, SUM( case when avg_rsrp >= -95 and avg_rsrp< -93 then 1 end) as [<=-95 a <-93]
			, SUM( case when avg_rsrp >= -93 and avg_rsrp< -92 then 1 end) as [<=-93 a <-92]
			, SUM( case when avg_rsrp >= -92 and avg_rsrp< -90 then 1 end) as [<=-92 a <-90]
			, SUM( case when avg_rsrp >= -90 and avg_rsrp< -87 then 1 end) as [<=-90 a <-87]
			, SUM( case when avg_rsrp >= -87 and avg_rsrp< -85 then 1 end) as [<=-87 a <-85]
			, SUM( case when avg_rsrp >= -85 and avg_rsrp< -84 then 1 end) as [<=-85 a <-84]
			, SUM( case when avg_rsrp >= -84 and avg_rsrp< -82 then 1 end) as [<=-84 a <-82]
			, SUM( case when avg_rsrp >= -82 and avg_rsrp< -81 then 1 end) as [<=-82 a <-81]
			, SUM( case when avg_rsrp >= -81 and avg_rsrp< -80 then 1 end) as [<=-81 a <-80]
			, SUM( case when avg_rsrp >= -80 and avg_rsrp< -77 then 1 end) as [<=-80 a <-77]
			, SUM( case when avg_rsrp >= -77 and avg_rsrp< -75 then 1 end) as [<=-77 a <-75]
			, SUM( case when avg_rsrp >= -75 and avg_rsrp< -72 then 1 end) as [<=-75 a <-72]
			, SUM( case when avg_rsrp >= -72 and avg_rsrp< -70 then 1 end) as [<=-72 a <-70]
			, SUM( case when avg_rsrp >= -70 and avg_rsrp< -67 then 1 end) as [<=-70 a <-67]
			, SUM( case when avg_rsrp >= -67 and avg_rsrp< -66 then 1 end) as [<=-67 a <-66]
			, SUM( case when avg_rsrp >= -66 and avg_rsrp< -65 then 1 end) as [<=-66 a <-65]
			, SUM( case when avg_rsrp >= -65 and avg_rsrp< -62 then 1 end) as [<=-65 a <-62]
			, SUM( case when avg_rsrp >= -62 and avg_rsrp< -60 then 1 end) as [<=-62 a <-60]
			, SUM( case when avg_rsrp >= -60 then 1 end) as [>=-60]
			,10*log10(AVG(POWER(convert(float,10.0), (convert(float,avg_rsrq))/10.0))) as avg_rsrq
			, SUM( case when avg_rsrq > -3  then 1 end) as [>-3]
			, SUM( case when avg_rsrq <= -3 and avg_rsrq>-9  then 1 end) as [-3 a -9]
			, SUM( case when avg_rsrq <= -9 and avg_rsrq>-12 then 1 end) as [-9 a -12]
			, SUM( case when avg_rsrq <= -12 then 1 end) as [-12 a -20]
			, 10*log10(AVG(POWER(convert(float,10.0), (convert(float,avg_CINR))/10.0))) as avg_CINR
			, SUM( case when avg_CINR < -10  then 1 end) as [< -10]
			, SUM( case when avg_CINR >= -10 and avg_CINR<0  then 1 end) as [-10 a 0]
			, SUM( case when avg_CINR >= 0 and avg_CINR<10  then 1 end) as [0 a 10]
			, SUM( case when avg_CINR >= 10 and avg_CINR<20 then 1 end) as [10 a 20]
			, SUM( case when avg_CINR >= 20 and avg_CINR<30 then 1 end) as [20 a 30]
			, SUM( case when avg_CINR >= 30  then 1 end) as [> 30]
			, avg(Indoor_Coverage_Prob) as Indoor_Coverage_Prob
			, SUM( case when (avg_rsrp >= -90 and bandwidth=5) then 1 end) as BW_5_CutOff
			, SUM( case when (avg_rsrp >= -90 and bandwidth=10) then 1 end) as BW_10_CutOff
			, SUM( case when (avg_rsrp >= -90 and bandwidth=15) then 1 end) as BW_15_CutOff
			, SUM( case when (avg_rsrp >= -90 and bandwidth=20) then 1 end) as BW_20_CutOff
			,sum(case when (band= ''LTE2100'' and bandwidth=5) then 1 else 0 end) as Count_LTE2100_BW5
			,sum(case when (band= ''LTE2100'' and bandwidth=10) then 1 else 0 end) as Count_LTE2100_BW10
			,sum(case when (band= ''LTE2100'' and bandwidth=15) then 1 else 0 end) as Count_LTE2100_BW15
			,sum(case when (band= ''LTE1800'' and bandwidth=10) then 1 else 0 end) as Count_LTE1800_BW10
			,sum(case when (band= ''LTE1800'' and bandwidth=15) then 1 else 0 end) as Count_LTE1800_BW15
			,sum(case when (band= ''LTE1800'' and bandwidth=20) then 1 else 0 end) as Count_LTE1800_BW20
			,avg(case when (band= ''LTE2100'' and bandwidth=5) then Indoor_Coverage_Prob end) as avg_LTE2100_BW5
			,avg(case when (band= ''LTE2100'' and bandwidth=10) then Indoor_Coverage_Prob end) as avg_LTE2100_BW10
			,avg(case when (band= ''LTE2100'' and bandwidth=15) then Indoor_Coverage_Prob end) as avg_LTE2100_BW15
			,avg(case when (band= ''LTE1800'' and bandwidth=10) then Indoor_Coverage_Prob end) as avg_LTE1800_BW10
			,avg(case when (band= ''LTE1800'' and bandwidth=15) then Indoor_Coverage_Prob end) as avg_LTE1800_BW15
			,avg(case when (band= ''LTE1800'' and bandwidth=20) then Indoor_Coverage_Prob end) as avg_LTE1800_BW20
			,sum(case when (band= ''LTE2100'' and bandwidth=5) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE2100_BW5_Ind
			,sum(case when (band= ''LTE2100'' and bandwidth=10) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE2100_BW10_Ind
			,sum(case when (band= ''LTE2100'' and bandwidth=15) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE2100_BW15_Ind
			,sum(case when (band= ''LTE1800'' and bandwidth=10) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE1800_BW10_Ind
			,sum(case when (band= ''LTE1800'' and bandwidth=15) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE1800_BW15_Ind
			,sum(case when (band= ''LTE1800'' and bandwidth=20) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE1800_BW20_Ind
			,sum(case when (band= ''LTE2100'' and bandwidth=5) and avg_rsrp >= -113 then 1 else 0 end) as Count_LTE2100_BW5_Out
			,sum(case when (band= ''LTE2100'' and bandwidth=10) and avg_rsrp >= -113  then 1 else 0 end) as Count_LTE2100_BW10_Out
			,sum(case when (band= ''LTE2100'' and bandwidth=15) and avg_rsrp >= -113  then 1 else 0 end) as Count_LTE2100_BW15_Out
			,sum(case when (band= ''LTE1800'' and bandwidth=10) and avg_rsrp >= -113  then 1 else 0 end) as Count_LTE1800_BW10_Out
			,sum(case when (band= ''LTE1800'' and bandwidth=15) and avg_rsrp >= -113  then 1 else 0 end) as Count_LTE1800_BW15_Out
			,sum(case when (band= ''LTE1800'' and bandwidth=20) and avg_rsrp >= -113  then 1 else 0 end) as Count_LTE1800_BW20_Out
			,[Region]
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
			,'''+ @week +''' as Meas_Week
			,'''+ @Meas_Round +''' as [Meas_Round]
			,'''+ @Meas_Date +''' as [Meas_Date]
			,'''+ @entidad +''' as Entidad
			, NULL as [Num_Medida]
			,'''+ @monthYearDash +''' as monthYearDash
			, '''+ @weekDash +''' as weekDash
		from 
		(select Longitud_50m,
			Latitud_50m,
			case when  max(RSRP_Outdoor)>='+ @umbralIndoor +'
					then max(RSRP_Indoor)				 
				 Else max(RSRP_Outdoor)
			end as avg_rsrp, 
			max(rsrq_max) as avg_rsrq,
			max(cinr_max) as avg_CINR,
			max(pcobInd) as Indoor_Coverage_Prob,
			Bandwidth,
			Band,
			row_number() over (partition by Longitud_50m, Latitud_50m order by RSRP_Outdoor desc) as id
		from dbo.lcc_cober4G_50x50_'+ @provTable +'_'+@Report+'
		where  operator='''+@operator+''' 
			and frecuencia like '''+@band+''' 
		group by Longitud_50m,
			Latitud_50m, Bandwidth, RSRP_Outdoor,Band
		) t, 
		[AGRIDS].dbo.lcc_parcelas p
	where p.nombre=master.dbo.fn_lcc_getParcel(t.longitud_50m,t.latitud_50m)
	and t.id=1
	group by 	master.dbo.fn_lcc_getParcel(longitud_50m,latitud_50m)
		,[Region]
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
		--,[Grupo_Car]
		,[Carretera_P3]
		,[Ciudad_P3]
		,[Entorno_P3]
	order by 1
	')

	While @idx <= @idx_max 
	begin
		set @band_freq = (select Frequency from #FREQ_TABLE ft Where ft.freq_idx = @idx)
		set @frequency_band = (select Band from #FREQ_TABLE ft Where ft.freq_idx = @idx)
		
		exec ('select 
				'''+ @bd +''' as [Database]
				,'''+ @mnc +''' as mnc
				,master.dbo.fn_lcc_getParcel(longitud_50m,latitud_50m) as parcel
				, '''+@band_freq+''' as [carrier]
				, '''+@frequency_band+''' as [band] 
				, SUM(1) as muestras
				, 10*log10(AVG(POWER(convert(float,10.0), (convert(float,avg_rsrp))/10.0))) as [cobertura AVG]
				, SUM( case when avg_rsrp<-120 then 1  end) as  [<-120]
				, SUM( case when avg_rsrp >= -120 and avg_rsrp< -117 then 1 end) as [<=-120 a <-117]
				, SUM( case when avg_rsrp >= -117 and avg_rsrp< -115 then 1 end) as [<=-117 a <-115]
				, SUM( case when avg_rsrp >= -115 and avg_rsrp< -113 then 1 end) as [<=-115 a <-113]
				, SUM( case when avg_rsrp >= -113 and avg_rsrp< -110 then 1 end) as  [<=-113 a <-110]
				, SUM( case when avg_rsrp >= -110 and avg_rsrp< -107 then 1 end) as [<=-110 a <-107]
				, SUM( case when avg_rsrp >= -107 and avg_rsrp< -105 then 1 end) as [<=-107 a <-105]
				, SUM( case when avg_rsrp >= -105 and avg_rsrp< -103 then 1 end) as  [<=-105 a <-103]
				, SUM( case when avg_rsrp >= -103 and avg_rsrp< -100 then 1 end) as  [<=-103 a <-100]
				, SUM( case when avg_rsrp >= -100 and avg_rsrp< -97 then 1 end) as [<=-100 a <-97]
				, SUM( case when avg_rsrp >= -97 and avg_rsrp< -95 then 1 end) as [<=-97 a <-95]
				, SUM( case when avg_rsrp >= -95 and avg_rsrp< -93 then 1 end) as [<=-95 a <-93]
				, SUM( case when avg_rsrp >= -93 and avg_rsrp< -92 then 1 end) as [<=-93 a <-92]
				, SUM( case when avg_rsrp >= -92 and avg_rsrp< -90 then 1 end) as [<=-92 a <-90]
				, SUM( case when avg_rsrp >= -90 and avg_rsrp< -87 then 1 end) as [<=-90 a <-87]
				, SUM( case when avg_rsrp >= -87 and avg_rsrp< -85 then 1 end) as [<=-87 a <-85]
				, SUM( case when avg_rsrp >= -85 and avg_rsrp< -84 then 1 end) as [<=-85 a <-84]
				, SUM( case when avg_rsrp >= -84 and avg_rsrp< -82 then 1 end) as [<=-84 a <-82]
				, SUM( case when avg_rsrp >= -82 and avg_rsrp< -81 then 1 end) as [<=-82 a <-81]
				, SUM( case when avg_rsrp >= -81 and avg_rsrp< -80 then 1 end) as [<=-81 a <-80]
				, SUM( case when avg_rsrp >= -80 and avg_rsrp< -77 then 1 end) as [<=-80 a <-77]
				, SUM( case when avg_rsrp >= -77 and avg_rsrp< -75 then 1 end) as [<=-77 a <-75]
				, SUM( case when avg_rsrp >= -75 and avg_rsrp< -72 then 1 end) as [<=-75 a <-72]
				, SUM( case when avg_rsrp >= -72 and avg_rsrp< -70 then 1 end) as [<=-72 a <-70]
				, SUM( case when avg_rsrp >= -70 and avg_rsrp< -67 then 1 end) as [<=-70 a <-67]
				, SUM( case when avg_rsrp >= -67 and avg_rsrp< -66 then 1 end) as [<=-67 a <-66]
				, SUM( case when avg_rsrp >= -66 and avg_rsrp< -65 then 1 end) as [<=-66 a <-65]
				, SUM( case when avg_rsrp >= -65 and avg_rsrp< -62 then 1 end) as [<=-65 a <-62]
				, SUM( case when avg_rsrp >= -62 and avg_rsrp< -60 then 1 end) as [<=-62 a <-60]
				, SUM( case when avg_rsrp >= -60 then 1 end) as [>=-60]
				,10*log10(AVG(POWER(convert(float,10.0), (convert(float,avg_rsrq))/10.0))) as avg_rsrq
				, SUM( case when avg_rsrq > -3  then 1 end) as [>-3]
				, SUM( case when avg_rsrq <= -3 and avg_rsrq>-9  then 1 end) as [-3 a -9]
				, SUM( case when avg_rsrq <= -9 and avg_rsrq>-12 then 1 end) as [-9 a -12]
				, SUM( case when avg_rsrq <= -12 then 1 end) as [-12 a -20]
				, 10*log10(AVG(POWER(convert(float,10.0), (convert(float,avg_CINR))/10.0))) as avg_CINR
				, SUM( case when avg_CINR < -10  then 1 end) as [< -10]
				, SUM( case when avg_CINR >= -10 and avg_CINR<0  then 1 end) as [-10 a 0]
				, SUM( case when avg_CINR >= 0 and avg_CINR<10  then 1 end) as [0 a 10]
				, SUM( case when avg_CINR >= 10 and avg_CINR<20 then 1 end) as [10 a 20]
				, SUM( case when avg_CINR >= 20 and avg_CINR<30 then 1 end) as [20 a 30]
				, SUM( case when avg_CINR >= 30  then 1 end) as [> 30]
				, avg(Indoor_Coverage_Prob) as Indoor_Coverage_Prob
				, SUM( case when (avg_rsrp >= -90 and bandwidth=5) then 1 end) as BW_5_CutOff
				, SUM( case when (avg_rsrp >= -90 and bandwidth=10) then 1 end) as BW_10_CutOff
				, SUM( case when (avg_rsrp >= -90 and bandwidth=15) then 1 end) as BW_15_CutOff
				, SUM( case when (avg_rsrp >= -90 and bandwidth=20) then 1 end) as BW_20_CutOff
				,sum(case when (band= ''LTE2100'' and bandwidth=5) then 1 else 0 end) as Count_LTE2100_BW5
				,sum(case when (band= ''LTE2100'' and bandwidth=10) then 1 else 0 end) as Count_LTE2100_BW10
				,sum(case when (band= ''LTE2100'' and bandwidth=15) then 1 else 0 end) as Count_LTE2100_BW15
				,sum(case when (band= ''LTE1800'' and bandwidth=10) then 1 else 0 end) as Count_LTE1800_BW10
				,sum(case when (band= ''LTE1800'' and bandwidth=15) then 1 else 0 end) as Count_LTE1800_BW15
				,sum(case when (band= ''LTE1800'' and bandwidth=20) then 1 else 0 end) as Count_LTE1800_BW20
				,avg(case when (band= ''LTE2100'' and bandwidth=5) then Indoor_Coverage_Prob end) as avg_LTE2100_BW5
				,avg(case when (band= ''LTE2100'' and bandwidth=10) then Indoor_Coverage_Prob end) as avg_LTE2100_BW10
				,avg(case when (band= ''LTE2100'' and bandwidth=15) then Indoor_Coverage_Prob end) as avg_LTE2100_BW15
				,avg(case when (band= ''LTE1800'' and bandwidth=10) then Indoor_Coverage_Prob end) as avg_LTE1800_BW10
				,avg(case when (band= ''LTE1800'' and bandwidth=15) then Indoor_Coverage_Prob end) as avg_LTE1800_BW15
				,avg(case when (band= ''LTE1800'' and bandwidth=20) then Indoor_Coverage_Prob end) as avg_LTE1800_BW20
				,sum(case when (band= ''LTE2100'' and bandwidth=5) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE2100_BW5_Ind
				,sum(case when (band= ''LTE2100'' and bandwidth=10) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE2100_BW10_Ind
				,sum(case when (band= ''LTE2100'' and bandwidth=15) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE2100_BW15_Ind
				,sum(case when (band= ''LTE1800'' and bandwidth=10) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE1800_BW10_Ind
				,sum(case when (band= ''LTE1800'' and bandwidth=15) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE1800_BW15_Ind
				,sum(case when (band= ''LTE1800'' and bandwidth=20) and avg_rsrp >= ' + @4GThresIndoor + ' then 1 else 0 end) as Count_LTE1800_BW20_Ind
				,sum(case when (band= ''LTE2100'' and bandwidth=5) and avg_rsrp >= -113 then 1 else 0 end) as Count_LTE2100_BW5_Out
				,sum(case when (band= ''LTE2100'' and bandwidth=10) and avg_rsrp >= -113  then 1 else 0 end) as Count_LTE2100_BW10_Out
				,sum(case when (band= ''LTE2100'' and bandwidth=15) and avg_rsrp >= -113  then 1 else 0 end) as Count_LTE2100_BW15_Out
				,sum(case when (band= ''LTE1800'' and bandwidth=10) and avg_rsrp >= -113  then 1 else 0 end) as Count_LTE1800_BW10_Out
				,sum(case when (band= ''LTE1800'' and bandwidth=15) and avg_rsrp >= -113  then 1 else 0 end) as Count_LTE1800_BW15_Out
				,sum(case when (band= ''LTE1800'' and bandwidth=20) and avg_rsrp >= -113  then 1 else 0 end) as Count_LTE1800_BW20_Out
				,[Region]
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
				,'''+ @week +''' as Meas_Week
				,'''+ @Meas_Round +''' as [Meas_Round]
				,'''+ @Meas_Date +''' as [Meas_Date]
				,'''+ @entidad +''' as Entidad
				, NULL as [Num_Medida]
				,'''+ @monthYearDash +''' as monthYearDash
				, '''+ @weekDash +''' as weekDash
				into aux_'+@band_freq+'
				from 
			(select Longitud_50m,
				Latitud_50m,
				case when  max(RSRP_Outdoor)>='+ @umbralIndoor +'
						then max(RSRP_Indoor)				 
					 Else max(RSRP_Outdoor)
				end as avg_rsrp, 
				max(rsrq_max) as avg_rsrq,
				max(cinr_max) as avg_CINR,
				max(pcobInd) as Indoor_Coverage_Prob,
				Bandwidth,
				band,
				row_number() over (partition by Longitud_50m, Latitud_50m order by RSRP_Outdoor desc) as id
			from dbo.lcc_cober4G_50x50_'+ @provTable +'_'+@Report+'
			where  operator='''+@operator+''' 
				and frecuencia like '''+@band_freq+''' 
			group by Longitud_50m,
				Latitud_50m, Bandwidth, RSRP_Outdoor,band
			) t, 
			[AGRIDS].dbo.lcc_parcelas p
			where p.nombre=master.dbo.fn_lcc_getParcel(t.longitud_50m,t.latitud_50m)
			and t.id=1
			group by 	master.dbo.fn_lcc_getParcel(longitud_50m,latitud_50m)
				,[Region]
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
				--,[Grupo_Car]
				,[Carretera_P3]
				,[Ciudad_P3]
				,[Entorno_P3]')

		if @idx=1  
		BEGIN
				exec('select sq.* into results_final from
					  (select * from #results
					   UNION ALL
					   select * from aux_'+@band_freq+') sq')
        END
		ELSE		
		BEGIN
			    select * into results_aux from results_final
				drop table results_final

				exec('select sq.* into results_final from
					  (select * from results_aux
					   UNION ALL
					   select * from aux_'+@band_freq+') sq')

				drop table results_aux
        END;

		exec('drop table aux_'+@band_freq)
		set @idx = @idx + 1
	end

--Sacamos tabla resultado
select * from results_final order by carrier

--Borramos tablas intermedias
Drop table #FREQ_TABLE
Drop table #results
drop table results_final