/****** Script para el comando SelectTopNRows de SSMS  ******/
use dashboard
exec dbo.sp_lcc_dropifexists '_temp_4g'
SELECT v.entidad,
		case 
			when v.mnc='01' then 'VODAFONE'
			when v.mnc='07' then 'MOVISTAR'
			when v.mnc='03' then 'ORANGE'
			when v.mnc='04' then 'YOIGO'
		end as Operator,
		sum([coverage_den]) as [coverage4G_den]
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG],0)))/10.0)*samplesAVG)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG)) as 'cobertura_AVG_4G_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG L2600],0)))/10.0)*samplesAVG_L2600)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_L2600)) as 'cobertura_AVG_L2600_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG L2100],0)))/10.0)*samplesAVG_L2100)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_L2100)) as 'cobertura_AVG_L2100_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG L1800],0)))/10.0)*samplesAVG_L1800)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_L1800)) as 'cobertura_AVG_L1800_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG L800],0)))/10.0)*samplesAVG_L800)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_L800)) as 'cobertura_AVG_L800_Num'
		
		,sum([LTE_ProbCobInd]*[LTE_Samples_ProbCobInd]) as [4G_ProbCobInd]
		,case when sum(LTE_Samples_ProbCobInd) is not null then sum([coverage_den]) end [4G_Samples_ProbCobInd]	
		,sum([LTE2600_ProbCobInd]*[LTE2600_Samples_ProbCobInd]) as [LTE2600_ProbCobInd]
		,sum([LTE2100_ProbCobInd]*[LTE2100_Samples_ProbCobInd]) as [LTE2100_ProbCobInd]
		,sum([LTE2100_BW5_ProbCobInd]*[LTE2100_BW5_Samples_ProbCobInd]) as [LTE2100_BW5_ProbCobInd]
		,sum([LTE2100_BW10_ProbCobInd]*[LTE2100_BW10_Samples_ProbCobInd]) as [LTE2100_BW10_ProbCobInd]
		,sum([LTE2100_BW15_ProbCobInd]*[LTE2100_BW15_Samples_ProbCobInd]) as [LTE2100_BW15_ProbCobInd]
		,sum([LTE1800_ProbCobInd]*[LTE1800_Samples_ProbCobInd]) as [LTE1800_ProbCobInd]
		,sum([LTE1800_BW10_ProbCobInd]*[LTE1800_BW10_Samples_ProbCobInd]) as [LTE1800_BW10_ProbCobInd]
		,sum([LTE1800_BW15_ProbCobInd]*[LTE1800_BW15_Samples_ProbCobInd]) as [LTE1800_BW15_ProbCobInd]
		,sum([LTE1800_BW20_ProbCobInd]*[LTE1800_BW20_Samples_ProbCobInd]) as [LTE1800_BW20_ProbCobInd]
		,sum([LTE800_ProbCobInd]*[LTE800_Samples_ProbCobInd]) as [LTE800_ProbCobInd]
		,sum([LTE800_1800_ProbCobInd]*[LTE800_1800_Samples_ProbCobInd]) as [LTE800_1800_ProbCobInd]
		,sum([LTE800_2100_ProbCobInd]*[LTE800_2100_Samples_ProbCobInd]) as [LTE800_2100_ProbCobInd]
		,sum([LTE800_2600_ProbCobInd]*[LTE800_2600_Samples_ProbCobInd]) as [LTE800_2600_ProbCobInd]
		,sum([LTE1800_2100_ProbCobInd]*[LTE1800_2100_Samples_ProbCobInd]) as [LTE1800_2100_ProbCobInd]
		,sum([LTE1800_2600_ProbCobInd]*[LTE1800_2600_Samples_ProbCobInd]) as [LTE1800_2600_ProbCobInd]
		,sum([LTE2100_2600_ProbCobInd]*[LTE2100_2600_Samples_ProbCobInd]) as [LTE2100_2600_ProbCobInd]
		,sum([LTE800_1800_2100_ProbCobInd]*[LTE800_1800_2100_Samples_ProbCobInd]) as [LTE800_1800_2100_ProbCobInd]
		,sum([LTE800_1800_2600_ProbCobInd]*[LTE800_1800_2600_Samples_ProbCobInd]) as [LTE800_1800_2600_ProbCobInd]
		,sum([LTE800_2100_2600_ProbCobInd]*[LTE800_2100_2600_Samples_ProbCobInd]) as [LTE800_2100_2600_ProbCobInd]
		,sum([LTE1800_2100_2600_ProbCobInd]*[LTE1800_2100_2600_Samples_ProbCobInd]) as [LTE1800_2100_2600_ProbCobInd]
		

  into [dashboard].dbo._temp_4g	
  FROM [AGGRCoverage].[dbo].vlcc_cober4G_bands v 

  where v.entidad='alicante'
  and v.meas_round='fy1718_h1'
  and v.report_type='mun'
  group by v.entidad,v.mnc	


  select entidad + '- Curves',
		 operator,
		 10*log10([cobertura_AVG_4G_Num]/[coverage4G_den]) as [RSRP 4G Average],
		 10*log10([cobertura_AVG_L2600_Num]/[coverage4G_den]) as [RSRP L2600 Average],
		 10*log10([cobertura_AVG_L2100_Num]/[coverage4G_den]) as [RSRP L2100 Average],
		 10*log10([cobertura_AVG_L1800_Num]/[coverage4G_den]) as [RSRP L1800 Average],
		 10*log10([cobertura_AVG_L800_Num]/[coverage4G_den]) as [RSRP L800 Average],

		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[4G_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage 4G],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2100_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2100],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2100_BW5_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2100 BW5],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2100_BW10_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2100 BW10],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2100_BW15_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2100 BW15],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_BW10_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 BW10],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_BW15_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 BW15],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_BW20_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 BW20],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_1800_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE1800],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_2100_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE2100],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_2100_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 & LTE2100],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 & LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2100_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2100 & LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_1800_2100_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE1800 & LTE2100],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_1800_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE1800 & LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_2100_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE2100 & LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_2100_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 & LTE2100 & LTE2600],

		 '' as [Number of Best Servers 4G]

		 from [dashboard].dbo._temp_4g v
		 order by case 
			when v.operator='VODAFONE' then 1
			when v.operator='MOVISTAR' then 2
			when v.operator='ORANGE' then 3
			when v.operator='YOIGO' then 4
		end

