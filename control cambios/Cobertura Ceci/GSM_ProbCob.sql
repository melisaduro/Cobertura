--USE [FY1718_Coverage_Union_H1]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_plcc_create_lcc_GSMScanner_50x50_ProbCobIndoor]    Script Date: 03/10/2017 11:58:03 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO


--ALTER procedure [dbo].[sp_plcc_create_lcc_GSMScanner_50x50_ProbCobIndoor] 
--as 

--use FY1718_VOICE_REST_4G_H1_27 --SITGES
--use FY1718_VOICE_REST_4G_H1_13 --ALCORCON
use FY1718_VOICE_VALENCIA_4G_H1

------------------------------------------------------------------------------
-- 6) Prob de cobertura por operador y banda considerando los primeros 20 pilotos
------------------------------------------------------------------------------
exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_ALL'
select 
	b.*, 
	n.num_pilots, n.measdate,
	p1.rssi_avg,p1.band,p1.codigo_ine,
	p1.rssi_median as RSSI_BS, p1.channel as Channel_BS, p1.bsic as BSIC_BS,
	1.0-(
		(1.0-isnull(p1.PcobInd,0.0))*(1.0-isnull(p2.PcobInd,0.0))*(1.0-isnull(p3.PcobInd,0.0))*(1.0-isnull(p4.PcobInd,0.0))*(1.0-isnull(p5.PcobInd,0.0))*(1.0-isnull(p6.PcobInd,0.0))*(1.0-isnull(p7.PcobInd,0.0))*(1.0-isnull(p8.PcobInd,0.0))*(1.0-isnull(p9.PcobInd,0.0))*(1.0-isnull(p10.PcobInd,0.0))*
		(1.0-isnull(p11.PcobInd,0.0))*(1.0-isnull(p12.PcobInd,0.0))*(1.0-isnull(p13.PcobInd,0.0))*(1.0-isnull(p14.PcobInd,0.0))*(1.0-isnull(p15.PcobInd,0.0))*(1.0-isnull(p16.PcobInd,0.0))*(1.0-isnull(p17.PcobInd,0.0))*(1.0-isnull(p18.PcobInd,0.0))*(1.0-isnull(p19.PcobInd,0.0))*(1.0-isnull(p20.PcobInd,0.0))
	)	as PcobInd,
	p1.PcobInd as p1_PcobInd,	p2.PcobInd as p2_CobInd,	p3.PcobInd as p3_CobInd,	p4.PcobInd as p4_CobInd,	p5.PcobInd as p5_CobInd,	p6.PcobInd as p6_CobInd,	p7.PcobInd as p7_CobInd,	p8.PcobInd as p8_CobInd,	p9.PcobInd as p9_CobInd,	p10.PcobInd as p10_CobInd,
	p11.PcobInd as p11_PcobInd, p12.PcobInd as p12_CobInd,	p13.PcobInd as p13_CobInd,	p14.PcobInd as p14_CobInd,	p15.PcobInd as p15_CobInd,	p16.PcobInd as p16_CobInd,	p17.PcobInd as p17_CobInd,	p18.PcobInd as p18_CobInd,	p19.PcobInd as p19_CobInd,	p20.PcobInd as p20_CobInd
