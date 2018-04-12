--agregadas 05/04/2018 (segunda vuelta con restantes de williams)
select entidad, count(1) as 'Reg'
from [AGGRCoverage].[dbo].[lcc_aggr_sp_MDD_Coverage_All_Curves_4G]
group by entidad 
--5144
select count(1) from [dbo].[lcc_aggr_sp_MDD_Coverage_All_Curves_4G]

use [AGGRCoverage]

--0
select count(1)
from lcc_aggr_sp_MDD_Coverage_All_Curves t1 --970 760 (hay menos registros que en primer calculo de primeros de marzo porque MD borró aves antiguos agregados como VDF en curves y en MUN sin curves (el cambio de lógica se haría en medio))
	inner join lcc_aggr_sp_MDD_Coverage_All_Curves_4G t2 --5144
		on t1.parcel=t2.parcel and t1.mnc=t2.mnc and t1.Meas_Round=t2.Meas_Round and t1.[Database]=t2.[Database] and t1.Report_Type=t2.Report_Type and t1.Entidad=t2.Entidad
where t1.LTE_Samples <> t2.LTE_Samples
	or t1.LTE2600_Samples <> t2.LTE2600_Samples
	or t1.LTE2100_Samples <> t2.LTE2100_Samples
	or t1.LTE2100_BW5_Samples <> t2.LTE2100_BW5_Samples or t1.LTE2100_BW10_Samples <> t2.LTE2100_BW10_Samples or t1.LTE2100_BW15_Samples <> t2.LTE2100_BW15_Samples
	or t1.LTE1800_Samples <> t2.LTE1800_Samples
	or t1.LTE1800_BW10_Samples <> t2.LTE1800_BW10_Samples or t1.LTE1800_BW15_Samples <> t2.LTE1800_BW15_Samples or t1.LTE1800_BW20_Samples <> t2.LTE1800_BW20_Samples
	or t1.LTE800_Samples <> t2.LTE800_Samples
	or t1.LTE800_1800_Samples <> t2.LTE800_1800_Samples or t1.LTE800_2100_Samples <> t2.LTE800_2100_Samples or t1.LTE800_2600_Samples <> t2.LTE800_2600_Samples
	or t1.LTE1800_2100_Samples <> t2.LTE1800_2100_Samples or t1.LTE1800_2600_Samples <> t2.LTE1800_2600_Samples or t1.LTE2100_2600_Samples <> t2.LTE2100_2600_Samples
	or t1.LTE800_1800_2100_Samples <> t2.LTE800_1800_2100_Samples or t1.LTE800_1800_2600_Samples <> t2.LTE800_1800_2600_Samples or t1.LTE800_2100_2600_Samples <> t2.LTE800_2100_2600_Samples or t1.LTE1800_2100_2600_Samples <> t2.LTE1800_2100_2600_Samples


--Backup
select *	--count(1)--970760
into lcc_aggr_sp_MDD_Coverage_All_Curves_borrar_2
from lcc_aggr_sp_MDD_Coverage_All_Curves

--Updates nuevos valores
update lcc_aggr_sp_MDD_Coverage_All_Curves
set LTE_NEW= t2.LTE,
	LTE2600_NEW= t2.LTE2600,
	LTE2100_NEW= t2.LTE2100,
	LTE2100_BW5_NEW= t2.LTE2100_BW5,
	LTE2100_BW10_NEW= t2.LTE2100_BW10,
	LTE2100_BW15_NEW= t2.LTE2100_BW15,
	LTE1800_NEW= t2.LTE1800,
	LTE1800_BW10_NEW= t2.LTE1800_BW10,
	LTE1800_BW15_NEW= t2.LTE1800_BW15,
	LTE1800_BW20_NEW= t2.LTE1800_BW20,
	LTE800_NEW= t2.LTE800,
	LTE800_1800_NEW= t2.LTE800_1800,
	LTE800_2100_NEW= t2.LTE800_2100,
	LTE800_2600_NEW= t2.LTE800_2600,
	LTE1800_2100_NEW= t2.LTE1800_2100,
	LTE1800_2600_NEW= t2.LTE1800_2600,
	LTE2100_2600_NEW= t2.LTE2100_2600,
	LTE800_1800_2100_NEW= t2.LTE800_1800_2100,
	LTE800_1800_2600_NEW= t2.LTE800_1800_2600,
	LTE800_2100_2600_NEW= t2.LTE800_2100_2600,
	LTE1800_2100_2600_NEW= t2.LTE1800_2100_2600
--select count(1)
from lcc_aggr_sp_MDD_Coverage_All_Curves t1 --970760
inner join lcc_aggr_sp_MDD_Coverage_All_Curves_4G t2 --5144
on t1.parcel=t2.parcel and t1.mnc=t2.mnc and t1.Meas_Round=t2.Meas_Round and t1.[Database]=t2.[Database] and t1.Report_Type=t2.Report_Type and t1.Entidad=t2.Entidad
