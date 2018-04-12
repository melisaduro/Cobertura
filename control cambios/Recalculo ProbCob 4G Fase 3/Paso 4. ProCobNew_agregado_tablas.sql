
use [AGGRCoverage]

--0
select count(1)
from lcc_aggr_sp_MDD_Coverage_All_Curves t1 --1010860
	inner join lcc_aggr_sp_MDD_Coverage_All_Curves_4G t2 --144596
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

--Nuevas columnas
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE2600_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE2100_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE2100_BW5_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE2100_BW10_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE2100_BW15_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE1800_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE1800_BW10_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE1800_BW15_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE1800_BW20_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE800_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE800_1800_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE800_2100_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE800_2600_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE1800_2100_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE1800_2600_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE2100_2600_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE800_1800_2100_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE800_1800_2600_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE800_2100_2600_NEW float
alter table [AGGRCoverage].[dbo].lcc_aggr_sp_MDD_Coverage_All_Curves add LTE1800_2100_2600_NEW float

--Backup
select *	--count(1)--1010860
into lcc_aggr_sp_MDD_Coverage_All_Curves_borrar
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
from lcc_aggr_sp_MDD_Coverage_All_Curves t1 --1010860
inner join lcc_aggr_sp_MDD_Coverage_All_Curves_4G t2 --144596
on t1.parcel=t2.parcel and t1.mnc=t2.mnc and t1.Meas_Round=t2.Meas_Round and t1.[Database]=t2.[Database] and t1.Report_Type=t2.Report_Type and t1.Entidad=t2.Entidad
