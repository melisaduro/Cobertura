select zone,[master].dbo.fn_lcc_getElement(4, collectionname,'_'),*
from [FY1718_VOICE_REST_4G_H1_14].[dbo].filelist
where collectionname like '%fuenlabrada%'
	and  (fileid between 193 and 200 or fileid between 209 and 216 or fileid between 225 and 232 or fileid between 241 and 256  --system 3
		or fileid between 265 and 329) --system 5
order by 1,fileid

--Por ejemplo, deseamos borrar system 5

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- IMPACTOS HACIA OTRAS ENTIDADES:
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Entidades a las que impacta el borrado:
---------------------------------------------

--Miramos en Union a que entidades malla sus logs:  FUENLABRADA, HUMANESDEMADRID, MOSTOLES, PARLA
--No basamos únicamente en la tabla de municipio (por si huebiera parcelas asignadas a entidades distintas dependiendo del contorno)
select [Entity_name]
from [FY1718_Coverage_Union_H1].dbo.[lcc_position_Entity_List_Municipio]
where ddbb='FY1718_VOICE_REST_4G_H1_14' and fileid between 265 and 329
group by [Entity_name]


--De las entidas malladas por los logs de Fuenlabrada que queremos borrar, Mostoles tambien esta medida y se impactan mutuamente (se ve también más adelante)
--Además se encuentran en bbdd distintas: FY1718_VOICE_REST_4G_H1_15
select ddbb,[master].dbo.fn_lcc_getElement(4, collectionname,'_') as 'Medida',[Entity_name]
from [FY1718_Coverage_Union_H1].dbo.[lcc_position_Entity_List_Municipio]
where [master].dbo.fn_lcc_getElement(4, collectionname,'_') in ('HUMANESDEMADRID','MOSTOLES','PARLA')
group by ddbb,[master].dbo.fn_lcc_getElement(4, collectionname,'_'),[Entity_name]


--Ejemplo ficticio:
--Móstoles ya esta procesada y da unos resultados coherentes de cobertura (el impacto debe ser despreciable).No queremos tener que recalcular Móstoles
--> Vamos a borrar todo lo del system 5 de Fuenlabrada que NO pase por Móstoles (tanto en BBDD Origen como en Union, siempre tiene que ser coherente)


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Recalculo en BBDD origen
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Para que el cruce de la info sea más eficiente, generamos una tabla temporal con las parcelas a borrar:

--En bbdd origen una tabla (tendramos parcelas cerradas o no pero queremos borrar TODAS):
use [FY1718_Coverage_Union_H1]
exec sp_lcc_dropifexists '_tmp_positions_bbbd_14_Orig'

