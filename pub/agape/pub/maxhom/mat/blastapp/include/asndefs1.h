/***********************************************************************
*
**
*        Automatic header module from ASNTOOL
*
************************************************************************/

#ifndef _ASNTOOL_
#include <asn.h>
#endif

static char * asnfilename = "fo08";
static AsnValxNode avnx[36] = {
    {20,"not-set" ,0,0.0,&avnx[1] } ,
    {20,"amino-acid" ,1,0.0,&avnx[2] } ,
    {20,"nucleic-acid" ,2,0.0,&avnx[3] } ,
    {20,"other" ,255,0.0,NULL } ,
    {20,"not-set" ,0,0.0,&avnx[5] } ,
    {20,"neighborhood" ,1,0.0,&avnx[6] } ,
    {20,"search" ,2,0.0,&avnx[7] } ,
    {20,"threecomps" ,3,0.0,NULL } ,
    {20,"circular" ,1,0.0,&avnx[9] } ,
    {20,"single-stranded" ,2,0.0,&avnx[10] } ,
    {20,"rna" ,3,0.0,&avnx[11] } ,
    {20,"modified" ,4,0.0,NULL } ,
    {20,"plus" ,1,0.0,&avnx[13] } ,
    {20,"minus" ,2,0.0,&avnx[14] } ,
    {20,"both" ,3,0.0,&avnx[15] } ,
    {20,"plus-rf" ,5,0.0,&avnx[16] } ,
    {20,"minus-rf" ,6,0.0,NULL } ,
    {20,"score" ,1,0.0,&avnx[18] } ,
    {20,"p-value" ,2,0.0,&avnx[19] } ,
    {20,"e-value" ,3,0.0,&avnx[20] } ,
    {20,"pw-p-value" ,4,0.0,&avnx[21] } ,
    {20,"pw-e-value" ,5,0.0,&avnx[22] } ,
    {20,"poisson-p" ,6,0.0,&avnx[23] } ,
    {20,"poisson-e" ,7,0.0,&avnx[24] } ,
    {20,"poisson-n" ,8,0.0,&avnx[25] } ,
    {20,"pw-poisson-p" ,9,0.0,&avnx[26] } ,
    {20,"pw-poisson-e" ,10,0.0,&avnx[27] } ,
    {20,"sum-p" ,11,0.0,&avnx[28] } ,
    {20,"sum-e" ,12,0.0,&avnx[29] } ,
    {20,"sum-n" ,13,0.0,&avnx[30] } ,
    {20,"pw-sum-p" ,14,0.0,&avnx[31] } ,
    {20,"pw-sum-e" ,15,0.0,&avnx[32] } ,
    {20,"link-previous" ,16,0.0,&avnx[33] } ,
    {20,"link-next" ,17,0.0,NULL } ,
    {20,"ncbi4na" ,4,0.0,&avnx[35] } ,
    {20,"ncbistdaa" ,11,0.0,NULL } };

