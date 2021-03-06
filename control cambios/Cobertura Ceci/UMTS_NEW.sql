--USE [master]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_plcc_create_lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor]    Script Date: 03/10/2017 14:53:00 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--ALTER procedure [dbo].[sp_plcc_create_lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor] @toDelete int=0
--as 
--use FY1718_VOICE_REST_4G_H1_27 --SITGES
use FY1718_VOICE_REST_4G_H1_13

----declare @toDelete as int=1

--declare @dateIni as datetime = getdate()
-------------------
--if (@toDelete=1)	
--begin		-- Iniciamos la tabla desde el principio
--	exec sp_lcc_dropifexists 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor'
--	exec sp_lcc_dropifexists 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid'	-- podria valer el de GSM no ?¿ - todos para 1
--	select convert(bigint,0) max_fileid into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid
--end

--if ((select name from sys.all_objects where name='lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid' and type='U') is  null )
--begin		-- Inicializa el ultimo fileid procesado a 0
--	select convert(bigint,0) max_fileid into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid
--end

--declare @max_fileid bigint =(select max(max_fileid) from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid)


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
	--NEW
	FileId -- FileId que nos da la info para poder controlar las parcelas con info nueva
into temporal_sc
from (
	select 
		lonid, latid, li.Channel, li.sc, p.MeasDate,

		POWER(CAST(10 AS float), ((li.rxlev+li.CPICH)/10.0)) as RSCP_lin,  
		percentile_cont(0.5) 
			within group (order by  (li.rxlev+li.CPICH))
					over (partition by lonid, latid, li.Channel, li.sc, p.MeasDate,
						--CAC 02/10/2017: se calcula el valor de parcela-piloto por fecha y, ahora también, por fileid
						FileId) as RSCP_median,
			          
		POWER(CAST(10 AS float), (li.CPICH)/10.0) as EcI0_lin,            
		percentile_cont(0.5) 
			within group (order by li.CPICH)
					over (partition by lonid, latid, li.Channel, li.sc, p.MeasDate,
						--CAC 02/10/2017: se calcula el valor de parcela-piloto por fecha y, ahora también, por fileid
						FileId) as EcI0_median
		--NEW
		,p.FileId
	from lcc_scannerWcdma li,
		 (select *, CONVERT(INT, 2224.0*p.longitude*COS(2*PI()*p.latitude/360)) as  lonid, 
			   CONVERT(INT, 2224.0*p.latitude)as latid,
			   right('0000'+convert(varchar(4), year(p.msgtime)),4)+
			   right('0000'+convert(varchar(4), month(p.msgtime)),2)+
			   right('0000'+convert(varchar(4), day(p.msgtime)),2) as Measdate
		 from Position p) p
		 --,  sessions s		-- Se añade el linkado con sessions, para quedarnos con las VALIDAS (invalidaciones por fuera de contorno)
	where 
		li.PosId=p.PosId  -- and p.sessionid=s.sessionid and s.valid=1
		--SITGES
		--and (p.FileId between 9 and 24 or p.fileid between 33 and 48)
		--and (p.FileId between 9 and 24) -- solo considera la nueva info
		--and (p.fileid between 33 and 48) -- solo considera la nueva info	
		--ALCORCON 57-96   102-125
		and (p.FileId between 57 and 96 or p.fileid between 102 and 125)
) t

group by lonid, latid, Channel, sc, MeasDate,FileId


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
	--NEW
	,c.FileId
