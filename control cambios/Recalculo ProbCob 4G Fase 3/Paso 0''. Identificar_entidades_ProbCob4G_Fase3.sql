--De las entidades agregadas a 02/03/2018 no tienen la tabla de entidad 5 de ellas (se valida con query 'Script_identificacion_tablas'):
--	GANDIAPLAYA la tendría como GANDIA
--  ALICANTE, GRANADA, JUMILLA, MISLATA no la tienen

--Esta entidades luego se excluyen en el volcadp

--select * from _entidades_ProbCob4G_Fase3 order by 1
--drop table _entidades_ProbCob4G_Fase3
select  entidad	
into _entidades_ProbCob4G_Fase3		
from	[AGGRCoverage].[dbo].vlcc_cober2G_bands c, [AGRIDS].[dbo].vlcc_parcelas_osp p
where p.parcela=isnull(c.parcel,'0.00000 Long, 0.00000 Lat') 
	and report_Type = 'MUN'
	and meas_round = 'FY1718_H1'		
group by entidad
union
select  entidad			
from	[AGGRCoverage].[dbo].vlcc_cober3G_bands c, [AGRIDS].[dbo].vlcc_parcelas_osp p
where p.parcela=isnull(c.parcel,'0.00000 Long, 0.00000 Lat') 
	and report_Type = 'MUN'
	and meas_round = 'FY1718_H1'		
group by entidad
union
select  entidad			
from	[AGGRCoverage].[dbo].vlcc_cober4G_bands c, [AGRIDS].[dbo].vlcc_parcelas_osp p
where p.parcela=isnull(c.parcel,'0.00000 Long, 0.00000 Lat') 
	and report_Type = 'MUN'
	and meas_round = 'FY1718_H1'		
group by entidad
