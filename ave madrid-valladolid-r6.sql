select longitude,latitude,channel,scode,rscp_avg,rscp_median,ecio_avg,ecio_median,band,operator, from 
FY1617_Coverage_Union_AVE_H2.dbo.lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord t, FY1617_Coverage_Union_AVE_H2.dbo.lcc_position_Entity_List_Vodafone p
where t.lonid=p.lonid and t.latid=p.latid
and collectionname like '%mad%valla-R6%'
and operator='Vodafone'
and type='RW'
order by fileid


