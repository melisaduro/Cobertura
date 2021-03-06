USE [FY1617_Voice_Rest_3G_H1_9]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_plcc_create_lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_20161017]    Script Date: 03/11/2016 9:58:54 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--ALTER procedure [dbo].[sp_plcc_create_lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_20161017] @toDelete int=0
--as 


--declare @toDelete as int=1
-------------------
--if (@toDelete=1)	
--begin		-- Iniciamos la tabla desde el principio
--	exec sp_lcc_dropifexists 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_prueba'
--	exec sp_lcc_dropifexists 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid_prueba'	-- podria valer el de GSM no ?¿ - todos para 1
--	select convert(bigint,0) max_fileid into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid_prueba
--end

--if ((select name from sys.all_objects where name='lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid_prueba' and type='U') is  null )
--begin		-- Inicializa el ultimo fileid procesado a 0
--	select convert(bigint,0) max_fileid into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid_prueba
--end

--declare @max_fileid bigint =(select max(max_fileid) from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid_prueba)


-------------------------------------------------------------------------------------------------
-- 1) Crea la tabla de todos los pilotos, añadiendo la probabilidad de cober de cada uno de ellos 
-------------------------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_sc_prueba'

select 
	lonid, latid, Channel, sc as SCode, MeasDate,
	10*log10(avg(RSCP_lin)) as RSCP_avg,
	10*log10(avg(EcI0_lin)) as EcI0_avg,
	avg(RSCP_median)		as RSCP_median,
	avg(EcI0_median)		as EcI0_median

into temporal_sc_prueba
from (
	select 
		lonid, latid, li.Channel, li.sc, p.MeasDate,

		POWER(CAST(10 AS float), ((li.rxlev+li.CPICH)/10.0)) as RSCP_lin,  
		percentile_cont(0.5) 
			within group (order by  (li.rxlev+li.CPICH))
					over (partition by lonid, latid, li.Channel, li.sc) as RSCP_median,
			          
		POWER(CAST(10 AS float), (li.CPICH)/10.0) as EcI0_lin,            
		percentile_cont(0.5) 
			within group (order by li.CPICH)
					over (partition by lonid, latid, li.Channel, li.sc) as EcI0_median

	from lcc_scannerWcdma li, filelist f, sessions s,
		 (select *, CONVERT(INT, 2224.0*p.longitude*COS(2*PI()*p.latitude/360)) as  lonid, 
			   CONVERT(INT, 2224.0*p.latitude)as latid,
			   right('0000'+convert(varchar(4), year(p.msgtime)),4)+
			   right('0000'+convert(varchar(4), month(p.msgtime)),2)+
			   right('0000'+convert(varchar(4), day(p.msgtime)),2) as Measdate
		 from Position p) p
		 --,  sessions s		-- Se añade el linkado con sessions, para quedarnos con las VALIDAS (invalidaciones por fuera de contorno)
	where 
		f.fileid=s.fileid and s.sessionid=li.sessionid
		and collectionname like '%navalcarnero%'
		and li.PosId=p.PosId  -- and p.sessionid=s.sessionid and s.valid=1
		--and p.FileId>@max_fileid		-- solo considera la nueva inf
		--and p.FileId=3
) t

group by lonid, latid, Channel, sc, MeasDate


-- select * from temporal_sc_prueba



------------------------------------------------------------------------------
-- 2) Tabla con los valores medios por cuadricula de cada magnitud
--		* ordenacion por banda y operador
--------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_sc2_prueba'
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

into temporal_sc2_prueba
from 
    (
	select *, ROW_NUMBER() over (partition by lonid, latid, Channel, SCode order by RSCP_median desc, measdate desc) as mdate_id
	from temporal_sc_prueba
    )  c
	LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof	on c.Channel=sof.Frequency
	LEFT OUTER JOIN [AGRIDS].dbo.lcc_G2K5Absolute_INDEX_new	  i		on c.lonid=i.lonid and c.latid=i.latid

where c.mdate_id=1

-- select * from temporal_sc2_prueba



------------------------------------------------------------------------------
-- 3) Tabla final con la info actualizada
--		* tenemos 1 linea por cuadrícula
--		* se guarda la información con mejor resultado y mas reciente siempre
--		* se mantiene tmb info del dia de la medida, por si fuera necesario invalidar
--				meas date -> aaaa/mm/dd
------------------------------------------------------------------------------
if ((select name from sys.all_objects where name='lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_prueba' and type='U') is  null )
	begin
		------------------------------------------
		-- Crea desde el principio la tabla con las prob por cuadricula
		------------------------------------------
		 select *, convert(int,1) as valid 
		 into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_prueba
		 from temporal_sc2_prueba
	end