select [fileid],[lonid],[latid],[MeasDate],[Entity_name]
into [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_14_Orig
from FY1718_VOICE_REST_4G_H1_14.[dbo].[lcc_position_Entity_List_Municipio]
where fileid between 265 and 329 and [Entity_name]<> 'MOSTOLES'
group by [fileid],[lonid],[latid],[MeasDate],[Entity_name]


--Borrado en bbdd origen
----------------------------------------------
--Borramos cruzando por las parcelas malladas por el system 5 que no sean Móstoles, query análoga en las siguientes tablas:
--		lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
--		lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
--		lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor

--Si se borrará la información completa de los logs, no haría falta ningún cruce, sino filtrar por ellos.
delete FY1718_VOICE_REST_4G_H1_14.[dbo].lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
from  FY1718_VOICE_REST_4G_H1_14.[dbo].lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor t1
	inner join [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_14_Orig t2
		on t2.[fileid]=t1.[fileid] and t2.[lonid]=t1.[lonid] and t2.[latid]=t1.[latid] and t2.[MeasDate]=t1.[MeasDate]


--Identificamos que posibles recalculos tenemos que hacer: 
--De las parcelas de las que vamos a borrar info de system 5 de Fuenlabrada miramos que otros logs las mallan
--101 y 103 logs de Leganes y logs de Fuenlabrada del otro system
select [fileid],[master].dbo.fn_lcc_getElement(4, collectionname,'_'), count(distinct convert(varchar,t1.lonid)+'_'+convert(varchar,t1.latid)) as 'Num_Parcelas'
from FY1718_VOICE_REST_4G_H1_14.[dbo].[lcc_position_Entity_List_Municipio] t1
	inner join (select t1.[lonid],t1.[latid]
		from  FY1718_VOICE_REST_4G_H1_14.[dbo].lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor t1
			inner join [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_14_Orig t2
				on t2.[fileid]=t1.[fileid] and t2.[lonid]=t1.[lonid] and t2.[latid]=t1.[latid] and t2.[MeasDate]=t1.[MeasDate]
		group by t1.[lonid],t1.[latid]) t2
	on t2.[lonid]=t1.[lonid] and t2.[latid]=t1.[latid]
where fileid not between 265 and 329
group by [fileid],[master].dbo.fn_lcc_getElement(4, collectionname,'_')

--En este punto también debemos tomar una decision: 
--si el impacto es mínimo, como es el caso de Leganes, no tendría sentido hacer un recálculo de su aportación
--Con el recálculo del otro system de Fuenlabrada, nos valdría.
--Además Leganes, es una entidad ya cerrada.

--En bbdd origen, valdría con el parcial de los logs y no habría que borrarlos:
-- No tenemos cálculo de ProbCobInd de pilotos hasta la union.
-- Las tablas _ord se recargan enteras


--Lanzamos parcial del calculo en origen:
----------------------------------------------
--De momento hay que lanzar por partes cada uno de los between: (ya se avisará cuando se pueda hacer de forma conjunta con or)
--between 193 and 200 / between 209 and 216 / between 225 and 232 / between 241 and 256
exec sp_plcc_create_lcc_Scanner_all_50x50_probCobIndoor_Fileid 'ALL', 'between 193 and 200'


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Recalculo en BBDD Union
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Para que el cruce de la info sea más eficiente, generamos una tabla temporal con las parcelas a borrar:

use [FY1718_Coverage_Union_H1]
exec sp_lcc_dropifexists '_tmp_positions_bbbd_14'

select [fileid],[lonid],[latid],[MeasDate],[Entity_name]
into [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_14
from [FY1718_Coverage_Union_H1].[dbo].[lcc_position_Entity_List_Municipio]
where fileid between 265 and 329 and [Entity_name]<> 'MOSTOLES' and ddbb='FY1718_VOICE_REST_4G_H1_14'
group by [fileid],[lonid],[latid],[MeasDate],[Entity_name]


--Identificamos que posibles recalculos tenemos que hacer: 
--De las parcelas de las que vamos a borrar info de system 5 de Fuenlabrada miramos que otros logs las mallan en la Union (NO tiene por qué coincidir con lo que nos sale en origen)
--101 y 103 logs de Leganes y logs de Fuenlabrada del otro system
select ddbb,[fileid],[master].dbo.fn_lcc_getElement(4, collectionname,'_'), count(distinct convert(varchar,t1.lonid)+'_'+convert(varchar,t1.latid)) as 'Num_Parcelas'
from [FY1718_Coverage_Union_H1].[dbo].[lcc_position_Entity_List_Municipio] t1
	inner join (select t1.[lonid],t1.[latid]
		from  [FY1718_Coverage_Union_H1].[dbo].lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor t1
			inner join [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_14 t2
				on t2.[fileid]=t1.[fileid] and t2.[lonid]=t1.[lonid] and t2.[latid]=t1.[latid] and t2.[MeasDate]=t1.[MeasDate]
		group by t1.[lonid],t1.[latid]) t2
	on t2.[lonid]=t1.[lonid] and t2.[latid]=t1.[latid]
where fileid not between 265 and 329 or ddbb<>'FY1718_VOICE_REST_4G_H1_14'
group by ddbb,[fileid],[master].dbo.fn_lcc_getElement(4, collectionname,'_')


--En este caso, nos sale lo mismo que en origen (NO tiene por qué), nos aseguramos:
select [master].dbo.fn_lcc_getElement(4, collectionname,'_'),[Entity_name],DDBB, count(distinct convert(varchar,lonid)+'_'+convert(varchar,latid)) as 'Num_Parcelas'
from [FY1718_Coverage_Union_H1].[dbo].[lcc_position_Entity_List_Municipio]
where [Entity_name] = 'FUENLABRADA'
group by master.dbo.fn_lcc_getElement(4, collectionname,'_'),[Entity_name],DDBB
order by 1,2
--Solo hay 22 parcelas malladas por Móstoles de la bbdd _15 pero estas no coinciden con las que vamos a borrar


--Borrado en bbdd union
----------------------------------------------
--Borramos la información del system 5 que queremos pero también la del otro system que tienen mallado común y que luego recalcularemos:

--Tabla temporal con las parcelas del recalculo:

use [FY1718_Coverage_Union_H1]
exec sp_lcc_dropifexists '_tmp_positions_bbbd_14_Recalculo'

select [fileid],[lonid],[latid],[MeasDate],[Entity_name]
into [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_14_Recalculo
from [FY1718_Coverage_Union_H1].[dbo].[lcc_position_Entity_List_Municipio]
where (fileid between 193 and 200 or fileid between 209 and 216 or fileid between 225 and 232 or fileid between 241 and 256) and ddbb='FY1718_VOICE_REST_4G_H1_14'
group by [fileid],[lonid],[latid],[MeasDate],[Entity_name]


-- Query análoga en las siguientes tablas:
--		lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
--		lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
--		lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor
--		lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord
--		lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord
--		lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord

--Borrado de system 5:
delete [FY1718_Coverage_Union_H1].[dbo].lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
from  [FY1718_Coverage_Union_H1].[dbo].lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor t1
	inner join [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_14 t2
		on t2.[fileid]=t1.[fileid] and t2.[lonid]=t1.[lonid] and t2.[latid]=t1.[latid] and t2.[MeasDate]=t1.[MeasDate]


--Borrado del recalculo:
delete [FY1718_Coverage_Union_H1].[dbo].lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
from  [FY1718_Coverage_Union_H1].[dbo].lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor t1
	inner join [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_14_Recalculo t2
		on t2.[fileid]=t1.[fileid] and t2.[lonid]=t1.[lonid] and t2.[latid]=t1.[latid] and t2.[MeasDate]=t1.[MeasDate]


-- Query análoga en las siguientes tablas:
--		lcc_GSMScanner_50x50_ProbCobIndoor
--		lcc_UMTSScanner_50x50_ProbCobIndoor

--Borrado de system 5:
delete [FY1718_Coverage_Union_H1].[dbo].lcc_GSMScanner_50x50_ProbCobIndoor
from  [FY1718_Coverage_Union_H1].[dbo].lcc_GSMScanner_50x50_ProbCobIndoor t1
	inner join [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_14 t2
		on t2.[lonid]=t1.[lonid] and t2.[latid]=t1.[latid]


--Borrado del recalculo:
delete [FY1718_Coverage_Union_H1].[dbo].lcc_GSMScanner_50x50_ProbCobIndoor
from  [FY1718_Coverage_Union_H1].[dbo].lcc_GSMScanner_50x50_ProbCobIndoor t1
	inner join [FY1718_Coverage_Union_H1].dbo._tmp_positions_bbbd_14_Recalculo t2
		on t2.[lonid]=t1.[lonid] and t2.[latid]=t1.[latid]



--Lanzamos parcial del calculo en union:
----------------------------------------------
--De momento hay que lanzar por partes cada uno de los between: (ya se avisará cuando se pueda hacer de forma conjunta con or)
--between 193 and 200 / between 209 and 216 / between 225 and 232 / between 241 and 256
exec plcc_Coverage_union_ddbb_Fileid 'FY1718_VOICE_REST_4G_H1_14', 'between 193 and 200' , 1,1,1