static AsnType atx[167] = {
  {401, "BLAST0-Preface" ,1,0,0,0,0,1,0,0,NULL,&atx[18],&atx[1],0,&atx[20]} ,
  {0, "program" ,128,0,0,0,0,0,0,0,NULL,&atx[2],NULL,0,&atx[3]} ,
  {323, "VisibleString" ,0,26,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "desc" ,128,1,0,0,0,0,0,0,NULL,&atx[2],NULL,0,&atx[4]} ,
  {0, "version" ,128,2,0,1,0,0,0,0,NULL,&atx[2],NULL,0,&atx[5]} ,
  {0, "dev-date" ,128,3,0,1,0,0,0,0,NULL,&atx[2],NULL,0,&atx[6]} ,
  {0, "bld-date" ,128,4,0,1,0,0,0,0,NULL,&atx[2],NULL,0,&atx[7]} ,
  {0, "cit" ,128,5,0,1,0,0,0,0,NULL,&atx[9],&atx[8],0,&atx[10]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[2],NULL,0,NULL} ,
  {312, "SEQUENCE OF" ,0,16,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "notice" ,128,6,0,1,0,0,0,0,NULL,&atx[9],&atx[11],0,&atx[12]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[2],NULL,0,NULL} ,
  {0, "susage" ,128,7,0,0,0,0,0,0,NULL,&atx[13],NULL,0,&atx[19]} ,
  {412, "BLAST0-Seq-usage" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[14],0,&atx[30]} ,
  {0, "raw" ,128,0,0,0,0,0,0,0,NULL,&atx[15],NULL,0,&atx[17]} ,
  {415, "BLAST0-Alphatype" ,1,0,0,0,0,0,0,0,NULL,&atx[16],&avnx[0],0,&atx[86]} ,
  {310, "ENUMERATED" ,0,10,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "cooked" ,128,1,0,0,0,0,0,0,NULL,&atx[15],NULL,0,NULL} ,
  {311, "SEQUENCE" ,0,16,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "qusage" ,128,8,0,0,0,0,0,0,NULL,&atx[13],NULL,0,NULL} ,
  {402, "BLAST0-Job-desc" ,1,0,0,0,0,1,0,0,NULL,&atx[18],&atx[21],0,&atx[25]} ,
  {0, "jid" ,128,0,0,0,0,0,0,0,NULL,&atx[16],&avnx[4],0,&atx[22]} ,
  {0, "desc" ,128,1,0,0,0,0,0,0,NULL,&atx[2],NULL,0,&atx[23]} ,
  {0, "size" ,128,2,0,0,0,0,0,0,NULL,&atx[24],NULL,0,NULL} ,
  {302, "INTEGER" ,0,2,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {403, "BLAST0-Job-progress" ,1,0,0,0,0,1,0,0,NULL,&atx[18],&atx[26],0,&atx[28]} ,
  {0, "done" ,128,0,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[27]} ,
  {0, "positives" ,128,1,0,0,0,0,0,0,NULL,&atx[24],NULL,0,NULL} ,
  {404, "BLAST0-Query" ,1,0,0,0,0,1,0,0,NULL,&atx[18],&atx[29],0,&atx[63]} ,
  {0, "seq" ,128,0,0,0,0,0,0,0,NULL,&atx[30],NULL,0,&atx[53]} ,
  {413, "BLAST0-Sequence" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[31],0,&atx[55]} ,
  {0, "desc" ,128,0,0,0,0,0,0,0,NULL,&atx[9],&atx[32],0,&atx[42]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[33],NULL,0,NULL} ,
  {424, "BLAST0-Seq-desc" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[34],0,&atx[45]} ,
  {0, "id" ,128,0,0,0,0,0,0,0,NULL,&atx[35],NULL,0,&atx[41]} ,
  {426, "BLAST0-Seq-id" ,1,0,0,0,0,0,0,0,NULL,&atx[40],&atx[36],0,&atx[135]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[39],&atx[37],0,NULL} ,
  {0, "giid" ,128,0,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[38]} ,
  {0, "textid" ,128,1,0,0,0,0,0,0,NULL,&atx[2],NULL,0,NULL} ,
  {315, "CHOICE" ,0,-1,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {314, "SET OF" ,0,17,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "defline" ,128,1,0,1,0,0,0,0,NULL,&atx[2],NULL,0,NULL} ,
  {0, "length" ,128,1,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[43]} ,
  {0, "attrib" ,128,2,0,1,0,0,0,0,NULL,&atx[9],&atx[44],0,&atx[46]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[45],NULL,0,NULL} ,
  {425, "BLAST0-Seq-attrib" ,1,0,0,0,0,0,0,0,NULL,&atx[16],&avnx[8],0,&atx[35]} ,
  {0, "gcode" ,128,3,0,1,0,0,0,0,NULL,&atx[24],NULL,0,&atx[47]} ,
  {0, "seq" ,128,4,0,1,0,0,0,0,NULL,&atx[48],NULL,0,NULL} ,
  {423, "BLAST0-Seq-data" ,1,0,0,0,0,0,0,0,NULL,&atx[39],&atx[49],0,&atx[33]} ,
  {0, "ncbistdaa" ,128,0,0,0,0,0,0,0,NULL,&atx[50],NULL,0,&atx[51]} ,
  {304, "OCTET STRING" ,0,4,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "ncbi2na" ,128,1,0,0,0,0,0,0,NULL,&atx[50],NULL,0,&atx[52]} ,
  {0, "ncbi4na" ,128,2,0,0,0,0,0,0,NULL,&atx[50],NULL,0,NULL} ,
  {0, "nw-mask" ,128,1,0,1,0,0,0,0,NULL,&atx[9],&atx[54],0,&atx[59]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[55],NULL,0,NULL} ,
  {414, "BLAST0-Seq-interval" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[56],0,&atx[15]} ,
  {0, "strand" ,128,0,0,1,0,0,0,0,NULL,&atx[16],&avnx[12],0,&atx[57]} ,
  {0, "from" ,128,1,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[58]} ,
  {0, "to" ,128,2,0,0,0,0,0,0,NULL,&atx[24],NULL,0,NULL} ,
  {0, "x-mask" ,128,2,0,1,0,0,0,0,NULL,&atx[9],&atx[60],0,&atx[61]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[55],NULL,0,NULL} ,
  {0, "hard-mask" ,128,3,0,1,0,0,0,0,NULL,&atx[9],&atx[62],0,NULL} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[55],NULL,0,NULL} ,
  {405, "BLAST0-KA-Blk" ,1,0,0,0,0,1,0,0,NULL,&atx[18],&atx[64],0,&atx[75]} ,
  {0, "matid" ,128,0,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[65]} ,
  {0, "n-way" ,128,1,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[66]} ,
  {0, "frames" ,128,2,0,0,0,0,0,0,NULL,&atx[9],&atx[67],0,&atx[68]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[24],NULL,0,NULL} ,
  {0, "lambda" ,128,3,0,0,0,0,0,0,NULL,&atx[69],NULL,0,&atx[70]} ,
  {309, "REAL" ,0,9,0,0,0,0,0,0,NULL,NULL,NULL,0,NULL} ,
  {0, "lambda-orig" ,128,4,0,1,0,0,0,0,NULL,&atx[69],NULL,0,&atx[71]} ,
  {0, "k" ,128,5,0,0,0,0,0,0,NULL,&atx[69],NULL,0,&atx[72]} ,
  {0, "k-orig" ,128,6,0,1,0,0,0,0,NULL,&atx[69],NULL,0,&atx[73]} ,
  {0, "h" ,128,7,0,0,0,0,0,0,NULL,&atx[69],NULL,0,&atx[74]} ,
  {0, "h-orig" ,128,8,0,1,0,0,0,0,NULL,&atx[69],NULL,0,NULL} ,
  {406, "BLAST0-Db-Desc" ,1,0,0,0,0,1,0,0,NULL,&atx[18],&atx[76],0,&atx[84]} ,
  {0, "name" ,128,0,0,0,0,0,0,0,NULL,&atx[2],NULL,0,&atx[77]} ,
  {0, "type" ,128,1,0,0,0,0,0,0,NULL,&atx[15],NULL,0,&atx[78]} ,
  {0, "def" ,128,2,0,1,0,0,0,0,NULL,&atx[2],NULL,0,&atx[79]} ,
  {0, "rel-date" ,128,3,0,1,0,0,0,0,NULL,&atx[2],NULL,0,&atx[80]} ,
  {0, "bld-date" ,128,4,0,1,0,0,0,0,NULL,&atx[2],NULL,0,&atx[81]} ,
  {0, "count" ,128,5,0,1,0,0,0,0,NULL,&atx[24],NULL,0,&atx[82]} ,
  {0, "totlen" ,128,6,0,1,0,0,0,0,NULL,&atx[24],NULL,0,&atx[83]} ,
  {0, "maxlen" ,128,7,0,1,0,0,0,0,NULL,&atx[24],NULL,0,NULL} ,
  {407, "BLAST0-Result" ,1,0,0,0,0,1,0,0,NULL,&atx[18],&atx[85],0,&atx[129]} ,
  {0, "hist" ,128,0,0,1,0,0,0,0,NULL,&atx[86],NULL,0,&atx[95]} ,
  {416, "BLAST0-Histogram" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[87],0,&atx[99]} ,
  {0, "expect" ,128,0,0,0,0,0,0,0,NULL,&atx[69],NULL,0,&atx[88]} ,
  {0, "observed" ,128,1,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[89]} ,
  {0, "nbars" ,128,2,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[90]} ,
  {0, "bar" ,128,3,0,0,0,0,0,0,NULL,&atx[9],&atx[91],0,NULL} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[92],NULL,0,NULL} ,
  {419, "BLAST0-Histogram-bar" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[93],0,&atx[111]} ,
  {0, "x" ,128,0,0,0,0,0,0,0,NULL,&atx[69],NULL,0,&atx[94]} ,
  {0, "n" ,128,1,0,0,0,0,0,0,NULL,&atx[24],NULL,0,NULL} ,
  {0, "count" ,128,1,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[96]} ,
  {0, "dim" ,128,2,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[97]} ,
  {0, "hsp-si" ,128,3,0,0,0,0,0,0,NULL,&atx[9],&atx[98],0,&atx[103]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[99],NULL,0,NULL} ,
  {417, "BLAST0-Score-Info" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[100],0,&atx[105]} ,
  {0, "sid" ,128,0,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[101]} ,
  {0, "tag" ,128,1,0,0,0,0,0,0,NULL,&atx[2],NULL,0,&atx[102]} ,
  {0, "desc" ,128,2,0,1,0,0,0,0,NULL,&atx[2],NULL,0,NULL} ,
  {0, "hitlists" ,128,4,0,0,0,0,0,0,NULL,&atx[9],&atx[104],0,NULL} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[105],NULL,0,NULL} ,
  {418, "BLAST0-HitList" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[106],0,&atx[92]} ,
  {0, "count" ,128,0,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[107]} ,
  {0, "kablk" ,128,1,0,1,0,0,0,0,NULL,&atx[9],&atx[108],0,&atx[109]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[63],NULL,0,NULL} ,
  {0, "hsps" ,128,2,0,0,0,0,0,0,NULL,&atx[9],&atx[110],0,&atx[127]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[111],NULL,0,NULL} ,
  {420, "BLAST0-HSP" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[112],0,&atx[115]} ,
  {0, "matid" ,128,0,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[113]} ,
  {0, "scores" ,128,1,0,0,0,0,0,0,NULL,&atx[9],&atx[114],0,&atx[120]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[115],NULL,0,NULL} ,
  {421, "BLAST0-Score" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[116],0,&atx[123]} ,
  {0, "sid" ,128,0,0,0,0,0,0,0,NULL,&atx[24],&avnx[17],0,&atx[117]} ,
  {0, "value" ,128,1,0,0,0,0,0,0,NULL,&atx[39],&atx[118],0,NULL} ,
  {0, "i" ,128,0,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[119]} ,
  {0, "r" ,128,1,0,0,0,0,0,0,NULL,&atx[69],NULL,0,NULL} ,
  {0, "len" ,128,2,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[121]} ,
  {0, "segs" ,128,3,0,0,0,0,0,0,NULL,&atx[9],&atx[122],0,NULL} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[123],NULL,0,NULL} ,
  {422, "BLAST0-Segment" ,1,0,0,0,0,0,0,0,NULL,&atx[18],&atx[124],0,&atx[48]} ,
  {0, "loc" ,128,0,0,0,0,0,0,0,NULL,&atx[55],NULL,0,&atx[125]} ,
  {0, "str" ,128,1,0,1,0,0,0,0,NULL,&atx[48],NULL,0,&atx[126]} ,
  {0, "str-raw" ,128,2,0,1,0,0,0,0,NULL,&atx[48],NULL,0,NULL} ,
  {0, "seqs" ,128,3,0,0,0,0,0,0,NULL,&atx[9],&atx[128],0,NULL} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[30],NULL,0,NULL} ,
  {408, "BLAST0-Matrix" ,1,0,0,0,0,1,0,0,NULL,&atx[18],&atx[130],0,&atx[144]} ,
  {0, "matid" ,128,0,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[131]} ,
  {0, "name" ,128,1,0,0,0,0,0,0,NULL,&atx[2],NULL,0,&atx[132]} ,
  {0, "comments" ,128,2,0,1,0,0,0,0,NULL,&atx[9],&atx[133],0,&atx[134]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[2],NULL,0,NULL} ,
  {0, "qalpha" ,128,3,0,0,0,0,0,0,NULL,&atx[135],NULL,0,&atx[136]} ,
  {427, "BLAST0-Alpha-ID" ,1,0,0,0,0,0,0,0,NULL,&atx[16],&avnx[34],0,NULL} ,
  {0, "salpha" ,128,4,0,0,0,0,0,0,NULL,&atx[135],NULL,0,&atx[137]} ,
  {0, "scores" ,128,5,0,1,0,0,0,0,NULL,&atx[39],&atx[138],0,NULL} ,
  {0, "scaled-ints" ,128,0,0,0,0,0,0,0,NULL,&atx[18],&atx[139],0,&atx[142]} ,
  {0, "scale" ,128,0,0,0,0,0,0,0,NULL,&atx[69],NULL,0,&atx[140]} ,
  {0, "ints" ,128,1,0,0,0,0,0,0,NULL,&atx[9],&atx[141],0,NULL} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[24],NULL,0,NULL} ,
  {0, "reals" ,128,1,0,0,0,0,0,0,NULL,&atx[9],&atx[143],0,NULL} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[69],NULL,0,NULL} ,
  {409, "BLAST0-Warning" ,1,0,0,0,0,1,0,0,NULL,&atx[145],NULL,0,&atx[145]} ,
  {410, "BLAST0-Status" ,1,0,0,0,0,1,0,0,NULL,&atx[18],&atx[146],0,&atx[148]} ,
  {0, "code" ,128,0,0,0,0,0,0,0,NULL,&atx[24],NULL,0,&atx[147]} ,
  {0, "reason" ,128,1,0,1,0,0,0,0,NULL,&atx[2],NULL,0,NULL} ,
  {411, "BLAST0-Outblk" ,1,0,0,0,0,0,0,0,NULL,&atx[40],&atx[149],0,&atx[13]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[39],&atx[150],0,NULL} ,
  {0, "preface" ,128,0,0,0,0,0,0,0,NULL,&atx[0],NULL,0,&atx[151]} ,
  {0, "query" ,128,1,0,0,0,0,0,0,NULL,&atx[28],NULL,0,&atx[152]} ,
  {0, "dbdesc" ,128,2,0,0,0,0,0,0,NULL,&atx[75],NULL,0,&atx[153]} ,
  {0, "matrix" ,128,3,0,0,0,0,0,0,NULL,&atx[9],&atx[154],0,&atx[155]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[129],NULL,0,NULL} ,
  {0, "kablk" ,128,4,0,0,0,0,0,0,NULL,&atx[9],&atx[156],0,&atx[157]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[63],NULL,0,NULL} ,
  {0, "job-start" ,128,5,0,0,0,0,0,0,NULL,&atx[20],NULL,0,&atx[158]} ,
  {0, "job-progress" ,128,6,0,0,0,0,0,0,NULL,&atx[25],NULL,0,&atx[159]} ,
  {0, "job-done" ,128,7,0,0,0,0,0,0,NULL,&atx[25],NULL,0,&atx[160]} ,
  {0, "result" ,128,8,0,0,0,0,0,0,NULL,&atx[84],NULL,0,&atx[161]} ,
  {0, "parms" ,128,9,0,0,0,0,0,0,NULL,&atx[9],&atx[162],0,&atx[163]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[2],NULL,0,NULL} ,
  {0, "stats" ,128,10,0,0,0,0,0,0,NULL,&atx[9],&atx[164],0,&atx[165]} ,
  {0, NULL,1,-1,0,0,0,0,0,0,NULL,&atx[2],NULL,0,NULL} ,
  {0, "warning" ,128,11,0,0,0,0,0,0,NULL,&atx[144],NULL,0,&atx[166]} ,
  {0, "status" ,128,12,0,0,0,0,0,0,NULL,&atx[145],NULL,0,NULL} };

