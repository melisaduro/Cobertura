/****** Script para el comando SelectTopNRows de SSMS  ******/
use dashboard
exec dbo.sp_lcc_dropifexists '_temp_3g'
SELECT v.entidad,
		case 
			when v.mnc='01' then 'VODAFONE'
			when v.mnc='07' then 'MOVISTAR'
			when v.mnc='03' then 'ORANGE'
			when v.mnc='04' then 'YOIGO'
		end as Operator,
		sum([coverage_den]) as [coverage3G_den]
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG],0)))/10.0)*samplesAVG)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG)) as 'cobertura_AVG_3G_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG U2100],0)))/10.0)*samplesAVG_U2100)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_U2100)) as 'cobertura_AVG_U2100_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG U900],0)))/10.0)*samplesAVG_U900)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_U900)) as 'cobertura_AVG_U900_Num'
		,sum([Pollution]) as [% Pilot Pollution]
		,sum([Pollution BS Curves]) as [% Pilot Pollution BS]		
		,sum([UMTS_ProbCobInd]*[UMTS_Samples_ProbCobInd]) as [3G_ProbCobInd]
		,case when sum(UMTS_Samples_ProbCobInd) is not null then sum([coverage_den]) end [3G_Samples_ProbCobInd]	
		,sum(UMTS2100_ProbCobInd*UMTS2100_Samples_ProbCobInd) as UMTS2100_ProbCobInd
		,sum(UMTS2100_F1_ProbCobInd*UMTS2100_F1_Samples_ProbCobInd) as UMTS2100_F1_ProbCobInd
		,sum(UMTS2100_F2_ProbCobInd*UMTS2100_F2_Samples_ProbCobInd) as UMTS2100_F2_ProbCobInd
		,sum(UMTS2100_F3_ProbCobInd*UMTS2100_F3_Samples_ProbCobInd) as UMTS2100_F3_ProbCobInd
		,sum(UMTS2100_Dual_Carrier_ProbCobInd*UMTS2100_Dual_Carrier_Samples_ProbCobInd) as UMTS2100_Dual_Carrier_ProbCobInd
		,sum(UMTS2100_P1_ProbCobInd*UMTS2100_P1_Samples_ProbCobInd) as UMTS2100_P1_ProbCobInd
		,sum(UMTS2100_P2_ProbCobInd*UMTS2100_P2_Samples_ProbCobInd) as UMTS2100_P2_ProbCobInd
		,sum(UMTS2100_P3_ProbCobInd*UMTS2100_P3_Samples_ProbCobInd) as UMTS2100_P3_ProbCobInd
		,sum(UMTS900_ProbCobInd*UMTS900_Samples_ProbCobInd) as UMTS900_ProbCobInd
		,sum(UMTS900_F1_ProbCobInd*UMTS900_F1_Samples_ProbCobInd) as UMTS900_F1_ProbCobInd
		,sum(UMTS900_F2_ProbCobInd*UMTS900_F2_Samples_ProbCobInd) as UMTS900_F2_ProbCobInd
		,sum(UMTS900_P1_ProbCobInd*UMTS900_P1_Samples_ProbCobInd) as UMTS900_P1_ProbCobInd
		,sum(UMTS900_P2_ProbCobInd*UMTS900_P2_Samples_ProbCobInd) as UMTS900_P2_ProbCobInd

  into [dashboard].dbo._temp_3g	
  FROM [AGGRCoverage].[dbo].vlcc_cober3G_bands v 

  where v.entidad='alicante'
  and v.meas_round='fy1718_h1'
  and v.report_type='mun'
  group by v.entidad,v.mnc

  select entidad + '- Curves',
		 operator,
		 10*log10([cobertura_AVG_3G_Num]/[coverage3G_den]) as [RSCP 3G Average],
		 10*log10([cobertura_AVG_U2100_Num]/[coverage3G_den]) as [RSCP UMTS2100 Average],
		 10*log10([cobertura_AVG_U900_Num]/[coverage3G_den]) as [RSCP UMTS900 Average],
		 case when [coverage3G_den]>0 then 1.0*([% Pilot Pollution])/(1.0*([coverage3G_den])) end as [% Pilot Pollution],
		 case when [coverage3G_den]>0 then 1.0*([% Pilot Pollution BS])/(1.0*([coverage3G_den])) end as [% Pilot Pollution BS],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[3G_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage 3G],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS2100_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS2100_F1_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 F1],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS2100_F2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 F2],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS2100_F3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 F3],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS2100_Dual_Carrier_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 Dual Carrier],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS2100_P1_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 P1],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS2100_P2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 P2],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS2100_P3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 P3],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS900_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS900_F1_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 F1],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS900_F2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 F2],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS900_P1_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 P1],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100*[UMTS900_P2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 P2],
		 '' as [Number of Best Servers 3G]

		 from [dashboard].dbo._temp_3g v
		 order by case 
			when v.operator='VODAFONE' then 1
			when v.operator='MOVISTAR' then 2
			when v.operator='ORANGE' then 3
			when v.operator='YOIGO' then 4
		end

