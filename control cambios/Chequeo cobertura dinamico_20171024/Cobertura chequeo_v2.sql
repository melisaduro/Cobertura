/****** Script para el comando SelectTopNRows de SSMS  ******/
SELECT avg([cobertura AVG])
      ,avg([cobertura AVG GSM])
      ,avg([cobertura AVG DCS])
	  ,sum([coverage_den]) as [coverage2G_den]
	  ,case when sum([2G_Samples_ProbCobInd]) is not null then sum([coverage_den]) end [coverage2G_den_ProbCob]	
	  ,sum([samples_GSMcov_num]) as [samples_GSMcov_num]
	  ,sum(samples_DCScov_num) as samples_DCScov_num
	  ,sum(samples_GSMDCScov_num) as samples_GSMDCScov_num
	  ,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG],0)))/10.0)*samplesAVG)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*([coverage_den]-samplesAVG)) as 'cobertura_AVG_2G_Num'
	  ,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG GSM],0)))/10.0)*samplesAVG_GSM)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*([coverage_den]-samplesAVG_GSM)) as 'cobertura_AVG_GSM_Num'
	  ,sum(POWER(convert(float,10.0),(convert(float,isnull([cobertura AVG DCS],0)))/10.0)*samplesAVG_DCS)+sum(POWER(convert(float,10.0),(convert(float,-110))/10.0)*([coverage_den]-samplesAVG_DCS)) as 'cobertura_AVG_DCS_Num'
      
  FROM [AGGRCoverage].[dbo].vlcc_cober2G_bands
  where entidad='alicante'
  and meas_round='fy1718_h1'
  and mnc=1
  and report_type='mun'