into temporal_sc2
from 
    (
	select *, ROW_NUMBER() over (partition by lonid, latid, Channel, SCode order by RSCP_median desc, measdate desc, fileid desc) as mdate_id
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
if ((select name from sys.all_objects where name='lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ALCORCON_NEW' and type='U') is  null )
	begin
		------------------------------------------
		-- Crea desde el principio la tabla con las prob por cuadricula
		------------------------------------------
		 select *, convert(int,1) as valid 
		 into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ALCORCON_NEW
		 from temporal_sc2
	end
else
begin
		------------------------------------------
		-- Update de las cuadriculas comunes
		------------------------------------------
		update  lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ALCORCON_NEW
		set RSCP_avg	=	t.RSCP_avg,				RSCP_median	=	t.RSCP_median,		
			EcI0_avg	=	t.EcI0_avg,				EcI0_median	=	t.EcI0_median,

			PcobInd_voice		=	t.PcobInd_voice,
			PcobInd_DataGood	=	t.PcobInd_DataGood,
			PcobInd_DataFair	=	t.PcobInd_DataFair,

			measdate		=	t.Measdate,
			valid			=	1
			--NEW
			,FileId= t.FileId
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ALCORCON_NEW c, temporal_sc2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.SCode=t.SCode
				and (t.RSCP_median>c.RSCP_median									-- la nueva es mayor que la existente
					or (t.RSCP_median=c.RSCP_median and (t.Measdate>c.measdate or (t.Measdate=c.measdate or t.fileid>c.fileid))))-- si son iguales, nos quedamos con la reciente

		------------------------------------------
		-- Borrado de las comunes actualizadas
		------------------------------------------
		-- prompt de los pilots actualizados
		select sum(1) as updated_pilots
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ALCORCON_NEW c, temporal_sc2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.SCode=t.SCode
					and (t.RSCP_median>c.RSCP_median 
						or (t.RSCP_median=c.RSCP_median and (t.Measdate>c.measdate or (t.Measdate=c.measdate or t.fileid>c.fileid))))
		-- Borrado
		delete temporal_sc2
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ALCORCON_NEW c, temporal_sc2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.Channel=t.Channel and c.SCode=t.SCode
					--and (t.RSRP_median>c.RSRP_median 
					--	or (t.RSRP_median=c.RSRP_median and t.Measdate>c.measdate))
	
		---------------------------------------
		-- Insertar las nuevas cuadrículas
		-----------------------------------------
		-- prompt
		select sum(1) as added_newPilots
		from temporal_sc2

		-- Insert de las nuevas cuadriculas/pilotos
		insert into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ALCORCON_NEW
		select *, convert(int, 1) as valid
		from temporal_sc2
end

-- select * from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor



------------------------------------------------------------------------------
-- 4) Update de ultimo fileid
------------------------------------------------------------------------------
---- prompt
--select max_fileid as Initial_fileid_Processed
--from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid

----
--update lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid
--set max_fileid=(select max(fileid) from filelist)

---- prompt
--select max_fileid as Last_fileid_included
--from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid



------------------------------------------------------------------------------
-- 5) Tabla con la ordenación de pilotos por nivel:
--		* debe crearse desde cero cada vez ya que le influyen los cambios y updates 
--		  que se hayan podido producir en la tabla de lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
--		* en 4G, con el primero es suficiente (20 para 2G y 5 para el 3G)
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_ALCORCON_NEW'
select *,
	-- Ordenacion por operador - es la que se utilizara para crear la tabla:	lcc_LTEScanner_50x50_ProbCobIndoor
	ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator
					   order by RSCP_median desc)				  as operator_ord,
	-- Ordenación por operador y Banda:
    ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band
					    order by RSCP_median desc)				 as operator_band_ord,
	-- En el caso de 3G y 4G hay que añadir ordenación por canal
    ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band,
									channel
					    order by RSCP_median desc)				 as operator_band_channel_ord
into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_ALCORCON_NEW	
from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ALCORCON_NEW

-- Prompt --
select 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord' New_Table_Ordered_pilots_perBand_and_Operator_Created





--------------------------------------------------------------------------------
---- Control ejecucion lanzada
--------------------------------------------------------------------------------
--insert into [AddedValue].dbo.[lcc_executions_coverage]
--select db_name(),'3G','sp_plcc_create_lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor', @dateIni, GETDATE(),
--	@max_fileid,(select max(max_fileid) from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid),
--	@toDelete,NULL,
--	NULL,NULL,NULL,NULL,NULL,
--	NULL,NULL,
--	NULL

------------------------------------------------------------------------------
-- Borrado de las tablas temporales
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_sc'
exec sp_lcc_dropifexists 'temporal_sc2'


