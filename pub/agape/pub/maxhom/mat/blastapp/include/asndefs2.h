/***********************************************************************
*
**
*        Automatic header module from ASNTOOL
*
************************************************************************/

#ifndef _ASNTOOL_
#include <asn.h>
#endif

static char * asnfilename = "include/asndefs2.h08";
static AsnValxNode avnx[8] = {
    {20,"interactive-high" ,7,0.0,&avnx[1] } ,
    {20,"interactive-med" ,6,0.0,&avnx[2] } ,
    {20,"interactive-low" ,5,0.0,&avnx[3] } ,
    {20,"batch-high" ,4,0.0,&avnx[4] } ,
    {20,"batch-med" ,3,0.0,&avnx[5] } ,
    {20,"batch-low" ,2,0.0,&avnx[6] } ,
    {20,"scavenger" ,1,0.0,&avnx[7] } ,
    {20,"not-set" ,0,0.0,NULL } };

static AsnType atx[95] = {
  {401, "BLAST0-Preface" ,1,0,0,0,0,0,1,0,NULL,NULL,NULL,0,&atx[1]} ,
  {402, "BLAST0-Job-desc" ,1,0,0,0,0,0,1,0,NULL,NULL,NULL,0,&atx[2]} ,
  {403, "BLAST0-Job-progress" ,1,0,0,0,0,0,1,0,NULL,NULL,NULL,0,&atx[3]} ,
  {404, "BLAST0-Query" ,1,0,0,0,0,0,1,0,NULL,NULL,NULL,0,&atx[4]} ,
  {405, "BLAST0-KA-Blk" ,1,0,0,0,0,0,1,0,NULL,NULL,NULL,0,&atx[5]} ,
  {406, "BLAST0-Db-Desc" ,1,0,0,0,0,0,1,0,NULL,NULL,NULL,0,&atx[6]} ,
  {407, "BLAST0-Result" ,1,0,0,0,0,0,1,0,NULL,NULL,NULL,0,&atx[7]} ,
  {408, "BLAST0-Matrix" ,1,0,0,0,0,0,1,0,NULL,NULL,NULL,0,&atx[8]} ,
  {409, "BLAST0-Warning" ,1,0,0,0,0,0,1,0,NULL,NULL,NULL,0,&atx[9]} ,
  {410, "BLAST0-Status" ,1,0,0,0,0,0,1,0,NULL,NULL,NULL,0,&atx[10]} ,
  {411, "BLAST0-Request" ,1,0,0,0,0,0,0,0,NULL,&atx[41],&atx[11],0,&atx[17]} ,
  {0, "hello" ,128,0,0,0,0,0,0,0,NULL,&atx[12],NULL,0,&atx[13]} ,
  {323, "VisibleString" ,0,26,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "motd" ,128,1,0,0,0,0,0,0,NULL,&atx[14],NULL,0,&atx[15]} ,
  {305, "NULL" ,0,5,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "session-get" ,128,2,0,0,0,0,0,0,NULL,&atx[14],NULL,0,&atx[16]} ,
  {0, "session-set" ,128,3,0,0,0,0,0,0,NULL,&atx[17],NULL,0,&atx[30]} ,
  {412, "BLAST0-Session" ,1,0,0,0,0,0,0,0,NULL,&atx[29],&atx[18],0,&atx[34]} ,
  {0, "group" ,128,0,0,1,0,0,0,0,NULL,&atx[12],NULL,0,&atx[19]} ,
  {0, "priority" ,128,1,0,1,0,0,0,0,NULL,&atx[20],&avnx[0],0,&atx[21]} ,
  {310, "ENUMERATED" ,0,10,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "search-max" ,128,2,0,1,0,0,0,0,NULL,&atx[22],NULL,0,&atx[23]} ,
  {302, "INTEGER" ,0,2,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "tot-cpu-max" ,128,3,0,1,0,0,0,0,NULL,&atx[22],NULL,0,&atx[24]} ,
  {0, "tot-real-max" ,128,4,0,1,0,0,0,0,NULL,&atx[22],NULL,0,&atx[25]} ,
  {0, "cpu-max" ,128,5,0,1,0,0,0,0,NULL,&atx[22],NULL,0,&atx[26]} ,
  {0, "real-max" ,128,6,0,1,0,0,0,0,NULL,&atx[22],NULL,0,&atx[27]} ,
  {0, "idle-max" ,128,7,0,1,0,0,0,0,NULL,&atx[22],NULL,0,&atx[28]} ,
  {0, "imalive" ,128,8,0,1,0,0,0,0,NULL,&atx[22],NULL,0,NULL} ,
  {311, "SEQUENCE" ,0,16,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "prog-info" ,128,4,0,0,0,0,0,0,NULL,&atx[14],NULL,0,&atx[31]} ,
  {0, "db-info" ,128,5,0,0,0,0,0,0,NULL,&atx[14],NULL,0,&atx[32]} ,
  {0, "goodbye" ,128,6,0,0,0,0,0,0,NULL,&atx[14],NULL,0,&atx[33]} ,
  {0, "search" ,128,7,0,0,0,0,0,0,NULL,&atx[34],NULL,0,NULL} ,
  {413, "BLAST0-Search" ,1,0,0,0,0,0,0,0,NULL,&atx[29],&atx[35],0,&atx[42]} ,
  {0, "program" ,128,0,0,0,0,0,0,0,NULL,&atx[12],NULL,0,&atx[36]} ,
  {0, "database" ,128,1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,&atx[37]} ,
  {0, "query" ,128,2,0,0,0,0,0,0,NULL,&atx[3],NULL,0,&atx[38]} ,
  {0, "options" ,128,3,0,1,0,0,0,0,NULL,&atx[40],&atx[39],0,NULL} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,NULL} ,
  {312, "SEQUENCE OF" ,0,16,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {315, "CHOICE" ,0,-1,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {414, "BLAST0-Response" ,1,0,0,0,0,0,0,0,NULL,&atx[41],&atx[43],0,&atx[45]} ,
  {0, "hello" ,128,0,0,0,0,0,0,0,NULL,&atx[12],NULL,0,&atx[44]} ,
  {0, "motd" ,128,1,0,0,0,0,0,0,NULL,&atx[45],NULL,0,&atx[47]} ,
  {415, "BLAST0-Motd" ,1,0,0,0,0,0,0,0,NULL,&atx[40],&atx[46],0,&atx[53]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,NULL} ,
  {0, "session-get" ,128,2,0,0,0,0,0,0,NULL,&atx[17],NULL,0,&atx[48]} ,
  {0, "session-set" ,128,3,0,0,0,0,0,0,NULL,&atx[17],NULL,0,&atx[49]} ,
  {0, "prog-info" ,128,4,0,0,0,0,0,0,NULL,&atx[40],&atx[50],0,&atx[51]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[0],NULL,0,NULL} ,
  {0, "db-info" ,128,5,0,0,0,0,0,0,NULL,&atx[40],&atx[52],0,&atx[67]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[53],NULL,0,NULL} ,
  {416, "BLAST0-Db-Info" ,1,0,0,0,0,0,0,0,NULL,&atx[29],&atx[54],0,&atx[68]} ,
  {0, "desc" ,128,0,0,0,0,0,0,0,NULL,&atx[5],NULL,0,&atx[55]} ,
  {0, "dbtags" ,128,1,0,0,0,0,0,0,NULL,&atx[40],&atx[56],0,&atx[57]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,NULL} ,
  {0, "divisions" ,128,2,0,0,0,0,0,0,NULL,&atx[40],&atx[58],0,&atx[59]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,NULL} ,
  {0, "updatedby" ,128,3,0,0,0,0,0,0,NULL,&atx[40],&atx[60],0,&atx[61]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,NULL} ,
  {0, "contains" ,128,4,0,0,0,0,0,0,NULL,&atx[40],&atx[62],0,&atx[63]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,NULL} ,
  {0, "derivof" ,128,5,0,0,0,0,0,0,NULL,&atx[40],&atx[64],0,&atx[65]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,NULL} ,
  {0, "progs" ,128,6,0,0,0,0,0,0,NULL,&atx[40],&atx[66],0,NULL} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,NULL} ,
  {0, "ack" ,128,6,0,0,0,0,0,0,NULL,&atx[68],NULL,0,&atx[73]} ,
  {417, "BLAST0-Ack" ,1,0,0,0,0,0,0,0,NULL,&atx[29],&atx[69],0,&atx[75]} ,
  {0, "code" ,128,0,0,0,0,0,0,0,NULL,&atx[22],NULL,0,&atx[70]} ,
  {0, "reason" ,128,1,0,1,0,0,0,0,NULL,&atx[12],NULL,0,&atx[71]} ,
  {0, "cpu-used" ,128,2,0,1,0,0,0,0,NULL,&atx[22],NULL,0,&atx[72]} ,
  {0, "cpu-remains" ,128,3,0,1,0,0,0,0,NULL,&atx[22],NULL,0,NULL} ,
  {0, "goodbye" ,128,7,0,0,0,0,0,0,NULL,&atx[68],NULL,0,&atx[74]} ,
  {0, "queued" ,128,8,0,0,0,0,0,0,NULL,&atx[75],NULL,0,&atx[78]} ,
  {418, "BLAST0-Queued" ,1,0,0,0,0,0,0,0,NULL,&atx[29],&atx[76],0,NULL} ,
  {0, "name" ,128,0,0,0,0,0,0,0,NULL,&atx[12],NULL,0,&atx[77]} ,
  {0, "length" ,128,1,0,0,0,0,0,0,NULL,&atx[22],NULL,0,NULL} ,
  {0, "preface" ,128,9,0,0,0,0,0,0,NULL,&atx[0],NULL,0,&atx[79]} ,
  {0, "query" ,128,10,0,0,0,0,0,0,NULL,&atx[3],NULL,0,&atx[80]} ,
  {0, "dbdesc" ,128,11,0,0,0,0,0,0,NULL,&atx[5],NULL,0,&atx[81]} ,
  {0, "matrix" ,128,12,0,0,0,0,0,0,NULL,&atx[40],&atx[82],0,&atx[83]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[7],NULL,0,NULL} ,
  {0, "kablk" ,128,13,0,0,0,0,0,0,NULL,&atx[40],&atx[84],0,&atx[85]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[4],NULL,0,NULL} ,
  {0, "job-start" ,128,14,0,0,0,0,0,0,NULL,&atx[1],NULL,0,&atx[86]} ,
  {0, "job-progress" ,128,15,0,0,0,0,0,0,NULL,&atx[2],NULL,0,&atx[87]} ,
  {0, "job-done" ,128,16,0,0,0,0,0,0,NULL,&atx[2],NULL,0,&atx[88]} ,
  {0, "result" ,128,17,0,0,0,0,0,0,NULL,&atx[6],NULL,0,&atx[89]} ,
  {0, "parms" ,128,18,0,0,0,0,0,0,NULL,&atx[40],&atx[90],0,&atx[91]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,NULL} ,
  {0, "stats" ,128,19,0,0,0,0,0,0,NULL,&atx[40],&atx[92],0,&atx[93]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[12],NULL,0,NULL} ,
  {0, "warning" ,128,20,0,0,0,0,0,0,NULL,&atx[8],NULL,0,&atx[94]} ,
  {0, "status" ,128,21,0,0,0,0,0,0,NULL,&atx[9],NULL,0,NULL} };

