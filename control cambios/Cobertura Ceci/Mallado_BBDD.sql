--------------------------------------------------------------------------------------------------------------------------------------------------
-- Ver parcelas-entidades abiertas malladas por una bbdd (el contorno Orange no lo tenemos en cuenta, ya que no lo usamos en entidades normales):
--------------------------------------------------------------------------------------------------------------------------------------------------

--Miramos que posiciones recorridas tiene:
--------------------------------------------------------------------------------------------
--	Todas las parcelas NO tiene por qué tener todas info de scanner

use [FY1718_Coverage_Union_H1]
exec sp_lcc_dropifexists '_tmp_positions_bbbd_14'

select [fileid],[lonid],[latid],[MeasDate],[Entity_name]
into _tmp_positions_bbbd_14
from [lcc_position_Entity_List_Municipio]
where ddbb='FY1718_VOICE_REST_4G_H1_14'
group by [fileid],[lonid],[latid],[MeasDate],[Entity_name]
union 
select [fileid],[lonid],[latid],[MeasDate],[Entity_name]
from [lcc_position_Entity_List_Vodafone]
where ddbb='FY1718_VOICE_REST_4G_H1_14'
group by [fileid],[lonid],[latid],[MeasDate],[Entity_name]



--Miramos entidades con info de scanner que nos da cada fileId: --> Info scanner por piloto
--------------------------------------------------------------------------------------------
-- (análogo para UMTS-LTE)

--Entidades abiertas
SELECT g.[fileid],[Entity_name],g.[MeasDate], count(1)
FROM [lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord] g
	inner join _tmp_positions_bbbd_14 t1
	   on g.[lonid]=t1.[lonid] and g.[latid]=t1.[latid] and g.[MeasDate]=t1.[MeasDate] and g.[fileid]=t1.[fileid]
group by g.[fileid],[Entity_name],g.[MeasDate]
order by 1,2,3