static AsnModule ampx[1] = {
  { "NCBI-BLAST-1" , "fo08",&atx[0],NULL,NULL,0,0} };

static AsnValxNodePtr avn = avnx;
static AsnTypePtr at = atx;
static AsnModulePtr amp = ampx;



/**************************************************
*
*    Defines for Module NCBI-BLAST-1
*
**************************************************/

#define BLAST0_PREFACE &at[0]
#define BLAST0_PREFACE_program &at[1]
#define BLAST0_PREFACE_desc &at[3]
#define BLAST0_PREFACE_version &at[4]
#define BLAST0_PREFACE_dev_date &at[5]
#define BLAST0_PREFACE_bld_date &at[6]
#define BLAST0_PREFACE_cit &at[7]
#define BLAST0_PREFACE_cit_E &at[8]
#define BLAST0_PREFACE_notice &at[10]
#define BLAST0_PREFACE_notice_E &at[11]
#define BLAST0_PREFACE_susage &at[12]
#define BLAST0_PREFACE_qusage &at[19]

#define BLAST0_JOB_DESC &at[20]
#define BLAST0_JOB_DESC_jid &at[21]
#define BLAST0_JOB_DESC_desc &at[22]
#define BLAST0_JOB_DESC_size &at[23]

#define BLAST0_JOB_PROGRESS &at[25]
#define BLAST0_JOB_PROGRESS_done &at[26]
#define BLAST0_JOB_PROGRESS_positives &at[27]

