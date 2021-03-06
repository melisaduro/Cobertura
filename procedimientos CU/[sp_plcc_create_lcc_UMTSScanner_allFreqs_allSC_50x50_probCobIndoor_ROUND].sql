USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_plcc_create_lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ROUND]    Script Date: 14/03/2017 11:38:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[sp_plcc_create_lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ROUND] @toDelete int=0
as 


--declare @toDelete as int=1
-----------------
if (@toDelete=1)	
begin		-- Iniciamos la tabla desde el principio
	exec sp_lcc_dropifexists 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor'
	exec sp_lcc_dropifexists 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid'	-- podria valer el de GSM no ?¿ - todos para 1
	select convert(bigint,0) max_fileid into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid
end

if ((select name from sys.all_objects where name='lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid' and type='U') is  null )
begin		-- Inicializa el ultimo fileid procesado a 0
	select convert(bigint,0) max_fileid into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid
end

declare @max_fileid bigint =(select max(max_fileid) from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid)

--Calculamos la entidad medida por cada log: 
--Añadimos el cruce con la tabla de AGRIDs lcc_AVE_ROAD_names para hacer la traducción de collectionname 
--a nombre procesado (AVEs extra->nombre largo, Resto->nombre corto). 
--Si se añade algún AVE o ROAD adicional, habría que añadirlo en esa tabla.

exec sp_lcc_dropifexists 'temporal_log' 
select FileId,concat(t.entity_procesado,'-',Substring([master].dbo.fn_lcc_getElement(4, CollectionName,'_'),len([master].dbo.fn_lcc_getElement(4, CollectionName,'_'))-charindex('-',reverse([master].dbo.fn_lcc_getElement(4, CollectionName,'_')))+2,3)) as 'Entidad_Medida'
into temporal_log
from FileList f, AGRIDS.dbo.lcc_AVE_ROAD_names t 
where FileId>@max_fileid
and reverse(Substring(reverse([master].dbo.fn_lcc_getElement(4, f.CollectionName,'_')),charindex('-',reverse([master].dbo.fn_lcc_getElement(4, f.CollectionName,'_')))+1,len(reverse([master].dbo.fn_lcc_getElement(4, f.CollectionName,'_')))))= t.entity_collectionname 
group by FileId,entity_procesado,CollectionName


-------------------------------------------------------------------------------------------------
-- 1) Crea la tabla de todos los pilotos, añadiendo la probabilidad de cober de cada uno de ellos 
-------------------------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_sc'

select 
	lonid, latid, Channel, sc as SCode, MeasDate,
	10*log10(avg(RSCP_lin)) as RSCP_avg,
	10*log10(avg(EcI0_lin)) as EcI0_avg,
	avg(RSCP_median)		as RSCP_median,
	avg(EcI0_median)		as EcI0_median,
	Entidad_Medida
into temporal_sc
from (
	select 
		lonid, latid, li.Channel, li.sc, p.MeasDate,

		POWER(CAST(10 AS float), ((li.rxlev+li.CPICH)/10.0)) as RSCP_lin,  
		percentile_cont(0.5) 
			within group (order by  (li.rxlev+li.CPICH))
					over (partition by lonid, latid, li.Channel, li.sc,Entidad_Medida) as RSCP_median,
			          
		POWER(CAST(10 AS float), (li.CPICH)/10.0) as EcI0_lin,            
		percentile_cont(0.5) 
			within group (order by li.CPICH)
					over (partition by lonid, latid, li.Channel, li.sc,Entidad_Medida) as EcI0_median,
		e.Entidad_Medida
	from lcc_scannerWcdma li,
		 (select *, CONVERT(INT, 2224.0*p.longitude*COS(2*PI()*p.latitude/360)) as  lonid, 
			   CONVERT(INT, 2224.0*p.latitude)as latid,
			   right('0000'+convert(varchar(4), year(p.msgtime)),4)+
			   right('0000'+convert(varchar(4), month(p.msgtime)),2)+
			   right('0000'+convert(varchar(4), day(p.msgtime)),2) as Measdate
		 from Position p) p,
		 temporal_log e
		 --,  sessions s		-- Se añade el linkado con sessions, para quedarnos con las VALIDAS (invalidaciones por fuera de contorno)
	where 
		li.PosId=p.PosId  -- and p.sessionid=s.sessionid and s.valid=1
		and p.FileId=e.FileId
		and p.FileId>@max_fileid		-- solo considera la nueva inf
		--and p.FileId=3
) t

group by lonid, latid, Channel, sc, MeasDate,Entidad_Medida


-- select * from temporal_sc



------------------------------------------------------------------------------
-- 2) Tabla con los valores medios por cuadricula de cada magnitud
--		* ordenacion por banda y operador
--------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_sc2'
select 
	(c.lonid/2224.0)*(1/(cos(2*pi()*c.latid/(2224.0*360)))) as longitude,	c.latid/2224.0 as latitude,
	c.lonid,	c.latid,
	Channel,	SCode,
	RSCP_avg,	RSCP_median,
	EcI0_avg,	EcI0_median,

	sof.Band,	sof.ServingOperator as operator,
	c.Measdate,
	master.dbo.fn_lcc_ProbindoorCoverage(rscp_median,sof.Band, 
									case i.mob_type when 3 then 'DU' 
													when 2 then 'U' 
													else 'SU' end
								, 'voice' )								as PcobInd_voice,
	master.dbo.fn_lcc_ProbindoorCoverage(rscp_median,sof.Band, 
									case i.mob_type when 3 then 'DU' 
													when 2 then 'U' 
													else 'SU' end
								, 'Data Good' )							as PcobInd_DataGood,
	master.dbo.fn_lcc_ProbindoorCoverage(rscp_median,sof.Band, 
									case i.mob_type when 3 then 'DU' 
													when 2 then 'U' 
													else 'SU' end
								, 'Data Fair' )							as PcobInd_DataFair,
    i.codigo_ine
	,c.Entidad_Medida