else
begin
		------------------------------------------
		-- Update de las cuadriculas comunes
		------------------------------------------
		update  lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_prueba
		set RSCP_avg	=	t.RSCP_avg,				RSCP_median	=	t.RSCP_median,		
			EcI0_avg	=	t.EcI0_avg,				EcI0_median	=	t.EcI0_median,

			PcobInd_voice		=	t.PcobInd_voice,
			PcobInd_DataGood	=	t.PcobInd_DataGood,
			PcobInd_DataFair	=	t.PcobInd_DataFair,

			measdate		=	t.Measdate,
			valid			=	1
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_prueba c, temporal_sc2_prueba t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.SCode=t.SCode
				and (t.RSCP_median>c.RSCP_median									-- la nueva es mayor que la existente
					or (t.RSCP_median=c.RSCP_median and t.Measdate>c.Measdate))		-- si son iguales, nos quedamos con la reciente

		------------------------------------------
		-- Borrado de las comunes actualizadas
		------------------------------------------
		-- prompt de los pilots actualizados
		select sum(1) as updated_pilots
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_prueba c, temporal_sc2_prueba t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.SCode=t.SCode
					and (t.RSCP_median>c.RSCP_median 
						or (t.RSCP_median=c.RSCP_median and t.Measdate>c.measdate))
		-- Borrado
		delete temporal_sc2_prueba
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_prueba c, temporal_sc2_prueba t
		where c.lonid=t.lonid and c.latid=t.latid and c.Channel=t.Channel and c.SCode=t.SCode
					--and (t.RSRP_median>c.RSRP_median 
					--	or (t.RSRP_median=c.RSRP_median and t.Measdate>c.measdate))
	
		---------------------------------------
		-- Insertar las nuevas cuadrículas
		-----------------------------------------
		-- prompt
		select sum(1) as added_newPilots
		from temporal_sc2_prueba

		-- Insert de las nuevas cuadriculas/pilotos
		insert into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_prueba
		select *, convert(int, 1) as valid
		from temporal_sc2_prueba
end

-- select * from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_prueba



------------------------------------------------------------------------------
-- 4) Update de ultimo fileid
------------------------------------------------------------------------------
---- prompt
--select max_fileid as Initial_fileid_Processed
--from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid_prueba

----
--update lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid_prueba
--set max_fileid=(select max(fileid) from filelist)

---- prompt
--select max_fileid as Last_fileid_included
--from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid_prueba



------------------------------------------------------------------------------
-- 5) Tabla con la ordenación de pilotos por nivel:
--		* debe crearse desde cero cada vez ya que le influyen los cambios y updates 
--		  que se hayan podido producir en la tabla de lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
--		* en 4G, con el primero es suficiente (20 para 2G y 5 para el 3G)
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba'
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
into lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba
from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_prueba

-- Prompt --
select 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba' New_Table_Ordered_pilots_perBand_and_Operator_Created