#define BLAST0_QUERY &at[28]
#define BLAST0_QUERY_seq &at[29]
#define BLAST0_QUERY_nw_mask &at[53]
#define BLAST0_QUERY_nw_mask_E &at[54]
#define BLAST0_QUERY_x_mask &at[59]
#define BLAST0_QUERY_x_mask_E &at[60]
#define BLAST0_QUERY_hard_mask &at[61]
#define BLAST0_QUERY_hard_mask_E &at[62]

#define BLAST0_KA_BLK &at[63]
#define BLAST0_KA_BLK_matid &at[64]
#define BLAST0_KA_BLK_n_way &at[65]
#define BLAST0_KA_BLK_frames &at[66]
#define BLAST0_KA_BLK_frames_E &at[67]
#define BLAST0_KA_BLK_lambda &at[68]
#define BLAST0_KA_BLK_lambda_orig &at[70]
#define BLAST0_KA_BLK_k &at[71]
#define BLAST0_KA_BLK_k_orig &at[72]
#define BLAST0_KA_BLK_h &at[73]
#define BLAST0_KA_BLK_h_orig &at[74]

#define BLAST0_DB_DESC &at[75]
#define BLAST0_DB_DESC_name &at[76]
#define BLAST0_DB_DESC_type &at[77]
#define BLAST0_DB_DESC_def &at[78]
#define BLAST0_DB_DESC_rel_date &at[79]
#define BLAST0_DB_DESC_bld_date &at[80]
#define BLAST0_DB_DESC_count &at[81]
#define BLAST0_DB_DESC_totlen &at[82]
#define BLAST0_DB_DESC_maxlen &at[83]

