USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_plcc_create_lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ROUND]    Script Date: 14/03/2017 11:37:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_plcc_create_lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ROUND] @toDelete int=0
as 

--declare @toDelete as int=0
-----------------
if (@toDelete=1)	
begin		-- Iniciamos la tabla desde el principio
	exec sp_lcc_dropifexists 'lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor'
	exec sp_lcc_dropifexists 'lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid'		-- podria valer el de GSM no ?¿ - todos para 1
	select convert(bigint,0) max_fileid into lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid
end

-----------------
if ((select name from sys.all_objects where name='lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid' and type='U') is  null )	
begin		-- Inicializa el ultimo fileid procesado a 0
	select convert(bigint,0) max_fileid into lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid
end

-----------------
declare @max_fileid bigint = (select max(max_fileid) from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid)

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
exec sp_lcc_dropifexists 'temporal_pci'
select
	lonid, latid, Channel, PhCId,  MeasDate, BandWidth,
	10*log10(avg(RSRP_lin)) as RSRP_avg,
	10*log10(avg(RSRQ_lin)) as RSRQ_avg,
	10*log10(avg(CINR_lin)) as CINR_avg,
	avg(RSRP_median)		as RSRP_median,
	avg(RSRQ_median)		as RSRQ_median,
	avg(CINR_median)		as CINR_median,
	Entidad_Medida
into temporal_pci
from (
	select 
		lonid, 	latid, li.Channel, l.PhCId,	p.MeasDate, li.bandwidth/1000 as BandWidth,

		POWER(CAST(10 AS float), (l.RSRP)/10.0) as RSRP_lin,  
		percentile_cont(0.5) 
			within group (order by l.RSRP)
					over (partition by lonid, latid, li.Channel, l.PhCId,Entidad_Medida) as RSRP_median,
			          
		POWER(CAST(10 AS float), (l.RSRQ)/10.0) as RSRQ_lin,            
		percentile_cont(0.5) 
			within group (order by l.RSRQ)
					over (partition by lonid, latid, li.Channel, l.PhCId,Entidad_Medida) as RSRQ_median,

		POWER(CAST(10 AS float), (l.CINR)/10.0) as CINR_lin,  
		percentile_cont(0.5) 
			within group (order by l.CINR)
					over (partition by lonid, latid, li.Channel, l.PhCId,Entidad_Medida) as CINR_median,
		e.Entidad_Medida
	from MsgLTEScannerTopNInfo li, MsgLTEScannerTopN l, 
		 (select *, CONVERT(INT, 2224.0*p.longitude*COS(2*PI()*p.latitude/360)) as  lonid, 
			   CONVERT(INT, 2224.0*p.latitude)as latid,
			   right('0000'+convert(varchar(4), year(p.msgtime)),4)+
			   right('0000'+convert(varchar(4), month(p.msgtime)),2)+
			   right('0000'+convert(varchar(4), day(p.msgtime)),2) as Measdate
		 from Position p) p,
		 temporal_log e
	where 
		li.LTETopNId=l.LTETopNId 
		and li.PosId=p.PosId 
		and p.FileId=e.FileId
		and p.FileId>@max_fileid		-- solo considera la nueva info
		--and p.FileId = 28	
) t
group by lonid, latid, Channel, PhCId, Measdate, BandWidth,Entidad_Medida

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
	,c.Entidad_Medida
into temporal_pci2
from 
    (select *, ROW_NUMBER() over (partition by lonid, latid, Channel, PhCId,Entidad_Medida order by RSRP_median desc, Measdate desc) as mdate_id
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
if ((select name from sys.all_objects where name='lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor' and type='U') is  null )
	begin
		------------------------------------------
		-- Crea desde el principio la tabla con las prob por cuadricula
		------------------------------------------
		 select *, convert(int,1) as valid 
		 into lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
		 from temporal_pci2
	end
else
begin
		------------------------------------------
		-- Update de las cuadriculas comunes
		------------------------------------------
		update  lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
		set RSRP_avg	=	t.RSRP_avg,				RSRP_median	=	t.RSRP_median,		
			RSRQ_avg	=	t.RSRQ_avg,				RSRQ_median	=	t.RSRQ_median,
			CINR_avg	=	t.CINR_avg,				CINR_median	=	t.CINR_median,

			PcobInd		=	t.PcobInd,
			measdate	=	t.Measdate,
			BandWidth	=	t.BandWidth,
			valid		=	1
		from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor c, temporal_pci2 t
		where 
			--Actualizamos parcelas con mismo canal, PhCId y entidad_medida
			c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.PhCId=t.PhCId and c.Entidad_Medida=t.Entidad_Medida
				and (t.RSRP_median>c.RSRP_median									-- la nueva es mayor que la existente
					or (t.RSRP_median=c.RSRP_median and t.Measdate>c.Measdate))		-- si son iguales, nos quedamos con la reciente

		------------------------------------------
		-- Borrado de las comunes actualizadas
		------------------------------------------
		-- prompt de los pilots actualizados
		select sum(1) as updated_pilots
		from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor c, temporal_pci2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.PhCId=t.PhCId and c.Entidad_Medida=t.Entidad_Medida
					and (t.RSRP_median>c.RSRP_median 
						or (t.RSRP_median=c.RSRP_median and t.Measdate>c.measdate))
		-- borrado de las parcelas nuevas que sean coincidentes (hemos podido usar esa info o no por ser peor)
		delete temporal_pci2
		from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor c, temporal_pci2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.Channel=t.Channel and c.PhCId=t.PhCId and c.Entidad_Medida=t.Entidad_Medida
	
		---------------------------------------
		-- Insertar las nuevas cuadrículas
		-----------------------------------------
		-- prompt
		select sum(1) as added_newPilots
		from temporal_pci2

		-- Insert de las nuevas cuadriculas/pilotos
		insert into lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
		select *, convert(int, 1) as valid
		from temporal_pci2
end

-- select * from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor


------------------------------------------------------------------------------
-- 4) Update de ultimo fileid
------------------------------------------------------------------------------
-- prompt
select max_fileid as Initial_fileid_Processed
from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid

