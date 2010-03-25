##!/usr/local/bin/perl -w
##!/usr/pub/bin/perl5 -w
##!/usr/pub/bin/perl5.003 -w
##!/usr/pub/bin/perl
##! /usr/pub/bin/perl
#================================================================================ #
#                                                                                 #
#-------------------------------------------------------------------------------- #
# Predict Protein - a secondary structure prediction and sequence analysis system # 
# Copyright (C) <2004> CUBIC, Columbia University                                 #
#                                                                                 #
# Burkhard Rost		rost@columbia.edu			                  #
# http://cubic.bioc.columbia.edu/~rost/	                                          #
# Jinfeng Liu             liu@cubic.bioc.columbia.edu  	                          #
# Guy Yachdav         yachdav@cubic.bioc.columbia.edu        	                  #
#                                                                                 # 
# This program is free software; you can redistribute it and/or modify it under   #
# the terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2 of the License, or (at your option)                #
# any later version.                                                              #
#                                                                                 #
# This program is distributed in the hope that it will be useful,                 # 
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE.                                            #
# See the GNU General Public License for more details.                            #
#                                                                                 #   
# You should have received a copy of the GNU General Public License along with    #
# this program; if not, write to the Free Software Foundation, Inc.,              #
# 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA                         #
#                                                                                 #
# Contact Information:                                                            # 
#                                                                                 #
# predict_help@columbia.edu                                                       #
#                                                                                 #
# CUBIC   Columbia University                                                     #
# Department of Biochemistry & Molecular Biophysics                               # 
# 630 West, 168 Street, BB217                                                     #
# New York, N.Y. 10032 USA                                                        #
# Tel +1-212-305 4018 / Fax +1-212-305 7932                                       #
#------------------------------------------------------------------------------   #
#	Copyright				  May,    	 1998	          #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			          #
#	EMBL			http://www.embl-heidelberg.de/~rost/	          #
#	D-69012 Heidelberg						          #
#			        v 1.0   	  May,           1998             #
#------------------------------------------------------------------------------   #
#   
#   --------------------------------
#   Error code number library for PP
#   --------------------------------
#   
#   include library if error occurred (require lib)
#   
#   this is a collection of subroutines assigning descriptions to the 
#   error code numbers in the new PP (Jan 98).
#   
#   the main part (sbr errCode) does:
#      in:   number ($i)
#      out:  'explanation cryptic, explanation for PP users'
#      e.g.:
#      out=  no file found in sbr xx, blabla
#            Sorry, we couldn't return a prediction.
#            The software detected the following problem:
#            Your sequence was too short.
#            For reference: error code no = $i.
#   
#   the following system is used:
#      errCode[$i] = 'explanation cryptic, explanation for PP users'
#   the pointer is actually to a subroutine:
#      errCode[$i] = &txt_for_error_i
#   files or other information that should be send to the reader in
#   case of error number $i, should be passed as arguments
#   
#   The hierarchy with the error numbers is:
#      10 -    99 main script (predPackage)
#                 10 - 19 before
#                 20 - 29 convert
#                 30 - 39 pre-ali
#                 40 - 49 ali 1
#                 50 - 59 ali 2
#                 60 - 69 PHD
#                 70 - 79 topits
#                 80 - 99 other
#     100 -   999 modules, numbers as above *100
#   10000 - 10999 ini of predPackage
#   
#   
#   
#   
#-------------------------------------------------------------------------------
#
#===============================================================================

