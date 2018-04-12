
------------
-- Tabla general
use AGRIDS_v2
select * from [dbo].[lcc_AGRIDS_Contornos_VF]
where entity_name like '%pamplona%'

------------
-- Para ver de q bbdd tira la info - son las que tienen q estar actualizadas
use [FY1617_Coverage_Union]

select distinct ddbb	, 
	master.dbo.fn_lcc_lonidtolongitude(lonid, latid) as longitude,
	master.dbo.fn_lcc_latidtolatitude(latid) as latitude
from lcc_position_entity_list_vodafone
where entity_name like '%pamplona%'

select distinct ddbb	, 
	master.dbo.fn_lcc_lonidtolongitude(lonid, latid) as longitude,
	master.dbo.fn_lcc_latidtolatitude(latid) as latitude
from lcc_position_entity_list_orange
where entity_name like '%pamplona%'

select distinct ddbb	, 
	master.dbo.fn_lcc_lonidtolongitude(lonid, latid) as longitude,
	master.dbo.fn_lcc_latidtolatitude(latid) as latitude
from lcc_position_entity_list_municipio
where entity_name like '%pamplona%'

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

--- 1º Ejecutar sp_erase_entity en la BBDD origen 

-- AVISAR siempre a PROCESADO y COORDINACION que no esten trabajando en estas bbdd
use FY1617_Data_Rest_4G_H1_5
exec sp_erase_entity_info

use FY1617_Voice_Rest_4G_H1_5
exec sp_erase_entity_info


--2º El argumento es el listado de BBDDs origen restauradas --
-- AVISAR siempre a PROCESADO y COORDINACION que no esten trabajando en esta bbdd
use [FY1617_Coverage_Union]
exec sp_plcc_restore_Coverage_Union_Grid_Info '''OSP1617_Voice_Rest_3G_H1'', ''OSP1617_Voice_Rest_3G_H1_2'''


