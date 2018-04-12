USE [FY1617_Voice_Rest_3G_H1_9]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_plcc_create_lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_20161017]    Script Date: 04/11/2016 10:15:17 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO


--ALTER procedure [dbo].[sp_plcc_create_lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_20161017] @toDelete int=0
--as 

-- EXEC sys.sp_MS_marksystemobject 

-- (select name from sys.all_objects where name='lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor' and type='U') is not null 

--declare @toDelete as int=1

-----------------
--if (@toDelete=1)	
--begin		-- Iniciamos la tabla desde el principio
--	exec sp_lcc_dropifexists 'lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor'
--	exec sp_lcc_dropifexists 'lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid'
--	select convert(bigint,0) max_fileid into lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid
--end

-------------------
--if ((select name from sys.all_objects where name='lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid' and type='U') is  null )
--begin		-- inicializa el ultimo fileid procesado a 0
--	select convert(bigint,0) max_fileid into lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid
--end

-------------------
--declare @max_fileid bigint = (select max(max_fileid) from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid)



-------------------------------------------------------------------------------------------------
-- 1) Crea la tabla de todos los pilotos, añadiendo la probabilidad de cober de cada uno de ellos 
-------------------------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_bcch_prueba' 
select 
	lonid, latid,channel,bsic,  measdate,
	10*log10(avg(rssi_lin)) rxlev_avg,
	avg(rssi_median) as rxlev_median
into temporal_bcch_prueba
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
				   over (partition by lonid, latid, l.channel, 
									  case when l.CC1_1<10 and l.CC2_1<10  then
										 convert(int,convert(varchar(1),l.CC1_1)+ convert(varchar(1),l.CC2_1)) 		
									  end
						)
		as rssi_median
	from MsgScannerBCCHInfo li,
		MsgScannerBCCH l, filelist f, sessions s,
		(select *, CONVERT(INT, 2224.0*p.longitude*COS(2*PI()*p.latitude/360)) as  lonid, 
			CONVERT(INT, 2224.0*p.latitude)as latid,
			right('0000'+convert(varchar(4), year(p.msgtime)),4)+
			right('0000'+convert(varchar(4), month(p.msgtime)),2)+
			right('0000'+convert(varchar(4), day(p.msgtime)),2) as Measdate
		   from Position p
		 )p
	where f.fileid=s.fileid and s.sessionid=li.sessionid
		and collectionname like '%navalcarnero%'
		and li.BCCHScanId=l.BCCHScanId
		and li.PosId=p.PosId
		--and p.FileId>@max_fileid -- solo considera la nueva info
) t
group by lonid, latid,channel,bsic, Measdate
	
-- select * from temporal_bcch_prueba


 

