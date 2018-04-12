--usse FY1718_VOICE_PRUEBA_4G
use FY1617_Voice_MRoad_A4_H2_2

--Backup:
--77123
--1462809
select *
into [dbo].MsgScannerBCCHInfo_20170605
from [dbo].MsgScannerBCCHInfo

--522789
--10152385
select *
into [dbo].[MsgWCDMAScannerTopCPICH_20170605]
from [dbo].[MsgWCDMAScannerTopCPICH]

--267410
--1942047
select *
into [dbo].[MsgLTEScannerTopNInfo_20170605]
from [dbo].[MsgLTEScannerTopNInfo]
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
--Tablas filtradas
--68468
--drop table [dbo].MsgScannerBCCHInfo_vacias
select msgtime, msgid, master.dbo.fn_lcc_gettimelink(msgtime) as timelink
into [dbo].MsgScannerBCCHInfo_vacias
from [dbo].MsgScannerBCCHInfo
where posid in (713147,787104) 
--476701
--drop table [MsgWCDMAScannerTopCPICH_vacias]
select msgtime, msgid, master.dbo.fn_lcc_gettimelink(msgtime) as timelink
into [dbo].[MsgWCDMAScannerTopCPICH_vacias]
from [dbo].[MsgWCDMAScannerTopCPICH]
where posid in (713147,787104) 
--241170
--drop table [MsgLTEScannerTopNInfo_vacias]
select msgtime, msgid, master.dbo.fn_lcc_gettimelink(msgtime) as timelink
into [dbo].[MsgLTEScannerTopNInfo_vacias]
from [dbo].[MsgLTEScannerTopNInfo]
where posid in (713147,787104) 

--18434
select *
into lcc_timelink_position_Log
from  lcc_timelink_position
where collectionname='20170525_MR_INDOOR_A4-CAD-R9_17_4G' --collate Latin1_General_CI_AS 
    and side='A'

--73958
select master.dbo.fn_lcc_gettimelink( p.msgtime) as timelink, p.fileid, p.posid
into position_Log
from position p
	inner join filelist f
		on p.fileid=f.fileid
where f.collectionname='20170525_MR_INDOOR_A4-CAD-R9_17_4G'

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--select top 2 * from [dbo].MsgScannerBCCHInfo
--select top 2 * from [dbo].[MsgWCDMAScannerTopCPICH]
--select top 2 * from [dbo].[MsgLTEScannerTopNInfo]

--select *
--from (
--	select timelink as timelinkPos,t.fileid as fileidPos,
--		ROW_NUMBER() over (partition by lc.msgid
--						   order by t.msgtime ASC)				  as idTimeLink,
--		lc.msgid
--	from MsgScannerBCCHInfo_vacias lc 
--		inner join lcc_timelink_position_Log t on timelink>=master.dbo.fn_lcc_gettimelink(lc.msgtime) 
--	) t 
--	inner join position p
--	on t.timelinkPos = master.dbo.fn_lcc_gettimelink(p.msgtime) and t.fileidPos =  p.fileid
--where idTimeLink=1



--select *
--from (
--select timelink as timelinkPos,t.fileid as fileidPos,
--	ROW_NUMBER() over (partition by lc.msgid
--					   order by t.msgtime ASC)				  as idTimeLink,
--	lc.msgid
--from MsgWCDMAScannerTopCPICH_vacias lc 
--	inner join lcc_timelink_position_Log t on timelink>=master.dbo.fn_lcc_gettimelink(lc.msgtime) 
--) t inner join position p
--	on t.timelinkPos = master.dbo.fn_lcc_gettimelink(p.msgtime) and t.fileidPos =  p.fileid
--where idTimeLink=1


--select *
--from (
--select timelink as timelinkPos,t.fileid as fileidPos,
--	ROW_NUMBER() over (partition by lc.msgid
--					   order by t.msgtime ASC)				  as idTimeLink,
--	lc.msgid
--from MsgLTEScannerTopNInfo_vacias lc 
--	inner join lcc_timelink_position_Log t on timelink>=master.dbo.fn_lcc_gettimelink(lc.msgtime) 
--) t inner join position p
--	on t.timelinkPos = master.dbo.fn_lcc_gettimelink(p.msgtime) and t.fileidPos =  p.fileid
--where idTimeLink=1