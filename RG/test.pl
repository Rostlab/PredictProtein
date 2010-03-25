#!/usr/bin/perl

use lib  '.';
use predictPP;
			       ($Lok,$err,$msg,$parBlastDb)=
&predictPP::modInterpret ("/nfs/data5/users/ppuser/server/scr/tst/tdisis2","tdisis2","/dev/null","/nfs/data5/users/ppuser/server/work","/dev/null",
	       "/dev/null",1,0,0,0);

print $msg,"\n";
print $job{"out"};
#  &modInterpret($File_name,$filePID,$fileHtmlTmp,$fileHtmlToc,
		#   $envPP{"dir_work"},$fhOut,$fhTrace,$Debug,$envPP{"parPhdMinLen"},
		#   $envPP{"parMaxhomMaxNres"},$envPP{"parMaxhomMaxACGT"});

#sub modInterpret {
#    local($fileInLoc,$fileJobIdLoc,$fileHtmlTmp,$fileHtmlToc,$dirWorkLoc,$fhOutSbr,$fhErrSbr,
#	  $LdebugLoc,$paraMinLenLoc,$paraMaxLenLoc,$paraGeneLoc) = @_ ;
#    local($sbr,$fhin,$tmp,$Lok,$msg,$msgRet,$seq_char_per_line,$name,$format,%tmp,
#	  @tmp,$modeLoc,$LokWrt,$fileOut,$errn,$fileOutGuide,$fileOutOther);
#    $[ =1 ;
