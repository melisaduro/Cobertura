USE [AGGRCoverage_ROAD]

select lp.entorno,
		mnc,parcel,Meas_Round, Date_Reporting, Week_Reporting, entidad, Report_Type
		--Region_VF, Region_OSP
		,max ([LTE_Samples]) as coverage_den
		
		,sum([LTE]) as samples_4Gcov_num
		
		,sum([RSRP_LTE_Samples]) as samplesAVG
		
		,10*log10(sum(POWER(convert(float,10.0),(convert(float,[RSRP_LTE]))/10.0)*[RSRP_LTE_Samples])/nullif(sum([RSRP_LTE_Samples]),0)) as 'cobertura AVG'
		
		
	from(	
	select a.parcel,a.Meas_Round, a.Date_Reporting,a.mnc, a.carrier, a.band, a.Week_Reporting,a.Report_Type
		--,a.Region_VF, a.Region_OSP
		,a.entidad 	
		,sum(a.[LTE_Samples]) as [LTE_Samples]
		,sum(a.[LTE]) as [LTE]
		
		---Info de probCobInd, Pollution, niveles de señal
		,10*log10(sum(POWER(convert(float,10.0),(convert(float,a.[RSRP_LTE]))/10.0)*a.[RSRP_LTE_Samples])/nullif(sum(a.[RSRP_LTE_Samples]),0)) as [RSRP_LTE]
		,sum(a.[RSRP_LTE_Samples]) as [RSRP_LTE_Samples]
		

	from [lcc_aggr_sp_MDD_Coverage_All_Indoor] a
	where entidad='a1-irun-r3'
		and meas_round like '%1718%'
		and mnc=1
		and report_type='osp'
	group by a.parcel, a.Meas_Round, a.Date_Reporting, a.mnc, a.carrier, a.band, a.Week_Reporting, a.entidad,
			a.Report_Type--, a.Region_VF, a.Region_OSP
	) c,
									agrids.dbo.lcc_parcelas lp
	where c.carrier = 'all'
		and lp.nombre = c.parcel
		and lp.entorno='RUR'
	group by lp.entorno,mnc,parcel,Meas_Round, Date_Reporting,Week_Reporting, entidad, Report_Type/*, Region_VF, Region_OSP*/

	order by 1





















GO


