use OSP1718_Coverage_1
--2G
select channel from MsgScannerBCCHInfo s,MsgScannerBCCH l, sessions t, lcc_position_Entity_List_Municipio f, [AGRIDS].dbo.lcc_ref_servingOperator_Freq sof
where s.BCCHScanId=l.BCCHScanId
and s.sessionid=t.sessionid
and t.fileid=f.fileid
and l.Channel=sof.Frequency
and entity_name like '%villas%'
and servingoperator='Yoigo'

--3G
select * from MsgWCDMAScannerTopCPICH s, sessions t, lcc_position_Entity_List_Municipio f
where s.sessionid=t.sessionid
and t.fileid=f.fileid
and entity_name like '%cardena%'
and channel  in ('10613','10588','10613')

--4G
select * from MsgLTEScannerTopNInfo p, position t, lcc_position_Entity_List_Municipio f
where p.posid=t.posid
and t.fileid=f.fileid
and entity_name like '%villas%'
and channel in ('1691','1655','1675','126')