static AsnModule ampx[1] = {
  { "NCBI-BLAST-2" , "include/asndefs2.h08",&atx[0],NULL,NULL,0,0} };

static AsnValxNodePtr avn = avnx;
static AsnTypePtr at = atx;
static AsnModulePtr amp = ampx;



/**************************************************
*
*    Defines for Module NCBI-BLAST-2
*
**************************************************/

#define BLAST0_REQUEST &at[10]
#define BLAST0_REQUEST_hello &at[11]
#define BLAST0_REQUEST_motd &at[13]
#define BLAST0_REQUEST_session_get &at[15]
#define BLAST0_REQUEST_session_set &at[16]
#define BLAST0_REQUEST_prog_info &at[30]
#define BLAST0_REQUEST_db_info &at[31]
#define BLAST0_REQUEST_goodbye &at[32]
#define BLAST0_REQUEST_search &at[33]

#define BLAST0_SESSION &at[17]
#define BLAST0_SESSION_group &at[18]
#define BLAST0_SESSION_priority &at[19]
#define BLAST0_SESSION_search_max &at[21]
#define BLAST0_SESSION_tot_cpu_max &at[23]
#define BLAST0_SESSION_tot_real_max &at[24]
#define BLAST0_SESSION_cpu_max &at[25]
#define BLAST0_SESSION_real_max &at[26]
#define BLAST0_SESSION_idle_max &at[27]
#define BLAST0_SESSION_imalive &at[28]

