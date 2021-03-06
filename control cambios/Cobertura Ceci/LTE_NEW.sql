--USE [master]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_plcc_create_lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor]    Script Date: 03/10/2017 13:59:03 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO


--ALTER procedure [dbo].[sp_plcc_create_lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor] @toDelete int=0
--as 

--use FY1718_VOICE_REST_4G_H1_27 --SITGES
--use FY1718_VOICE_REST_4G_H1_13 --ALCORCON
use FY1718_VOICE_VALENCIA_4G_H1


----declare @toDelete as int=0

--declare @dateIni as datetime = getdate()
-------------------
--if (@toDelete=1)	
--begin		-- Iniciamos la tabla desde el principio
--	exec sp_lcc_dropifexists 'lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor'
--	exec sp_lcc_dropifexists 'lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid'		-- podria valer el de GSM no ?¿ - todos para 1
--	select convert(bigint,0) max_fileid into lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid
--end

-------------------
--if ((select name from sys.all_objects where name='lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid' and type='U') is  null )	
--begin		-- Inicializa el ultimo fileid procesado a 0
--	select convert(bigint,0) max_fileid into lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid
--end

-------------------
--declare @max_fileid bigint = (select max(max_fileid) from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid)



-------------------------------------------------------------------------------------------------
-- 1) Crea la tabla de todos los pilotos, añadiendo la probabilidad de cober de cada uno de ellos 
-------------------------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_pci'
select
	lonid, latid, Channel, PhCId,  MeasDate, BandWidth,
	10*log10(avg(RSRP_lin)) as RSRP_avg,
	10*log10(avg(RSRQ_lin)) as RSRQ_avg,
	10*log10(avg(CINR_lin)) as CINR_avg,
	avg(RSRP_median)		as RSRP_median,
	avg(RSRQ_median)		as RSRQ_median,
	avg(CINR_median)		as CINR_median,
	--NEW
	FileId --FileId que nos da la info para poder controlar las parcelas con info nueva
into temporal_pci
from (
	select 
		lonid, 	latid, li.Channel, l.PhCId,	p.MeasDate, li.bandwidth/1000 as BandWidth,

		POWER(CAST(10 AS float), (l.RSRP)/10.0) as RSRP_lin,  
		percentile_cont(0.5) 
			within group (order by l.RSRP)
					over (partition by lonid, latid, li.Channel, l.PhCId, p.MeasDate,
						--CAC 02/10/2017: se calcula el valor de parcela-piloto por fecha y, ahora también, por fileid
						FileId) as RSRP_median,
			          
		POWER(CAST(10 AS float), (l.RSRQ)/10.0) as RSRQ_lin,            
		percentile_cont(0.5) 
			within group (order by l.RSRQ)
					over (partition by lonid, latid, li.Channel, l.PhCId, p.MeasDate,
						--CAC 02/10/2017: se calcula el valor de parcela-piloto por fecha y, ahora también, por fileid
						FileId) as RSRQ_median,

		POWER(CAST(10 AS float), (l.CINR)/10.0) as CINR_lin,  
		percentile_cont(0.5) 
			within group (order by l.CINR)
					over (partition by lonid, latid, li.Channel, l.PhCId, p.MeasDate,
						--CAC 02/10/2017: se calcula el valor de parcela-piloto por fecha y, ahora también, por fileid
						FileId) as CINR_median
		--NEW
		,p.FileId
	from MsgLTEScannerTopNInfo li, MsgLTEScannerTopN l, 
		 (select *, CONVERT(INT, 2224.0*p.longitude*COS(2*PI()*p.latitude/360)) as  lonid, 
			   CONVERT(INT, 2224.0*p.latitude)as latid,
			   right('0000'+convert(varchar(4), year(p.msgtime)),4)+
			   right('0000'+convert(varchar(4), month(p.msgtime)),2)+
			   right('0000'+convert(varchar(4), day(p.msgtime)),2) as Measdate
		 from Position p) p
	where 
		li.LTETopNId=l.LTETopNId and li.PosId=p.PosId 
		--SITGES
		--and (p.FileId between 9 and 24 or p.fileid between 33 and 48)
		--and (p.FileId between 9 and 24) -- solo considera la nueva info
		--and (p.fileid between 33 and 48) -- solo considera la nueva info	
		--ALCORCON 57-96   102-125
		--and (p.FileId between 57 and 96 or p.fileid between 102 and 125)
		--VALENCIA: todos los logs
) t
group by lonid, latid, Channel, PhCId, Measdate, BandWidth,fileid

