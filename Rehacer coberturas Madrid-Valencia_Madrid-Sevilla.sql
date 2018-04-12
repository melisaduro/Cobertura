use FY1718_VOICE_AVE_MAD_VLC_H1
--use FY1718_VOICE_AVE_MAD_BCN_H1
--use FY1718_VOICE_AVE_MAD_SEV_H1

select * from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor


drop table lcc_scannerwcdma
drop table lcc_Scanner_LTE_Detailed
drop table lcc_Scanner_UMTS_Detailed
drop table lcc_Scanner_GSM_Detailed
drop table lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
drop table lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord
drop table lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_LastFileid
drop table lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor
drop table lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord
drop table lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_LastFileid
drop table lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor
drop table lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord
drop table lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_LastFileid


--Scanner
if db_name() like '%Voice%'
begin
	exec sp_Create_LCC_scannerWcdma
	exec sp_lcc_create_Scanner_Tables

	if charindex('Road',db_name())>0 or charindex('AVE',db_name())>0
	begin 
		exec sp_plcc_create_lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ROUND 1
		exec sp_plcc_create_lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ROUND 1
		exec sp_plcc_create_lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ROUND 1
	end
	else 
	begin
		select 'Entra'
		--exec sp_plcc_create_lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor 0
		--exec sp_plcc_create_lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor 0
		--exec sp_plcc_create_lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor 0
	end
	--Chequeos integridad Scanner/telefono	
	exec sp_plcc_create_lcc_Table_diffScanTLF
	--exec sp_lcc_diff_SCN_TLF_3G_5_tab_32G
	--exec sp_lcc_diff_SCN_TLF_3G_5_tab_ADD
	exec sp_lcc_diff_SCN_TLF_4G_5_tab_32G
	exec sp_lcc_diff_SCN_TLF_4G_5_tab_ADD
end


--------------------------------------COVERAGE UNION
--DROP TABLES COVERAGE MAD_SEV y MAD_VLC

--DELETES TABLAS COVERAGE_UNION
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_ProbCobIndoor where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_50x50_ProbCobIndoor where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U900_F1 where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U900_F2 where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U2100_F1 where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U2100_F2 where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U2100_F3 where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U900 where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U2100 where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_ALL where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_50x50_probCobIndoor_Tratar_ALL where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_50x50_probCobIndoor_Tratar_GSM where entidad_medida like '%MAD_SEV_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_50x50_probCobIndoor_Tratar_DCS where entidad_medida like '%MAD_SEV_r2%'

--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_ProbCobIndoor where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_50x50_ProbCobIndoor where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_LTEScanner_allFreqs_allPCIS_50x50_probCobIndoor_ord where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U900_F1 where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U900_F2 where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U2100_F1 where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U2100_F2 where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U2100_F3 where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U900 where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_U2100 where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_UMTSScanner_50x50_probCobIndoor_Tratar_ALL where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_50x50_probCobIndoor_Tratar_ALL where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_50x50_probCobIndoor_Tratar_GSM where entidad_medida like '%MAD_VLC_r2%'
--delete from fy1718_coverage_union_ave_h1.dbo.lcc_GSMScanner_50x50_probCobIndoor_Tratar_DCS where entidad_medida like '%MAD_VLC_r2%'

--Relanzar cobertura
--[plcc_Coverage_union_ddbb_ROUND] 

---Parciales
--procedure [dbo].[plcc_Coverage_union_ddbb_Fileid_ROUND] (

--declare @ddbb as varchar (256)='FY1718_VOICE_AVE_MAD_SEV_H1'
--declare @filtroFileId as varchar (256)='between 1 and 71'
--declare @2G as int=1
--declare @3G as int=1
--declare @4G as int=1

--procedure [dbo].[plcc_Coverage_union_ddbb_Fileid_ROUND] (

--declare @ddbb as varchar (256)='FY1718_VOICE_AVE_MAD_VLC_H1'
--declare @filtroFileId as varchar (256)='between 1 and 81'
--declare @2G as int=1
--declare @3G as int=1
--declare @4G as int=1

--Comprobacion-

--MAD-VLC-R2	27948
--MAD-SEV-R2	31671
select entidad_medida, count(1)
from lcc_GSMScanner_50x50_ProbCobIndoor
group by entidad_medida
order by 2

--MAD-VLC-R2	315246
--MAD-SEV-R2	350579
select entidad_medida, count(1)
from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor
group by entidad_medida
order by 2

select entidad_medida, count(1)
from lcc_GSMScanner_allFreqs_allBCCH_50x50_probCobIndoor_ord
group by entidad_medida
order by 2


--MAD-VLC-R2	70049
--MAD-SEV-R2	91974
select entidad_medida, count(1)
from lcc_UMTSScanner_50x50_ProbCobIndoor
group by entidad_medida
order by 2

--MAD-VLC-R2	174204
--MAD-SEV-R2	246942
select entidad_medida, count(1)
from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor
group by entidad_medida
order by 2

select entidad_medida, count(1)
from lcc_UMTSScanner_allFreqs_allSC_50x50_probCobIndoor_ord
group by entidad_medida
order by 2

--MAD-VLC-R2	65375
--MAD-SEV-R2	85614
select entidad_medida, count(1)
from lcc_LTEScanner_allFreqs_allPCIs_50x50_probCobIndoor
group by entidad_medida
order by 2

select entidad_medida, count(1)
from lcc_LTEScanner_allFreqs_allPCIs_50x50_probCobIndoor_ord
group by entidad_medida
order by 2



