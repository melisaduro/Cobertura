USE [AGGRCoverage]
GO

/****** Object:  View [dbo].[vlcc_aggr_sp_MDD_Coverage_4G_union]    Script Date: 09/03/2018 14:09:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE view [dbo].[vlcc_aggr_sp_MDD_Coverage_4G_union_new] as
		
select a.parcel,a.Meas_Round, a.Date_Reporting,a.mnc, a.carrier, a.band, a.Week_Reporting,a.Report_type
	,a.Region_VF, a.Region_OSP
	,a.entidad 	
	,sum(a.[LTE_Samples]) as [LTE_Samples]
	,sum(a.[LTE]) as [LTE]
	,sum(a.[LTE2600]) as [LTE2600]
	,sum(a.[LTE2100]) as [LTE2100]
	,sum(a.[LTE2100_BW5]) as [LTE2100_BW5]
	,sum(a.[LTE2100_BW10]) as [LTE2100_BW10]
	,sum(a.[LTE2100_BW15]) as [LTE2100_BW15]
	,sum(a.[LTE1800]) as [LTE1800]
	,sum(a.[LTE1800_BW10]) as [LTE1800_BW10]
	,sum(a.[LTE1800_BW15]) as [LTE1800_BW15]
	,sum(a.[LTE1800_BW20]) as [LTE1800_BW20]
	,sum(a.[LTE800]) as [LTE800]
	,sum(a.[LTE800_1800]) as [LTE800_1800]
	,sum(a.[LTE800_2100]) as [LTE800_2100]
	,sum(a.[LTE800_2600]) as [LTE800_2600]
	,sum(a.[LTE1800_2100]) as [LTE1800_2100]
	,sum(a.[LTE1800_2600]) as [LTE1800_2600]
	,sum(a.[LTE2100_2600]) as [LTE2100_2600]
	,sum(a.[LTE800_1800_2100]) as [LTE800_1800_2100]
	,sum(a.[LTE800_1800_2600]) as [LTE800_1800_2600]
	,sum(a.[LTE800_2100_2600]) as [LTE800_2100_2600]
	,sum(a.[LTE1800_2100_2600]) as [LTE1800_2100_2600]

	---Info de probCobInd, Pollution, niveles de señal
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,b.[RSRP_LTE]))/10.0)*b.[RSRP_LTE_Samples])/nullif(sum(b.[RSRP_LTE_Samples]),0)) as [RSRP_LTE]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,b.[RSRP_LTE2600]))/10.0)*b.[RSRP_LTE2600_Samples])/nullif(sum(b.[RSRP_LTE2600_Samples]),0)) as [RSRP_LTE2600]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,b.[RSRP_LTE2100]))/10.0)*b.[RSRP_LTE2100_Samples])/nullif(sum(b.[RSRP_LTE2100_Samples]),0)) as [RSRP_LTE2100]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,b.[RSRP_LTE1800]))/10.0)*b.[RSRP_LTE1800_Samples])/nullif(sum(b.[RSRP_LTE1800_Samples]),0)) as [RSRP_LTE1800]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,b.[RSRP_LTE800]))/10.0)*b.[RSRP_LTE800_Samples])/nullif(sum(b.[RSRP_LTE800_Samples]),0)) as [RSRP_LTE800]
	,sum(b.[RSRP_LTE_Samples]) as [RSRP_LTE_Samples]
	,sum(b.[RSRP_LTE2600_Samples]) as [RSRP_LTE2600_Samples]
	,sum(b.[RSRP_LTE2100_Samples]) as [RSRP_LTE2100_Samples]
	,sum(b.[RSRP_LTE1800_Samples]) as [RSRP_LTE1800_Samples]
	,sum(b.[RSRP_LTE800_Samples]) as [RSRP_LTE800_Samples]
	,avg(b.[LTE_NEW]) as LTE_ProbCobInd
	,avg(b.[LTE2600_NEW]) as LTE2600_ProbCobInd
	,avg(b.[LTE2100_NEW]) as LTE2100_ProbCobInd
	,avg(b.[LTE2100_BW5_NEW]) as LTE2100_BW5_ProbCobInd
	,avg(b.[LTE2100_BW10_NEW]) as LTE2100_BW10_ProbCobInd
	,avg(b.[LTE2100_BW15_NEW]) as LTE2100_BW15_ProbCobInd
	,avg(b.[LTE1800_NEW]) as LTE1800_ProbCobInd
	,avg(b.[LTE1800_BW10_NEW]) as LTE1800_BW10_ProbCobInd
	,avg(b.[LTE1800_BW15_NEW]) as LTE1800_BW15_ProbCobInd
	,avg(b.[LTE1800_BW20_NEW]) as LTE1800_BW20_ProbCobInd
	,avg(b.[LTE800_NEW]) as LTE800_ProbCobInd
	,avg(b.[LTE800_1800_NEW]) as LTE800_1800_ProbCobInd
	,avg(b.[LTE800_2100_NEW]) as LTE800_2100_ProbCobInd
	,avg(b.[LTE800_2600_NEW]) as LTE800_2600_ProbCobInd
	,avg(b.[LTE1800_2100_NEW]) as LTE1800_2100_ProbCobInd
	,avg(b.[LTE1800_2600_NEW]) as LTE1800_2600_ProbCobInd
	,avg(b.[LTE2100_2600_NEW]) as LTE2100_2600_ProbCobInd
	,avg(b.[LTE800_1800_2100_NEW]) as LTE800_1800_2100_ProbCobInd
	,avg(b.[LTE800_1800_2600_NEW]) as LTE800_1800_2600_ProbCobInd
	,avg(b.[LTE800_2100_2600_NEW]) as LTE800_2100_2600_ProbCobInd
	,avg(b.[LTE1800_2100_2600_NEW]) as LTE1800_2100_2600_ProbCobInd
	,sum(b.[LTE_Samples]) as LTE_Samples_ProbCobInd
	,sum(b.[LTE2600_Samples]) as LTE2600_Samples_ProbCobInd
	,sum(b.[LTE2100_Samples]) as LTE2100_Samples_ProbCobInd
	,sum(b.[LTE2100_BW5_Samples]) as LTE2100_BW5_Samples_ProbCobInd
	,sum(b.[LTE2100_BW10_Samples]) as LTE2100_BW10_Samples_ProbCobInd
	,sum(b.[LTE2100_BW15_Samples]) as LTE2100_BW15_Samples_ProbCobInd
	,sum(b.[LTE1800_Samples]) as LTE1800_Samples_ProbCobInd
	,sum(b.[LTE1800_BW10_Samples]) as LTE1800_BW10_Samples_ProbCobInd
	,sum(b.[LTE1800_BW15_Samples]) as LTE1800_BW15_Samples_ProbCobInd
	,sum(b.[LTE1800_BW20_Samples]) as LTE1800_BW20_Samples_ProbCobInd
	,sum(b.[LTE800_Samples]) as LTE800_Samples_ProbCobInd
	,sum(b.[LTE800_1800_Samples]) as LTE800_1800_Samples_ProbCobInd
	,sum(b.[LTE800_2100_Samples]) as LTE800_2100_Samples_ProbCobInd
	,sum(b.[LTE800_2600_Samples]) as LTE800_2600_Samples_ProbCobInd
	,sum(b.[LTE1800_2100_Samples]) as LTE1800_2100_Samples_ProbCobInd
	,sum(b.[LTE1800_2600_Samples]) as LTE1800_2600_Samples_ProbCobInd
	,sum(b.[LTE2100_2600_Samples]) as LTE2100_2600_Samples_ProbCobInd
	,sum(b.[LTE800_1800_2100_Samples]) as LTE800_1800_2100_Samples_ProbCobInd
	,sum(b.[LTE800_1800_2600_Samples]) as LTE800_1800_2600_Samples_ProbCobInd
	,sum(b.[LTE800_2100_2600_Samples]) as LTE800_2100_2600_Samples_ProbCobInd
	,sum(b.[LTE1800_2100_2600_Samples]) as LTE1800_2100_2600_Samples_ProbCobInd		

from [lcc_aggr_sp_MDD_Coverage_All_Indoor] a
		inner join [lcc_aggr_sp_MDD_Coverage_All_Curves] b on b.parcel=a.parcel and b.mnc=a.mnc and b.Date_Reporting=a.Date_Reporting and b.Meas_Round=a.meas_round
																	and b.Week_Reporting=a.Week_Reporting and b.Entidad=a.Entidad and b.Report_type=a.Report_type

group by a.parcel, a.Meas_Round, a.Date_Reporting, a.mnc, a.carrier, a.band, a.Week_Reporting, a.entidad,a.Report_type,a.Region_VF, a.Region_OSP
union
select a.parcel,a.Meas_Round, a.Date_Reporting,a.mnc, a.carrier, a.band, a.Week_Reporting,a.Report_type
	,a.Region_VF, a.Region_OSP
	,a.entidad 	
	,sum(a.[LTE_Samples]) as [LTE_Samples]
	,sum(a.[LTE]) as [LTE]
	,sum(a.[LTE2600]) as [LTE2600]
	,sum(a.[LTE2100]) as [LTE2100]
	,sum(a.[LTE2100_BW5]) as [LTE2100_BW5]
	,sum(a.[LTE2100_BW10]) as [LTE2100_BW10]
	,sum(a.[LTE2100_BW15]) as [LTE2100_BW15]
	,sum(a.[LTE1800]) as [LTE1800]
	,sum(a.[LTE1800_BW10]) as [LTE1800_BW10]
	,sum(a.[LTE1800_BW15]) as [LTE1800_BW15]
	,sum(a.[LTE1800_BW20]) as [LTE1800_BW20]
	,sum(a.[LTE800]) as [LTE800]
	,sum(a.[LTE800_1800]) as [LTE800_1800]
	,sum(a.[LTE800_2100]) as [LTE800_2100]
	,sum(a.[LTE800_2600]) as [LTE800_2600]
	,sum(a.[LTE1800_2100]) as [LTE1800_2100]
	,sum(a.[LTE1800_2600]) as [LTE1800_2600]
	,sum(a.[LTE2100_2600]) as [LTE2100_2600]
	,sum(a.[LTE800_1800_2100]) as [LTE800_1800_2100]
	,sum(a.[LTE800_1800_2600]) as [LTE800_1800_2600]
	,sum(a.[LTE800_2100_2600]) as [LTE800_2100_2600]
	,sum(a.[LTE1800_2100_2600]) as [LTE1800_2100_2600]

	---Info de probCobInd, Pollution, niveles de señal
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,a.[RSRP_LTE]))/10.0)*a.[RSRP_LTE_Samples])/nullif(sum(a.[RSRP_LTE_Samples]),0)) as [RSRP_LTE]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,a.[RSRP_LTE2600]))/10.0)*a.[RSRP_LTE2600_Samples])/nullif(sum(a.[RSRP_LTE2600_Samples]),0)) as [RSRP_LTE2600]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,a.[RSRP_LTE2100]))/10.0)*a.[RSRP_LTE2100_Samples])/nullif(sum(a.[RSRP_LTE2100_Samples]),0)) as [RSRP_LTE2100]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,a.[RSRP_LTE1800]))/10.0)*a.[RSRP_LTE1800_Samples])/nullif(sum(a.[RSRP_LTE1800_Samples]),0)) as [RSRP_LTE1800]
	,10*log10(sum(POWER(convert(float,10.0),(convert(float,a.[RSRP_LTE800]))/10.0)*a.[RSRP_LTE800_Samples])/nullif(sum(a.[RSRP_LTE800_Samples]),0)) as [RSRP_LTE800]
	,sum(a.[RSRP_LTE_Samples]) as [RSRP_LTE_Samples]
	,sum(a.[RSRP_LTE2600_Samples]) as [RSRP_LTE2600_Samples]
	,sum(a.[RSRP_LTE2100_Samples]) as [RSRP_LTE2100_Samples]
	,sum(a.[RSRP_LTE1800_Samples]) as [RSRP_LTE1800_Samples]
	,sum(a.[RSRP_LTE800_Samples]) as [RSRP_LTE800_Samples]
	,null as LTE_ProbCobInd
	,null as LTE2600_ProbCobInd
	,null as LTE2100_ProbCobInd
	,null as LTE2100_BW5_ProbCobInd
	,null as LTE2100_BW10_ProbCobInd
	,null as LTE2100_BW15_ProbCobInd
	,null as LTE1800_ProbCobInd
	,null as LTE1800_BW10_ProbCobInd
	,null as LTE1800_BW15_ProbCobInd
	,null as LTE1800_BW20_ProbCobInd
	,null as LTE800_ProbCobInd
	,null as LTE800_1800_ProbCobInd
	,null as LTE800_2100_ProbCobInd
	,null as LTE800_2600_ProbCobInd
	,null as LTE1800_2100_ProbCobInd
	,null as LTE1800_2600_ProbCobInd
	,null as LTE2100_2600_ProbCobInd
	,null as LTE800_1800_2100_ProbCobInd
	,null as LTE800_1800_2600_ProbCobInd
	,null as LTE800_2100_2600_ProbCobInd
	,null as LTE1800_2100_2600_ProbCobInd
	,null as LTE_Samples_ProbCobInd
	,null as LTE2600_Samples_ProbCobInd
	,null as LTE2100_Samples_ProbCobInd
	,null as LTE2100_BW5_Samples_ProbCobInd
	,null as LTE2100_BW10_Samples_ProbCobInd
	,null as LTE2100_BW15_Samples_ProbCobInd
	,null as LTE1800_Samples_ProbCobInd
	,null as LTE1800_BW10_Samples_ProbCobInd
	,null as LTE1800_BW15_Samples_ProbCobInd
	,null as LTE1800_BW20_Samples_ProbCobInd
	,null as LTE800_Samples_ProbCobInd
	,null as LTE800_1800_Samples_ProbCobInd
	,null as LTE800_2100_Samples_ProbCobInd
	,null as LTE800_2600_Samples_ProbCobInd
	,null as LTE1800_2100_Samples_ProbCobInd
	,null as LTE1800_2600_Samples_ProbCobInd
	,null as LTE2100_2600_Samples_ProbCobInd
	,null as LTE800_1800_2100_Samples_ProbCobInd
	,null as LTE800_1800_2600_Samples_ProbCobInd
	,null as LTE800_2100_2600_Samples_ProbCobInd
	,null as LTE1800_2100_2600_Samples_ProbCobInd		

from [lcc_aggr_sp_MDD_Coverage_All_Outdoor] a
group by a.parcel, a.Meas_Round, a.Date_Reporting, a.mnc, a.carrier, a.band, a.Week_Reporting, a.entidad,a.Report_type,a.Region_VF, a.Region_OSP





GO


