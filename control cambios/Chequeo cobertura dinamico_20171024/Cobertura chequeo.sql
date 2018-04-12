select 
	mnc,Meas_Round, Date_Reporting, Week_Reporting, entidad,Report_Type
	,c.Region_VF, c.Region_OSP
	,max ([2G_Samples]) as coverage_den
	,sum([2G]) as samples_2Gcov_num
	,sum([GSM]) as samples_GSMcov_num
	,sum([DCS]) as samples_DCScov_num
	,sum([GSM_DCS]) as samples_GSMDCScov_num
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,[RxLev_2G]))/10.0)*[RxLev_2G_Samples])/nullif(sum([RxLev_2G_Samples]),0)) as [cobertura AVG]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,[RxLev_GSM]))/10.0)*[RxLev_GSM_Samples])/nullif(sum([RxLev_GSM_Samples]),0)) as 'cobertura AVG GSM'
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,[RxLev_DCS]))/10.0)*[RxLev_DCS_Samples])/nullif(sum([RxLev_DCS_Samples]),0)) as 'cobertura AVG DCS'
	,sum([RxLev_2G_Samples]) as samplesAVG
	,sum([RxLev_GSM_Samples]) as samplesAVG_GSM
	,sum([RxLev_DCS_Samples]) as samplesAVG_DCS
	,avg([2G_ProbCobInd]) as [2G_ProbCobInd]
	,avg(GSM_ProbCobInd) as GSM_ProbCobInd
	,avg(DCS_ProbCobInd) as DCS_ProbCobInd
	,avg(GSM_DCS_ProbCobInd) as GSM_DCS_ProbCobInd
	,sum([2G_Samples_ProbCobInd]) as [2G_Samples_ProbCobInd]
	,sum(GSM_Samples_ProbCobInd) as GSM_Samples_ProbCobInd
	,sum(DCS_Samples_ProbCobInd) as DCS_Samples_ProbCobInd
	,sum(GSM_DCS_Samples_ProbCobInd) as GSM_DCS_Samples_ProbCobInd

from vlcc_aggr_sp_MDD_Coverage_2G_union c
where c.carrier = 'all'
and c.entidad='alicante'
and report_type='mun'
and mnc=1
and meas_round='FY1718_H1'
group by mnc,Meas_Round, Date_Reporting,Week_Reporting, entidad, Report_Type, c.Region_VF, c.Region_OSP

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------



select a.Meas_Round, a.Date_Reporting,a.mnc,  a.Week_Reporting,a.Report_type
	,a.Region_VF, a.Region_OSP	
	,a.entidad 	
	,sum(a.[2G_Samples]) as [2G_Samples]
	,sum(a.[2G]) as [2G]
	,sum(a.[GSM]) as [GSM]
	,sum(a.[DCS]) as [DCS]
	,sum(a.[GSM_DCS]) as [GSM_DCS]

	---Info de probCobInd, Pollution, niveles de señal		
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,b.[RxLev_2G]))/10.0)*b.[RxLev_2G_Samples])/nullif(sum(b.[RxLev_2G_Samples]),0)) as [RxLev_2G]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,b.[RxLev_GSM]))/10.0)*b.[RxLev_GSM_Samples])/nullif(sum(b.[RxLev_GSM_Samples]),0)) as [RxLev_GSM]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,b.[RxLev_DCS]))/10.0)*b.[RxLev_DCS_Samples])/nullif(sum(b.[RxLev_DCS_Samples]),0)) as [RxLev_DCS]
	,sum(b.[RxLev_2G_Samples]) as [RxLev_2G_Samples]
	,sum(b.[RxLev_GSM_Samples]) as [RxLev_GSM_Samples]
	,sum(b.[RxLev_DCS_Samples]) as [RxLev_DCS_Samples]
	,avg(b.[2G]) as [2G_ProbCobInd]
	,avg(b.[GSM]) as GSM_ProbCobInd
	,avg(b.[DCS]) as DCS_ProbCobInd
	,avg(b.[GSM_DCS]) as GSM_DCS_ProbCobInd
	,sum(b.[2G_Samples]) as [2G_Samples_ProbCobInd]
	,sum(b.[GSM_Samples]) as GSM_Samples_ProbCobInd
	,sum(b.[DCS_Samples]) as DCS_Samples_ProbCobInd
	,sum(b.[GSM_DCS_Samples]) as GSM_DCS_Samples_ProbCobInd

from [lcc_aggr_sp_MDD_Coverage_All_Indoor] a
		inner join [lcc_aggr_sp_MDD_Coverage_All_Curves] b on b.parcel=a.parcel and b.mnc=a.mnc and b.Date_Reporting=a.Date_Reporting and b.Meas_Round=a.meas_round
																and b.Week_Reporting=a.Week_Reporting and b.Entidad=a.Entidad and b.Report_type=a.Report_type
where a.entidad='alicante'
and a.mnc=1
and a.meas_round='fy1718_h1'
and a.report_type='mun'
group by a.parcel, a.Meas_Round, a.Date_Reporting, a.mnc, a.Week_Reporting, a.entidad,a.Report_type, a.Region_VF, a.Region_OSP 

	