exec dbo.sp_lcc_dropifexists '_temp_3g'
SELECT v.entidad,
		case 
			when v.mnc='01' then 'VODAFONE'
			when v.mnc='07' then 'MOVISTAR'
			when v.mnc='03' then 'ORANGE'
			when v.mnc='04' then 'YOIGO'
		end as Operator,
		sum([coverage_den]) as [coverage3G_den]
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG],0)))/10.0)*samplesAVG)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG)) as 'cobertura_AVG_3G_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG U2100],0)))/10.0)*samplesAVG_U2100)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_U2100)) as 'cobertura_AVG_U2100_Num'
		,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG U900],0)))/10.0)*samplesAVG_U900)+sum(POWER(convert(float,10.0),(convert(float,-140))/10.0)*([coverage_den]-samplesAVG_U900)) as 'cobertura_AVG_U900_Num'
		,sum(t.[Pollution]) as [% Pilot Pollution]
		,sum(t.[Pollution BS RSCP]) as [% Pilot Pollution BS]
		,sum(t.[UMTS]) as [3G_ProbCobInd]
		,sum(t.[UMTS2100]) as UMTS2100_ProbCobInd
		,sum(t.[UMTS2100_Carrier_only]) as UMTS2100_Carrier_only_ProbCobInd
		,sum(t.[UMTS2100_F1]) as UMTS2100_F1_ProbCobInd
		,sum(t.[UMTS2100_F2]) as UMTS2100_F2_ProbCobInd
		,sum(t.[UMTS2100_F3]) as UMTS2100_F3_ProbCobInd	
		,sum(t.[UMTS2100_P1]) as UMTS2100_P1_ProbCobInd
		,sum(t.[UMTS2100_P2]) as UMTS2100_P2_ProbCobInd
		,sum(t.[UMTS2100_P3]) as UMTS2100_P3_ProbCobInd	
		,sum(t.[UMTS2100_Dual_Carrier]) as UMTS2100_Dual_Carrier_ProbCobInd
		,sum(t.[UMTS2100_F1_F2]) as UMTS2100_F1_F2_ProbCobInd
		,sum(t.[UMTS2100_F1_F3]) as UMTS2100_F1_F3_ProbCobInd
		,sum(t.[UMTS2100_F2_F3]) as UMTS2100_F2_F3_ProbCobInd
		,sum(t.[UMTS2100_F1_F2_F3]) as UMTS2100_F1_F2_F3_ProbCobInd
		,sum(t.[UMTS900]) as UMTS900_ProbCobInd
		,sum(t.[UMTS900_F1]) as UMTS900_F1_ProbCobInd
		,sum(t.[UMTS900_F2]) as UMTS900_F2_ProbCobInd
		,sum(t.[UMTS900_P1]) as UMTS900_P1_ProbCobInd
		,sum(t.[UMTS900_P2]) as UMTS900_P2_ProbCobInd
		,sum(t.[UMTS900_U2100_Carrier_only]) as UMTS900_U2100_Carrier_only_ProbCobInd
		,sum(t.[UMTS900_U2100_F1]) as UMTS900_U2100_F1_ProbCobInd
		,sum(t.[UMTS900_U2100_F2]) as UMTS900_U2100_F2_ProbCobInd
		,sum(t.[UMTS900_U2100_F3]) as UMTS900_U2100_F3_ProbCobInd
		,sum(t.[UMTS900_U2100_Dual_Carrier]) as UMTS900_U2100_Dual_Carrier_ProbCobInd
		,sum(t.[UMTS900_U2100_F1_F2]) as UMTS900_U2100_F1_F2_ProbCobInd
		,sum(t.[UMTS900_U2100_F1_F3]) as UMTS900_U2100_F1_F3_ProbCobInd
		,sum(t.[UMTS900_U2100_F2_F3]) as UMTS900_U2100_F2_F3_ProbCobInd
		,sum(t.[UMTS900_U2100_F1_F2_F3]) as UMTS900_U2100_F1_F2_F3_ProbCobInd
		,sum(t.[UMTS_Samples]) as [3G_Samples_ProbCobInd]
		
		
  into [dashboard].dbo._temp_3g	
  FROM [AGGRCoverage].[dbo].vlcc_cober3G_bands v 
   inner join [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Indoor t 
  on v.parcel=t.parcel and v.mnc=t.mnc and v.Date_Reporting=t.Date_Reporting and v.Meas_Round=t.meas_round
	 and v.Week_Reporting=t.Week_Reporting and v.Entidad=t.Entidad and v.Report_type=t.Report_type

  where v.entidad='alicante'
  and v.meas_round='fy1718_h1'
  and v.report_type='mun'
  group by v.entidad,v.mnc
  --select * from _temp_3g

  select entidad + '- Indoor',
		 operator,
		 10*log10([cobertura_AVG_3G_Num]/[coverage3G_den]) as [RSCP 3G Average],
		 10*log10([cobertura_AVG_U2100_Num]/[coverage3G_den]) as [RSCP UMTS2100 Average],
		 10*log10([cobertura_AVG_U900_Num]/[coverage3G_den]) as [RSCP UMTS900 Average],
		 case when [coverage3G_den]>0 then 1.0*([% Pilot Pollution])/(1.0*([coverage3G_den])) end as [% Pilot Pollution],
		 case when [coverage3G_den]>0 then 1.0*([% Pilot Pollution BS])/(1.0*([coverage3G_den])) end as [% Pilot Pollution BS],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[3G_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage 3G],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_Carrier_only_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 Carrier only],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_F1_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 F1],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_F2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 F2],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_F3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 F3],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_Dual_Carrier_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 Dual Carrier],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_F1_F2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 F1 & F2],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_F1_F3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 F1 & F3],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_F2_F3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 F2 & F3],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_F1_F2_F3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 F1 & F2 & F3],		 
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_P1_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 P1],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_P2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 P2],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS2100_P3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS2100 P3],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_F1_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 F1],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_F2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 F2],

		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_U2100_Carrier_only_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 & UMTS 2100 (Carrier only)],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_U2100_F1_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 & UMTS 2100 F1],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_U2100_F2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 & UMTS 2100 F2],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_U2100_F3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 & UMTS 2100 F3],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_U2100_Dual_Carrier_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 & UMTS 2100 (Dual Carrier)],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_U2100_F1_F2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 & UMTS 2100 (F1 & F2)],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_U2100_F1_F3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 & UMTS 2100 (F1 & F3)],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_U2100_F2_F3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 & UMTS 2100 (F2 & F3)],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_U2100_F1_F2_F3_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 & UMTS 2100 (F1 & F2 & F3)],

		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_P1_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 P1],
		 convert(varchar(256),isnull(case when [3G_Samples_ProbCobInd]>0 then 100.0*[UMTS900_P2_ProbCobInd]/[3G_Samples_ProbCobInd] end,0)) + '%' as [Coverage UMTS900 P2],
		 '' as [Number of Best Servers 3G]

		 from [dashboard].dbo._temp_3g v
		 order by case 
			when v.operator='VODAFONE' then 1
			when v.operator='MOVISTAR' then 2
			when v.operator='ORANGE' then 3
			when v.operator='YOIGO' then 4
		end
exec dbo.sp_lcc_dropifexists '_temp_3g'