into lcc_GSMScanner_50x50_ProbCobIndoor_ALL
from
	(select b1.*, op.* from
		(
		select longitude, latitude, lonid,latid from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		group by longitude, latitude, lonid,latid
		) b1,  
	(select operator from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW where operator is not null group by operator) op
	)b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover

		  left outer join
		  (select lonid,latid, operator,max(operator_ord) as num_pilots ,min(measdate) as min_measdate, max(measdate) as measdate
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		   group by lonid, latid,operator
		   ) n
		  on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator

	-- Cada uno de los pilotos y su cobertura
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd,rssi_avg,codigo_ine
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=1
		  ) p1
		  on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=2
		  ) p2
		  on p2.lonid=b.lonid and p2.latid=b.latid and p2.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=3
		  ) p3
		  on p3.lonid=b.lonid and p3.latid=b.latid and p3.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=4
		  ) p4
		  on p4.lonid=b.lonid and p4.latid=b.latid and p4.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=5
		  ) p5
		  on p5.lonid=b.lonid and p5.latid=b.latid and p5.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=6
		  ) p6
		  on p6.lonid=b.lonid and p6.latid=b.latid and p6.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=7
		  ) p7
		  on p7.lonid=b.lonid and p7.latid=b.latid and p7.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=8
		  ) p8
		  on p8.lonid=b.lonid and p8.latid=b.latid and p8.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=9
		  ) p9
		  on p9.lonid=b.lonid and p9.latid=b.latid and p9.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=10
		  ) p10
		  on p10.lonid=b.lonid and p10.latid=b.latid and p10.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=11
		  ) p11
		  on p11.lonid=b.lonid and p11.latid=b.latid and p11.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=12
		  ) p12
		  on p12.lonid=b.lonid and p12.latid=b.latid and p12.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=13
		  ) p13
		  on p13.lonid=b.lonid and p13.latid=b.latid and p13.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=14
		  ) p14
		  on p14.lonid=b.lonid and p14.latid=b.latid and p14.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=15
		  ) p15
		  on p15.lonid=b.lonid and p15.latid=b.latid and p15.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=16
		  ) p16
		  on p16.lonid=b.lonid and p16.latid=b.latid and p16.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=17
		  ) p17
		  on p17.lonid=b.lonid and p17.latid=b.latid and p17.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=18
		  ) p18
		  on p18.lonid=b.lonid and p18.latid=b.latid and p18.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=19
		  ) p19
		  on p19.lonid=b.lonid and p19.latid=b.latid and p19.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_ord=20
		  ) p20
		  on p20.lonid=b.lonid and p20.latid=b.latid and p20.operator=b.operator
option (Optimize for unknown)


exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_GSM'
select 
	b.*, 
	n.num_pilots, n.measdate,
	p1.rssi_avg,p1.band,p1.codigo_ine,
	p1.rssi_median as RSSI_BS, p1.channel, p1.bsic,
	1.0-(
		(1.0-isnull(p1.PcobInd,0.0))*(1.0-isnull(p2.PcobInd,0.0))*(1.0-isnull(p3.PcobInd,0.0))*(1.0-isnull(p4.PcobInd,0.0))*(1.0-isnull(p5.PcobInd,0.0))*(1.0-isnull(p6.PcobInd,0.0))*(1.0-isnull(p7.PcobInd,0.0))*(1.0-isnull(p8.PcobInd,0.0))*(1.0-isnull(p9.PcobInd,0.0))*(1.0-isnull(p10.PcobInd,0.0))*
		(1.0-isnull(p11.PcobInd,0.0))*(1.0-isnull(p12.PcobInd,0.0))*(1.0-isnull(p13.PcobInd,0.0))*(1.0-isnull(p14.PcobInd,0.0))*(1.0-isnull(p15.PcobInd,0.0))*(1.0-isnull(p16.PcobInd,0.0))*(1.0-isnull(p17.PcobInd,0.0))*(1.0-isnull(p18.PcobInd,0.0))*(1.0-isnull(p19.PcobInd,0.0))*(1.0-isnull(p20.PcobInd,0.0))
	)	as PcobInd,
	p1.PcobInd as p1_PcobInd,	p2.PcobInd as p2_CobInd,	p3.PcobInd as p3_CobInd,	p4.PcobInd as p4_CobInd,	p5.PcobInd as p5_CobInd,	p6.PcobInd as p6_CobInd,	p7.PcobInd as p7_CobInd,	p8.PcobInd as p8_CobInd,	p9.PcobInd as p9_CobInd,	p10.PcobInd as p10_CobInd,
	p11.PcobInd as p11_PcobInd, p12.PcobInd as p12_CobInd,	p13.PcobInd as p13_CobInd,	p14.PcobInd as p14_CobInd,	p15.PcobInd as p15_CobInd,	p16.PcobInd as p16_CobInd,	p17.PcobInd as p17_CobInd,	p18.PcobInd as p18_CobInd,	p19.PcobInd as p19_CobInd,	p20.PcobInd as p20_CobInd
