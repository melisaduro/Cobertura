--1. Abrir contorno entidad con procedimiento DASHBOARD sp_lcc_abrir_cobertura_FY1718

use FY1718_Coverage_Union_H1

--2. Hacemos restore a la base de datos origen para volver a crear las tablas de entidad de la union

exec sp_plcc_restore_Coverage_Union_Grid_Info '''FY1718_VOICE_ZARAGOZA_4G_H1'''


--3. Lanzamos recursos

exec sp_MDD_Resources_2G_Scan_FY1617_Union
exec sp_MDD_Resources_3G_Scan_FY1617_Union
exec sp_MDD_Resources_4G_Scan_FY1617_Union

-- Para ver de q bbdd tira la info - son las que tienen q estar actualizadas

use FY1718_Coverage_Union_H1


select COUNT(1)
from lcc_position_entity_list_vodafone T1,[lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor] T2
where entity_name like '%ZARAGOZA%'
AND master.dbo.fn_lcc_lonidtolongitude(T1.lonid, T1.latid)=T2.LONGITUDE
AND master.dbo.fn_lcc_latidtolatitude(T1.latid)=T2.LATITUDE

select COUNT(1)
from lcc_position_entity_list_vodafone T1,[lcc_UMTSScanner_50x50_ProbCobIndoor] T2
where entity_name like '%ZARAGOZA%'
AND master.dbo.fn_lcc_lonidtolongitude(T1.lonid, T1.latid)=T2.LONGITUDE
AND master.dbo.fn_lcc_latidtolatitude(T1.latid)=T2.LATITUDE

select COUNT(1)
from lcc_position_entity_list_vodafone T1,[lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor] T2
where entity_name like '%ZARAGOZA%'
AND master.dbo.fn_lcc_lonidtolongitude(T1.lonid, T1.latid)=T2.LONGITUDE
AND master.dbo.fn_lcc_latidtolatitude(T1.latid)=T2.LATITUDE