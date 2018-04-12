--PASO 1: Hacemos backup de las tablas de sistema

use FY1718_VOICE_AVE_COR_MAL_H1

select * from fi where posid=79445

--Backup:
--39764
select *
into [dbo].MsgScannerBCCHInfo_20171004
from [dbo].MsgScannerBCCHInfo

--241242
select *
into [dbo].[MsgWCDMAScannerTopCPICH_20171004]
from [dbo].[MsgWCDMAScannerTopCPICH]

--135230
select *
into [dbo].[MsgLTEScannerTopNInfo_20171004]
from [dbo].[MsgLTEScannerTopNInfo]

--Tablas position que toma las posiciones de la parte A de voz del log de vuelta
--drop table lcc_timelink_position_Log
--15951
select *
into lcc_timelink_position_Log
from  lcc_timelink_position
where collectionname='20170914_RW_INDOOR_COR-MAL-R2_2_VOLTE' --collate Latin1_General_CI_AS 
    and side='A'
--drop table position_Log
--21767
select master.dbo.fn_lcc_gettimelink( p.msgtime) as timelink, p.fileid, p.posid
into position_Log
from position p
	inner join filelist f
		on p.fileid=f.fileid
where f.collectionname='20170914_RW_INDOOR_COR-MAL-R2_2_VOLTE'

select * from position where fileid=36

--Tablas filtradas donde no tenemos muestras en la position
--2G
--7768
--drop table [dbo].MsgScannerBCCHInfo_vacias
select msgtime, msgid, master.dbo.fn_lcc_gettimelink(msgtime) as timelink,posid,sessionid
into [dbo].MsgScannerBCCHInfo_vacias
from [dbo].MsgScannerBCCHInfo
where posid in (87218)
--3G 
--40746
--drop table [MsgWCDMAScannerTopCPICH_vacias]
select msgtime, msgid, master.dbo.fn_lcc_gettimelink(msgtime) as timelink
into [dbo].[MsgWCDMAScannerTopCPICH_vacias]
from [dbo].[MsgWCDMAScannerTopCPICH]
where posid in (87218) 
--4G
--22697
--drop table [MsgLTEScannerTopNInfo_vacias]
select msgtime, msgid, master.dbo.fn_lcc_gettimelink(msgtime) as timelink
into [dbo].[MsgLTEScannerTopNInfo_vacias]
from [dbo].[MsgLTEScannerTopNInfo]
where posid in (87218) 


--Rellenamos la info linkando por tiempo para los posid que tenemos vacios. Cogemos el posid del mas cercano.

--drop table MsgScannerBCCHInfo_relleno
--10359
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


--57906
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

--drop table MsgLTEScannerTopNInfo_relleno
--32197
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

--Hacemos el update a las tablas del sistema asignando el posid de la voz

--7768
update [dbo].MsgScannerBCCHInfo
set posid = t2.posid
from [dbo].MsgScannerBCCHInfo t1 
	inner join (
		select msgid,max(posid) as posid
		from MsgScannerBCCHInfo_relleno
		group by msgid
	) t2
	on t1.msgid=t2.msgid

--40746
update [dbo].MsgWCDMAScannerTopCPICH
set posid = t2.posid
from [dbo].MsgWCDMAScannerTopCPICH t1 
	inner join (
		select msgid,max(posid) as posid
		from MsgWCDMAScannerTopCPICH_relleno
		group by msgid
	) t2
	on t1.msgid=t2.msgid

--22697
update [dbo].MsgLTEScannerTopNInfo
set posid = t2.posid
from [dbo].MsgLTEScannerTopNInfo t1 
	inner join (
		select msgid,max(posid) as posid
		from MsgLTEScannerTopNInfo_relleno
		group by msgid
	) t2
	on t1.msgid=t2.msgid

--Para este caso los logs de scanner no están incrustados en la voz. Sino que tienen un fileid asignado a parte (Fileid=36 en este caso)
--Para esto caso, en los procedimientos de cobertura ROUND, tenemos que quitar el linkado pos fileid con la tabla position.