into lcc_GSMScanner_50x50_ProbCobIndoor_GSM
from
	(select b1.*, op.* from
		(
		select longitude, latitude, lonid,latid from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		group by longitude, latitude, lonid,latid
		) b1,  
	(select operator from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW where operator is not null group by operator) op
	)b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover

		  left outer join
		  (select lonid,latid, operator,max(operator_band_ord) as num_pilots ,min(measdate) as min_measdate, max(measdate) as measdate
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where band in ('GSM','EGSM')
		   group by lonid, latid,operator
		   ) n
		  on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator

	-- Cada uno de los pilotos y su cobertura
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd,rssi_avg,codigo_ine
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=1 and band in ('GSM','EGSM')
		  ) p1
		  on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=2 and band in ('GSM','EGSM')
		  ) p2
		  on p2.lonid=b.lonid and p2.latid=b.latid and p2.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=3 and band in ('GSM','EGSM')
		  ) p3
		  on p3.lonid=b.lonid and p3.latid=b.latid and p3.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=4 and band in ('GSM','EGSM')
		  ) p4
		  on p4.lonid=b.lonid and p4.latid=b.latid and p4.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=5 and band in ('GSM','EGSM')
		  ) p5
		  on p5.lonid=b.lonid and p5.latid=b.latid and p5.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=6 and band in ('GSM','EGSM')
		  ) p6
		  on p6.lonid=b.lonid and p6.latid=b.latid and p6.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=7 and band in ('GSM','EGSM')
		  ) p7
		  on p7.lonid=b.lonid and p7.latid=b.latid and p7.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=8 and band in ('GSM','EGSM')
		  ) p8
		  on p8.lonid=b.lonid and p8.latid=b.latid and p8.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=9 and band in ('GSM','EGSM')
		  ) p9
		  on p9.lonid=b.lonid and p9.latid=b.latid and p9.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=10 and band in ('GSM','EGSM')
		  ) p10
		  on p10.lonid=b.lonid and p10.latid=b.latid and p10.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=11 and band in ('GSM','EGSM')
		  ) p11
		  on p11.lonid=b.lonid and p11.latid=b.latid and p11.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=12 and band in ('GSM','EGSM')
		  ) p12
		  on p12.lonid=b.lonid and p12.latid=b.latid and p12.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=13 and band in ('GSM','EGSM')
		  ) p13
		  on p13.lonid=b.lonid and p13.latid=b.latid and p13.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=14 and band in ('GSM','EGSM')
		  ) p14
		  on p14.lonid=b.lonid and p14.latid=b.latid and p14.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=15 and band in ('GSM','EGSM')
		  ) p15
		  on p15.lonid=b.lonid and p15.latid=b.latid and p15.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=16 and band in ('GSM','EGSM')
		  ) p16
		  on p16.lonid=b.lonid and p16.latid=b.latid and p16.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=17 and band in ('GSM','EGSM')
		  ) p17
		  on p17.lonid=b.lonid and p17.latid=b.latid and p17.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=18 and band in ('GSM','EGSM')
		  ) p18
		  on p18.lonid=b.lonid and p18.latid=b.latid and p18.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=19 and band in ('GSM','EGSM')
		  ) p19
		  on p19.lonid=b.lonid and p19.latid=b.latid and p19.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=20 and band in ('GSM','EGSM')
		  ) p20
		  on p20.lonid=b.lonid and p20.latid=b.latid and p20.operator=b.operator
option (Optimize for unknown)


exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_DCS'
select 
	b.*, 
	n.num_pilots, n.measdate,
	p1.rssi_avg,p1.band,p1.codigo_ine,
	p1.rssi_median as RSSI_BS, p1.channel, p1.bsic,
	1.0-(
		(1.0-isnull(p1.PcobInd,0.0))*(1.0-isnull(p2.PcobInd,0.0))*(1.0-isnull(p3.PcobInd,0.0))*(1.0-isnull(p4.PcobInd,0.0))*(1.0-isnull(p5.PcobInd,0.0))*(1.0-isnull(p6.PcobInd,0.0))*(1.0-isnull(p7.PcobInd,0.0))*(1.0-isnull(p8.PcobInd,0.0))*(1.0-isnull(p9.PcobInd,0.0))*(1.0-isnull(p10.PcobInd,0.0))*
		(1.0-isnull(p11.PcobInd,0.0))*(1.0-isnull(p12.PcobInd,0.0))*(1.0-isnull(p13.PcobInd,0.0))*(1.0-isnull(p14.PcobInd,0.0))*(1.0-isnull(p15.PcobInd,0.0))*(1.0-isnull(p16.PcobInd,0.0))*(1.0-isnull(p17.PcobInd,0.0))*(1.0-isnull(p18.PcobInd,0.0))*(1.0-isnull(p19.PcobInd,0.0))*(1.0-isnull(p20.PcobInd,0.0))
	)	as PcobInd,
	p1.PcobInd as p1_PcobInd,	p2.PcobInd as p2_CobInd,	p3.PcobInd as p3_CobInd,	p4.PcobInd as p4_CobInd,	p5.PcobInd as p5_CobInd,	p6.PcobInd as p6_CobInd,	p7.PcobInd as p7_CobInd,	p8.PcobInd as p8_CobInd,	p9.PcobInd as p9_CobInd,	p10.PcobInd as p10_CobInd,
	p11.PcobInd as p11_PcobInd, p12.PcobInd as p12_CobInd,	p13.PcobInd as p13_CobInd,	p14.PcobInd as p14_CobInd,	p15.PcobInd as p15_CobInd,	p16.PcobInd as p16_CobInd,	p17.PcobInd as p17_CobInd,	p18.PcobInd as p18_CobInd,	p19.PcobInd as p19_CobInd,	p20.PcobInd as p20_CobInd