--
update lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid
set max_fileid=(select max(fileid) from filelist)

-- prompt
select max_fileid as Last_fileid_included
from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid
	

------------------------------------------------------------------------------
-- 5) Tabla con la ordenación de pilotos por nivel:
--		* debe crearse desde cero cada vez ya que le influyen los cambios y updates 
--		  que se hayan podido producir en la tabla de lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
--		* en 4G, con el primero es suficiente (20 para 2G y 5 para el 3G)
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord'
select *,
	-- Ordenacion por operador - es la que se utilizara para crear la tabla:	lcc_LTEScanner_50x50_ProbCobIndoor
	ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									Entidad_Medida
					   order by RSRP_median desc)				  as operator_ord,
	-- Ordenación por operador y Banda:
    ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band,
									Entidad_Medida
					    order by RSRP_median desc)				 as operator_band_ord,
	-- En el caso de 3G y 4G hay que añadir ordenación por canal
    ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band,
									channel,
									Entidad_Medida
					    order by RSRP_median desc)				 as operator_band_channel_ord
into lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord	
from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor

-- Prompt --
select 'lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord' New_Table_Ordered_pilots_perBand_and_Operator_Created


------------------------------------------------------------------------------
-- 6) Prob de cobertura por operador y banda considerando sólo el primer piloto
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_LTEScanner_50x50_ProbCobIndoor'
select 
	b.*, 
	n.num_pilots,	-- numero de pilotos teniendo en cuenta la ordenación por operador solo
	n.measdate,
	p1.RSRP_median as RSRP_BS, p1.RSRQ_median as RSRQ_BS, p1.CINR_median as CINR_BS,
	p1.Channel as Channel_BS, 
	p1.BandWidth,
	p1.PhCId as PhCId_BS,
	--1.0-(
	--	  (1.0-isnull(p1.PcobInd,0.0))*(1.0-isnull(p2.PcobInd,0.0))*(1.0-isnull(p3.PcobInd,0.0))*(1.0-isnull(p4.PcobInd,0.0))*(1.0-isnull(p5.PcobInd,0.0))*(1.0-isnull(p6.PcobInd,0.0))*(1.0-isnull(p7.PcobInd,0.0))*(1.0-isnull(p8.PcobInd,0.0))*(1.0-isnull(p9.PcobInd,0.0))*(1.0-isnull(p10.PcobInd,0.0))*
	--	  (1.0-isnull(p11.PcobInd,0.0))*(1.0-isnull(p12.PcobInd,0.0))*(1.0-isnull(p13.PcobInd,0.0))*(1.0-isnull(p14.PcobInd,0.0))*(1.0-isnull(p15.PcobInd,0.0))*(1.0-isnull(p16.PcobInd,0.0))*(1.0-isnull(p17.PcobInd,0.0))*(1.0-isnull(p18.PcobInd,0.0))*(1.0-isnull(p19.PcobInd,0.0))*(1.0-isnull(p20.PcobInd,0.0))
	--	)
	-- as PcobInd,
	p1.PcobInd as p1_PcobInd
into lcc_LTEScanner_50x50_ProbCobIndoor
from
	(select b1.*, op.* 
	from
		(select longitude, latitude, lonid, latid,Entidad_Medida
		from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord 
		group by longitude, latitude, lonid,latid,Entidad_Medida
		) b1,  

		(select operator 
		from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord 
		where operator is not null group by operator) op
	) b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover
	
	LEFT OUTER JOIN	(select lonid, latid, operator, Entidad_Medida,
							max(operator_ord) as num_pilots, min(measdate) as min_measdate, max(measdate) as measdate
					from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord
					group by lonid, latid, operator, Entidad_Medida
					) n on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator and b.Entidad_Medida=n.Entidad_Medida
  
  -- cada uno de los pilotos y su cobertura -> en este caso solo 1, el primero
	LEFT OUTER JOIN	(select lonid, latid, operator, channel, BandWidth, PhCId, RSRP_median,band, RSRQ_median, CINR_median, PcobInd,Entidad_Medida
					from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord
					where operator_ord=1
					) p1 on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator and b.Entidad_Medida=p1.Entidad_Medida


-- prompt --
select 'lcc_LTEScanner_50x50_ProbCobIndoor' New_Table_4G_probCobIndoor_Created
----------

------------------------------------------------------------------------------
-- Borrado de las tablas temporales
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_log'
exec sp_lcc_dropifexists 'temporal_pci'
exec sp_lcc_dropifexists 'temporal_pci2'
