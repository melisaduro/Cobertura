USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_plcc_create_lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ROUND]    Script Date: 14/03/2017 11:12:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER procedure [dbo].[sp_plcc_create_lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ROUND] @toDelete int=0
as 

-- EXEC sys.sp_MS_marksystemobject 

-- (select name from sys.all_objects where name='lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor' and type='U') is not null 

--declare @toDelete as int=1

-----------------
if (@toDelete=1)	
begin		-- Iniciamos la tabla desde el principio
	exec sp_lcc_dropifexists 'lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor'
	exec sp_lcc_dropifexists 'lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid'
	select convert(bigint,0) max_fileid into lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid
end

-----------------
if ((select name from sys.all_objects where name='lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid' and type='U') is  null )
begin		-- inicializa el ultimo fileid procesado a 0
	select convert(bigint,0) max_fileid into lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid
end

-----------------
declare @max_fileid bigint = (select max(max_fileid) from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid)


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
exec sp_lcc_dropifexists 'temporal_bcch' 
select 
	lonid, latid,channel,bsic,  measdate,
	10*log10(avg(rssi_lin)) rxlev_avg,
	avg(rssi_median) as rxlev_median,
	Entidad_Medida
into temporal_bcch
from
(
	Select 
		lonid, 		latid,		l.Channel,
		case when l.CC1_1<10 and l.CC2_1<10  then
				   convert(int,convert(varchar(1),l.CC1_1)+ convert(varchar(1),l.CC2_1)) 		
		end --- hay muestras del scanner 2G que detectan varios bsics... se establece el 1 como el correcto
		as bsic,
		p.Measdate,
		POWER(CAST(10 AS float), (l.RSSI)/10.0) rssi_lin,
		percentile_cont(0.5) 
			within group (order by l.rssi)
				   over (partition by lonid, latid, l.channel,Entidad_Medida,
									  case when l.CC1_1<10 and l.CC2_1<10  then
										 convert(int,convert(varchar(1),l.CC1_1)+ convert(varchar(1),l.CC2_1)) 		
									  end
						)
		as rssi_median,
		e.Entidad_Medida
	from MsgScannerBCCHInfo li,
		MsgScannerBCCH l,
		(select *, CONVERT(INT, 2224.0*p.longitude*COS(2*PI()*p.latitude/360)) as  lonid, 
			CONVERT(INT, 2224.0*p.latitude)as latid,
			right('0000'+convert(varchar(4), year(p.msgtime)),4)+
			right('0000'+convert(varchar(4), month(p.msgtime)),2)+
			right('0000'+convert(varchar(4), day(p.msgtime)),2) as Measdate
		   from Position p
		 )p,
		 temporal_log e
	where li.BCCHScanId=l.BCCHScanId
		and li.PosId=p.PosId
		and p.FileId=e.FileId
		and p.FileId>@max_fileid -- solo considera la nueva info
) t
group by lonid, latid,channel,bsic, Measdate,Entidad_Medida
	
-- select * from temporal_bcch


 

------------------------------------------------------------------------------
-- 2) Tabla con los valores medios por cuadricula de cada magnitud
--		* ordenacion por banda y operador
--------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_bcch2'
select 
	(c.lonid/2224.0)*(1/(cos(2*pi()*c.latid/(2224.0*360)))) as longitude,
	c.latid/2224.0 as latitude,
	c.lonid,	c.latid,
	Channel,	bsic,
	rxlev_avg rssi_avg,	rxlev_median rssi_median,
	sof.Band,			sof.ServingOperator as operator,
	c.Measdate,
	master.dbo.fn_lcc_ProbindoorCoverage(rxlev_median,sof.Band, 
	                                 case i.mob_type when 3 then 'DU' when 2 then 'U' else 'SU' end, 'voice' ) as PcobInd
    ,i.codigo_ine
	,c.Entidad_Medida
into temporal_bcch2
--lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor 
from 
    (
		select *, ROW_NUMBER() over (partition by lonid,latid,channel, bsic,Entidad_Medida order by rxlev_median desc, measdate desc) as mdate_id
		 from temporal_bcch
    )  c
	LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof 
		on c.Channel=sof.Frequency
	left outer join agrids.dbo.[lcc_G2K5Absolute_INDEX_new] i
	   on c.lonid=i.lonid and c.latid=i.latid
