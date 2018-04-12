select *
from [AGRIDS].dbo.lcc_ref_servingOperator_Freq
where  band like '%lte%'
order by 1

use FY1617_Voice_Rest_4G_H2_7
select distinct sessionid from filelist f, sessions s
where collectionname like '%teruel%'
and f.fileid=s.fileid
order by sessionid asc

use FY1617_Voice_Rest_3G_H2_8
select *
from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord p, lcc_position_Entity_List_Municipio t
where t.lonid=p.lonid and t.latid=p.latid
and entity_name='teruel'
and fileid between 99 and 104
and fileidb between 99 and 104

use FY1617_Voice_Rest_3G_H2_8
select *
from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord p, lcc_position_Entity_List_Municipio t
where t.lonid=p.lonid and t.latid=p.latid
and entity_name='teruel'
and fileid between 113 and 120
and fileidb between 113 and 120



begin transaction
delete lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord
from lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord p, lcc_position_Entity_List_Municipio t
where t.lonid=p.lonid and t.latid=p.latid
and entity_name='teruel'
and fileid between 99 and 104
and fileidb between 99 and 104
commit


select 
		lonid, 	latid, li.Channel, l.PhCId,	p.MeasDate, li.bandwidth/1000 as BandWidth,

		POWER(CAST(10 AS float), (l.RSRP)/10.0) as RSRP_lin,  
		percentile_cont(0.5) 
			within group (order by l.RSRP)
					over (partition by lonid, latid, li.Channel, l.PhCId) as RSRP_median,
			          
		POWER(CAST(10 AS float), (l.RSRQ)/10.0) as RSRQ_lin,            
		percentile_cont(0.5) 
			within group (order by l.RSRQ)
					over (partition by lonid, latid, li.Channel, l.PhCId) as RSRQ_median,

		POWER(CAST(10 AS float), (l.CINR)/10.0) as CINR_lin,  
		percentile_cont(0.5) 
			within group (order by l.CINR)
					over (partition by lonid, latid, li.Channel, l.PhCId) as CINR_median

	from MsgLTEScannerTopNInfo li, MsgLTEScannerTopN l, 
		 (select *, CONVERT(INT, 2224.0*p.longitude*COS(2*PI()*p.latitude/360)) as  lonid, 
			   CONVERT(INT, 2224.0*p.latitude)as latid,
			   right('0000'+convert(varchar(4), year(p.msgtime)),4)+
			   right('0000'+convert(varchar(4), month(p.msgtime)),2)+
			   right('0000'+convert(varchar(4), day(p.msgtime)),2) as Measdate
		 from Position p) p
	where 
		li.LTETopNId=l.LTETopNId and li.PosId=p.PosId 
		and p.FileId between 97 and 113