--USE [FY1718_Coverage_Union_H1]
--GO
--/****** Object:  StoredProcedure [dbo].[sp_plcc_create_lcc_UMTSScanner_50x50_ProbCobIndoor]    Script Date: 03/10/2017 15:31:41 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO


--ALTER procedure [dbo].[sp_plcc_create_lcc_UMTSScanner_50x50_ProbCobIndoor] 
--as 

--use FY1718_VOICE_REST_4G_H1_27 --SITGES
--use FY1718_VOICE_REST_4G_H1_13 --ALCORCON
use FY1718_VOICE_VALENCIA_4G_H1

-----------------------------------------U900_F1-------------------------------------
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U900_F1'
select 
	b.*, 
	n.num_pilots,	-- numero de pilotos teniendo en cuenta la ordenación por operador solo
	n.measdate,
	p1.RSCP_median, p1.EcI0_median, 
	p1.Channel, 
	p1.SCode,
	p1.band,
	-- 
	1.0-(
		  (1.0-isnull(p1.PcobInd_voice,0.0))*(1.0-isnull(p2.PcobInd_voice,0.0))*(1.0-isnull(p3.PcobInd_voice,0.0))*(1.0-isnull(p4.PcobInd_voice,0.0))*(1.0-isnull(p5.PcobInd_voice,0.0))
		)
	 as PcobInd_Voice,
	p1.PcobInd_voice as p1_PcobInd_voice,	p2.PcobInd_voice as p2_PcobInd_voice,	p3.PcobInd_voice as p3_PcobInd_voice,	
	p4.PcobInd_voice as p4_PcobInd_voice,	p5.PcobInd_voice as p5_PcobInd_voice,
	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataGood,0.0))*(1.0-isnull(p2.PcobInd_DataGood,0.0))*(1.0-isnull(p3.PcobInd_DataGood,0.0))*(1.0-isnull(p4.PcobInd_DataGood,0.0))*(1.0-isnull(p5.PcobInd_DataGood,0.0))
		)
	 as PcobInd_DataGood,
	p1.PcobInd_DataGood as p1_PcobInd_DataGood,	p2.PcobInd_DataGood as p2_PcobInd_DataGood,	p3.PcobInd_DataGood as p3_PcobInd_DataGood,	
	p4.PcobInd_DataGood as p4_PcobInd_DataGood,	p5.PcobInd_DataGood as p5_PcobInd_DataGood,
	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataFair,0.0))*(1.0-isnull(p2.PcobInd_DataFair,0.0))*(1.0-isnull(p3.PcobInd_DataFair,0.0))*(1.0-isnull(p4.PcobInd_DataFair,0.0))*(1.0-isnull(p5.PcobInd_DataFair,0.0))
		)
	 as PcobInd_DataFair,
	p1.PcobInd_DataFair as p1_PcobInd_DataFair,	p2.PcobInd_DataFair as p2_PcobInd_DataFair,	p3.PcobInd_DataFair as p3_PcobInd_DataFair,	
	p4.PcobInd_DataFair as p4_PcobInd_DataFair,	p5.PcobInd_DataFair as p5_PcobInd_DataFair
into lcc_UMTSScanner_50x50_ProbCobIndoor_U900_F1
from
	(select b1.*, op.* 
	from
		(select longitude, latitude, lonid, latid 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		group by longitude, latitude, lonid,latid
		) b1,  

		(select operator 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator is not null group by operator) op
	) b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover
	
	LEFT OUTER JOIN	(select lonid, latid, operator, 
			max(operator_band_channel_ord) as num_pilots, min(measdate) as min_measdate, max(measdate) as measdate
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW
		where band ='UMTS900' and Channel in (3087,3011,2959)
		group by lonid, latid, operator
	) n 
	on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator
  
	-- Cada uno de los pilotos y su cobertura -> en este caso los 5 primeros 
	LEFT OUTER JOIN
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=1 and band ='UMTS900' and Channel in (3087,3011,2959)
	) p1											
	on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=2 and band ='UMTS900' and Channel in (3087,3011,2959)
	) p2											
	on p2.lonid=b.lonid and p2.latid=b.latid and p2.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=3 and band ='UMTS900' and Channel in (3087,3011,2959)
	) p3											
	on p3.lonid=b.lonid and p3.latid=b.latid and p3.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=4 and band ='UMTS900' and Channel in (3087,3011,2959)
	) p4											
	on p4.lonid=b.lonid and p4.latid=b.latid and p4.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=5 and band ='UMTS900' and Channel in (3087,3011,2959)
	) p5											
	on p5.lonid=b.lonid and p5.latid=b.latid and p5.operator=b.operator
option (optimize for unknown)


-----------------------------------------U900_F2-------------------------------------
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U900_F2'
select 
	b.*, 
	n.num_pilots,	-- numero de pilotos teniendo en cuenta la ordenación por operador solo
	n.measdate,
	p1.RSCP_median, p1.EcI0_median, 
	p1.Channel, 
	p1.SCode,
	p1.band,
	-- 
	1.0-(
		  (1.0-isnull(p1.PcobInd_voice,0.0))*(1.0-isnull(p2.PcobInd_voice,0.0))*(1.0-isnull(p3.PcobInd_voice,0.0))*(1.0-isnull(p4.PcobInd_voice,0.0))*(1.0-isnull(p5.PcobInd_voice,0.0))
		)
	 as PcobInd_Voice,
	p1.PcobInd_voice as p1_PcobInd_voice,	p2.PcobInd_voice as p2_PcobInd_voice,	p3.PcobInd_voice as p3_PcobInd_voice,	
	p4.PcobInd_voice as p4_PcobInd_voice,	p5.PcobInd_voice as p5_PcobInd_voice,
	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataGood,0.0))*(1.0-isnull(p2.PcobInd_DataGood,0.0))*(1.0-isnull(p3.PcobInd_DataGood,0.0))*(1.0-isnull(p4.PcobInd_DataGood,0.0))*(1.0-isnull(p5.PcobInd_DataGood,0.0))
		)
	 as PcobInd_DataGood,
	p1.PcobInd_DataGood as p1_PcobInd_DataGood,	p2.PcobInd_DataGood as p2_PcobInd_DataGood,	p3.PcobInd_DataGood as p3_PcobInd_DataGood,	
	p4.PcobInd_DataGood as p4_PcobInd_DataGood,	p5.PcobInd_DataGood as p5_PcobInd_DataGood,
	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataFair,0.0))*(1.0-isnull(p2.PcobInd_DataFair,0.0))*(1.0-isnull(p3.PcobInd_DataFair,0.0))*(1.0-isnull(p4.PcobInd_DataFair,0.0))*(1.0-isnull(p5.PcobInd_DataFair,0.0))
		)
	 as PcobInd_DataFair,
	p1.PcobInd_DataFair as p1_PcobInd_DataFair,	p2.PcobInd_DataFair as p2_PcobInd_DataFair,	p3.PcobInd_DataFair as p3_PcobInd_DataFair,	
	p4.PcobInd_DataFair as p4_PcobInd_DataFair,	p5.PcobInd_DataFair as p5_PcobInd_DataFair
into lcc_UMTSScanner_50x50_ProbCobIndoor_U900_F2
from
	(select b1.*, op.* 
	from
		(select longitude, latitude, lonid, latid 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		group by longitude, latitude, lonid,latid
		) b1,  

		(select operator 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator is not null group by operator) op
	) b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover
	
	LEFT OUTER JOIN	(select lonid, latid, operator, 
			max(operator_band_channel_ord) as num_pilots, min(measdate) as min_measdate, max(measdate) as measdate
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW
		where band ='UMTS900' and Channel in (3062,3032)
		group by lonid, latid, operator
	) n 
	on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator
  
	-- Cada uno de los pilotos y su cobertura -> en este caso los 5 primeros 
	LEFT OUTER JOIN
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=1 and band ='UMTS900' and Channel in (3062,3032)
	) p1											
	on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=2 and band ='UMTS900' and Channel in (3062,3032)
	) p2											
	on p2.lonid=b.lonid and p2.latid=b.latid and p2.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=3 and band ='UMTS900' and Channel in (3062,3032)
	) p3											
	on p3.lonid=b.lonid and p3.latid=b.latid and p3.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=4 and band ='UMTS900' and Channel in (3062,3032)
	) p4											
	on p4.lonid=b.lonid and p4.latid=b.latid and p4.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=5 and band ='UMTS900' and Channel in (3062,3032)
	) p5											
	on p5.lonid=b.lonid and p5.latid=b.latid and p5.operator=b.operator
option (optimize for unknown)

----------------------------------------U2100_F1-------------------------------------
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F1'
select 
	b.*, 
	n.num_pilots,	-- numero de pilotos teniendo en cuenta la ordenación por operador solo
	n.measdate,
	p1.RSCP_median, p1.EcI0_median, 
	p1.Channel, 
	p1.SCode,
	p1.band,
	-- 
	1.0-(
		  (1.0-isnull(p1.PcobInd_voice,0.0))*(1.0-isnull(p2.PcobInd_voice,0.0))*(1.0-isnull(p3.PcobInd_voice,0.0))*(1.0-isnull(p4.PcobInd_voice,0.0))*(1.0-isnull(p5.PcobInd_voice,0.0))
		)
	 as PcobInd_Voice,
	p1.PcobInd_voice as p1_PcobInd_voice,	p2.PcobInd_voice as p2_PcobInd_voice,	p3.PcobInd_voice as p3_PcobInd_voice,	
	p4.PcobInd_voice as p4_PcobInd_voice,	p5.PcobInd_voice as p5_PcobInd_voice,
	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataGood,0.0))*(1.0-isnull(p2.PcobInd_DataGood,0.0))*(1.0-isnull(p3.PcobInd_DataGood,0.0))*(1.0-isnull(p4.PcobInd_DataGood,0.0))*(1.0-isnull(p5.PcobInd_DataGood,0.0))
		)
	 as PcobInd_DataGood,
	p1.PcobInd_DataGood as p1_PcobInd_DataGood,	p2.PcobInd_DataGood as p2_PcobInd_DataGood,	p3.PcobInd_DataGood as p3_PcobInd_DataGood,	
	p4.PcobInd_DataGood as p4_PcobInd_DataGood,	p5.PcobInd_DataGood as p5_PcobInd_DataGood,
	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataFair,0.0))*(1.0-isnull(p2.PcobInd_DataFair,0.0))*(1.0-isnull(p3.PcobInd_DataFair,0.0))*(1.0-isnull(p4.PcobInd_DataFair,0.0))*(1.0-isnull(p5.PcobInd_DataFair,0.0))
		)
	 as PcobInd_DataFair,
	p1.PcobInd_DataFair as p1_PcobInd_DataFair,	p2.PcobInd_DataFair as p2_PcobInd_DataFair,	p3.PcobInd_DataFair as p3_PcobInd_DataFair,	
	p4.PcobInd_DataFair as p4_PcobInd_DataFair,	p5.PcobInd_DataFair as p5_PcobInd_DataFair
into lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F1
from
	(select b1.*, op.* 
	from
		(select longitude, latitude, lonid, latid 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		group by longitude, latitude, lonid,latid
		) b1,  

		(select operator 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator is not null group by operator) op
	) b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover
	
	LEFT OUTER JOIN	(select lonid, latid, operator, 
			max(operator_band_channel_ord) as num_pilots, min(measdate) as min_measdate, max(measdate) as measdate
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW
		where band ='UMTS2100' and Channel in (10713, 10788, 10638, 10563)
		group by lonid, latid, operator
	) n 
	on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator
  
	-- Cada uno de los pilotos y su cobertura -> en este caso los 5 primeros 
	LEFT OUTER JOIN
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=1 and band ='UMTS2100' and Channel in (10713, 10788, 10638, 10563)
	) p1											
	on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=2 and band ='UMTS2100' and Channel in (10713, 10788, 10638, 10563)
	) p2											
	on p2.lonid=b.lonid and p2.latid=b.latid and p2.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=3 and band ='UMTS2100' and Channel in (10713, 10788, 10638, 10563)
	) p3											
	on p3.lonid=b.lonid and p3.latid=b.latid and p3.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=4 and band ='UMTS2100' and Channel in (10713, 10788, 10638, 10563)
	) p4											
	on p4.lonid=b.lonid and p4.latid=b.latid and p4.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=5 and band ='UMTS2100' and Channel in (10713, 10788, 10638, 10563)
	) p5											
	on p5.lonid=b.lonid and p5.latid=b.latid and p5.operator=b.operator
option (optimize for unknown)


----------------------------------------U2100_F2-------------------------------------
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F2'
select 
	b.*, 
	n.num_pilots,	-- numero de pilotos teniendo en cuenta la ordenación por operador solo
	n.measdate,
	p1.RSCP_median, p1.EcI0_median, 
	p1.Channel, 
	p1.SCode,
	p1.band,
	-- 
	1.0-(
		  (1.0-isnull(p1.PcobInd_voice,0.0))*(1.0-isnull(p2.PcobInd_voice,0.0))*(1.0-isnull(p3.PcobInd_voice,0.0))*(1.0-isnull(p4.PcobInd_voice,0.0))*(1.0-isnull(p5.PcobInd_voice,0.0))
		)
	 as PcobInd_Voice,
	p1.PcobInd_voice as p1_PcobInd_voice,	p2.PcobInd_voice as p2_PcobInd_voice,	p3.PcobInd_voice as p3_PcobInd_voice,	
	p4.PcobInd_voice as p4_PcobInd_voice,	p5.PcobInd_voice as p5_PcobInd_voice,
	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataGood,0.0))*(1.0-isnull(p2.PcobInd_DataGood,0.0))*(1.0-isnull(p3.PcobInd_DataGood,0.0))*(1.0-isnull(p4.PcobInd_DataGood,0.0))*(1.0-isnull(p5.PcobInd_DataGood,0.0))
		)
	 as PcobInd_DataGood,
	p1.PcobInd_DataGood as p1_PcobInd_DataGood,	p2.PcobInd_DataGood as p2_PcobInd_DataGood,	p3.PcobInd_DataGood as p3_PcobInd_DataGood,	
	p4.PcobInd_DataGood as p4_PcobInd_DataGood,	p5.PcobInd_DataGood as p5_PcobInd_DataGood,
	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataFair,0.0))*(1.0-isnull(p2.PcobInd_DataFair,0.0))*(1.0-isnull(p3.PcobInd_DataFair,0.0))*(1.0-isnull(p4.PcobInd_DataFair,0.0))*(1.0-isnull(p5.PcobInd_DataFair,0.0))
		)
	 as PcobInd_DataFair,
	p1.PcobInd_DataFair as p1_PcobInd_DataFair,	p2.PcobInd_DataFair as p2_PcobInd_DataFair,	p3.PcobInd_DataFair as p3_PcobInd_DataFair,	
	p4.PcobInd_DataFair as p4_PcobInd_DataFair,	p5.PcobInd_DataFair as p5_PcobInd_DataFair
into lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F2
from
	(select b1.*, op.* 
	from
		(select longitude, latitude, lonid, latid 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		group by longitude, latitude, lonid,latid
		) b1,  

		(select operator 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator is not null group by operator) op
	) b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover
	
	LEFT OUTER JOIN	(select lonid, latid, operator, 
			max(operator_band_channel_ord) as num_pilots, min(measdate) as min_measdate, max(measdate) as measdate
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW
		where band ='UMTS2100' and Channel in (10738, 10813, 10663, 10588)
		group by lonid, latid, operator
	) n 
	on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator
  
	-- Cada uno de los pilotos y su cobertura -> en este caso los 5 primeros 
	LEFT OUTER JOIN
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=1 and band ='UMTS2100' and Channel in (10738, 10813, 10663, 10588)
	) p1											
	on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=2 and band ='UMTS2100' and Channel in (10738, 10813, 10663, 10588)
	) p2											
	on p2.lonid=b.lonid and p2.latid=b.latid and p2.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=3 and band ='UMTS2100' and Channel in (10738, 10813, 10663, 10588)
	) p3											
	on p3.lonid=b.lonid and p3.latid=b.latid and p3.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=4 and band ='UMTS2100' and Channel in (10738, 10813, 10663, 10588)
	) p4											
	on p4.lonid=b.lonid and p4.latid=b.latid and p4.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=5 and band ='UMTS2100' and Channel in (10738, 10813, 10663, 10588)
	) p5											
	on p5.lonid=b.lonid and p5.latid=b.latid and p5.operator=b.operator
option (optimize for unknown)

----------------------------------------U2100_F3-------------------------------------
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F3'
select 
	b.*, 
	n.num_pilots,	-- numero de pilotos teniendo en cuenta la ordenación por operador solo
	n.measdate,
	p1.RSCP_median, p1.EcI0_median, 
	p1.Channel, 
	p1.SCode,
	p1.band,
	-- 
	1.0-(
		  (1.0-isnull(p1.PcobInd_voice,0.0))*(1.0-isnull(p2.PcobInd_voice,0.0))*(1.0-isnull(p3.PcobInd_voice,0.0))*(1.0-isnull(p4.PcobInd_voice,0.0))*(1.0-isnull(p5.PcobInd_voice,0.0))
		)
	 as PcobInd_Voice,
	p1.PcobInd_voice as p1_PcobInd_voice,	p2.PcobInd_voice as p2_PcobInd_voice,	p3.PcobInd_voice as p3_PcobInd_voice,	
	p4.PcobInd_voice as p4_PcobInd_voice,	p5.PcobInd_voice as p5_PcobInd_voice,
	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataGood,0.0))*(1.0-isnull(p2.PcobInd_DataGood,0.0))*(1.0-isnull(p3.PcobInd_DataGood,0.0))*(1.0-isnull(p4.PcobInd_DataGood,0.0))*(1.0-isnull(p5.PcobInd_DataGood,0.0))
		)
	 as PcobInd_DataGood,
	p1.PcobInd_DataGood as p1_PcobInd_DataGood,	p2.PcobInd_DataGood as p2_PcobInd_DataGood,	p3.PcobInd_DataGood as p3_PcobInd_DataGood,	
	p4.PcobInd_DataGood as p4_PcobInd_DataGood,	p5.PcobInd_DataGood as p5_PcobInd_DataGood,
	--
	1.0-(
		  (1.0-isnull(p1.PcobInd_DataFair,0.0))*(1.0-isnull(p2.PcobInd_DataFair,0.0))*(1.0-isnull(p3.PcobInd_DataFair,0.0))*(1.0-isnull(p4.PcobInd_DataFair,0.0))*(1.0-isnull(p5.PcobInd_DataFair,0.0))
		)
	 as PcobInd_DataFair,
	p1.PcobInd_DataFair as p1_PcobInd_DataFair,	p2.PcobInd_DataFair as p2_PcobInd_DataFair,	p3.PcobInd_DataFair as p3_PcobInd_DataFair,	
	p4.PcobInd_DataFair as p4_PcobInd_DataFair,	p5.PcobInd_DataFair as p5_PcobInd_DataFair
into lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F3
from
	(select b1.*, op.* 
	from
		(select longitude, latitude, lonid, latid 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		group by longitude, latitude, lonid,latid
		) b1,  

		(select operator 
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator is not null group by operator) op
	) b -- en b (tabla base) estan todas las posibles cuadriculas y operadores.. para que si no hay scanner de algun operador cuente como no cover
	
	LEFT OUTER JOIN	(select lonid, latid, operator, 
			max(operator_band_channel_ord) as num_pilots, min(measdate) as min_measdate, max(measdate) as measdate
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW
		where band ='UMTS2100' and Channel in (10763, 10838, 10688, 10613)
		group by lonid, latid, operator
	) n 
	on b.lonid=n.lonid and b.latid=n.latid and b.operator=n.operator
  
	-- Cada uno de los pilotos y su cobertura -> en este caso los 5 primeros 
	LEFT OUTER JOIN
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=1 and band ='UMTS2100' and Channel in (10763, 10838, 10688, 10613)
	) p1											
	on p1.lonid=b.lonid and p1.latid=b.latid and p1.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=2 and band ='UMTS2100' and Channel in (10763, 10838, 10688, 10613)
	) p2											
	on p2.lonid=b.lonid and p2.latid=b.latid and p2.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=3 and band ='UMTS2100' and Channel in (10763, 10838, 10688, 10613)
	) p3											
	on p3.lonid=b.lonid and p3.latid=b.latid and p3.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=4 and band ='UMTS2100' and Channel in (10763, 10838, 10688, 10613)
	) p4											
	on p4.lonid=b.lonid and p4.latid=b.latid and p4.operator=b.operator
	---
	LEFT OUTER JOIN 
		(select lonid, latid, operator, Channel, SCode, RSCP_median, EcI0_median, band, PcobInd_voice, PcobInd_DataGood, PcobInd_DataFair
		from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
		where operator_band_channel_ord=5 and band ='UMTS2100' and Channel in (10763, 10838, 10688, 10613)
	) p5											
	on p5.lonid=b.lonid and p5.latid=b.latid and p5.operator=b.operator
option (optimize for unknown)


exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U900'
select b.longitude, b.latitude, b.lonid, b.latid, 
	b.band, b.operator,b.num_pilots,
	case when isnull(u9_f1.PcobInd_voice,0) >= isnull(u9_f2.PcobInd_voice,0) then u9_f1.PcobInd_voice
		else u9_f2.PcobInd_voice
	end as 'PcobInd_voice_Band',
	case when isnull(u9_f1.PcobInd_DataGood,0) >= isnull(u9_f2.PcobInd_DataGood,0) then u9_f1.PcobInd_DataGood
		else u9_f2.PcobInd_DataGood
	end as 'PcobInd_DataGood_Band',
	case when isnull(u9_f1.PcobInd_DataFair,0) >= isnull(u9_f2.PcobInd_DataFair,0) then u9_f1.PcobInd_DataFair
		else u9_f2.PcobInd_DataFair
	end as 'PcobInd_DataFair_Band'
into lcc_UMTSScanner_50x50_ProbCobIndoor_U900
from 
	( select longitude, latitude, lonid, latid, band, operator,max(operator_band_ord) as num_pilots
	from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW
	where band ='UMTS900'
	group by longitude, latitude, lonid, latid, band, operator
	) b
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U900_F1 u9_f1
		on u9_f1.lonid=b.lonid and u9_f1.latid=b.latid and u9_f1.operator=b.operator
			and u9_f1.band=b.band
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U900_F2 u9_f2
		on u9_f2.lonid=b.lonid and u9_f2.latid=b.latid and u9_f2.operator=b.operator
			and u9_f2.band=b.band


exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U2100'
select b.longitude, b.latitude, b.lonid, b.latid, 
	b.band, b.operator,b.num_pilots,
	case when isnull(u21_f1.PcobInd_voice,0) >= isnull(u21_f2.PcobInd_voice,0) and isnull(u21_f1.PcobInd_voice,0) >= isnull(u21_f3.PcobInd_voice,0) then u21_f1.PcobInd_voice
		 when isnull(u21_f2.PcobInd_voice,0) >= isnull(u21_f1.PcobInd_voice,0) and isnull(u21_f2.PcobInd_voice,0) >= isnull(u21_f3.PcobInd_voice,0) then u21_f2.PcobInd_voice
		else u21_f3.PcobInd_voice
	end as 'PcobInd_voice_Band',	
	case when isnull(u21_f1.PcobInd_DataGood,0) >= isnull(u21_f2.PcobInd_DataGood,0) and isnull(u21_f1.PcobInd_DataGood,0) >= isnull(u21_f3.PcobInd_DataGood,0) then u21_f1.PcobInd_DataGood
		 when isnull(u21_f2.PcobInd_DataGood,0) >= isnull(u21_f1.PcobInd_DataGood,0) and isnull(u21_f2.PcobInd_DataGood,0) >= isnull(u21_f3.PcobInd_DataGood,0) then u21_f2.PcobInd_DataGood
		else u21_f3.PcobInd_DataGood
	end as 'PcobInd_DataGood_Band',
	case when isnull(u21_f1.PcobInd_DataFair,0) >= isnull(u21_f2.PcobInd_DataFair,0) and isnull(u21_f1.PcobInd_DataFair,0) >= isnull(u21_f3.PcobInd_DataFair,0) then u21_f1.PcobInd_DataFair
		 when isnull(u21_f2.PcobInd_DataFair,0) >= isnull(u21_f1.PcobInd_DataFair,0) and isnull(u21_f2.PcobInd_DataFair,0) >= isnull(u21_f3.PcobInd_DataFair,0) then u21_f2.PcobInd_DataFair
		else u21_f3.PcobInd_DataFair
	end as 'PcobInd_DataFair_Band'
into lcc_UMTSScanner_50x50_ProbCobIndoor_U2100
from 
	( select longitude, latitude, lonid, latid, band, operator,max(operator_band_ord) as num_pilots
	from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW
	where band ='UMTS2100'
	group by longitude, latitude, lonid, latid, band, operator
	) b
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F1 u21_f1
		on u21_f1.lonid=b.lonid and u21_f1.latid=b.latid and u21_f1.operator=b.operator
			and u21_f1.band=b.band
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F2 u21_f2
		on u21_f2.lonid=b.lonid and u21_f2.latid=b.latid and u21_f2.operator=b.operator
			and u21_f2.band=b.band
    left join lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F3 u21_f3
		on u21_f3.lonid=b.lonid and u21_f3.latid=b.latid and u21_f3.operator=b.operator
			and u21_f3.band=b.band

exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_ALL'
select b.longitude, b.latitude, b.lonid, b.latid, b.operator,b.num_pilots,
	case when isnull(u9.PcobInd_voice_Band,0) >= isnull(u21.PcobInd_voice_Band,0) then u9.PcobInd_voice_Band
		else u21.PcobInd_voice_Band
	end as 'PcobInd_voice',
	case when isnull(u9.PcobInd_DataGood_Band,0) >= isnull(u21.PcobInd_DataGood_Band,0) then u9.PcobInd_DataGood_Band
		else u21.PcobInd_DataGood_Band
	end as 'PcobInd_DataGood',
	case when isnull(u9.PcobInd_DataFair_Band,0) >= isnull(u21.PcobInd_DataFair_Band,0) then u9.PcobInd_DataFair_Band
		else u21.PcobInd_DataFair_Band
	end as 'PcobInd_DataFair'
into lcc_UMTSScanner_50x50_ProbCobIndoor_ALL
from 
	( select longitude, latitude, lonid, latid ,operator,max(operator_ord) as num_pilots
	from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW 
	group by longitude, latitude, lonid,latid,operator
	) b
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U900 u9
		on u9.lonid=b.lonid and U9.latid=b.latid and U9.operator=b.operator
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U2100 u21
		on u21.lonid=b.lonid and u21.latid=b.latid and u21.operator=b.operator


exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_VALENCIA_NEW'
select b.longitude, b.latitude, b.lonid, b.latid, 
	b.Channel, b.Scode, b.rscp_avg, b.rscp_median,b.EcI0_avg,b.EcI0_median, b.band, b.operator, b.measdate,
	t.PcobInd_voice,
	t.PcobInd_DataGood,
	t.PcobInd_DataFair,
	t.num_pilots,
	case when b.band = 'UMTS900' then u9.PcobInd_voice_Band
		when b.band = 'UMTS2100' then u21.PcobInd_voice_Band 
	end as 'PcobInd_voice_Band',
	case when b.band = 'UMTS900' then u9.PcobInd_DataGood_Band
		when b.band = 'UMTS2100' then u21.PcobInd_DataGood_Band
	end as 'PcobInd_DataGood_Band',
	case when b.band = 'UMTS900' then u9.PcobInd_DataFair_Band
		when b.band = 'UMTS2100' then u21.PcobInd_DataFair_Band
	end as 'PcobInd_DataFair_Band',
	case when b.band = 'UMTS900' then u9.num_pilots
		when b.band = 'UMTS2100' then u21.num_pilots 
	end as 'num_pilots_Band',	
	case when b.band = 'UMTS900' and b.Channel in (3087,3011,2959)  then u9_f1.PcobInd_voice
		when b.band = 'UMTS900' and b.Channel in (3062,3032)  then u9_f2.PcobInd_voice
		when b.band = 'UMTS2100' and b.Channel in (10713, 10788, 10638, 10563)  then u21_f1.PcobInd_voice
		when b.band = 'UMTS2100' and b.Channel in (10738, 10813, 10663, 10588)  then u21_f2.PcobInd_voice
		when b.band = 'UMTS2100' and b.Channel in (10763, 10838, 10688, 10613)  then u21_f3.PcobInd_voice
	end as 'PcobInd_voice_Channel',
	case when b.band = 'UMTS900' and b.Channel in (3087,3011,2959)  then u9_f1.PcobInd_DataGood
		when b.band = 'UMTS900' and b.Channel in (3062,3032)  then u9_f2.PcobInd_DataGood
		when b.band = 'UMTS2100' and b.Channel in (10713, 10788, 10638, 10563)  then u21_f1.PcobInd_DataGood
		when b.band = 'UMTS2100' and b.Channel in (10738, 10813, 10663, 10588)  then u21_f2.PcobInd_DataGood
		when b.band = 'UMTS2100' and b.Channel in (10763, 10838, 10688, 10613)  then u21_f3.PcobInd_DataGood
	end as 'PcobInd_DataGood_Channel',
	case when b.band = 'UMTS900' and b.Channel in (3087,3011,2959)  then u9_f1.PcobInd_DataFair
		when b.band = 'UMTS900' and b.Channel in (3062,3032)  then u9_f2.PcobInd_DataFair
		when b.band = 'UMTS2100' and b.Channel in (10713, 10788, 10638, 10563)  then u21_f1.PcobInd_DataFair
		when b.band = 'UMTS2100' and b.Channel in (10738, 10813, 10663, 10588)  then u21_f2.PcobInd_DataFair
		when b.band = 'UMTS2100' and b.Channel in (10763, 10838, 10688, 10613)  then u21_f3.PcobInd_DataFair
	end as 'PcobInd_DataFair_Channel',
	case when b.band = 'UMTS900' and b.Channel in (3087,3011,2959)  then u9_f1.num_pilots
		when b.band = 'UMTS900' and b.Channel in (3062,3032)  then u9_f2.num_pilots
		when b.band = 'UMTS2100' and b.Channel in (10713, 10788, 10638, 10563)  then u21_f1.num_pilots
		when b.band = 'UMTS2100' and b.Channel in (10738, 10813, 10663, 10588)  then u21_f2.num_pilots
		when b.band = 'UMTS2100' and b.Channel in (10763, 10838, 10688, 10613)  then u21_f3.num_pilots
	end as 'num_pilots_Channel',
	b.codigo_ine,
	b.operator_ord,
	b.operator_band_ord,
	b.fileId
into lcc_UMTSScanner_50x50_ProbCobIndoor_VALENCIA_NEW
from 
	( select longitude,latitude,lonid,latid, operator,channel,Scode,rscp_median,band,PcobInd_Voice,rscp_avg,measdate,codigo_ine,EcI0_median,EcI0_avg,fileId,
		ROW_NUMBER() over (partition by lonid, 
									 latid,
									 Operator
						order by RSCP_median desc) as operator_ord,
		ROW_NUMBER() over (partition by lonid, 
									latid,
									Operator,
									band
					    order by RSCP_median desc)as operator_band_ord
	from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord_VALENCIA_NEW
	where operator_band_channel_ord=1
	) b
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_ALL t
		on t.lonid=b.lonid and t.latid=b.latid and t.operator=b.operator
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U900 u9
		on u9.lonid=b.lonid and U9.latid=b.latid and U9.operator=b.operator
			and U9.band=b.band
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U900_F1 u9_f1
		on u9_f1.lonid=b.lonid and u9_f1.latid=b.latid and u9_f1.operator=b.operator
			and u9_f1.channel=b.channel and u9_f1.Scode=b.Scode and u9_f1.band=b.band
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U900_F2 u9_f2
		on u9_f2.lonid=b.lonid and u9_f2.latid=b.latid and u9_f2.operator=b.operator
			and u9_f2.channel=b.channel and u9_f2.Scode=b.Scode and u9_f2.band=b.band	
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U2100 u21
		on u21.lonid=b.lonid and u21.latid=b.latid and u21.operator=b.operator
			and u21.band=b.band
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F1 u21_f1
		on u21_f1.lonid=b.lonid and u21_f1.latid=b.latid and u21_f1.operator=b.operator
			and u21_f1.channel=b.channel and u21_f1.Scode=b.Scode and u21_f1.band=b.band
	left join lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F2 u21_f2
		on u21_f2.lonid=b.lonid and u21_f2.latid=b.latid and u21_f2.operator=b.operator
			and u21_f2.channel=b.channel and u21_f2.Scode=b.Scode and u21_f2.band=b.band
    left join lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F3 u21_f3
		on u21_f3.lonid=b.lonid and u21_f3.latid=b.latid and u21_f3.operator=b.operator
			and u21_f3.channel=b.channel and u21_f3.Scode=b.Scode and u21_f3.band=b.band
option (optimize for unknown)

--Insertamos información de parcelas re-calculadas
--insert into lcc_UMTSScanner_50x50_ProbCobIndoor
--select *
--from lcc_UMTSScanner_50x50_ProbCobIndoor_Tratar

--exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_Tratar'
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_ALL'
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U900'
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U900_F1'
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U900_F2'
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U2100'
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F1'
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F2'
exec sp_lcc_dropifexists 'lcc_UMTSScanner_50x50_ProbCobIndoor_U2100_F3'