#define BLAST0_RESULT &at[84]
#define BLAST0_RESULT_hist &at[85]
#define BLAST0_RESULT_count &at[95]
#define BLAST0_RESULT_dim &at[96]
#define BLAST0_RESULT_hsp_si &at[97]
#define BLAST0_RESULT_hsp_si_E &at[98]
#define BLAST0_RESULT_hitlists &at[103]
#define BLAST0_RESULT_hitlists_E &at[104]

#define BLAST0_MATRIX &at[129]
#define BLAST0_MATRIX_matid &at[130]
#define BLAST0_MATRIX_name &at[131]
#define BLAST0_MATRIX_comments &at[132]
#define BLAST0_MATRIX_comments_E &at[133]
#define BLAST0_MATRIX_qalpha &at[134]
#define BLAST0_MATRIX_salpha &at[136]
#define BLAST0_MATRIX_scores &at[137]
#define MATRIX_scores_scaled_ints &at[138]
#define scores_scaled_ints_scale &at[139]
#define MATRIX_scores_scaled_ints_ints &at[140]
#define scores_scaled_ints_ints_E &at[141]
#define BLAST0_MATRIX_scores_reals &at[142]
#define BLAST0_MATRIX_scores_reals_E &at[143]

#define BLAST0_WARNING &at[144]