#===============================================================================
sub errCode {
    local(@tmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   note: $tmp[1]=number, $tmp[2]='fileAppMsfExample|fileAppSafExample'
    $sbrName="errCode";$fhinLoc="FHIN"."$sbrName";

    $in=$tmp[1];$in=~s/\s//g;
    $pre="--- ";

    $errCode[1]=    "intern: internal software/hardware problem\n"         .&internal($pre);
    $errCode[10]=   "";
    $errCode[11]=   "intern:predPack after moduleBefore job{fin} not 0\n"  .&internal($pre);
    $errCode[21]=   "intern:predPack after moduleInterpret\n";
    $errCode[22]=   "usr:predPack after moduleInterpret wrong format from USER\n";
    $errCode[23]=   "usr:predPack after moduleInterpret help request from USER\n";
    $errCode[24]=   "intern:predPack after moduleInterpretManu\n";
    $errCode[31]=   "intern:predPack after moduleConvert\n";
    $errCode[41]=   "intern:predPack after moduleAlign\n";
    $errCode[41]=   "intern:predPack after module\n";
    $errCode[95]=   "";
    $errCode[96]=   "";
    $errCode[97]=   "";
    $errCode[98]=   "";
    $errCode[99]=   "";
    $errCode[100]=  "";
    $errCode[101]=  "int:modBefore some input argument not defined\n"      .&internal($pre);
    $errCode[102]=  "int:modBefore some input file missing\n"              .&internal($pre);
    $errCode[103]=  "int:modBefore filePurgeNullChar failed\n"             .&internal($pre);
    $errCode[104]=  "int:moduleBefore filePurgeBlankLine failed\n"         .&internal($pre);
    $errCode[105]=  "usr:licence problem = invalid password \n"            .&licence_password($pre);
    $errCode[106]=  "int:modBefore decrypt problem (not on)\n"             .&internal($pre);
    $errCode[200]=  "";
    $errCode[201]=  "int:modInterpret some input argument not defined\n"   .&internal($pre);
    $errCode[202]=  "int:modInterpret some input file missing\n"           .&internal($pre);
    $errCode[203]=  "int:modInterpret some parameter unreasonable\n"       .&internal($pre);
    $errCode[204]=  "int:modInterpret open file error\n"                   .&internal($pre);
    $errCode[205]=  "usr:modInterpret missing hash in query\n"             .&internal($pre);
    $errCode[206]=  "usr:modInterpret for EVALSEC COL format needed\n"     .&inWrgEvalsec($pre);
    $errCode[207]=  "usr:modInterpret after 'interpretSeqPP'\n"            .&internal($pre);
    $errCode[208]=  "usr:modInterpret sequence too short\n"                .&inWrgTooShort($pre);
    $errCode[209]=  "usr:modInterpret sequence too long\n"                 .&inWrgTooLong($pre);
    $errCode[210]=  "usr:modInterpret genome sequence\n"                   .&inWrgTooGene($pre);
    $errCode[2001]= "usr:modInterpret nothing found after # line!\n"       .&inWrgFormat($pre);

    $errCode[211]=  "int:modInterpret after 'interpretSeqMsf'\n"           .&internal($pre);
    $errCode[212]=  "usr:modInterpret wrong MSF input\n"                   .&inWrgMsf($pre,$tmp[2]);
    $errCode[213]=  "int:modInterpret after 'interpretSeqCol'\n"           .&internal($pre);
    $errCode[214]=  "usr:modInterpret wrong COL input\n"                   .&inWrgCol($pre);
    $errCode[215]=  "int:modInterpret after 'interpretSeqSaf'\n"           .&internal($pre);
    $errCode[216]=  "usr:modInterpret wrong SAF input\n"                   .&inWrgSaf($pre,$tmp[2]);
    $errCode[217]=  "int:modInterpret after 'interpretSeqPirlist'\n"       .&internal($pre);
    $errCode[218]=  "usr:modInterpret wrong PIRlist input\n"               .&inWrgPirList($pre);
    $errCode[219]=  "usr:modInterpret wrong PIRlist too few alis\n"        .&inWrgPirList($pre);
    $errCode[220]=  "usr:modInterpret wrong PIRlist too short seq\n"       .&inWrgPirList($pre);
    $errCode[2172]= "int:modInterpret after 'interpretSeqPirmul'\n"        .&internal($pre);
    $errCode[2182]= "usr:modInterpret wrong PIRmul input\n"                .&inWrgPirMul($pre);
    $errCode[2192]= "usr:modInterpret wrong PIRmul too few alis\n"         .&inWrgPirMul($pre);
    $errCode[2202]= "usr:modInterpret wrong PIRmul too short seq\n"        .&inWrgPirMul($pre);

    $errCode[221]=  "int:modInterpret after 'interpretSeqFastalist'\n"     .&internal($pre);
    $errCode[222]=  "usr:modInterpret wrong FASTAlist input\n"             .&inWrgFastaList($pre);
    $errCode[223]=  "usr:modInterpret wrong FASTAlist too few alis\n"      .&inWrgFastaList($pre);
    $errCode[224]=  "usr:modInterpret wrong FASTAlist too short seq\n"     .&inWrgFastaList($pre);
    $errCode[2212]= "int:modInterpret after 'interpretSeqFastamul'\n"      .&internal($pre);
    $errCode[2222]= "usr:modInterpret wrong FASTAmul input\n"              .&inWrgFastaMul($pre);
    $errCode[2232]= "usr:modInterpret wrong FASTAmul too few alis\n"       .&inWrgFastaMul($pre);
    $errCode[2242]= "usr:modInterpret wrong FASTAmul too short seq\n"      .&inWrgFastaMul($pre);
    $errCode[229]=  "usr:modInterpret wrong prediction option/input\n"     .&inWrgColPhd($pre);
    $errCode[230]=  "int:manual input format not recognised\n"             .&inWrgManual($pre);;
    $errCode[231]=  "int:manual input format not an option\n"              .&internal($pre);;
    $errCode[232]=  "int:modInterpret MSF input no FASTA of guide\n"       .&internal($pre);;
    $errCode[233]=  "int:modInterpret COL input no FASTA of guide\n"       .&internal($pre);;
    $errCode[234]=  "int:modInterpret SAF msfCheckFormat error\n"          .&internal($pre);;
    $errCode[235]=  "int:modInterpret SAF input no FASTA of guide\n"       .&internal($pre);;
    $errCode[236]=  "int:modInterpret SAF wrong input format\n"            .&inWrgSaf($pre);

    $errCode[240]=  "int:manual input format\n"                            .&internal($pre);;

    $errCode[301]=  "int:modConvert some input argument not defined\n"     .&internal($pre);
    $errCode[302]=  "int:modConvert input working dir missing\n"           .&internal($pre);
    $errCode[303]=  "int:modConvert some input file missing\n"             .&internal($pre);
    $errCode[304]=  "int:modConvert some executable missing\n"             .&internal($pre);
    $errCode[305]=  "int:modConvert open file error (SAF)\n"               .&internal($pre);
    $errCode[306]=  "int:modConvert move file error (SAF)\n"               .&internal($pre);
    $errCode[307]=  "int:modConvert failed MSF -> HSSP \n"                 .&internal($pre);
    $errCode[308]=  "int:modConvert move file error (MSF)\n"               .&internal($pre);
    $errCode[309]=  "int:modConvert failed to append to predTmp\n"         .&internal($pre);
    $errCode[421]=  "int:modConvert append convHssp2msf failed\n"          .&internal($pre);
    $errCode[422]=  "int:modConvert append exeHsspExtrHdr failed\n"        .&internal($pre);

    $errCode[315]=  "int:modConvert PirList: convSeq2fasta failed!\n"      .&internal($pre);
    $errCode[316]=  "int:modConvert PirList: Maxhom default missing!\n"    .&internal($pre);
    $errCode[317]=  "int:modConvert PirList: MaxhomRunLoop failed\n"       .&internal($pre);
    $errCode[318]=  "int:modConvert PirList: HSSP->MSF failed\n"           .&internal($pre);
    $errCode[319]=  "int:modConvert Pir|FastaMul: copf failed on FASTA in\n" .&internal($pre);
    $errCode[320]=  "int:modConvert Pir|FastaMul: copf failed fasta->HSSP\n" .&internal($pre);

    $errCode[330]=  "int:modConvert manual failed on SWISS-PROT 1\n"       .&internal($pre);
    $errCode[331]=  "int:modConvert manual failed on SWISS-PROT 2\n"       .&internal($pre);
    $errCode[332]=  "int:modConvert manual failed on SWISS-PROT 3\n"       .&internal($pre);
    $errCode[333]=  "int:modConvert manual failed on PIR-sim 1\n"          .&internal($pre);
    $errCode[334]=  "int:modConvert manual failed on PIR-sim 2 (move)\n"   .&internal($pre);
    $errCode[335]=  "int:modConvert manual failed on PIR-sim 3 (move)\n"   .&internal($pre);
    $errCode[336]=  "int:modConvert manual failed on PHD.rdb\n"            .&internal($pre);
    $errCode[337]=  "int:modConvert manual failed on maxhomSelf\n"         .&internal($pre);

    $errCode[401]=  "int:modAlign some input argument not defined\n"       .&internal($pre);
    $errCode[402]=  "int:modAlign input working dir missing\n"             .&internal($pre);
    $errCode[403]=  "int:modAlign some input file missing\n"               .&internal($pre);
    $errCode[404]=  "int:modAlign some executable missing\n"               .&internal($pre);
    $errCode[405]=  "int:modAlign file with sequence missing!!\n"          .&internal($pre);


    $errCode[4011]= "int:runProsite some input argument not defined\n"     .&internal($pre);
    $errCode[4021]= "int:runProsite some input file missing\n"             .&internal($pre);
    $errCode[4012]= "int:runSegNorm some input argument not defined\n"     .&internal($pre);
    $errCode[4022]= "int:runSegNorm some input file missing\n"             .&internal($pre);
    $errCode[4042]= "int:runSegNorm some executable missing\n"             .&internal($pre);
    $errCode[4015]= "int:runProdom  some input argument not defined\n"     .&internal($pre);
    $errCode[4025]= "int:runProdom  some input file missing\n"             .&internal($pre);

    $errCode[410]=  "int:modAlign fault in convert_seq\n"                  .&internal($pre);
    $errCode[411]=  "int:modAlign after convert_seq couldnt del file\n"    .&internal($pre);
    $errCode[412]=  "int:modAlign after convert_seq couldnt cp file\n"     .&internal($pre);
    $errCode[413]=  "int:modAlign fasta problem\n"                         .&internal($pre);
    $errCode[414]=  "int:modAlign blastp problem\n"                        .&internal($pre);

    $errCode[4140]= "int:modAlign prodom problem (failed reading blast)\n" .&internal($pre);
    $errCode[4141]= "int:modAlign prodom problem (failed prodomWrt)\n"     .&internal($pre);
    
    $errCode[415]=  "int:modAlign maxhom no local default file\n"          .&internal($pre);
    $errCode[416]=  "int:modAlign maxhom (loop) returns error\n"           .&internal($pre);
    $errCode[417]=  "int:modAlign maxhom (loop) no output file\n"          .&internal($pre);
    $errCode[418]=  "int:modAlign append cat appIlyaPdb failed\n"          .&internal($pre);
    $errCode[419]=  "int:modAlign append cat appRetNoali failed\n"         .&internal($pre);
    $errCode[420]=  "int:modAlign append hsspChopProf failed\n"            .&internal($pre);
    $errCode[421]=  "int:modAlign append convHssp2msf failed\n"            .&internal($pre);
    $errCode[422]=  "int:modAlign append exeHsspExtrHdr failed\n"          .&internal($pre);
    $errCode[423]=  "int:modAlign append shit final append failed\n"       .&internal($pre);
    $errCode[423]=  "int:modAlign filter ali for PHD failed\n"             .&internal($pre);
    $errCode[424]=  "int:modAlign fault in convert_seq\n"                  .&internal($pre);
    $errCode[425]=  "int:modAlign never got FASTA format of sequence\n"    .&internal($pre);

    $errCode[491]=  "int:runEvalsec wrong argument passing to SBR\n"       .&internal($pre);
    $errCode[492]=  "int:runEvalsec missing file/dir/exe passed\n"         .&internal($pre);
    $errCode[493]=  "int:runEvalsec fault during running ext prog\n"       .&internal($pre);
    $errCode[494]=  "int:runEvalsec fault during appending files\n"        .&internal($pre);
    $errCode[495]=  "int:runEvalsec fault during creating error files\n"   .&internal($pre);

    $errCode[501]=  "int:runCoils some input argument not defined\n"       .&internal($pre);
    $errCode[502]=  "int:runCoils input working dir missing\n"             .&internal($pre);
    $errCode[503]=  "int:runCoils some input file missing\n"               .&internal($pre);
    $errCode[504]=  "int:runCoils some executable missing\n"               .&internal($pre);
    $errCode[505]=  "int:runCoils file with sequence missing!!\n"          .&internal($pre);

    $errCode[510]=  "int:runCoils fault in convert_seq\n"                  .&internal($pre);
    $errCode[511]=  "int:runCoils could not read guide seq\n"              .&internal($pre);
    $errCode[512]=  "int:runCoils fastaWrt error\n"                        .&internal($pre);
    $errCode[513]=  "int:runCoils fastaWrt error no output file\n"         .&internal($pre);

    $errCode[520]=  "int:runCoils no output from coilsRun\n"               .&internal($pre);
    $errCode[521]=  "int:runCoils error in coilsRd\n"                      .&internal($pre);
#    $errCode[520]=  "int:runCoils \n"                                      .&internal($pre);

    $errCode[530]=  "int:runCoils fault during appending files\n"          .&internal($pre);
    $errCode[541]=  "int:runCyspred some input argument not defined\n"     .&internal($pre);
    $errCode[542]=  "int:runCyspred input working dir missing\n"           .&internal($pre);
    $errCode[543]=  "int:runCyspred some input file missing\n"             .&internal($pre);
    $errCode[544]=  "int:runCyspred some executable missing\n"             .&internal($pre);
    $errCode[545]=  "int:runCyspred file with sequence missing!!\n"        .&internal($pre);
    $errCode[546]=  "int:runCyspred hssp file missing!!\n";
    $errCode[550]=  "int:runCyspred fault in convert_seq\n"                .&internal($pre);
    $errCode[551]=  "int:runCyspred could not read guide seq\n"            .&internal($pre);
    $errCode[552]=  "int:runCyspred fastaWrt error\n"                      .&internal($pre);
    $errCode[553]=  "int:runCyspred fastaWrt error no output file\n"       .&internal($pre);
    $errCode[555]=  "int:runCyspred fault during checking jobs\n"          .&internal($pre);
    $errCode[560]=  "int:runCyspred fault during ext prog\n"               .&internal($pre);
    

    $errCode[570]=  "int:runCyspred fault during appending files\n"        .&internal($pre);

    $errCode[580]=  "int:runR4S safBlastPsi file missing!!\n";


    $errCode[601]=  "int:runPhd some input argument not defined\n"         .&internal($pre);
    $errCode[602]=  "int:runPhd input working dir missing\n"               .&internal($pre);
    $errCode[603]=  "int:runPhd some input file missing\n"                 .&internal($pre);
    $errCode[604]=  "int:runPhd some executable missing\n"                 .&internal($pre);
    $errCode[605]=  "int:runPhd not HSSP file put in!\n"                   .&internal($pre);
    $errCode[606]=  "int:runPhd input HSSP file empty!\n"                  .&internal($pre);

    $errCode[611]=  "int:runPhd output .pred missing\n"                    .&internal($pre);

    $errCode[612]=  "int:runPhd output .rdb  missing\n"                    .&internal($pre);
    $errCode[613]=  "int:runPhd phd2dssp failed to produce out (1)\n"      .&internal($pre);
    $errCode[614]=  "int:runPhd rdb2kg failed to produce out (1)\n"        .&internal($pre);
    $errCode[615]=  "int:runPhd rdb2kg failed to produce out (2 htm)\n"    .&internal($pre);
    $errCode[616]=  "int:runPhd rdb2kg failed to produce out (3 sim)\n"    .&internal($pre);
    $errCode[617]=  "int:runPhd convPhd2col failed \n"                     .&internal($pre);
    $errCode[618]=  "int:runPhd after convPhd2col append went wrong\n"     .&internal($pre);
    $errCode[619]=  "int:runPhd convHssp2msf failed\n"                     .&internal($pre);
    $errCode[620]=  "int:runPhd phd2msf (ext) failed\n"                    .&internal($pre);
    $errCode[621]=  "int:runPhd phd2casp2 (ext) failed\n"                  .&internal($pre);
    $errCode[622]=  "int:runPhd globeOne failed\n"                         .&internal($pre);
    $errCode[623]=  "int:runPhd cat output .pred failed\n"                 .&internal($pre);
    $errCode[624]=  "int:runPhd cat output .pred failed (2)\n"             .&internal($pre);


    $errCode[640]=  "int:runAsp some input argument not defined\n"       .&internal($pre);
    $errCode[641]=  "int:runAsp input working dir missing\n"             .&internal($pre);
    $errCode[642]=  "int:runAsp some input file missing\n"               .&internal($pre);
    $errCode[643]=  "int:runAsp some executable missing\n"               .&internal($pre);
    $errCode[644]=  "int:runAsp file with PHD output missing!!\n"        .&internal($pre);


    $errCode[645]=  "int: runAsp output .asp not found or err found\n"   .&internal($pre);
    $errCode[646]=  "int:runAsp fault during appending files\n"          .&internal($pre);

    $errCode[651]=  "int:runProf some input argument not defined\n"        .&internal($pre);
    $errCode[652]=  "int:runProf input working dir missing\n"              .&internal($pre);
    $errCode[653]=  "int:runProf some input file missing\n"                .&internal($pre);
    $errCode[654]=  "int:runProf some executable missing\n"                .&internal($pre);
    $errCode[655]=  "int:runProf not HSSP file put in!\n"                  .&internal($pre);
    $errCode[656]=  "int:runProf input HSSP file empty!\n"                 .&internal($pre);

    $errCode[661]=  "int:runProf output .rdb missing\n"                    .&internal($pre);
    $errCode[662]=  "int:runProf output .ascii missing\n"                  .&internal($pre);
    $errCode[663]=  "int:runProf phd2dssp failed to produce out (1)\n"     .&internal($pre);
    $errCode[664]=  "int:runProf rdb2kg failed to produce out (1)\n"       .&internal($pre);
    $errCode[665]=  "int:runProf rdb2kg failed to produce out (2 htm)\n"   .&internal($pre);
    $errCode[666]=  "int:runProf rdb2kg failed to produce out (3 sim)\n"   .&internal($pre);
    $errCode[667]=  "int:runProf convPhd2col failed \n"                    .&internal($pre);
    $errCode[668]=  "int:runProf after convPhd2col append went wrong\n"    .&internal($pre);
    $errCode[669]=  "int:runProf convHssp2msf failed\n"                    .&internal($pre);
    $errCode[670]=  "int:runProf phd2msf (ext) failed\n"                   .&internal($pre);
    $errCode[671]=  "int:runProf phd2casp2 (ext) failed\n"                 .&internal($pre);
    $errCode[672]=  "int:runProf globeOne failed\n"                        .&internal($pre);
    $errCode[673]=  "int:runProf cat output .pred failed\n"                .&internal($pre);
    $errCode[674]=  "int:runProf cat output .pred failed (2)\n"            .&internal($pre);

    $errCode[680]=  "int:runNors some input argument not defined\n"       .&internal($pre);
    $errCode[681]=  "int:runNors input working dir missing\n"             .&internal($pre);
    $errCode[682]=  "int:runNors some input file missing\n"               .&internal($pre);
    $errCode[683]=  "int:runNors some executable missing\n"               .&internal($pre);
    $errCode[684]=  "int:runNors sequence file missing!!\n"               .&internal($pre);
    $errCode[685]=  "int:runNors file with PHDhtm output missing!!\n"     .&internal($pre);
    $errCode[686]=  "int:runNors file with PROF output missing!!\n"       .&internal($pre);
    $errCode[687]=  "int:runNors file with COILS output missing!!\n"      .&internal($pre);

    $errCode[688]=  "int: runNors output .Nors not found or err found\n"   .&internal($pre);
    $errCode[689]=  "int:runNors fault during appending files\n"          .&internal($pre);
    

    $errCode[701]=  "int:runTopits some input argument not defined\n"      .&internal($pre);
    $errCode[702]=  "int:runTopits input working dir missing\n"            .&internal($pre);
    $errCode[703]=  "int:runTopits some input file missing\n"              .&internal($pre);
    $errCode[704]=  "int:runTopits some executable missing\n"              .&internal($pre);
    $errCode[705]=  "int:runTopits not HSSP file put in!\n"                .&internal($pre);
    $errCode[706]=  "int:runTopits input HSSP file empty!\n"               .&internal($pre);
    $errCode[707]=  "int:runTopits local maxhom default failed!\n"         .&internal($pre);

    $errCode[711]=  "int:runTopits output .hssp missing\n"                 .&internal($pre);
    $errCode[712]=  "int:runTopits output .hssp empty\n"                   .&internal($pre);
    $errCode[713]=  "int:runTopits output .msf  missing\n"                 .&internal($pre);

    $errCode[720]=  "int:runCafasp output .AL  missing\n"                  .&internal($pre);

    $errCode[801]=  "int:modFin some input argument not defined\n"         .&internal($pre);
    $errCode[802]=  "int:modFin input working dir missing\n"               .&internal($pre);
    $errCode[803]=  "int:modFin some input file missing\n"                 .&internal($pre);

    $errCode[901]=  "int:runPredIsis some input argument not defined\n"         .&internal($pre);
    $errCode[902]=  "int:runPredIsis input working dir missing\n"               .&internal($pre);
    $errCode[903]=  "int:runPredIsis some input file missing\n"                 .&internal($pre);

				# --------------------------------------------------
				# HTML output
				# --------------------------------------------------
    $errCode[2100]= "int:htmlBuild failed\n"                               .&internal($pre);
    $errCode[2101]= "int:htmlBuild failed ini phase\n"                     .&internal($pre);
    $errCode[2102]= "int:htmlBuild file new open error\n"                  .&internal($pre);
    $errCode[2102]= "int:htmlBuild file new open error toc\n"              .&internal($pre);
    $errCode[2103]= "int:htmlBuild file append error\n"                    .&internal($pre);
    $errCode[2104]= "int:htmlBuild file append error toc\n"                .&internal($pre);

    $errCode[2110]= "int:htmlBuild keyword unknown\n"                      .&internal($pre);
    $errCode[2121]= "int:htmlBuild BODY file input open failed\n"          .&internal($pre);

    $errCode[2210]= "int:htmlBuild failed in_given stuff\n"                .&internal($pre);
    $errCode[2220]= "int:htmlBuild failed in_taken stuff\n"                .&internal($pre);
    $errCode[2221]= "int:htmlBuild failed ali_maxhom_head stuff\n"         .&internal($pre);

    $errCode[2231]= "int:htmlBuild failed prosite\n"                       .&internal($pre);
    $errCode[2232]= "int:htmlProdom failed ProDom\n"                       .&internal($pre);
    $errCode[2233]= "int:htmlBuild failed prodom\n"                        .&internal($pre);
    $errCode[2234]= "int:htmlBuild failed segNorm\n"                       .&internal($pre);

    $errCode[2238]= "int:htmlBuild: failed BLASTout\n"                     .&internal($pre);
    $errCode[2239]= "int:htmlBlast failed BLASTout\n"                      .&internal($pre);

    $errCode[2240]= "int:no file MviewIn defined\n"                        .&internal($pre);

    $errCode[2242]= "int:htmlMaxhom failed\n"                              .&internal($pre);
    $errCode[2244]= "int:htmlBuild failed maxhom_body\n"                   .&internal($pre);

    $errCode[2250]= "int:htmlBuild failed coils\n"                         .&internal($pre);
    $errCode[2260]= "int:htmlBuild failed evalsec_head\n"                  .&internal($pre);
    $errCode[2261]= "int:htmlBuild failed evalsec_body\n"                  .&internal($pre);

    $errCode[2270]= "int:htmlBuild failed phd_info\n"                      .&internal($pre);
    $errCode[2271]= "int:htmlBuild failed phd_body\n"                      .&internal($pre);
    $errCode[2272]= "int:htmlBuild failed globe\n"                         .&internal($pre);
    $errCode[2273]= "int:htmlBuild failed phd_col\n"                       .&internal($pre);
    $errCode[2274]= "int:htmlBuild failed phd_msf\n"                       .&internal($pre);
    $errCode[2275]= "int:htmlBuild failed phd_rdb\n"                       .&internal($pre);

    $errCode[2277]= "int:htmlBuild failed asp\n"                           .&internal($pre);

    $errCode[2280]= "int:htmlBuild failed topits_head\n"                   .&internal($pre);
    $errCode[2281]= "int:htmlBuild failed topits_msf\n"                    .&internal($pre);
    $errCode[2282]= "int:htmlBuild failed topits_hssp\n"                   .&internal($pre);
    $errCode[2283]= "int:htmlBuild failed topits_strip\n"                  .&internal($pre);
    $errCode[2284]= "int:htmlBuild failed topits_own\n"                    .&internal($pre);

    $errCode[2288]= "int:htmlTopits failed topits_msf\n"                   .&internal($pre);


    $errCode[2295]= "int:htmlFin failed \n"                                .&internal($pre);


    $errCode[2300]= "int:htmlBuild failed prof_info\n"                     .&internal($pre);
    $errCode[2301]= "int:htmlBuild failed prof_body\n"                     .&internal($pre);
    $errCode[2302]= "int:htmlBuild failed prof_globe\n"                    .&internal($pre);
    $errCode[2303]= "int:htmlBuild failed prof_col\n"                      .&internal($pre);
    $errCode[2304]= "int:htmlBuild failed prof_msf\n"                      .&internal($pre);
    $errCode[2305]= "int:htmlBuild failed prof_rdb\n"                      .&internal($pre);


    $errCode[9101]= "int:INIT scannerPP failed to require env_pack\n"      .&internal($pre);
    $errCode[9102]= "int:INIT scannerPP error in env\n"                    .&internal($pre);
				# --------------------------------------------------
				# scannerPP: sbr scannerBeforeLoop
                                #    (1) check file quota
                                #    (2) restrict number of lines of all log files
                                #    (3) clean up dead requests
                                #    (4) clean up other old files
                                #    (5) report status of PP server to WWW docs
				# --------------------------------------------------
    $errCode[9200]= "int:scannerPP:BeforeLoop failed\n"                    .&internal($pre);
    $errCode[9210]= "int:scannerPP:ctrlSpaceNumberCheck failed\n"          .&internal($pre);
    $errCode[9211]= "int:scannerPP:ctrlSpaceNumberCheck no delete\n"       .&internal($pre);
    $errCode[9212]= "int:scannerPP:ctrlSpaceNumberCheck no delete\n"       .&internal($pre);
    $errCode[9220]= "int:scannerPP:ctrlSpaceDuCheck failed\n"              .&internal($pre);
    $errCode[9221]= "int:scannerPP:ctrlSpaceDuCheck err exeDu\n"           .&internal($pre);
    $errCode[9222]= "int:scannerPP:ctrlSpaceDuCheck failed repeat\n"       .&internal($pre);
    $errCode[9222]= "int:scannerPP:ctrlSpaceDuCheck did NOT clean\n"       .&internal($pre);

    $errCode[9230]= "int:scannerPP:ctrlSpaceQuotaInit failed\n"            .&internal($pre);
    $errCode[9231]= "int:scannerPP:ctrlSpaceQuotaInit err exeQuota\n"      .&internal($pre);
    $errCode[9232]= "int:scannerPP:ctrlSpaceQuotaCheck err exeQuota\n"     .&internal($pre);
    $errCode[9233]= "int:scannerPP:ctrlSpaceQuotaCheck no delete\n"        .&internal($pre);
    $errCode[9234]= "int:scannerPP:ctrlSpaceQuotaCheck no delete(2)\n"     .&internal($pre);
    $errCode[9235]= "int:scannerPP:ctrlSpaceQuotaCheck failed\n"           .&internal($pre);
    $errCode[9236]= "int:scannerPP:ctrlSpaceQuotaCheck failed (2)\n"       .&internal($pre);
    $errCode[9237]= "int:scannerPP:ctrlSpaceQuotaCheck did NOT clean\n"    .&internal($pre);
    
    $errCode[9240]= "int:scannerPP:ctrlSpaceFreeSpace no file to delete\n" .&internal($pre);
    $errCode[9241]= "int:scannerPP:ctrlSpaceFreeSpace failed to list tar\n".&internal($pre);
    $errCode[9250]= "int:scannerPP:ctrlSpaceFreeFile no file to delete\n"  .&internal($pre);
    $errCode[9251]= "int:scannerPP:ctrlSpaceFreeFile failed to list tar\n" .&internal($pre);
    $errCode[9260]= "int:scannerPP:ctrlSpaceDuCheck failed to complete \n" .&internal($pre);
    $errCode[9270]= "int:scannerPP:beforeLoop failed to restrict log\n"    .&internal($pre);
    $errCode[9271]= "int:scannerPP:ctrlFileRestrict open log file failed\n".&internal($pre);
    $errCode[9272]= "int:scannerPP:ctrlFileRestrict open log file 2 fail\n".&internal($pre);
    $errCode[9273]= "int:scannerPP:ctrlFileRestrict open new log failed\n" .&internal($pre);
    $errCode[9280]= "int:scannerPP:beforeLoop failed to delete expired\n"  .&internal($pre);
    $errCode[9290]= "int:scannerPP:beforeLoop failed to check status\n"    .&internal($pre);
    $errCode[9291]= "int:scannerPP:ctrlReportStatus repeated run?\n"       .&internal($pre);
    $errCode[9291]= "int:scannerPP:ctrlReportStatus no status report exe\n".&internal($pre);


				# --------------------------------------------------
				# scannerPP (in loop) scannerProcessInputMail
				# --------------------------------------------------
    $errCode[9400]= "int:scannerPP: ProcessInputMail failed\n"             .&internal($pre);
    $errCode[9401]= "int:scannerPP:ProcessInputMail arguments error\n"     .&internal($pre);

				# --------------------------------------------------
				# scannerPP (in loop) scannerProcessInputMail
				# --------------------------------------------------
    $errCode[9600]= "int:scannerPP: Predict failed\n"                      .&internal($pre);
    $errCode[9601]= "int:scannerPP: Predict arguments error\n"             .&internal($pre);
    $errCode[9602]= "int:scannerPP: Predict format error in input file\n"  .&internal($pre);
    $errCode[9610]= "int:scannerPP:Predict:ctrlSpaceCheck error\n"         .&internal($pre);
    $errCode[9620]= "int:scannerPP:Predict:sysWhoWantsToWork error\n"      .&internal($pre);
    $errCode[9630]= "int:scannerPP:Predict:fileRemoveNullChar error\n"     .&internal($pre);
    $errCode[9640]= "int:scannerPP:Predict:sysWhoWantsToWork error\n"      .&internal($pre);
    $errCode[9640]= "int:scannerPP:Predict:fileExtractHeader (user,orig)\n".&internal($pre);

				# --------------------------------------------------
				# scannerPP (in loop) scannerProcessInputMail
				# --------------------------------------------------
    $errCode[9800]= "int:scannerPP: SendMail failed\n"                     .&internal($pre);
    $errCode[9801]= "int:scannerPP: SendMail arguments error\n"            .&internal($pre);
    $errCode[9810]= "int:scannerPP: SendMail failed to get user name\n"    .&internal($pre);
    

				# --------------------------------------------------
				# scannerPP (in loop) scannerProcessInputMail
				# --------------------------------------------------
    $errCode[9900]= "int:scannerPP: ManageExpired failed\n"                .&internal($pre);
    $errCode[9901]= "int:scannerPP: ManageExpired arguments error\n"       .&internal($pre);
    $errCode[9902]= "int:scannerPP: ManageExpired dirRes missing\n"        .&internal($pre);
    $errCode[9910]= "int:scannerPP: ManageExpired mail command wrong\n"    .&internal($pre);
    $errCode[9911]= "int:scannerPP: ManageExpired file missing\n"          .&internal($pre);


				# --------------------------------------------------
				# 
				# --------------------------------------------------
    $errCode[10001]="int:INIT env_pack could NOT be required\n"            .&internal($pre);
    $errCode[10002]="int:INIT env_pack after 'initPackEnv'\n"              .&internal($pre);
    $errCode[10003]="int:INIT some library not required ok\n"              .&internal($pre);
    $errCode[10004]="int:iniPredict xx still missing\n"                    .&internal($pre);

				# --------------------------------------------------
				# www submission
				# --------------------------------------------------
    $errCode[11000]="int:www submit failed on INIT env_pack\n"             .&internal($pre);
    $errCode[11001]="int:www submit env_pack could NOT be required\n"      .&internal($pre);
    $errCode[11002]="int:www submit env_pack variable not defined\n"       .&internal($pre);
    $errCode[11003]="int:www submit env_pack failed to require cgi-lib\n"  .&internal($pre);



				# ------------------------------
				# final string
    $directive=
	$pre."Please send your file and refer to the  following  ERROR\n".
	    $pre."number when contacting   predict-help\@rostlab.org\n".
		$pre."for further help: ";
    if (! defined $errCode[$in]){
	return(0,"ERROR in ERROR code search no number defined!!!");}
    else {
	return(1,&addBefore($pre).$directive.
	       "errNo=$in\n".$pre.$errCode[$in].&addAfter($pre));}
}				# end of errCode

#===============================================================================
sub addBefore {
    local($pre)=@_;
#    $txt = "<pre>\n";
    $txt .=$pre."--------------------------------------------------------\n";
    $txt.=$pre."Dear Colleague,\n";
    $txt.=$pre."\n";
    $txt.=$pre."Unfortunately, we have to apologise for  NOT returning a\n";
    $txt.=$pre."prediction for the peptide you sent.\n";
    return($txt);}

#===============================================================================
sub addAfter {
    local($pre)=@_;
    $txt =$pre."With my best regards\n";
    $txt.=$pre."        Burkhard Rost\n";
    #$txt.=$pre."        EMBL Heidelberg, 69012 Heidelberg, Europe\n";
    $txt.=$pre."        CUBIC, Dept Biochemistry & Mol Biophysics\n";
    $txt.=$pre."        Columbia University, New York, US\n";
    $txt.=$pre."        \t " . `date`;
    $txt.=$pre."\n";
    $txt.=$pre."For personal  messages, or  questions to the  PP author,\n";
    $txt.=$pre."send an email to Predict-Help\@columbia.edu\n";
    $txt.=$pre."--------------------------------------------------------\n";
 #   $txt = "</pre>\n";
    return($txt);}

#===============================================================================
sub internal {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."We assume that the error was caused by an internal soft-\n";
    $txt.=$pre."ware  problem which we attempt to spot.  However, in the\n";
    $txt.=$pre."past,such errors were often caused by format violations.\n";
    $txt.=$pre."Thus, please check the data you submitted, and  possibly\n";
    $txt.=$pre."try again to request a prediction with a more adequately\n";
    $txt.=$pre."formatted input.  Thanks!\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub licence_password {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."Please check the usage of your password.\n";
    $txt.=$pre."\n";
    $txt.=$pre."(1) Only commercial user should use a password.\n";
    $txt.=$pre."(2) If you are:  you would  want to provide the  correct\n";
    $txt.=$pre."    password in any line before the one starting with  a\n";
    $txt.=$pre."    hash ('#'), using the following syntax:\n";
    $txt.=$pre."         password(my_password)\n";
    $txt.=$pre."    If you assume to have used this format, and  a valid\n";
    $txt.=$pre."    password, and you still get this message. Well, then\n\n";
    $txt.=$pre."    I assume there was a typo...\n";
    $txt.=$pre."Sorry, and thanks for trying again.\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgCol {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."You submitted a file  containing secondary structure and\n";
    $txt.=$pre."solvent accessibility.   However, your definition of the\n";
    $txt.=$pre."column format did not quite match ours.  Sorry.  Please.\n";
    $txt.=$pre."try to spot typos or errors.\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgColPhd {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."You submitted a file  containing secondary structure and\n";
    $txt.=$pre."solvent accessibility.  However, you did NOT choose  the\n";
    $txt.=$pre."prediction option 'threading', resp. 'TOPITS'.    Conse-\n";
    $txt.=$pre."quently, PredictProtein expects that you request a  pre-\n";
    $txt.=$pre."diction of 1D structure.   Unfortunately,  this does not\n";
    $txt.=$pre."make too much sense...\n";
    $txt.=$pre."\n";
    $txt.=$pre."NOTE: you may find it easier to use automatic formatting\n";
    $txt.=$pre."      via the WWW interface to PredictProtein:\n";
    $txt.=$pre."http://www.predictprotein.org/submit.php\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgEvalsec {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."--------------------------------------------------------\n";
    $txt.=$pre."The problem was caused by the format of your submission.\n";
    $txt.=$pre."\n";
    $txt.=$pre."Your request was interpreted as a request for  EVALSEC ,\n";
    $txt.=$pre."i.e., the comparison of observed and predicted secondary\n";
    $txt.=$pre."structure.\n";
    $txt.=$pre."If that is NOT what you wanted:  watch the line with the\n";
    $txt.=$pre."hash (#).   That seem to contain a  keyword starting the\n";
    $txt.=$pre."EVALSEC program.  Furthermore, please adhere to the fol-\n";
    $txt.=$pre."lowing constraints when providing your prediction:\n";
    $txt.=$pre."(1) before line with hash (#)\n";
    $txt.=$pre."    Use the option 'evaluate prediction accuracy' in any\n";
    $txt.=$pre."    line before the one starting with a hash (#).\n";
    $txt.=$pre."(2) 1st line: '\# COLUMN format'\n";
    $txt.=$pre."    This is the signal for our software to expect  a  1D\n";
    $txt.=$pre."    prediction as input.\n";
    $txt.=$pre."(3) 2nd line: describtors\n";
    $txt.=$pre."    The file MUST contain:\n";
    $txt.=$pre."     	predicted and observed secondary structure\n";
    $txt.=$pre."    The following symbols  are mandatory:\n";
    $txt.=$pre."        'AA'    amino acid in one-letter code\n";
    $txt.=$pre."        'PSEC'  predicted secondary structure, 3 states:\n";
    $txt.=$pre."                H=helix, E=strand, L=other\n";
    $txt.=$pre."        'OSEC'  observed secondary structure,  3 states:\n";
    $txt.=$pre."                H=helix, E=strand, L=other\n";
    $txt.=$pre."(4) 3rd line (and all following): prediction, and obser-\n";
    $txt.=$pre."    vation, one row per residue.\n";
    $txt.=$pre."\n";
    $txt.=$pre."(*) Delimiters between columns: \n";
    $txt.=$pre."    either of the following is allowed:\n";
    $txt.=$pre."        comma, space, tab\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgFastaList {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."Your request was interpreted as an unaligned FASTA list, however, the\n";
    $txt.=$pre."required format for that list could not be found.\n";
    $txt.=$pre."\n";
    $txt.=$pre."For details, please, see the WWW site:\n";
    $txt.=$pre."http://www.predictprotein.org/Dexa/optin_fasta.html\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgFastaMul {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."Your request was interpreted as an aligned FASTA list, however, the\n";
    $txt.=$pre."required format for that list could not be found.\n";
    $txt.=$pre."\n";
    $txt.=$pre."For details, please, see the WWW site:\n";
    $txt.=$pre."http://www.predictprotein.org/Dexa/optin_fasta.html\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgFormat {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."The software could not find the information after the  #\n";
    $txt.=$pre."line. Mind you: after that line all your sequence infor-\n";
    $txt.=$pre."mation is expected to start.  Thus, we did not find any-\n";
    $txt.=$pre."thing to do.\n";
    $txt.=$pre."\n";
    $txt.=$pre."Note: this  message could also have been  produced  by a\n";
    $txt.=$pre."      format violation!  If your sequence contained more\n";
    $txt.=$pre."      than 17 residues,  than  the most likely cause for\n";
    $txt.=$pre."      the error  message is the use  of a non-amino acid\n";
    $txt.=$pre."      character in the  1st or  2nd  line after the line\n";
    $txt.=$pre."      with the hash (#). The automatic format extraction\n";
    $txt.=$pre."      procedure interprets everything after that hash as\n";
    $txt.=$pre."      amino acid sequence, and  ignores  everything from\n";
    $txt.=$pre."      the first line with a  non-amino  acid  character,\n";
    $txt.=$pre."      e.g. any of the following:\n";
    $txt.=$pre."      \n";
    $txt.=$pre."      .-_bjozx0123456789!,\n";
    $txt.=$pre."      \n";
    $txt.=$pre."      asf. ...\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgManual {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."For manual use of PP the input file must be in either of\n";
    $txt.=$pre."the following formats: \n";
    $txt.=$pre."HSSP, DSSP, MSF, PIR, PIR_MUL, FASTA, FASTA_MUL, SWISS-PROT\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgMsf {
    local($pre,$fileInLoc)=@_;
    $txt =$pre."\n";
    $txt.=$pre."The software did not understand your version of the  MSF\n";
    $txt.=$pre."from the alignment you supplied.   Please make sure that\n";
    $txt.=$pre."your request is in the format described in the help text\n";
    $txt.=$pre."below, respectively on the WWW:\n";
    $txt.=$pre."http://www.predictprotein.org/doc/help_toc.html\n";
    $txt.=$pre."or (more specifically):\n";
    $txt.=$pre."http://www.predictprotein.org/\n";
    $txt.=$pre."   Dexa/optin_msf.html    (type these two as one line in\n";
    $txt.=$pre."                           your browser!)\n";
    $txt.=$pre."NOTE: the most common reason for this response is an in-\n";
    $txt.=$pre."      appropriate header...\n";
    $txt.=$pre."\n";
    $txt.=$pre."In the following an example for the MSF format.\n";
    $txt.=$pre."\n";
    $txt.=$pre."--------------------------------------------------------\n";
    $txt.=$pre."\n";
    if (defined $fileInLoc){
	open(FHIN_INWRGMSF,"$fileInLoc") || 
	    return(0,"err=1","*** inWrgMsf(errCode): cannot open input file '$fileInLoc'!");
	while(<FHIN_INWRGMSF>){$txt.=$_;}close(FHIN_INWRGMSF);}
    return($txt);}

#===============================================================================
sub inWrgPirList {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."Your request was interpreted as a PIR list, however, the\n";
    $txt.=$pre."required format for that list could not be found.\n";
    $txt.=$pre."\n";
    $txt.=$pre."For details, please, see the WWW site:\n";
    $txt.=$pre."http://www.predictprotein.org/Dexa/optin_pir.html\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgPirMul {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."Your request was interpreted as an aligned PIR list, however, the\n";
    $txt.=$pre."required format for that list could not be found.\n";
    $txt.=$pre."\n";
    $txt.=$pre."For details, please, see the WWW site:\n";
    $txt.=$pre."http://www.predictprotein.org/Dexa/optin_pir.html\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgSaf {
    local($pre,$fileInLoc)=@_;
    $txt =$pre."\n";
    $txt =$pre."--------------------------------------------------------\n";
    $txt.=$pre."\n";
    $txt.=$pre."The software did not understand your SAF  (Simple Align-\n";
    $txt.=$pre."ment Format).   Please make sure that your request is in\n";
    $txt.=$pre."the format described in the help text below, or on WWW: \n";
    $txt.=$pre."http://www.predictprotein.org/doc/help_toc.html\n";
    $txt.=$pre."or (more specifically):\n";
    $txt.=$pre."http://www.predictprotein.org\n";
    $txt.=$pre."   Dexa/optin_saf.html    (type these two as one line in\n";
    $txt.=$pre."                           your browser!)\n";
    $txt.=$pre."NOTE: the most common reason for this response is an in-\n";
    $txt.=$pre."      appropriate header...\n";
    $txt.=$pre."\n";
    if (defined $fileInLoc && -e $fileInLoc){
	$txt.=$pre."\n";
	$txt.=$pre."In the following an example for the SAF format.\n";
	$txt.=$pre."\n";
	open(FHIN_INWRGSAF,"$fileInLoc") || 
	    return(0,"err=1","*** inWrgSaf(errCode): cannot open input file '$fileInLoc'!");
	while(<FHIN_INWRGSAF>){$txt.=$_;}close(FHIN_INWRGSAF);}
    $txt.=$pre."--------------------------------------------------------\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgTooGene {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."PredictProtein bases predictions, and alignments on pro-\n";
    $txt.=$pre."tein sequences.  The sequence you sent was automatically\n";
    $txt.=$pre."recognised as a DNA or RNA sequence.  Currently, PP can-\n";
    $txt.=$pre."cope with that.  Please resubmit the corresponding amino\n";
    $txt.=$pre."acid sequence (for translation http://expasy.hcuge.ch/).\n";
    $txt.=$pre."\n";
    $txt.=$pre."Please let me know, if this message is wrong!\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgTooLong {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."I cannot handle sequences longer than 5500 residues.....\n";
    $txt.=$pre."This is due to limitations in  the memory  space alloca-\n";
    $txt.=$pre."ted for the PP server, in paricular the limiting step is\n";
    $txt.=$pre."the alignment procedure.  \n";
    $txt.=$pre."I advise you to cut your  protein  into major chains, or\n";
    $txt.=$pre."domains (e.g.  http://protein.toulouse.inra.fr), and to/\n";
    $txt.=$pre."re-submit the parts in separate files.\n";
    $txt.=$pre."\n";
    return($txt);}

#===============================================================================
sub inWrgTooShort {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."The neural networks of PHD were trained on peptides of >\n";
    $txt.=$pre."17 residues.  I strongly doubt that there is much sense-\n";
    $txt.=$pre."as the method is set up, currently - to make predictions\n";
    $txt.=$pre."for shorter fragments.  Already for segments of about 20\n";
    $txt.=$pre."residues  cut-off from a longer protein,  you  should be\n";
    $txt.=$pre."aware of possible 'border-effects' at the ends.\n";
    $txt.=$pre."\n";
    $txt.=$pre."Should you be able  to append  a few residues before and\n";
    $txt.=$pre."after the sequence  you sent this time, please try again\n";
    $txt.=$pre."with the longer stretch.\n";
    $txt.=$pre."\n";
    $txt.=$pre."Note: this  message could also have been  produced  by a\n";
    $txt.=$pre."      format violation!  If your sequence contained more\n";
    $txt.=$pre."      than 17 residues,  than  the most likely cause for\n";
    $txt.=$pre."      the error  message is the use  of a non-amino acid\n";
    $txt.=$pre."      character in the  1st or  2nd  line after the line\n";
    $txt.=$pre."      with the hash (#). The automatic format extraction\n";
    $txt.=$pre."      procedure interprets everything after that hash as\n";
    $txt.=$pre."      amino acid sequence, and  ignores  everything from\n";
    $txt.=$pre."      the first line with a  non-amino  acid  character,\n";
    $txt.=$pre."      e.g. any of the following:\n";
    $txt.=$pre."      \n";
    $txt.=$pre."      .-_bjozx0123456789!,\n";
    $txt.=$pre."      \n";
    $txt.=$pre."      asf. ...\n";
    $txt.=$pre."\n";
    return($txt);}


1;
