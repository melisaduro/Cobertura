
use FY1617_Voice_Rest_4G_H2_7
select
	lonid, latid, Channel, PhCId,  MeasDate, BandWidth,
	10*log10(avg(RSRP_lin)) as RSRP_avg,
	10*log10(avg(RSRQ_lin)) as RSRQ_avg,
	10*log10(avg(CINR_lin)) as CINR_avg,
	avg(RSRP_median)		as RSRP_median,
	avg(RSRQ_median)		as RSRQ_median,
	avg(CINR_median)		as CINR_median
--drop table temporal_pci_melisa
--into temporal_pci_melisa
from (
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
		and p.FileId between 377 and 392		-- solo considera la nueva info
		--and p.FileId = 28	
) t
--where channel in ('1675')
group by lonid, latid, Channel, PhCId, Measdate, BandWidth

select * from temporal_pci_melisa
use FY1617_Voice_Rest_3G_H2_8
select channel, sessiond count(1) from MsgLTEScannerTopNInfo 
where sessionid between '8001' and '10493'
and channel in ('1691',
'126',
'1675',
'1655')
group by channel

use [FY1617_PRUEBA_163]
select  li.LTETopNId,m.LTETopNId,channel, s.sessionid, collectionname,asidefilename, bsidefilename
from MsgLTEScannerTopNInfo li
left join MsgLTEScannerTopN m
on (li.LTETopNId=m.LTETopNId), sessions s, filelist f
where s.sessionid=li.sessionid
and s.fileid=f.fileid
and collectionname like '%teruel%'
and channel in ('1691',
'126',
'1675',
'1655')
group by li.LTETopNId,m.LTETopNId,channel,s.sessionid, collectionname,asidefilename, bsidefilename
order by 3,1

select  channel, count(1)
from MsgLTEScannerTopNInfo li, position m
where li.PosId=m.PosId 
--and m.FileId between 97 and 103	
and channel in ('1691',
'126',
'1675',
'1655')
group by channel



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

drop table temporal_pci2_melisa
--into temporal_pci2_melisa
from 
    (select distinct channel
	from temporal_pci_melisa)  c
		LEFT OUTER JOIN [AGRIDS].dbo.lcc_ref_servingOperator_Freq	sof	on c.Channel=sof.Frequency
		LEFT OUTER JOIN [AGRIDS].dbo.lcc_G2K5Absolute_INDEX_new		i	on c.lonid=i.lonid and c.latid=i.latid
where c.mdate_id=1

select * from temporal_pci2_melisa
where operator='yoigo'