-- select * from temporal_pci

------------------------------------------------------------------------------
-- 2) Tabla con los valores medios por cuadricula de cada magnitud
--		* ordenacion por banda y operador
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_pci2'
select 
	(c.lonid/2224.0)*(1/(cos(2*pi()*c.latid/(2224.0*360)))) as longitude,	c.latid/2224.0 as latitude,
	c.lonid,	c.latid,
	Channel,	PhCId,
	RSRP_avg as RSRP_avg,	RSRP_median as RSRP_median,
	RSRQ_avg as RSRQ_avg,	RSRQ_median as RSRQ_median,
	CINR_avg as CINR_avg,	CINR_median as CINR_median,

	sof.Band,	sof.ServingOperator as Operator, c.BandWidth,
	c.Measdate,
	master.dbo.fn_lcc_ProbindoorCoverage(RSRP_median, sof.Band, 
	                                 case i.mob_type when 3 then 'DU' when 2 then 'U' else 'SU' end, 'voice' ) as PcobInd
    ,i.codigo_ine
	--NEW
	,c.FileId
into temporal_pci2
from 
    (select *, ROW_NUMBER() over (partition by lonid, latid, Channel, PhCId order by RSRP_median desc, Measdate desc, fileid desc) as mdate_id
	from temporal_pci)  c
		LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq	sof	on c.Channel=sof.Frequency
		LEFT OUTER JOIN [AGRIDS].dbo.lcc_G2K5Absolute_INDEX_new		i	on c.lonid=i.lonid and c.latid=i.latid
where c.mdate_id=1

-- select * from temporal_pci2


------------------------------------------------------------------------------
-- 3) Tabla final con la info actualizada
--		* tenemos 1 linea por cuadrícula
--		* se guarda la información con mejor resultado y mas reciente siempre
--		* se mantiene tmb info del dia de la medida, por si fuera necesario invalidar
--				meas date -> aaaa/mm/dd
------------------------------------------------------------------------------
if ((select name from sys.all_objects where name='lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_VALENCIA_NEW' and type='U') is  null )
	begin
		------------------------------------------
		-- Crea desde el principio la tabla con las prob por cuadricula
		------------------------------------------
		 select *, convert(int,1) as valid 
		 into lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_VALENCIA_NEW
		 from temporal_pci2
	end
else
begin
		------------------------------------------
		-- Update de las cuadriculas comunes
		------------------------------------------
		update  lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_VALENCIA_NEW
		set RSRP_avg	=	t.RSRP_avg,				RSRP_median	=	t.RSRP_median,		
			RSRQ_avg	=	t.RSRQ_avg,				RSRQ_median	=	t.RSRQ_median,
			CINR_avg	=	t.CINR_avg,				CINR_median	=	t.CINR_median,

			PcobInd		=	t.PcobInd,
			measdate	=	t.Measdate,
			BandWidth	=	t.BandWidth,
			valid		=	1
			--NEW
			,FileId= t.FileId
		from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_VALENCIA_NEW c, temporal_pci2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.PhCId=t.PhCId
				and (t.RSRP_median>c.RSRP_median									-- la nueva es mayor que la existente
					or (t.RSRP_median=c.RSRP_median and (t.Measdate>c.measdate or (t.Measdate=c.measdate or t.fileid>c.fileid))))	-- si son iguales, nos quedamos con la reciente

		------------------------------------------
		-- Borrado de las comunes actualizadas
		------------------------------------------
		-- prompt de los pilots actualizados
		select sum(1) as updated_pilots
		from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_VALENCIA_NEW c, temporal_pci2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.PhCId=t.PhCId
					and (t.RSRP_median>c.RSRP_median 
						or (t.RSRP_median=c.RSRP_median and (t.Measdate>c.measdate or (t.Measdate=c.measdate or t.fileid>c.fileid))))
		-- Borrado
		delete temporal_pci2
		from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_VALENCIA_NEW c, temporal_pci2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.Channel=t.Channel and c.PhCId=t.PhCId
				--and (t.RSRP_median>c.RSRP_median 
				--	or (t.RSRP_median=c.RSRP_median and t.Measdate>c.Measdate))
	
		---------------------------------------
		-- Insertar las nuevas cuadrículas
		-----------------------------------------
		-- prompt
		select sum(1) as added_newPilots
		from temporal_pci2

		-- Insert de las nuevas cuadriculas/pilotos
		insert into lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_VALENCIA_NEW
		select *, convert(int, 1) as valid
		from temporal_pci2
