--101 entidades sin info de probCob_NEW
select *
from (select entidad, count(1) as 'Reg', 	sum(case when [LTE_NEW] is null	then 1 else 0 end) as 'Reg_null'
	from [AGGRCoverage].[dbo].[lcc_aggr_sp_MDD_Coverage_All_Curves]
	where report_Type = 'MUN'
		and meas_round = 'FY1718_H1'		
	group by entidad ) t
where Reg = Reg_null
order by entidad
	
--Williams con probCob_NEW ya calculada: 412
select *
from (select *
	from (select entidad, count(1) as 'Reg', 	sum(case when [LTE_NEW] is null	then 1 else 0 end) as 'Reg_null'
		from [AGGRCoverage].[dbo].[lcc_aggr_sp_MDD_Coverage_All_Curves]
		where report_Type = 'MUN'
			and meas_round = 'FY1718_H1'		
		group by entidad ) t
	where Reg <> Reg_null) t
	inner join [AGRIDS_v2].[dbo].[lcc_ciudades_tipo_Project_V9] t2
	on t.entidad=t2.entity_name
where scope='ADD-ON CITIES WILLIAMS'

--405 williamns siguen en la tabla de entidad los campos probCob_NEW, 7 no --> se han reprocesado y tb reclacularemos
select * from _entidad_ProbCob_new order by 1


--CALCULO:
--drop table _entidades_ProbCob4G_Fase3_2
select entidad
into FY1718_Coverage_Union_H1.dbo._entidades_ProbCob4G_Fase3_2
from (select entidad, count(1) as 'Reg', 	sum(case when [LTE_NEW] is null	then 1 else 0 end) as 'Reg_null'
	from [AGGRCoverage].[dbo].[lcc_aggr_sp_MDD_Coverage_All_Curves]
	where report_Type = 'MUN'
		and meas_round = 'FY1718_H1'		
	group by entidad ) t
where Reg = Reg_null
union
select t1.entidad
from (select entidad
	from (select *
		from (select entidad, count(1) as 'Reg', 	sum(case when [LTE_NEW] is null	then 1 else 0 end) as 'Reg_null'
			from [AGGRCoverage].[dbo].[lcc_aggr_sp_MDD_Coverage_All_Curves]
			where report_Type = 'MUN'
				and meas_round = 'FY1718_H1'		
			group by entidad ) t
		where Reg <> Reg_null) t
		inner join [AGRIDS_v2].[dbo].[lcc_ciudades_tipo_Project_V9] t2
		on t.entidad=t2.entity_name
	where scope='ADD-ON CITIES WILLIAMS') t1
	left join FY1718_Coverage_Union_H1.dbo._entidad_ProbCob_new t2 on t1.entidad=t2.entidad
where t2.entidad is null


select * from FY1718_Coverage_Union_H1.dbo._entidades_ProbCob4G_Fase3_2