------------------------------------------------------------------------------
-- 2) Tabla con los valores medios por cuadricula de cada magnitud
--		* ordenacion por banda y operador
--------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'temporal_bcch2_prueba'
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
into temporal_bcch2_prueba
--lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_prueba
from 
    (
		select *, ROW_NUMBER() over (partition by lonid,latid,channel, bsic order by rxlev_median desc, measdate desc) as mdate_id
		 from temporal_bcch_prueba
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
if ((select name from sys.all_objects where name='lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_prueba' and type='U') is  null )
	begin
		------------------------------------------
		-- Crea desde el principio la tabla con las prob por cuadricula
		------------------------------------------
		 select *, convert(int,1) as valid 
		 into lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_prueba
		 from temporal_bcch2_prueba
	end
else
	begin
		------------------------------------------
		-- Update de las cuadriculas comunes
		------------------------------------------
		update  lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_prueba
		set rssi_avg	=	t.rssi_avg,
			rssi_median	=	t.rssi_median,
			PcobInd		=	t.PcobInd,
			measdate	=	t.Measdate,
			valid		=	1
		from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_prueba c,temporal_bcch2_prueba t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.bsic=t.bsic
			and( t.rssi_median>c.rssi_median 
				or (t.rssi_median=c.rssi_median and t.Measdate>c.measdate))
		
		------------------------------------------
		-- Borrado de las comunes actualizadas
		------------------------------------------
		-- prompt de los pilots actualizados
		select sum(1) as updated_pilots
		from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_prueba c,temporal_bcch2_prueba t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.bsic=t.bsic
			and( t.rssi_median>c.rssi_median 
				or (t.rssi_median=c.rssi_median and t.Measdate>c.measdate))

		-- borrado
		delete  temporal_bcch2_prueba
		from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_prueba c,temporal_bcch2_prueba t
		where c.lonid=t.lonid and c.latid=t.latid and c.channel=t.Channel and c.bsic=t.bsic
				--and( t.rssi_median>c.rssi_median 
					-- or (t.rssi_median=c.rssi_median and t.Measdate>c.measdate))
	
		---------------------------------------
		-- Insertar las nuevas cuadrículas
		-----------------------------------------
		-- prompt
		 select sum(1) as added_newPilots
		 from temporal_bcch2_prueba
		-- insert de las nuevas cuadriculas/pilotos
		insert into lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_prueba
		select *, convert(int, 1) as valid
		from temporal_bcch2_prueba
end

-- select * from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_prueba


------------------------------------------------------------------------------
-- 4) Update de ultimo fileid
------------------------------------------------------------------------------
---- prompt
--select max_fileid as Initial_fileid_Processed
--from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid

----
--update lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid
--set max_fileid=(select max(fileid) from filelist)

---- prompt
--select max_fileid as Last_fileid_included
--from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid



------------------------------------------------------------------------------
-- 5) Tabla con la ordenación de pilotos por nivel:
-- tabla con la ordenación de pilotos por nivel
---   debe crearse desde cero cada vez ya que le influyen los cambios y updates
--    que se hayan podido producir en la tabla de lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba'
select *
	-- Ordenacion por operador - es la que se utilizara para crear la tabla:	lcc_GSMScanner_50x50_ProbCobIndoor_prueba
	,ROW_NUMBER() over (partition by lonid, 
									 latid,
									 Operator
						order by rssi_median desc)				as operator_ord,
    ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band
						order by rssi_median desc)				as operator_band_ord
into lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_prueba

---- prompt ----
 select 'lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba' New_Table_Ordered_pilots_perBand_and_Operator_Created




------------------------------------------------------------------------------
-- 6) Prob de cobertura por operador y banda considerando los primeros 20 pilotos
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_prueba'
select 
	b.*, 
	n.num_pilots, n.measdate,
	p1.rssi_median as RSSI_BS, p1.channel as Channel_BS, p1.bsic as BSIC_BS,
	1.0-(
		(1.0-isnull(p1.PcobInd,0.0))*(1.0-isnull(p2.PcobInd,0.0))*(1.0-isnull(p3.PcobInd,0.0))*(1.0-isnull(p4.PcobInd,0.0))*(1.0-isnull(p5.PcobInd,0.0))*(1.0-isnull(p6.PcobInd,0.0))*(1.0-isnull(p7.PcobInd,0.0))*(1.0-isnull(p8.PcobInd,0.0))*(1.0-isnull(p9.PcobInd,0.0))*(1.0-isnull(p10.PcobInd,0.0))*
		(1.0-isnull(p11.PcobInd,0.0))*(1.0-isnull(p12.PcobInd,0.0))*(1.0-isnull(p13.PcobInd,0.0))*(1.0-isnull(p14.PcobInd,0.0))*(1.0-isnull(p15.PcobInd,0.0))*(1.0-isnull(p16.PcobInd,0.0))*(1.0-isnull(p17.PcobInd,0.0))*(1.0-isnull(p18.PcobInd,0.0))*(1.0-isnull(p19.PcobInd,0.0))*(1.0-isnull(p20.PcobInd,0.0))
	)	as PcobInd,
	p1.PcobInd as p1_PcobInd,	p2.PcobInd as p2_CobInd,	p3.PcobInd as p3_CobInd,	p4.PcobInd as p4_CobInd,	p5.PcobInd as p5_CobInd,	p6.PcobInd as p6_CobInd,	p7.PcobInd as p7_CobInd,	p8.PcobInd as p8_CobInd,	p9.PcobInd as p9_CobInd,	p10.PcobInd as p10_CobInd,
	p11.PcobInd as p11_PcobInd, p12.PcobInd as p12_CobInd,	p13.PcobInd as p13_CobInd,	p14.PcobInd as p14_CobInd,	p15.PcobInd as p15_CobInd,	p16.PcobInd as p16_CobInd,	p17.PcobInd as p17_CobInd,	p18.PcobInd as p18_CobInd,	p19.PcobInd as p19_CobInd,	p20.PcobInd as p20_CobInd