#define BLAST0_STATUS &at[145]
#define BLAST0_STATUS_code &at[146]
#define BLAST0_STATUS_reason &at[147]

#define BLAST0_OUTBLK &at[148]
#define BLAST0_OUTBLK_E &at[149]
#define BLAST0_OUTBLK_E_preface &at[150]
#define BLAST0_OUTBLK_E_query &at[151]
#define BLAST0_OUTBLK_E_dbdesc &at[152]
#define BLAST0_OUTBLK_E_matrix &at[153]
#define BLAST0_OUTBLK_E_matrix_E &at[154]
#define BLAST0_OUTBLK_E_kablk &at[155]
#define BLAST0_OUTBLK_E_kablk_E &at[156]
#define BLAST0_OUTBLK_E_job_start &at[157]
#define BLAST0_OUTBLK_E_job_progress &at[158]
#define BLAST0_OUTBLK_E_job_done &at[159]
#define BLAST0_OUTBLK_E_result &at[160]
#define BLAST0_OUTBLK_E_parms &at[161]
#define BLAST0_OUTBLK_E_parms_E &at[162]
#define BLAST0_OUTBLK_E_stats &at[163]
#define BLAST0_OUTBLK_E_stats_E &at[164]
#define BLAST0_OUTBLK_E_warning &at[165]
#define BLAST0_OUTBLK_E_status &at[166]