into temporal_sc2
from 
    (
	select *, ROW_NUMBER() over (partition by lonid, latid, Channel, SCode,Entidad_Medida order by RSCP_median desc, measdate desc) as mdate_id
	from temporal_sc
    )  c
	LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof	on c.Channel=sof.Frequency
	LEFT OUTER JOIN [AGRIDS].dbo.lcc_G2K5Absolute_INDEX_new	  i		on c.lonid=i.lonid and c.latid=i.latid

where c.mdate_id=1

-- select * from temporal_sc2



------------------------------------------------------------------------------
-- 3) Tabla final con la info actualizada
--		* tenemos 1 linea por cuadrícula
--		* se guarda la información con mejor resultado y mas reciente siempre
--		* se mantiene tmb info del dia de la medida, por si fuera necesario invalidar
--				meas date -> aaaa/mm/dd
------------------------------------------------------------------------------
if ((select name from sys.all_objects where name='lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor' and type='U') is  null )
	begin
		------------------------------------------
		-- Crea desde el principio la tabla con las prob por cuadricula
		------------------------------------------
		 select *, convert(int,1) as valid 
		 into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor
		 from temporal_sc2
	end
else
begin
		------------------------------------------
		-- Update de las cuadriculas comunes
		------------------------------------------
		update  lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor
		set RSCP_avg	=	t.RSCP_avg,				RSCP_median	=	t.RSCP_median,		
			EcI0_avg	=	t.EcI0_avg,				EcI0_median	=	t.EcI0_median,

			PcobInd_voice		=	t.PcobInd_voice,
			PcobInd_DataGood	=	t.PcobInd_DataGood,
			PcobInd_DataFair	=	t.PcobInd_DataFair,

			measdate		=	t.Measdate,
			valid			=	1
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor c, temporal_sc2 t
		where 
			--Actualizamos parcelas con mismo canal, sc y entidad_medida
			c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.SCode=t.SCode and c.Entidad_Medida=t.Entidad_Medida
			--cuya mediana de nivel de señal sea mejor ahora o siendo igual que la fecha de medida sea mas actual
			and (t.RSCP_median>c.RSCP_median									-- la nueva es mayor que la existente
				or (t.RSCP_median=c.RSCP_median and t.Measdate>c.Measdate))		-- si son iguales, nos quedamos con la reciente

		------------------------------------------
		-- Borrado de las comunes actualizadas
		------------------------------------------
		-- prompt de los pilots actualizados
		select sum(1) as updated_pilots
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor c, temporal_sc2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.SCode=t.SCode and c.Entidad_Medida=t.Entidad_Medida
					and (t.RSCP_median>c.RSCP_median 
						or (t.RSCP_median=c.RSCP_median and t.Measdate>c.measdate))
		-- Borrado de las parcelas nuevas que sean coincidentes (hemos podido usar esa info o no por ser peor)
		delete temporal_sc2
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor c, temporal_sc2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.Channel=t.Channel and c.SCode=t.SCode and c.Entidad_Medida=t.Entidad_Medida

	
		---------------------------------------
		-- Insertar las nuevas cuadrículas
		-----------------------------------------
		-- prompt
		select sum(1) as added_newPilots
		from temporal_sc2

		-- Insert de las nuevas cuadriculas/pilotos
		insert into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor
		select *, convert(int, 1) as valid
		from temporal_sc2
end

-- select * from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor



------------------------------------------------------------------------------
-- 4) Update de ultimo fileid
------------------------------------------------------------------------------
-- prompt
select max_fileid as Initial_fileid_Processed
from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid

--
update lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid
set max_fileid=(select max(fileid) from filelist)

-- prompt
select max_fileid as Last_fileid_included
from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid



------------------------------------------------------------------------------
-- 5) Tabla con la ordenación de pilotos por nivel:
--		* debe crearse desde cero cada vez ya que le influyen los cambios y updates 
--		  que se hayan podido producir en la tabla de lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
--		* en 4G, con el primero es suficiente (20 para 2G y 5 para el 3G)
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord'
select *,
	-- Ordenacion por operador - es la que se utilizara para crear la tabla:	lcc_LTEScanner_50x50_ProbCobIndoor
	ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									Entidad_Medida
					   order by RSCP_median desc)				  as operator_ord,
	-- Ordenación por operador y Banda:
    ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band,
									Entidad_Medida
					    order by RSCP_median desc)				 as operator_band_ord,
	-- En el caso de 3G y 4G hay que añadir ordenación por canal
    ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band,
									channel,
									Entidad_Medida
					    order by RSCP_median desc)				 as operator_band_channel_ord
into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord	
from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor

-- Prompt --
select 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord' New_Table_Ordered_pilots_perBand_and_Operator_Created


---- prompt --
--select 'lcc_UMTSScanner_50x50_ProbCobIndoor' New_Table_3G_probCobIndoor_Created
----------

------------------------------------------------------------------------------
-- Borrado de las tablas temporales
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_log'
exec sp_lcc_dropifexists 'temporal_sc'
exec sp_lcc_dropifexists 'temporal_sc2'