------------------------------------------------------------------------------
-- 6) Prob de cobertura por operador y banda considerando sólo el primer piloto
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_prueba'
select 
	b.*, 
	n.num_pilots,	-- numero de pilotos teniendo en cuenta la ordenación por operador solo
	n.measdate,
	p1.RSCP_median as RSCP_BS, p1.EcI0_median as EcI0_BS, 
	p1.Channel as Channel_BS, 
	p1.SCode as Scode_BS,

	-- 
	1.0-(
		  (1.0-isnull(p1.PcobInd_voice,0.0))*(1.0-isnull(p2.PcobInd_voice,0.0))*(1.0-isnull(p3.PcobInd_voice,0.0))*(1.0-isnull(p4.PcobInd_voice,0.0))*(1.0-isnull(p5.PcobInd_voice,0.0))
		  --*(1.0-isnull(p6.PcobInd_voice,0.0))*(1.0-isnull(p7.PcobInd_voice,0.0))*(1.0-isnull(p8.PcobInd_voice,0.0))*(1.0-isnull(p9.PcobInd_voice,0.0))*(1.0-isnull(p10.PcobInd_voice,0.0))
		  --*(1.0-isnull(p11.PcobInd_voice,0.0))*(1.0-isnull(p12.PcobInd_voice,0.0))*(1.0-isnull(p13.PcobInd_voice,0.0))*(1.0-isnull(p14.PcobInd_voice,0.0))*(1.0-isnull(p15.PcobInd_voice,0.0))
		  --*(1.0-isnull(p16.PcobInd_voice,0.0))*(1.0-isnull(p17.PcobInd_voice,0.0))*(1.0-isnull(p18.PcobInd_voice,0.0))*(1.0-isnull(p19.PcobInd_voice,0.0))*(1.0-isnull(p20.PcobInd_voice,0.0))
		)
	 as PcobInd_Voice,
	p1.PcobInd_voice as p1_PcobInd_voice,	p2.PcobInd_voice as p2_PcobInd_voice,	p3.PcobInd_voice as p3_PcobInd_voice,	
	p4.PcobInd_voice as p4_PcobInd_voice,	p5.PcobInd_voice as p5_PcobInd_voice,

	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataGood,0.0))*(1.0-isnull(p2.PcobInd_DataGood,0.0))*(1.0-isnull(p3.PcobInd_DataGood,0.0))*(1.0-isnull(p4.PcobInd_DataGood,0.0))*(1.0-isnull(p5.PcobInd_DataGood,0.0))
		  --*(1.0-isnull(p6.PcobInd_DataGood,0.0))*(1.0-isnull(p7.PcobInd_DataGood,0.0))*(1.0-isnull(p8.PcobInd_DataGood,0.0))*(1.0-isnull(p9.PcobInd_DataGood,0.0))*(1.0-isnull(p10.PcobInd_DataGood,0.0))
		  --*(1.0-isnull(p11.PcobInd_DataGood,0.0))*(1.0-isnull(p12.PcobInd_DataGood,0.0))*(1.0-isnull(p13.PcobInd_DataGood,0.0))*(1.0-isnull(p14.PcobInd_DataGood,0.0))*(1.0-isnull(p15.PcobInd_DataGood,0.0))
		  --*(1.0-isnull(p16.PcobInd_DataGood,0.0))*(1.0-isnull(p17.PcobInd_DataGood,0.0))*(1.0-isnull(p18.PcobInd_DataGood,0.0))*(1.0-isnull(p19.PcobInd_DataGood,0.0))*(1.0-isnull(p20.PcobInd_DataGood,0.0))
		)
	 as PcobInd_DataGood,
	p1.PcobInd_DataGood as p1_PcobInd_DataGood,	p2.PcobInd_DataGood as p2_PcobInd_DataGood,	p3.PcobInd_DataGood as p3_PcobInd_DataGood,	
	p4.PcobInd_DataGood as p4_PcobInd_DataGood,	p5.PcobInd_DataGood as p5_PcobInd_DataGood,

	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataFair,0.0))*(1.0-isnull(p2.PcobInd_DataFair,0.0))*(1.0-isnull(p3.PcobInd_DataFair,0.0))*(1.0-isnull(p4.PcobInd_DataFair,0.0))*(1.0-isnull(p5.PcobInd_DataFair,0.0))
		  --*(1.0-isnull(p6.PcobInd_DataFair,0.0))*(1.0-isnull(p7.PcobInd_DataFair,0.0))*(1.0-isnull(p8.PcobInd_DataFair,0.0))*(1.0-isnull(p9.PcobInd_DataFair,0.0))*(1.0-isnull(p10.PcobInd_DataFair,0.0))
		  --*(1.0-isnull(p11.PcobInd_DataFair,0.0))*(1.0-isnull(p12.PcobInd_DataFair,0.0))*(1.0-isnull(p13.PcobInd_DataFair,0.0))*(1.0-isnull(p14.PcobInd_DataFair,0.0))*(1.0-isnull(p15.PcobInd_DataFair,0.0))
		  --*(1.0-isnull(p16.PcobInd_DataFair,0.0))*(1.0-isnull(p17.PcobInd_DataFair,0.0))*(1.0-isnull(p18.PcobInd_DataFair,0.0))*(1.0-isnull(p19.PcobInd_DataFair,0.0))*(1.0-isnull(p20.PcobInd_DataFair,0.0))
		)
	 as PcobInd_DataFair,
	p1.PcobInd_DataFair as p1_PcobInd_DataFair,	p2.PcobInd_DataFair as p2_PcobInd_DataFair,	p3.PcobInd_DataFair as p3_PcobInd_DataFair,	
	p4.PcobInd_DataFair as p4_PcobInd_DataFair,	p5.PcobInd_DataFair as p5_PcobInd_DataFair

into lcc_UMTSScanner_50x50_ProbCobIndoor_prueba
from
	(select b1.*, op.* 
	from
		(select longitude, latitude, lonid, latid 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba
		group by longitude, latitude, lonid,latid
		) b1,  

		(select operator 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba
		where operator is not null group by operator) op
	) b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover
	
	LEFT OUTER JOIN	(select lonid, latid, operator, 
							max(operator_ord) as num_pilots, min(measdate) as min_measdate, max(measdate) as measdate
					from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba
					group by lonid, latid, operator
					) n on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator
  
	-- Cada uno de los pilotos y su cobertura -> en este caso los 5 primeros 
	LEFT OUTER JOIN
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba where operator_ord=1
		) p1											on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba where operator_ord=2
		) p2											on p2.lonid=b.lonid and p2.latid=b.latid and p2.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba where operator_ord=3
		) p3											on p3.lonid=b.lonid and p3.latid=b.latid and p3.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba where operator_ord=4
		) p4											on p4.lonid=b.lonid and p4.latid=b.latid and p4.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba where operator_ord=5
		) p5											on p5.lonid=b.lonid and p5.latid=b.latid and p5.operator=b.operator


-- prompt --
select 'lcc_UMTSScanner_50x50_ProbCobIndoor_prueba' New_Table_3G_probCobIndoor_Created
----------

select longitude,latitude
from [dbo].[lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor] s, lcc_position_entity_list_municipio d, [dbo]--,[lcc_UMTSScanner_50x50_ProbCobIndoor_prueba] t
where 
s.latid=d.latid and s.lonid=d.lonid
and operator = 'Vodafone'
and Entity_name= 'NAVALCARNERO'

select *
from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba


------------------------------------------------------------------------------
-- Borrado de las tablas temporales
------------------------------------------------------------------------------
--exec sp_lcc_dropifexists 'temporal_sc_prueba'
--exec sp_lcc_dropifexists 'temporal_sc2_prueba'
--exec sp_lcc_dropifexists 'lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_prueba'
--exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_prueba'
