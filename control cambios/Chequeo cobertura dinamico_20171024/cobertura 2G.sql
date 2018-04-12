/****** Script para el comando SelectTopNRows de SSMS  ******/
use dashboard
exec dbo.sp_lcc_dropifexists '_temp_2g'
SELECT v.entidad,
		case 
			when v.mnc='01' then 'VODAFONE'
			when v.mnc='07' then 'MOVISTAR'
			when v.mnc='03' then 'ORANGE'
			when v.mnc='04' then 'YOIGO'
		end as Operator,
		sum([coverage_den]) as [coverage2G_den]
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG],0)))/10.0)*samplesAVG)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*([coverage_den]-samplesAVG)) as 'cobertura_AVG_2G_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG GSM],0)))/10.0)*samplesAVG_GSM)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*([coverage_den]-samplesAVG_GSM)) as 'cobertura_AVG_GSM_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG DCS],0)))/10.0)*samplesAVG_DCS)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*([coverage_den]-samplesAVG_DCS)) as 'cobertura_AVG_DCS_Num'
		,sum([2G_ProbCobInd]*[2G_Samples_ProbCobInd]) as [2G_ProbCobInd]
		,sum(GSM_ProbCobInd*GSM_Samples_ProbCobInd) as GSM_ProbCobInd
		,sum(DCS_ProbCobInd*DCS_Samples_ProbCobInd) as DCS_ProbCobInd
		,sum(GSM_DCS_ProbCobInd*GSM_DCS_Samples_ProbCobInd) as GSM_DCS_ProbCobInd
		,sum([2G_Samples_ProbCobInd]) as [2G_Samples_ProbCobInd]
		,sum(GSM_Samples_ProbCobInd) as GSM_Samples_ProbCobInd

  into [dashboard].dbo._temp_2g	
  FROM [AGGRCoverage].[dbo].vlcc_cober2G_bands v 

  where v.entidad='alicante'
  and v.meas_round='fy1718_h1'
  and v.report_type='mun'
  group by v.entidad,v.mnc

  
  select entidad + '- Curves',
		 operator,
		 10*log10([cobertura_AVG_2G_Num]/[coverage2G_den]) as [RxLev 2G Average],
		 10*log10([cobertura_AVG_GSM_Num]/[coverage2G_den]) as [RxLev GSM Average],
		 10*log10([cobertura_AVG_DCS_Num]/[coverage2G_den]) as [RxLev DCS Average],
		 convert(varchar(256),isnull(case when [2G_Samples_ProbCobInd]>0 then 100*[2G_ProbCobInd]/[2G_Samples_ProbCobInd] end,0)) + '%' as [Coverage 2G],
		 convert(varchar(256),isnull(case when [coverage2G_den]>0 then 100*[GSM_DCS_ProbCobInd]/[coverage2G_den] end,0)) + '%' as [Coverage GSM & DCS],
		 convert(varchar(256),isnull(case when [GSM_Samples_ProbCobInd]>0 then 100*[GSM_ProbCobInd]/[GSM_Samples_ProbCobInd] end,0)) + '%' as [Coverage GSM],
		 convert(varchar(256),isnull(case when [coverage2G_den]>0 then 100*[DCS_ProbCobInd]/[coverage2G_den] end,0)) + '%' as [Coverage DCS],
		 '' as [Number of Best Servers 2G]

		 from [dashboard].dbo._temp_2g v
		 order by case 
			when v.operator='VODAFONE' then 1
			when v.operator='MOVISTAR' then 2
			when v.operator='ORANGE' then 3
			when v.operator='YOIGO' then 4
		end

exec dbo.sp_lcc_dropifexists '_temp_2g'
SELECT v.entidad,
		case 
			when v.mnc='01' then 'VODAFONE'
			when v.mnc='07' then 'MOVISTAR'
			when v.mnc='03' then 'ORANGE'
			when v.mnc='04' then 'YOIGO'
		end as Operator,
		sum([coverage_den]) as [coverage2G_den]
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG],0)))/10.0)*samplesAVG)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*([coverage_den]-samplesAVG)) as 'cobertura_AVG_2G_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG GSM],0)))/10.0)*samplesAVG_GSM)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*([coverage_den]-samplesAVG_GSM)) as 'cobertura_AVG_GSM_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG DCS],0)))/10.0)*samplesAVG_DCS)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*([coverage_den]-samplesAVG_DCS)) as 'cobertura_AVG_DCS_Num'
			
		,sum(t.[2G]) as [2G_ProbCobInd]
		,sum(t.[GSM]) as GSM_ProbCobInd
		,sum(t.[DCS]) as DCS_ProbCobInd
		,sum(t.[GSM_DCS]) as GSM_DCS_ProbCobInd
		,sum(t.[2G_Samples]) as [2G_Samples_ProbCobInd]
		

  into [dashboard].dbo._temp_2g	
  FROM [AGGRCoverage].[dbo].vlcc_cober2G_bands v 
   inner join [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Indoor t 
  on v.parcel=t.parcel and v.mnc=t.mnc and v.Date_Reporting=t.Date_Reporting and v.Meas_Round=t.meas_round
	 and v.Week_Reporting=t.Week_Reporting and v.Entidad=t.Entidad and v.Report_type=t.Report_type
	
  where v.entidad='alicante'
  and v.meas_round='fy1718_h1'
  and v.report_type='mun'
  group by v.entidad,v.mnc

  
  select entidad + '- Indoor',
		 operator,
		 10*log10([cobertura_AVG_2G_Num]/[coverage2G_den]) as [RxLev 2G Average],
		 10*log10([cobertura_AVG_GSM_Num]/[coverage2G_den]) as [RxLev GSM Average],
		 10*log10([cobertura_AVG_DCS_Num]/[coverage2G_den]) as [RxLev DCS Average],
		 convert(varchar(256),isnull(case when [2G_Samples_ProbCobInd]>0 then 100.0*[2G_ProbCobInd]/[2G_Samples_ProbCobInd] end,0)) + '%' as [Coverage 2G],
		 convert(varchar(256),isnull(case when [2G_Samples_ProbCobInd]>0 then 100.0*[GSM_DCS_ProbCobInd]/[2G_Samples_ProbCobInd] end,0)) + '%' as [Coverage GSM & DCS],
		 convert(varchar(256),isnull(case when [2G_Samples_ProbCobInd]>0 then 100.0*[GSM_ProbCobInd]/[2G_Samples_ProbCobInd] end,0)) + '%' as [Coverage GSM],
		 convert(varchar(256),isnull(case when [2G_Samples_ProbCobInd]>0 then 100.0*[DCS_ProbCobInd]/[2G_Samples_ProbCobInd] end,0)) + '%' as [Coverage DCS],
		 '' as [Number of Best Servers 2G]

		 from [dashboard].dbo._temp_2g v
		 order by case 
			when v.operator='VODAFONE' then 1
			when v.operator='MOVISTAR' then 2
			when v.operator='ORANGE' then 3
			when v.operator='YOIGO' then 4
		end

exec dbo.sp_lcc_dropifexists '_temp_2g'