#define BLAST0_SEQ_USAGE &at[13]
#define BLAST0_SEQ_USAGE_raw &at[14]
#define BLAST0_SEQ_USAGE_cooked &at[17]

#define BLAST0_SEQUENCE &at[30]
#define BLAST0_SEQUENCE_desc &at[31]
#define BLAST0_SEQUENCE_desc_E &at[32]
#define BLAST0_SEQUENCE_length &at[42]
#define BLAST0_SEQUENCE_attrib &at[43]
#define BLAST0_SEQUENCE_attrib_E &at[44]
#define BLAST0_SEQUENCE_gcode &at[46]
#define BLAST0_SEQUENCE_seq &at[47]

#define BLAST0_SEQ_INTERVAL &at[55]
#define BLAST0_SEQ_INTERVAL_strand &at[56]
#define BLAST0_SEQ_INTERVAL_from &at[57]
#define BLAST0_SEQ_INTERVAL_to &at[58]

#define BLAST0_ALPHATYPE &at[15]

#define BLAST0_HISTOGRAM &at[86]
#define BLAST0_HISTOGRAM_expect &at[87]
#define BLAST0_HISTOGRAM_observed &at[88]
#define BLAST0_HISTOGRAM_nbars &at[89]
#define BLAST0_HISTOGRAM_bar &at[90]
#define BLAST0_HISTOGRAM_bar_E &at[91]

#define BLAST0_SCORE_INFO &at[99]
#define BLAST0_SCORE_INFO_sid &at[100]
#define BLAST0_SCORE_INFO_tag &at[101]
#define BLAST0_SCORE_INFO_desc &at[102]

#define BLAST0_HITLIST &at[105]
#define BLAST0_HITLIST_count &at[106]
#define BLAST0_HITLIST_kablk &at[107]
#define BLAST0_HITLIST_kablk_E &at[108]
#define BLAST0_HITLIST_hsps &at[109]
#define BLAST0_HITLIST_hsps_E &at[110]
#define BLAST0_HITLIST_seqs &at[127]
#define BLAST0_HITLIST_seqs_E &at[128]

#define BLAST0_HISTOGRAM_BAR &at[92]
#define BLAST0_HISTOGRAM_BAR_x &at[93]
#define BLAST0_HISTOGRAM_BAR_n &at[94]

#define BLAST0_HSP &at[111]
#define BLAST0_HSP_matid &at[112]
#define BLAST0_HSP_scores &at[113]
#define BLAST0_HSP_scores_E &at[114]
#define BLAST0_HSP_len &at[120]
#define BLAST0_HSP_segs &at[121]
#define BLAST0_HSP_segs_E &at[122]

#define BLAST0_SCORE &at[115]
#define BLAST0_SCORE_sid &at[116]
#define BLAST0_SCORE_value &at[117]
#define BLAST0_SCORE_value_i &at[118]
#define BLAST0_SCORE_value_r &at[119]

#define BLAST0_SEGMENT &at[123]
#define BLAST0_SEGMENT_loc &at[124]
#define BLAST0_SEGMENT_str &at[125]
#define BLAST0_SEGMENT_str_raw &at[126]

#define BLAST0_SEQ_DATA &at[48]
#define BLAST0_SEQ_DATA_ncbistdaa &at[49]
#define BLAST0_SEQ_DATA_ncbi2na &at[51]
#define BLAST0_SEQ_DATA_ncbi4na &at[52]

#define BLAST0_SEQ_DESC &at[33]
#define BLAST0_SEQ_DESC_id &at[34]
#define BLAST0_SEQ_DESC_defline &at[41]

#define BLAST0_SEQ_ATTRIB &at[45]

#define BLAST0_SEQ_ID &at[35]
#define BLAST0_SEQ_ID_E &at[36]
#define BLAST0_SEQ_ID_E_giid &at[37]
#define BLAST0_SEQ_ID_E_textid &at[38]

#define BLAST0_ALPHA_ID &at[135]