into lcc_GSMScanner_50x50_ProbCobIndoor_prueba
from
	(select b1.*, op.* from
		(
		select longitude, latitude, lonid,latid from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba 
		group by longitude, latitude, lonid,latid
		) b1,  
	(select operator from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba where operator is not null group by operator) op
	)b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover

		  left outer join
		  (select lonid,latid, operator,max(operator_ord) as num_pilots ,min(measdate) as min_measdate, max(measdate) as measdate
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		   group by lonid, latid,operator
		   ) n
		  on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator

	-- Cada uno de los pilotos y su cobertura
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=1
		  ) p1
		  on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=2
		  ) p2
		  on p2.lonid=b.lonid and p2.latid=b.latid and p2.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=3
		  ) p3
		  on p3.lonid=b.lonid and p3.latid=b.latid and p3.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=4
		  ) p4
		  on p4.lonid=b.lonid and p4.latid=b.latid and p4.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=5
		  ) p5
		  on p5.lonid=b.lonid and p5.latid=b.latid and p5.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=6
		  ) p6
		  on p6.lonid=b.lonid and p6.latid=b.latid and p6.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=7
		  ) p7
		  on p7.lonid=b.lonid and p7.latid=b.latid and p7.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=8
		  ) p8
		  on p8.lonid=b.lonid and p8.latid=b.latid and p8.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=9
		  ) p9
		  on p9.lonid=b.lonid and p9.latid=b.latid and p9.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=10
		  ) p10
		  on p10.lonid=b.lonid and p10.latid=b.latid and p10.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=11
		  ) p11
		  on p11.lonid=b.lonid and p11.latid=b.latid and p11.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=12
		  ) p12
		  on p12.lonid=b.lonid and p12.latid=b.latid and p12.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=13
		  ) p13
		  on p13.lonid=b.lonid and p13.latid=b.latid and p13.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=14
		  ) p14
		  on p14.lonid=b.lonid and p14.latid=b.latid and p14.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=15
		  ) p15
		  on p15.lonid=b.lonid and p15.latid=b.latid and p15.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=16
		  ) p16
		  on p16.lonid=b.lonid and p16.latid=b.latid and p16.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=17
		  ) p17
		  on p17.lonid=b.lonid and p17.latid=b.latid and p17.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=18
		  ) p18
		  on p18.lonid=b.lonid and p18.latid=b.latid and p18.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=19
		  ) p19
		  on p19.lonid=b.lonid and p19.latid=b.latid and p19.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_prueba
		  where operator_ord=20
		  ) p20
		  on p20.lonid=b.lonid and p20.latid=b.latid and p20.operator=b.operator


-- prompt --
 select 'lcc_GSMScanner_50x50_ProbCobIndoor_prueba' New_Table_2G_probCobIndoor_Created
----------

-- select * from lcc_GSMScanner_50x50_ProbCobIndoor_prueba

------------------------------------------------------------------------------
-- Borrado de las tablas temporales
------------------------------------------------------------------------------
--exec sp_lcc_dropifexists 'temporal_bcch_prueba'
--exec sp_lcc_dropifexists 'temporal_bcch2_prueba'
--exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_prueba'
--exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_ord_prueba'

