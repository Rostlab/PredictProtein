#!/usr/pub/bin/perl
##! /usr/pub/bin/perl
#------------------------------------------------------------------------------#
#	Copyright				  Apr,    	 1998	       #
#	Burkhard Rost &		rost@EMBL-Heidelberg.DE			       #
#	EMBL			http://www.embl-heidelberg.de/~rost/	       #
#	D-69012 Heidelberg						       #
#			        v 1.0   	  Apr,           1998          #
#------------------------------------------------------------------------------#
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
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   note: $tmp[1]=number, $tmp[2]='fileAppMsfExample|fileAppSafExample'
    $sbrName="errCode";$fhinLoc="FHIN"."$sbrName";

    $in=$tmp[1];$in=~s/\s//g;
    $pre="--- ";

    $errCode[1]= "intern: internal software/hardware problem\n".&internal($pre);
    $errCode[10]="";
    $errCode[11]="intern:predPack after moduleBefore job{fin} not 0\n".&internal($pre);
    $errCode[21]="intern:predPack after moduleInterpret\n";
    $errCode[22]="usr:predPack after moduleInterpret wrong format from USER\n";
    $errCode[23]="usr:predPack after moduleInterpret help request from USER\n";
    $errCode[24]="intern:predPack after moduleInterpretManu\n";
    $errCode[31]="intern:predPack after moduleConvert\n";
    $errCode[41]="intern:predPack after moduleAlign\n";
    $errCode[41]="intern:predPack after module\n";
    $errCode[95]="";
    $errCode[96]="";
    $errCode[97]="";
    $errCode[98]="";
    $errCode[99]="";
    $errCode[100]="";
    $errCode[101]="int:modBefore some input argument not defined\n"   .&internal($pre);
    $errCode[102]="int:modBefore some input file missing\n"           .&internal($pre);
    $errCode[103]="int:modBefore filePurgeNullChar failed\n"          .&internal($pre);
    $errCode[104]="int:moduleBefore filePurgeBlankLine failed\n"      .&internal($pre);
    $errCode[105]="usr:licence problem = invalid password \n"         .&licence_password($pre);
    $errCode[106]="int:modBefore decrypt problem (not on)\n"          .&internal($pre);
    $errCode[200]="";
    $errCode[201]="int:modInterpret some input argument not defined\n".&internal($pre);
    $errCode[202]="int:modInterpret some input file missing\n"        .&internal($pre);
    $errCode[203]="int:modInterpret some parameter unreasonable\n"    .&internal($pre);
    $errCode[204]="int:modInterpret open file error\n"                .&internal($pre);
    $errCode[205]="usr:modInterpret missing hash in query\n"          .&internal($pre);
    $errCode[206]="usr:modInterpret for EVALSEC COL format needed\n"  .&inWrgEvalsec($pre);
    $errCode[207]="usr:modInterpret after 'interpretSeqPP'\n"         .&internal($pre);
    $errCode[208]="usr:modInterpret sequence too short\n"             .&inWrgTooShort($pre);
    $errCode[209]="usr:modInterpret sequence too long\n"              .&inWrgTooLong($pre);
    $errCode[210]="usr:modInterpret genome sequence\n"                .&inWrgTooGene($pre);

    $errCode[211]="int:modInterpret after 'interpretSeqMsf'\n"        .&internal($pre);
    $errCode[212]="usr:modInterpret wrong MSF input\n"                .&inWrgMsf($pre,$tmp[2]);
    $errCode[213]="int:modInterpret after 'interpretSeqCol'\n"        .&internal($pre);
    $errCode[214]="usr:modInterpret wrong COL input\n"                .&inWrgCol($pre);
    $errCode[215]="int:modInterpret after 'interpretSeqSaf'\n"        .&internal($pre);
    $errCode[216]="usr:modInterpret wrong SAF input\n"                .&inWrgSaf($pre,$tmp[2]);
    $errCode[217]="int:modInterpret after 'interpretSeqPirlist'\n"    .&internal($pre);
    $errCode[218]="usr:modInterpret wrong PIRlist input\n"            .&inWrgPirList($pre);
    $errCode[219]="usr:modInterpret wrong PIRlist too few alis\n"     .&inWrgPirList($pre);
    $errCode[220]="usr:modInterpret wrong PIRlist too short seq\n"    .&inWrgPirList($pre);
    $errCode[221]="int:modInterpret after 'interpretSeqFastalist'\n"  .&internal($pre);
    $errCode[222]="usr:modInterpret wrong FASTAlist input\n"          .&inWrgPirList($pre);
    $errCode[223]="usr:modInterpret wrong FASTAlist too few alis\n"   .&inWrgPirList($pre);
    $errCode[224]="usr:modInterpret wrong FASTAlist too short seq\n"  .&inWrgPirList($pre);
    
    $errCode[229]="usr:modInterpret wrong prediction option/input\n"  .&inWrgColPhd($pre);

    $errCode[230]="int:manual input format not recognised\n"          .&inWrgManual($pre);;
    $errCode[231]="int:manual input format not an option\n"           .&internal($pre);;
    $errCode[232]="int:modInterpret MSF input no FASTA of guide\n"    .&internal($pre);;
    $errCode[233]="int:modInterpret COL input no FASTA of guide\n"    .&internal($pre);;
    $errCode[234]="int:modInterpret SAF msfCheckFormat error\n"       .&internal($pre);;
    $errCode[235]="int:modInterpret SAF input no FASTA of guide\n"    .&internal($pre);;
    $errCode[236]="int:modInterpret SAF input no FASTA of guide\n"    .&internal($pre);;

    $errCode[240]="int:manual input format\n"                         .&internal($pre);;

    $errCode[301]="int:modConvert some input argument not defined\n"  .&internal($pre);
    $errCode[302]="int:modConvert input working dir missing\n"        .&internal($pre);
    $errCode[303]="int:modConvert some input file missing\n"          .&internal($pre);
    $errCode[304]="int:modConvert some executable missing\n"          .&internal($pre);
    $errCode[305]="int:modConvert open file error (SAF)\n"            .&internal($pre);
    $errCode[306]="int:modConvert move file error (SAF)\n"            .&internal($pre);
    $errCode[307]="int:modConvert failed MSF -> HSSP \n"              .&internal($pre);
    $errCode[308]="int:modConvert move file error (MSF)\n"            .&internal($pre);
    $errCode[309]="int:modConvert failed to append to predTmp\n"      .&internal($pre);
    $errCode[421]="int:modConvert append convHssp2msf failed\n"       .&internal($pre);
    $errCode[422]="int:modConvert append exeHsspExtrHdr failed\n"     .&internal($pre);

    $errCode[315]="int:modConvert PirList: convSeq2fasta failed!\n"   .&internal($pre);
    $errCode[316]="int:modConvert PirList: Maxhom default missing!\n" .&internal($pre);
    $errCode[317]="int:modConvert PirList: MaxhomRunLoop failed\n"    .&internal($pre);
    $errCode[318]="int:modConvert PirList: HSSP->MSF failed\n"        .&internal($pre);

    $errCode[330]="int:modConvert manual failed on SWISS-PROT 1\n"    .&internal($pre);
    $errCode[331]="int:modConvert manual failed on SWISS-PROT 2\n"    .&internal($pre);
    $errCode[332]="int:modConvert manual failed on SWISS-PROT 3\n"    .&internal($pre);
    $errCode[333]="int:modConvert manual failed on PIR-sim 1\n"       .&internal($pre);
    $errCode[334]="int:modConvert manual failed on PIR-sim 2 (move)\n".&internal($pre);
    $errCode[335]="int:modConvert manual failed on PIR-sim 3 (move)\n".&internal($pre);
    $errCode[336]="int:modConvert manual failed on PHD.rdb\n"         .&internal($pre);
    $errCode[337]="int:modConvert manual failed on maxhomSelf\n"      .&internal($pre);

    $errCode[401]="int:modAlign some input argument not defined\n"    .&internal($pre);
    $errCode[402]="int:modAlign input working dir missing\n"          .&internal($pre);
    $errCode[403]="int:modAlign some input file missing\n"            .&internal($pre);
    $errCode[404]="int:modAlign some executable missing\n"            .&internal($pre);
    $errCode[405]="int:modAlign file with sequence missing!!\n"       .&internal($pre);

    $errCode[410]="int:modAlign fault in convert_seq\n"               .&internal($pre);
    $errCode[411]="int:modAlign after convert_seq couldnt del file\n" .&internal($pre);
    $errCode[412]="int:modAlign after convert_seq couldnt cp file\n"  .&internal($pre);
    $errCode[413]="int:modAlign fasta problem\n"                      .&internal($pre);
    $errCode[414]="int:modAlign blastp problem\n"                     .&internal($pre);
    $errCode[415]="int:modAlign maxhom no local default file\n"       .&internal($pre);
    $errCode[416]="int:modAlign maxhom (loop) returns error\n"        .&internal($pre);
    $errCode[417]="int:modAlign maxhom (loop) no output file\n"       .&internal($pre);
    $errCode[418]="int:modAlign append cat appIlyaPdb failed\n"       .&internal($pre);
    $errCode[419]="int:modAlign append cat appRetNoali failed\n"      .&internal($pre);
    $errCode[420]="int:modAlign append hsspChopProf failed\n"         .&internal($pre);
    $errCode[421]="int:modAlign append convHssp2msf failed\n"         .&internal($pre);
    $errCode[422]="int:modAlign append exeHsspExtrHdr failed\n"       .&internal($pre);
    $errCode[423]="int:modAlign append shit final append failed\n"    .&internal($pre);

    $errCode[491]="int:runEvalsec wrong argument passing to SBR\n"    .&internal($pre);
    $errCode[492]="int:runEvalsec missing file/dir/exe passed\n"      .&internal($pre);
    $errCode[493]="int:runEvalsec fault during running ext prog\n"    .&internal($pre);
    $errCode[494]="int:runEvalsec fault during appending files\n"     .&internal($pre);

    $errCode[501]="int:modPredMis some input argument not defined\n"  .&internal($pre);
    $errCode[502]="int:modPredMis input working dir missing\n"        .&internal($pre);
    $errCode[503]="int:modPredMis some input file missing\n"          .&internal($pre);
    $errCode[504]="int:modPredMis some executable missing\n"          .&internal($pre);
    $errCode[505]="int:modPredMis file with sequence missing!!\n"     .&internal($pre);

    $errCode[510]="int:modPredMis fault in convert_seq\n"             .&internal($pre);
    $errCode[511]="int:modPredMis could not read guide seq\n"         .&internal($pre);
    $errCode[512]="int:modPredMis fastaWrt error\n"                   .&internal($pre);
    $errCode[513]="int:modPredMis fastaWrt error no output file\n"    .&internal($pre);

    $errCode[520]="int:modPredMis no output from coilsRun\n"          .&internal($pre);
    $errCode[521]="int:modPredMis error in coilsRd\n"                 .&internal($pre);