into lcc_GSMScanner_50x50_ProbCobIndoor_DCS
from
	(select b1.*, op.* from
		(
		select longitude, latitude, lonid,latid 
		from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		group by longitude, latitude, lonid,latid
		) b1,  
	(select operator from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW where operator is not null group by operator) op
	)b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover

		  left outer join
		  (select lonid,latid, operator,max(operator_band_ord) as num_pilots ,min(measdate) as min_measdate, max(measdate) as measdate
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where band = 'DCS'
		   group by lonid, latid,operator
		   ) n
		  on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator

	-- Cada uno de los pilotos y su cobertura
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd,rssi_avg,codigo_ine
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=1 and band = 'DCS'
		  ) p1
		  on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=2 and band = 'DCS'
		  ) p2
		  on p2.lonid=b.lonid and p2.latid=b.latid and p2.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=3 and band = 'DCS'
		  ) p3
		  on p3.lonid=b.lonid and p3.latid=b.latid and p3.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=4 and band = 'DCS'
		  ) p4
		  on p4.lonid=b.lonid and p4.latid=b.latid and p4.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=5 and band = 'DCS'
		  ) p5
		  on p5.lonid=b.lonid and p5.latid=b.latid and p5.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=6 and band = 'DCS'
		  ) p6
		  on p6.lonid=b.lonid and p6.latid=b.latid and p6.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=7 and band = 'DCS'
		  ) p7
		  on p7.lonid=b.lonid and p7.latid=b.latid and p7.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=8 and band = 'DCS'
		  ) p8
		  on p8.lonid=b.lonid and p8.latid=b.latid and p8.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=9 and band = 'DCS'
		  ) p9
		  on p9.lonid=b.lonid and p9.latid=b.latid and p9.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=10 and band = 'DCS'
		  ) p10
		  on p10.lonid=b.lonid and p10.latid=b.latid and p10.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=11 and band = 'DCS'
		  ) p11
		  on p11.lonid=b.lonid and p11.latid=b.latid and p11.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=12 and band = 'DCS'
		  ) p12
		  on p12.lonid=b.lonid and p12.latid=b.latid and p12.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=13 and band = 'DCS'
		  ) p13
		  on p13.lonid=b.lonid and p13.latid=b.latid and p13.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=14 and band = 'DCS'
		  ) p14
		  on p14.lonid=b.lonid and p14.latid=b.latid and p14.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=15 and band = 'DCS'
		  ) p15
		  on p15.lonid=b.lonid and p15.latid=b.latid and p15.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=16 and band = 'DCS'
		  ) p16
		  on p16.lonid=b.lonid and p16.latid=b.latid and p16.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=17 and band = 'DCS'
		  ) p17
		  on p17.lonid=b.lonid and p17.latid=b.latid and p17.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=18 and band = 'DCS'
		  ) p18
		  on p18.lonid=b.lonid and p18.latid=b.latid and p18.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=19 and band = 'DCS'
		  ) p19
		  on p19.lonid=b.lonid and p19.latid=b.latid and p19.operator=b.operator
		  ---
		  left outer join 
		  (select lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd
		  from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
		  where operator_band_ord=20 and band = 'DCS'
		  ) p20
		  on p20.lonid=b.lonid and p20.latid=b.latid and p20.operator=b.operator
option (Optimize for unknown)


exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_VALENCIA_NEW'
select b.longitude, b.latitude, b.lonid, b.latid, 
	b.Channel, b.bsic, b.rssi_avg, b.rssi_median, b.band, b.operator, b.measdate,
	t.PcobInd,t.num_pilots,
	case when b.band in ('GSM','EGSM') then g.PcobInd
		when b.band = 'DCS' then d.PcobInd 
	end as 'PcobInd_Band',
	case when b.band in ('GSM','EGSM') then g.num_pilots
		when b.band = 'DCS' then d.num_pilots 
	end as 'num_pilots_Band',
	b.codigo_ine,
	b.operator_ord,
	b.fileId
into lcc_GSMScanner_50x50_ProbCobIndoor_VALENCIA_NEW
from 
	( select longitude,latitude,lonid,latid, operator,channel,bsic,rssi_median,band,PcobInd,rssi_avg,measdate,codigo_ine,fileId,
		ROW_NUMBER() over (partition by lonid, 
									 latid,
									 Operator
						order by rssi_median desc) as operator_ord
	from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord_VALENCIA_NEW
	where operator_band_ord=1
	) b
	left join lcc_GSMScanner_50x50_ProbCobIndoor_ALL t
		on t.lonid=b.lonid and t.latid=b.latid and t.operator=b.operator
	left join lcc_GSMScanner_50x50_ProbCobIndoor_GSM g
		on g.lonid=b.lonid and g.latid=b.latid and g.operator=b.operator
			and g.channel=b.channel and g.bsic=b.bsic and g.band=b.band
	left join lcc_GSMScanner_50x50_ProbCobIndoor_DCS d
		on d.lonid=b.lonid and d.latid=b.latid and d.operator=b.operator
			and d.channel=b.channel and d.bsic=b.bsic and d.band=b.band
option (Optimize for unknown)


----Insertamos información de parcelas re-calculadas
--insert into lcc_GSMScanner_50x50_ProbCobIndoor
--select *
--from lcc_GSMScanner_50x50_ProbCobIndoor_Tratar

--exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_Tratar'
exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_ALL'
exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_GSM'
exec sp_lcc_dropifexists 'lcc_GSMScanner_50x50_ProbCobIndoor_DCS'

