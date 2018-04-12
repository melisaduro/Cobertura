--usse FY1718_VOICE_PRUEBA_4G
use FY1617_Voice_MRoad_A4_H2_2

--68468
update [dbo].MsgScannerBCCHInfo
set posid = t2.posid
from [dbo].MsgScannerBCCHInfo t1 
	inner join (
		select msgid,max(posid) as posid
		from MsgScannerBCCHInfo_relleno
		group by msgid
	) t2
	on t1.msgid=t2.msgid

--476701
update [dbo].MsgWCDMAScannerTopCPICH
set posid = t2.posid
from [dbo].MsgWCDMAScannerTopCPICH t1 
	inner join (
		select msgid,max(posid) as posid
		from MsgWCDMAScannerTopCPICH_relleno
		group by msgid
	) t2
	on t1.msgid=t2.msgid

--241170
update [dbo].MsgLTEScannerTopNInfo
set posid = t2.posid
from [dbo].MsgLTEScannerTopNInfo t1 
	inner join (
		select msgid,max(posid) as posid
		from MsgLTEScannerTopNInfo_relleno
		group by msgid
	) t2
	on t1.msgid=t2.msgid


--68856
select t.msgid,p.posid
into [dbo].MsgScannerBCCHInfo_relleno
from 
	(
		select min(t.timelink) timelinkPos,lc.msgid
		from [dbo].MsgScannerBCCHInfo_vacias lc 
				inner join lcc_timelink_position_Log t 
						on t.timelink>=lc.timelink
		group by lc.msgid
	) t 
	inner join lcc_timelink_position_Log t2
		on timelinkPos = timelink
	inner join position_Log p
		on t2.timelink = p.timelink and t2.fileid =  p.fileid



--select msgid,count(1)
--from MsgScannerBCCHInfo_relleno
--group by msgid
--having count(1)>1


--479760
select t.msgid,p.posid
into [dbo].MsgWCDMAScannerTopCPICH_relleno
from 
	(
		select min(t.timelink) timelinkPos,lc.msgid
		from [dbo].MsgWCDMAScannerTopCPICH_vacias lc 
				inner join lcc_timelink_position_Log t 
						on t.timelink>=lc.timelink
		group by lc.msgid
	) t 
	inner join lcc_timelink_position_Log t2
		on timelinkPos = timelink
	inner join position_Log p
		on t2.timelink = p.timelink and t2.fileid =  p.fileid

--242672
select t.msgid,p.posid
into [dbo].MsgLTEScannerTopNInfo_relleno
from 
	(
		select min(t.timelink) timelinkPos,lc.msgid
		from [dbo].MsgLTEScannerTopNInfo_vacias lc 
				inner join lcc_timelink_position_Log t 
						on t.timelink>=lc.timelink
		group by lc.msgid
	) t 
	inner join lcc_timelink_position_Log t2
		on timelinkPos = timelink
	inner join position_Log p
		on t2.timelink = p.timelink and t2.fileid =  p.fileid