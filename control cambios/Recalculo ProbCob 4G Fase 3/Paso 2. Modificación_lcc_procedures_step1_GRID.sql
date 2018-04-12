select *
from [AGRIDS].[dbo].[lcc_procedures_step1_GRID] --Tabla en la que se registran los procedimientos de paso 1
where type_Info='Coverage'
and (Methodology = 'ALL' or Methodology ='D16')

--249 tabla backup
select *
into [AGRIDS].[dbo].[lcc_procedures_step1_GRID_20180405]
--into [AGRIDS].[dbo].[lcc_procedures_step1_GRID_20180307]
from [AGRIDS].[dbo].[lcc_procedures_step1_GRID]

delete [AGRIDS].[dbo].[lcc_procedures_step1_GRID]
where type_Info='Coverage'
and (Methodology = 'ALL' or Methodology ='D16')


--delete [AGRIDS].[dbo].[lcc_procedures_step1_GRID]
--where type_Info='Coverage' and (Methodology = 'ALL' or Methodology ='D16') and name_proc='sp_MDD_Coverage_All_Curves_4G'

insert into [AGRIDS].[dbo].[lcc_procedures_step1_GRID]
select 'sp_MDD_Coverage_All_Curves_4G','Coverage','ALL','Y',NULL,NULL,'D16'

--Ejecución masiva
select *
into [AGRIDS].[dbo].[lcc_procedures_step1_GRID_ProbCob4G]
from [AGRIDS].[dbo].[lcc_procedures_step1_GRID]



drop table [AGRIDS].[dbo].[lcc_procedures_step1_GRID]

select *
into [AGRIDS].[dbo].[lcc_procedures_step1_GRID]
from [AGRIDS].[dbo].[lcc_procedures_step1_GRID_20180405]
--from [AGRIDS].[dbo].[lcc_procedures_step1_GRID_20180307]

drop table [AGRIDS].[dbo].[lcc_procedures_step1_GRID_201803XX]