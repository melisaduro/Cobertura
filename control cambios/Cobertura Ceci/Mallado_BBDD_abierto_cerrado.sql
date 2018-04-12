--------------------------------------------------------------------------------------------------------------------------------------------------
-- Ver parcelas-entidades malladas por una bbdd (el contorno Orange no lo tenemos en cuenta, ya que no lo usamos en entidades normales):
--------------------------------------------------------------------------------------------------------------------------------------------------
--Se mira mallado en entidades abiertas-cerradas pero de cara a analizar impacto en el borrado de un log, nos bastaría ver en abiertas.

--Miramos que posiciones recorridas tiene:
--------------------------------------------------------------------------------------------
--	Se mira en origen ya que en CoverageUnion no están las parcelas cerradas
--	Todas las parcelas NO tiene por qué tener todas info de scanner

use [FY1718_Coverage_Union_H1]
exec sp_lcc_dropifexists '_tmp_positions_bbbd_27_Orig'

select [fileid],[lonid],[latid],[MeasDate],[Entity_name]
into [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_27_Orig
from FY1718_VOICE_REST_4G_H1_27.[dbo].[lcc_position_Entity_List_Municipio]
group by [fileid],[lonid],[latid],[MeasDate],[Entity_name]
union 
select [fileid],[lonid],[latid],[MeasDate],[Entity_name]
from FY1718_VOICE_REST_4G_H1_27.[dbo].[lcc_position_Entity_List_Vodafone]
group by [fileid],[lonid],[latid],[MeasDate],[Entity_name]


--Miramos entidades con info de scanner que nos da cada fileId: --> Info scanner por piloto
--------------------------------------------------------------------------------------------
-- (análogo para UMTS-LTE)

--Entidades abiertas
SELECT g.[fileid],[Entity_name],g.[MeasDate], count(1)
FROM [lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord] g
inner join _tmp_positions_bbbd_27_Orig t1
   on g.[fileid]=t1.[fileid]  and g.[lonid]=t1.[lonid]
      and g.[latid]=t1.[latid]
	  and g.[MeasDate]=t1.[MeasDate]
group by g.[fileid],[Entity_name],g.[MeasDate]
order by 1,2,3
--Entidades cerradas
SELECT g.[fileid],[Entity_name],g.[MeasDate], count(1)
FROM [lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_Cerrado] g
inner join _tmp_positions_bbbd_27_Orig t1
   on g.[fileid]=t1.[fileid]  and g.[lonid]=t1.[lonid]
      and g.[latid]=t1.[latid]
	  and g.[MeasDate]=t1.[MeasDate]
group by g.[fileid],[Entity_name],g.[MeasDate]
order by 1,2,3