#    $errCode[520]="int:modPredMis \n"                      .&internal($pre);
    $errCode[590]="int:modPredMis fault during appending files\n"     .&internal($pre);

    $errCode[601]="int:runPhd some input argument not defined\n"      .&internal($pre);
    $errCode[602]="int:runPhd input working dir missing\n"            .&internal($pre);
    $errCode[603]="int:runPhd some input file missing\n"              .&internal($pre);
    $errCode[604]="int:runPhd some executable missing\n"              .&internal($pre);
    $errCode[605]="int:runPhd not HSSP file put in!\n"                .&internal($pre);
    $errCode[606]="int:runPhd input HSSP file empty!\n"               .&internal($pre);

    $errCode[611]="int:runPhd output .pred missing\n"                 .&internal($pre);

    $errCode[612]="int:runPhd output .rdb  missing\n"                 .&internal($pre);
    $errCode[613]="int:runPhd phd2dssp failed to produce out (1)\n"   .&internal($pre);
    $errCode[614]="int:runPhd rdb2kg failed to produce out (1)\n"     .&internal($pre);
    $errCode[615]="int:runPhd rdb2kg failed to produce out (2 htm)\n" .&internal($pre);
    $errCode[616]="int:runPhd rdb2kg failed to produce out (3 sim)\n" .&internal($pre);
    $errCode[617]="int:runPhd convPhd2col failed \n"                  .&internal($pre);
    $errCode[618]="int:runPhd after convPhd2col append went wrong\n"  .&internal($pre);
    $errCode[619]="int:runPhd convHssp2msf failed\n"                  .&internal($pre);
    $errCode[620]="int:runPhd phd2msf (ext) failed\n"                 .&internal($pre);
    $errCode[621]="int:runPhd phd2casp2 (ext) failed\n"               .&internal($pre);
    $errCode[622]="int:runPhd cat output .pred failed\n"              .&internal($pre);

    $errCode[701]="int:runTopits some input argument not defined\n"   .&internal($pre);
    $errCode[702]="int:runTopits input working dir missing\n"         .&internal($pre);
    $errCode[703]="int:runTopits some input file missing\n"           .&internal($pre);
    $errCode[704]="int:runTopits some executable missing\n"           .&internal($pre);
    $errCode[705]="int:runTopits not HSSP file put in!\n"             .&internal($pre);
    $errCode[706]="int:runTopits input HSSP file empty!\n"            .&internal($pre);
    $errCode[707]="int:runTopits local maxhom default failed!\n"      .&internal($pre);

    $errCode[711]="int:runTopits output .hssp missing\n"              .&internal($pre);
    $errCode[712]="int:runTopits output .hssp empty\n"                .&internal($pre);
    $errCode[713]="int:runTopits output .msf  missing\n"              .&internal($pre);

    $errCode[801]="int:modFin some input argument not defined\n"      .&internal($pre);
    $errCode[802]="int:modFin input working dir missing\n"            .&internal($pre);
    $errCode[803]="int:modFin some input file missing\n"              .&internal($pre);

    $errCode[10001]="int:INIT env_pack couldnt be required\n"         .&internal($pre);
    $errCode[10002]="int:INIT env_pack after 'initPackEnv'\n"         .&internal($pre);
    $errCode[10003]="int:INIT some library not required ok\n"         .&internal($pre);
    $errCode[10004]="int:iniPredict xx still missing\n"               .&internal($pre);
				# ------------------------------
				# final string
    $directive=
	$pre."Please send your file and refer to the  following  ERROR\n".
	    $pre."number when contacting   predict-help\@embl-heidelberg.de\n".
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
    $txt =$pre."--------------------------------------------------------\n";
    $txt.=$pre."Dear Colleague,\n";
    $txt.=$pre."\n";
    $txt.=$pre."Unfortunately, we have to apologise for  NOT returning a\n";
    $txt.=$pre."prediction for the peptide you sent.\n";return($txt);}