#define BLAST0_SEARCH &at[34]
#define BLAST0_SEARCH_program &at[35]
#define BLAST0_SEARCH_database &at[36]
#define BLAST0_SEARCH_query &at[37]
#define BLAST0_SEARCH_options &at[38]
#define BLAST0_SEARCH_options_E &at[39]

#define BLAST0_RESPONSE &at[42]
#define BLAST0_RESPONSE_hello &at[43]
#define BLAST0_RESPONSE_motd &at[44]
#define BLAST0_RESPONSE_session_get &at[47]
#define BLAST0_RESPONSE_session_set &at[48]
#define BLAST0_RESPONSE_prog_info &at[49]
#define BLAST0_RESPONSE_prog_info_E &at[50]
#define BLAST0_RESPONSE_db_info &at[51]
#define BLAST0_RESPONSE_db_info_E &at[52]
#define BLAST0_RESPONSE_ack &at[67]
#define BLAST0_RESPONSE_goodbye &at[73]
#define BLAST0_RESPONSE_queued &at[74]
#define BLAST0_RESPONSE_preface &at[78]
#define BLAST0_RESPONSE_query &at[79]
#define BLAST0_RESPONSE_dbdesc &at[80]
#define BLAST0_RESPONSE_matrix &at[81]
#define BLAST0_RESPONSE_matrix_E &at[82]
#define BLAST0_RESPONSE_kablk &at[83]
#define BLAST0_RESPONSE_kablk_E &at[84]
#define BLAST0_RESPONSE_job_start &at[85]
#define BLAST0_RESPONSE_job_progress &at[86]
#define BLAST0_RESPONSE_job_done &at[87]
#define BLAST0_RESPONSE_result &at[88]
#define BLAST0_RESPONSE_parms &at[89]
#define BLAST0_RESPONSE_parms_E &at[90]
#define BLAST0_RESPONSE_stats &at[91]
#define BLAST0_RESPONSE_stats_E &at[92]
#define BLAST0_RESPONSE_warning &at[93]
#define BLAST0_RESPONSE_status &at[94]

