USE [AGGRCoverage]

select mnc, entidad,
	[4G_Samples],
	1.0*LTE_ProbCobInd/nullif([4G_Samples],0) as ProbCob_4G,
	1.0*LTE_ProbCobInd_old/nullif([4G_Samples],0) as ProbCob_4G_old,
	1.0*LTE2600_ProbCobInd/nullif([4G_Samples],0) as ProbCob_4G_LTE2600,
	1.0*LTE2600_ProbCobInd_old/nullif([4G_Samples],0) as ProbCob_4G_LTE2600_old,
	1.0*LTE2100_ProbCobInd/nullif([4G_Samples],0) as ProbCob_4G_LTE2100,
	1.0*LTE2100_ProbCobInd_old/nullif([4G_Samples],0) as ProbCob_4G_LTE2100_old,
	1.0*LTE1800_ProbCobInd/nullif([4G_Samples],0) as ProbCob_4G_LTE1800,
	1.0*LTE1800_ProbCobInd_old/nullif([4G_Samples],0) as ProbCob_4G_LTE1800_old,
	1.0*LTE800_ProbCobInd/nullif([4G_Samples],0) as ProbCob_4G_LTE800,
	1.0*LTE800_ProbCobInd_old/nullif([4G_Samples],0) as ProbCob_4G_LTE800_old
from (
	select mnc
		,entidad 	
		,sum([4G_All_Samples]) as [4G_Samples]	
		,sum(1.0*[LTE]*[LTE_Samples]) as LTE_ProbCobInd_old
		,sum([LTE2600]*[LTE2600_Samples]) as LTE2600_ProbCobInd_old
		,sum([LTE2100]*[LTE2100_Samples]) as LTE2100_ProbCobInd_old
		,sum([LTE1800]*[LTE1800_Samples]) as LTE1800_ProbCobInd_old
		,sum([LTE800]*[LTE800_Samples]) as LTE800_ProbCobInd_old
		,sum(1.0*[LTE_NEW]*[LTE_Samples]) as LTE_ProbCobInd
		,sum([LTE2600_NEW]*[LTE2600_Samples]) as LTE2600_ProbCobInd
		,sum([LTE2100_NEW]*[LTE2100_Samples]) as LTE2100_ProbCobInd	
		,sum([LTE1800_NEW]*[LTE1800_Samples]) as LTE1800_ProbCobInd	
		,sum([LTE800_NEW]*[LTE800_Samples]) as LTE800_ProbCobInd
	--from [lcc_aggr_sp_MDD_Coverage_All_Curves_4G]
	from [lcc_aggr_sp_MDD_Coverage_All_Curves]
	where meas_Round= 'FY1718_H1' and report_type='MUN'
	group by mnc, entidad) t
--Ninguna entidad-operador tiene cober mejor ahora
where 1.0*LTE_ProbCobInd_old/nullif([4G_Samples],0) < 1.0*LTE_ProbCobInd/nullif([4G_Samples],0)
order by entidad, case when mnc=7 then 2 else mnc end