exec dbo.sp_lcc_dropifexists '_temp_4g'
SELECT v.entidad,
		case 
			when v.mnc='01' then 'VODAFONE'
			when v.mnc='07' then 'MOVISTAR'
			when v.mnc='03' then 'ORANGE'
			when v.mnc='04' then 'YOIGO'
		end as Operator,
		sum([coverage_den]) as [coverage4G_den]
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG],0)))/10.0)*samplesAVG)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG)) as 'cobertura_AVG_4G_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG L2600],0)))/10.0)*samplesAVG_L2600)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_L2600)) as 'cobertura_AVG_L2600_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG L2100],0)))/10.0)*samplesAVG_L2100)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_L2100)) as 'cobertura_AVG_L2100_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG L1800],0)))/10.0)*samplesAVG_L1800)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_L1800)) as 'cobertura_AVG_L1800_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG L800],0)))/10.0)*samplesAVG_L800)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_L800)) as 'cobertura_AVG_L800_Num'
		
		,sum(t.[RSRP_LTE_Samples]) as [RSRP_LTE_Samples]
		,sum(t.[RSRP_LTE2600_Samples]) as [RSRP_LTE2600_Samples]
		,sum(t.[RSRP_LTE2100_Samples]) as [RSRP_LTE2100_Samples]
		,sum(t.[RSRP_LTE1800_Samples]) as [RSRP_LTE1800_Samples]
		,sum(t.[RSRP_LTE800_Samples]) as [RSRP_LTE800_Samples]
		,sum(t.[LTE]) as [4G_ProbCobInd]
		,sum(t.[LTE2600]) as LTE2600_ProbCobInd
		,sum(t.[LTE2100]) as LTE2100_ProbCobInd
		,sum(t.[LTE2100_BW5]) as LTE2100_BW5_ProbCobInd
		,sum(t.[LTE2100_BW10]) as LTE2100_BW10_ProbCobInd
		,sum(t.[LTE2100_BW15]) as LTE2100_BW15_ProbCobInd
		,sum(t.[LTE1800]) as LTE1800_ProbCobInd
		,sum(t.[LTE1800_BW10]) as LTE1800_BW10_ProbCobInd
		,sum(t.[LTE1800_BW15]) as LTE1800_BW15_ProbCobInd
		,sum(t.[LTE1800_BW20]) as LTE1800_BW20_ProbCobInd
		,sum(t.[LTE800]) as LTE800_ProbCobInd
		,sum(t.[LTE800_1800]) as LTE800_1800_ProbCobInd
		,sum(t.[LTE800_2100]) as LTE800_2100_ProbCobInd
		,sum(t.[LTE800_2600]) as LTE800_2600_ProbCobInd
		,sum(t.[LTE1800_2100]) as LTE1800_2100_ProbCobInd
		,sum(t.[LTE1800_2600]) as LTE1800_2600_ProbCobInd
		,sum(t.[LTE2100_2600]) as LTE2100_2600_ProbCobInd
		,sum(t.[LTE800_1800_2100]) as LTE800_1800_2100_ProbCobInd
		,sum(t.[LTE800_1800_2600]) as LTE800_1800_2600_ProbCobInd
		,sum(t.[LTE800_2100_2600]) as LTE800_2100_2600_ProbCobInd
		,sum(t.[LTE1800_2100_2600]) as LTE1800_2100_2600_ProbCobInd
		,sum(t.[LTE_Samples]) as [4G_Samples_ProbCobInd]
		
		
  into [dashboard].dbo._temp_4g	
  FROM [AGGRCoverage].[dbo].vlcc_cober4G_bands v 
   inner join [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Indoor t 
  on v.parcel=t.parcel and v.mnc=t.mnc and v.Date_Reporting=t.Date_Reporting and v.Meas_Round=t.meas_round
	 and v.Week_Reporting=t.Week_Reporting and v.Entidad=t.Entidad and v.Report_type=t.Report_type

  where v.entidad='alicante'
  and v.meas_round='fy1718_h1'
  and v.report_type='mun'
  group by v.entidad,v.mnc
  --select * from _temp_4g

  select entidad + '- Indoor',
		 operator,
		 10*log10([cobertura_AVG_4G_Num]/[coverage4G_den]) as [RSRP 4G Average],
		 10*log10([cobertura_AVG_L2600_Num]/[coverage4G_den]) as [RSRP L2600 Average],
		 10*log10([cobertura_AVG_L2100_Num]/[coverage4G_den]) as [RSRP L2100 Average],
		 10*log10([cobertura_AVG_L1800_Num]/[coverage4G_den]) as [RSRP L1800 Average],
		 10*log10([cobertura_AVG_L800_Num]/[coverage4G_den]) as [RSRP L800 Average],

		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[4G_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage 4G],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2100_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2100],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2100_BW5_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2100 BW5],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2100_BW10_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2100 BW10],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2100_BW15_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2100 BW15],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_BW10_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 BW10],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_BW15_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 BW15],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_BW20_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 BW20],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_1800_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE1800],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_2100_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE2100],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_2100_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 & LTE2100],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 & LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE2100_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE2100 & LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_1800_2100_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE1800 & LTE2100],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_1800_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE1800 & LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE800_2100_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE800 & LTE2100 & LTE2600],
		 convert(varchar(256),isnull(case when [4G_Samples_ProbCobInd]>0 then 100.0*[LTE1800_2100_2600_ProbCobInd]/[4G_Samples_ProbCobInd] end,0)) + '%' as [Coverage LTE1800 & LTE2100 & LTE2600],

		 '' as [Number of Best Servers 4G]

		 from [dashboard].dbo._temp_4g v
		 order by case 
			when v.operator='VODAFONE' then 1
			when v.operator='MOVISTAR' then 2
			when v.operator='ORANGE' then 3
			when v.operator='YOIGO' then 4
		end
exec dbo.sp_lcc_dropifexists '_temp_4g'