#define BLAST0_MOTD &at[45]
#define BLAST0_MOTD_E &at[46]

#define BLAST0_DB_INFO &at[53]
#define BLAST0_DB_INFO_desc &at[54]
#define BLAST0_DB_INFO_dbtags &at[55]
#define BLAST0_DB_INFO_dbtags_E &at[56]
#define BLAST0_DB_INFO_divisions &at[57]
#define BLAST0_DB_INFO_divisions_E &at[58]
#define BLAST0_DB_INFO_updatedby &at[59]
#define BLAST0_DB_INFO_updatedby_E &at[60]
#define BLAST0_DB_INFO_contains &at[61]
#define BLAST0_DB_INFO_contains_E &at[62]
#define BLAST0_DB_INFO_derivof &at[63]
#define BLAST0_DB_INFO_derivof_E &at[64]
#define BLAST0_DB_INFO_progs &at[65]
#define BLAST0_DB_INFO_progs_E &at[66]

#define BLAST0_ACK &at[68]
#define BLAST0_ACK_code &at[69]
#define BLAST0_ACK_reason &at[70]
#define BLAST0_ACK_cpu_used &at[71]
#define BLAST0_ACK_cpu_remains &at[72]

#define BLAST0_QUEUED &at[75]
#define BLAST0_QUEUED_name &at[76]
#define BLAST0_QUEUED_length &at[77]
