use dashboard
exec dbo.sp_lcc_dropifexists '_temp_4G'
exec dbo.sp_lcc_dropifexists '_temp_3G'
exec dbo.sp_lcc_dropifexists '_temp_2G'

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
		

  into [dashboard].dbo._temp_4G	
  FROM [AGGRCoverage].[dbo].vlcc_cober4G_bands v 

  where v.entidad='alicante'
  and v.meas_round='fy1718_h1'
  and v.report_type='mun'
  and v.date_reporting='17_08'
  group by v.entidad,v.mnc	

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

  into [dashboard].dbo._temp_3G
  FROM [AGGRCoverage].[dbo].vlcc_cober3G_bands v 

  where v.entidad='alicante'
  and v.meas_round='fy1718_h1'
  and v.report_type='mun'
  and v.date_reporting='17_08'
  group by v.entidad,v.mnc

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

  into [dashboard].dbo._temp_2G	
  FROM [AGGRCoverage].[dbo].vlcc_cober2G_bands v 

  where v.entidad='alicante'
  and v.meas_round='fy1718_h1'
  and v.report_type='mun'
  and v.date_reporting='17_08'
  group by v.entidad,v.mnc


  select v1.entidad + '- Curves',
		 v1.operator,
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

		 '' as [Number of Best Servers 4G],

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
		 '' as [Number of Best Servers 3G],

		 10*log10([cobertura_AVG_2G_Num]/[coverage2G_den]) as [RxLev 2G Average],
		 10*log10([cobertura_AVG_GSM_Num]/[coverage2G_den]) as [RxLev GSM Average],
		 10*log10([cobertura_AVG_DCS_Num]/[coverage2G_den]) as [RxLev DCS Average],
		 convert(varchar(256),isnull(case when [2G_Samples_ProbCobInd]>0 then 100*[2G_ProbCobInd]/[2G_Samples_ProbCobInd] end,0)) + '%' as [Coverage 2G],
		 convert(varchar(256),isnull(case when [coverage2G_den]>0 then 100*[GSM_DCS_ProbCobInd]/[coverage2G_den] end,0)) + '%' as [Coverage GSM & DCS],
		 convert(varchar(256),isnull(case when [GSM_Samples_ProbCobInd]>0 then 100*[GSM_ProbCobInd]/[GSM_Samples_ProbCobInd] end,0)) + '%' as [Coverage GSM],
		 convert(varchar(256),isnull(case when [coverage2G_den]>0 then 100*[DCS_ProbCobInd]/[coverage2G_den] end,0)) + '%' as [Coverage DCS],
		 '' as [Number of Best Servers 2G]

		 from [dashboard].dbo._temp_4g v1, [dashboard].dbo._temp_3g v2, [dashboard].dbo._temp_2g v3
		 where v1.entidad=v2.entidad and v1.entidad=v3.entidad and v2.entidad=v3.entidad 
		 and v1.operator=v2.operator and v1.operator=v3.operator and v2.operator=v3.operator
		 order by case 
			when v1.operator='VODAFONE' then 1
			when v1.operator='MOVISTAR' then 2
			when v1.operator='ORANGE' then 3
			when v1.operator='YOIGO' then 4
		end

exec dbo.sp_lcc_dropifexists '_temp_4G'
exec dbo.sp_lcc_dropifexists '_temp_3G'
exec dbo.sp_lcc_dropifexists '_temp_2G'