where c.mdate_id=1

-- select sum(1) from  lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor


------------------------------------------------------------------------------
-- 3) Tabla final con la info actualizada
--		* tenemos 1 linea por cuadrícula
--		* se guarda la información con mejor resultado y mas reciente siempre
--		* se mantiene tmb info del dia de la medida, por si fuera necesario invalidar
--				meas date -> aaaa/mm/dd
------------------------------------------------------------------------------
if ((select name from sys.all_objects where name='lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor' and type='U') is  null )
	begin
		------------------------------------------
		-- Crea desde el principio la tabla con las prob por cuadricula
		------------------------------------------
		 select *, convert(int,1) as valid 
		 into lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
		 from temporal_BCCH2
	end
else
	begin
		------------------------------------------
		-- Update de las cuadriculas comunes
		------------------------------------------
		update  lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
		set rssi_avg	=	t.rssi_avg,
			rssi_median	=	t.rssi_median,
			PcobInd		=	t.PcobInd,
			measdate	=	t.Measdate,
			valid		=	1
		from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor c,temporal_BCCH2 t
		where 
			--Actualizamos parcelas con mismo canal, bsic y entidad_medida
			c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.bsic=t.bsic and c.Entidad_Medida=t.Entidad_Medida
			--cuya mediana de nivel de señal sea mejor ahora o siendo igual que la fecha de medida sea mas actual
			and( t.rssi_median>c.rssi_median 
				or (t.rssi_median=c.rssi_median and t.Measdate>c.measdate))
		
		------------------------------------------
		-- Borrado de las comunes actualizadas
		------------------------------------------
		-- prompt de los pilots actualizados
		select sum(1) as updated_pilots
		from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor c,temporal_BCCH2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.bsic=t.bsic and c.Entidad_Medida=t.Entidad_Medida
			and( t.rssi_median>c.rssi_median 
				or (t.rssi_median=c.rssi_median and t.Measdate>c.measdate))

		-- borrado de las parcelas nuevas que sean coincidentes (hemos podido usar esa info o no por ser peor)
		delete  temporal_BCCH2
		from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor c,temporal_BCCH2 t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.bsic=t.bsic and c.Entidad_Medida=t.Entidad_Medida

	
		---------------------------------------
		-- Insertar las nuevas cuadrículas
		-----------------------------------------
		-- prompt
		select sum(1) as added_newPilots
		from temporal_BCCH2
		-- insert de las nuevas cuadriculas/pilotos
		insert into lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
		select *, convert(int, 1) as valid
		from temporal_BCCH2
end

-- select * from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor


------------------------------------------------------------------------------
-- 4) Update de ultimo fileid
------------------------------------------------------------------------------
-- prompt
select max_fileid as Initial_fileid_Processed
from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid

--
update lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid
set max_fileid=(select max(fileid) from filelist)

-- prompt
select max_fileid as Last_fileid_included
from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid



------------------------------------------------------------------------------
-- 5) Tabla con la ordenación de pilotos por nivel:
-- tabla con la ordenación de pilotos por nivel
---   debe crearse desde cero cada vez ya que le influyen los cambios y updates
--    que se hayan podido producir en la tabla de lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord'
select *
	-- Ordenacion por operador - es la que se utilizara para crear la tabla:	lcc_GSMScanner_50x50_ProbCobIndoor
	,ROW_NUMBER() over (partition by lonid, 
									 latid,
									 Operator,
									 Entidad_Medida
						order by rssi_median desc)				as operator_ord,
    ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band,
									Entidad_Medida
						order by rssi_median desc)				as operator_band_ord
into lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord
from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor

---- prompt ----
 select 'lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord' New_Table_Ordered_pilots_perBand_and_Operator_Created
 


------------------------------------------------------------------------------
-- Borrado de las tablas temporales
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_log'
exec sp_lcc_dropifexists 'temporal_bcch'
exec sp_lcc_dropifexists 'temporal_bcch2'