sub addAfter {
    local($pre)=@_;
    $txt =$pre."With my best regards\n";
    $txt.=$pre."        Burkhard Rost\n";
    $txt.=$pre."        EMBL Heidelberg, 69012 Heidelberg, Europe\n";
    $txt.=$pre."        \t " . `date`;
    $txt.=$pre."\n";
    $txt.=$pre."For personal  messages, or  questions to the  PP author,\n";
    $txt.=$pre."send an email to Predict-Help\@EMBL-Heidelberg.DE\n";
    $txt.=$pre."--------------------------------------------------------\n";return($txt);}
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
    $txt.=$pre."\n";return($txt);}
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
    $txt.=$pre."\n";return($txt);}

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
    $txt.=$pre."\n";return($txt);}
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
    $txt.=$pre."\n";return($txt);}
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
    $txt.=$pre."\n";return($txt);}
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
    $txt.=$pre."\n";return($txt);}
#===============================================================================
sub inWrgMsf {
    local($pre,$fileInLoc)=@_;
    $txt =$pre."\n";
    $txt.=$pre."The software did not understand your version of the  MSF\n";
    $txt.=$pre."from the alignment you supplied.   Please make sure that\n";
    $txt.=$pre."your request is in the format described in the help text\n";
    $txt.=$pre."below, respectively on the WWW:\n";
    $txt.=$pre."http://www.embl-heidelberg.de/predictprotein/ppHelp.html\n";
    $txt.=$pre."or (more specifically):\n";
    $txt.=$pre."http://www.embl-heidelberg.de/predictprotein/\n";
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

sub inWrgSaf {
    local($pre,$fileInLoc)=@_;
    $txt =$pre."\n";
    $txt =$pre."--------------------------------------------------------\n";
    $txt.=$pre."\n";
    $txt.=$pre."The software did not understand your SAF  (Simple Align-\n";
    $txt.=$pre."ment Format).   Please make sure that your request is in\n";
    $txt.=$pre."the format described in the help text below, or on WWW: \n";
    $txt.=$pre."http://www.embl-heidelberg.de/predictprotein/ppHelp.html\n";
    $txt.=$pre."or (more specifically):\n";
    $txt.=$pre."http://www.embl-heidelberg.de/predictprotein/\n";
    $txt.=$pre."   Dexa/optin_saf.html    (type these two as one line in\n";
    $txt.=$pre."                           your browser!)\n";
    $txt.=$pre."NOTE: the most common reason for this response is an in-\n";
    $txt.=$pre."      appropriate header...\n";
    $txt.=$pre."\n";
    $txt.=$pre."In the following an example for the SAF format.\n";
    $txt.=$pre."\n";
    $txt.=$pre."--------------------------------------------------------\n";
    $txt.=$pre."\n";
    if (defined $fileInLoc){
	open(FHIN_INWRGSAF,"$fileInLoc") || 
	    return(0,"err=1","*** inWrgSaf(errCode): cannot open input file '$fileInLoc'!");
	while(<FHIN_INWRGSAF>){$txt.=$_;}close(FHIN_INWRGSAF);}
    return($txt);}

sub inWrgPirList {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."Your request was interpreted as a PIR list, however, the\n";
    $txt.=$pre."required format for that list could not be found.\n";
    $txt.=$pre."\n";
    $txt.=$pre."For details, please, see the WWW site:\n";
    $txt.=$pre."http://www.embl-heidelberg.de/predictprotein/Dexa/optin_pir.html\n";
    $txt.=$pre."\n";return($txt);}

sub inWrgCol {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."You submitted a file  containing secondary structure and\n";
    $txt.=$pre."solvent accessibility.   However, your definition of the\n";
    $txt.=$pre."column format did not quite match ours.  Sorry.  Please.\n";
    $txt.=$pre."try to spot typos or errors.\n";
    $txt.=$pre."\n";return($txt);}
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
    $txt.=$pre."http://www.embl-heidelberg.de/predictprotein/ppDoPred.html\n";
    $txt.=$pre."\n";return($txt);}
sub inWrgManual {
    local($pre)=@_;
    $txt =$pre."\n";
    $txt.=$pre."For manual use of PP the input file must be in either of\n";
    $txt.=$pre."the following formats: \n";
    $txt.=$pre."HSSP, DSSP, MSF, PIR, PIR_MUL, FASTA, FASTA_MUL, SWISS-PROT\n";
    $txt.=$pre."\n";return($txt);}

1;