end

-- select * from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor


------------------------------------------------------------------------------
-- 4) Update de ultimo fileid
------------------------------------------------------------------------------
---- prompt
--select max_fileid as Initial_fileid_Processed
--from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid

----
--update lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid
--set max_fileid=(select max(fileid) from filelist)

---- prompt
--select max_fileid as Last_fileid_included
--from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid
	

------------------------------------------------------------------------------
-- 5) Tabla con la ordenación de pilotos por nivel:
--		* debe crearse desde cero cada vez ya que le influyen los cambios y updates 
--		  que se hayan podido producir en la tabla de lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
--		* en 4G, con el primero es suficiente (20 para 2G y 5 para el 3G)
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord_VALENCIA_NEW'
select *,
	-- Ordenacion por operador - es la que se utilizara para crear la tabla:	lcc_LTEScanner_50x50_ProbCobIndoor
	ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator
					   order by RSRP_median desc)				  as operator_ord,
	-- Ordenación por operador y Banda:
    ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band
					    order by RSRP_median desc)				 as operator_band_ord,
	-- En el caso de 3G y 4G hay que añadir ordenación por canal
    ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band,
									channel
					    order by RSRP_median desc)				 as operator_band_channel_ord
into lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord_VALENCIA_NEW	
from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_VALENCIA_NEW

-- Prompt --
select 'lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord' New_Table_Ordered_pilots_perBand_and_Operator_Created


------------------------------------------------------------------------------
-- 6) Prob de cobertura por operador y banda considerando sólo el primer piloto
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_LTEScanner_50x50_ProbCobIndoor_VALENCIA_NEW'
select 
	b.*, 
	n.num_pilots,	-- numero de pilotos teniendo en cuenta la ordenación por operador solo
	n.measdate,
	p1.RSRP_median as RSRP_BS, p1.RSRQ_median as RSRQ_BS, p1.CINR_median as CINR_BS,
	p1.Channel as Channel_BS, 
	p1.BandWidth,
	p1.PhCId as PhCId_BS,	
	p1.PcobInd as p1_PcobInd
	--NEW
	,p1.FileId
into lcc_LTEScanner_50x50_ProbCobIndoor_VALENCIA_NEW
from
	(select b1.*, op.* 
	from
		(select longitude, latitude, lonid, latid 
		from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord_VALENCIA_NEW
		group by longitude, latitude, lonid,latid
		) b1,  

		(select operator 
		from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator is not null group by operator) op
	) b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover
	
	LEFT OUTER JOIN	(select lonid, latid, operator, 
							max(operator_ord) as num_pilots, min(measdate) as min_measdate, max(measdate) as measdate
					from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord_VALENCIA_NEW
					group by lonid, latid, operator
					) n on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator
  
  -- cada uno de los pilotos y su cobertura -> en este caso solo 1, el primero
	LEFT OUTER JOIN	(select lonid, latid, operator, channel, BandWidth, PhCId, RSRP_median,band, RSRQ_median, CINR_median, PcobInd
						--NEW
						,FileId
					from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord_VALENCIA_NEW
					where operator_ord=1
					) p1 on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator


-- prompt --
select 'lcc_LTEScanner_50x50_ProbCobIndoor' New_Table_4G_probCobIndoor_Created
----------

------------------------------------------------------------------------------
-- Control ejecucion lanzada
------------------------------------------------------------------------------
--insert into [AddedValue].dbo.[lcc_executions_coverage]
--select db_name(),'4G','sp_plcc_create_lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor', @dateIni, GETDATE(),
--	@max_fileid,(select max(max_fileid) from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid),
--	@toDelete,NULL,
--	NULL,NULL,NULL,NULL,NULL,
--	NULL,NULL,
--	NULL

------------------------------------------------------------------------------
-- Borrado de las tablas temporales
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_pci'
exec sp_lcc_dropifexists 'temporal_pci2'
