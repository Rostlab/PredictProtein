#!/usr/sbin/perl -w
#----------------------------------------------------------------------
# dumb_pred_bdg
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	dumb_pred_bdg.pl *.bdghssp_rdb file
#
# task:		predict binding sites by conservation
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost			AUGUST,	        1994           #
#			changed:		,      	1994           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "dumb_pred_bdg";
$script_goal      = "predict binding sites by conservation";
$script_input     = "*.bdghssp_rdb file";
$script_opt_ar[1] = "2nd = executable";

push (@INC, "/home/rost/perl") ;
# require "ctime.pl"; require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
#
#	$date is e.g.:		Oct:14:13:06:47:1993
#	@Date is e.g.:		Oct1413:06:471993
#	&ctime(time) is e.g.:	Thu Oct 14 13:06:47 1993
#
@Date = split(' ',&ctime(time)) ; shift (@Date) ; 

#------------------------------
# number of arguments ok?
#------------------------------
if ($#ARGV < 1) {
    die "*** ERROR: \n*** usage: \t $script_name $script_input \n";
    print "number of arguments:  \t$ARGV \n";
}

#----------------------------------------
# about script
#----------------------------------------
&myprt_line; &myprt_txt("perl script to $script_goal"); &myprt_empty;
&myprt_txt("usage: \t $script_name $script_input"); &myprt_txt("optional:");
for ($it=1; $it<=$#script_opt_ar; ++$it) {
    print"--- opt $it: \t $script_opt_ar[$it] \n"; 
} &myprt_empty; 
if ( ($ARGV[1]=~/help/) || ($ARGV[1]=~/help/) ) { exit; }

#----------------------------------------
# read input
#----------------------------------------
&myprt_empty;
$file_in	= $ARGV[1]; 	&myprt_txt("file in: \t \t $file_in"); 

$opt_passed = ""; $modebdg="";
for ( $it=1; $it <= $#ARGV; ++$it ) { 
    $opt_passed .= " " . "$ARGV[$it]"; 
    if ($ARGV[$it]=~/swiss/) { $modebdg="swiss"; } 
}
&myprt_txt("options passed:"); &myprt_txt("      \t \t$opt_passed"); 
&myprt_empty; &myprt_line; &myprt_empty;

#------------------------------
# defaults
#------------------------------
$tmp=$file_in;$tmp=~s/\.bdghssp_rdb//g; if (length($modebdg)>1) {$tmp.="_$modebdg";}
$foutcons="$tmp".".pred_cons"; $fhcons="FHOUT_CONS";
$foutvar= "$tmp".".pred_var";  $fhvar= "FHOUT_VAR";
$foutprod="$tmp".".pred_prod"; $fhprod="FHOUT_PROD";

#------------------------------
# check existence of file
#------------------------------
if (! -e $file_in) {&myprt_empty; &myprt_txt("ERROR:\t file $file_in does not exist"); exit; }

#----------------------------------------
# read list
#----------------------------------------
$fhin="FILE_IN"; &open_file("$fhin", "$file_in"); 
&read_bdghssp_rdb($fhin); 

#----------------------------------------
# analyse 
#----------------------------------------
&myprt_empty; print "--- now looking for maxima \n";

$ctres=0;
for ($nue=1;$nue<=$#name;++$nue) {
    for ($mue=1;$mue<=$nres[$nue];++$mue) {
        ++$ctres; $tmprent[$ctres]=$rent{$nue,$mue};
        $tmpvar[$ctres]=$var{$nue,$mue}; $tmpcons[$ctres]=$cons{$nue,$mue};
        $tmpprod[$ctres]=($rent{$nue,$mue}*(100-$var{$nue,$mue}));
    } 
}
$nrestot=$ctres; print "--- total number of residues =$nrestot,\n"; $fracbdg=($nrestot/10);
#----------
# sort
@tsvar=sort(@tmpvar); @tscons=sort(@tmpcons); @tsrent=sort(@tmprent); @tsprod=sort(@tmpprod); 
#----------
# cut offs
$cutvar=$tsvar[$nrestot-$fracbdg];   $cutcons=$tscons[$nrestot-$fracbdg];
$cutrent=$tsrent[$nrestot-$fracbdg]; $cutprod=$tsprod[$nrestot-$fracbdg];
print "--- cut_off values var:$cutvar,cons=$cutcons,rent=$cutrent,prod=$cutprod\n";

#--------------------------------------------------
#  now do the prediction
#--------------------------------------------------
&open_file("$fhcons", ">$foutcons"); 
print $fhcons "***\n","*** prediction of binding sites by:\n";
print $fhcons "*** conservation weight > max of 1/10 \% of residues\n","***\n";
printf $fhcons "num  %3d\n",$#name;

&open_file("$fhvar", ">$foutvar");
print $fhvar "***\n","*** prediction of binding sites by:\n";
print $fhvar "*** variability > max of 1/10 \% of residues\n","***\n";
printf $fhvar "num  %3d\n",$#name;

&open_file("$fhprod", ">$foutprod");
print $fhprod "***\n","*** prediction of binding sites by:\n";
print $fhprod "*** variability * relative entropy > max of 1/10 \% of residues\n","***\n";
printf $fhprod "num  %3d\n",$#name;

for ($nue=1;$nue<=$#name;++$nue) {
    print "--- predict $name[$nue] ($nres[$nue])\n";
    $#tmpvar=0;$#tmprent=0;$#tmpcons=0;$#tmpprod=0;
    for ($mue=1;$mue<=$nres[$nue];++$mue) {
        $tmpvar[$mue]=(100-$var{$nue,$mue}); $tmpcons[$mue]=$cons{$nue,$mue};
        $tmpprod[$mue]=($rent{$nue,$mue}*(100-$var{$nue,$mue})); 
    }

#   ----------
#   sort
    $#tsvar=0;$#tsrent=0;$#tscons=0; $#tsprod=0;
    @tsvar=sort numerically (@tmpvar); @tscons=sort numerically (@tmpcons); 
    @tsprod=sort numerically (@tmpprod);

#   ----------
#   cut offs (local)
    $tmp=$nres[$nue]-($nres[$nue]/10);
    $cutvar_loc=$tsvar[$tmp];   $cutcons_loc=$tscons[$tmp];
    $cutrent_loc=$tsrent[$tmp]; $cutprod_loc=$tsprod[$tmp];
    print "--- cut_off values var:$cutvar_loc,cons=$cutcons_loc,prod=$cutprod_loc\n";

    $seq="x"; $sec="x"; $bdg="x"; $prd_cons="x"; $prd_var="x"; $prd_prod="x";
    for ($mue=1;$mue<=$nres[$nue];++$mue) {
        $seq.=$aa{$nue,$mue};
        $sec.=$sec{$nue,$mue};
        if ($modebdg=~/swiss/) { $tmp=$sbdg{$nue,$mue}; } else {$tmp=$hbdg{$nue,$mue};}
	if ($tmp) {$bdg.="1";}else{$bdg.=" ";}

        if ($cons{$nue,$mue}>=$cutcons_loc) { $prd_cons.="1";} else {$prd_cons.=" "; }
        if ((100-$var{$nue,$mue}) >=$cutvar_loc)  { $prd_var.="1"; } else {$prd_var.=" ";}
        if (((100-$var{$nue,$mue})*$rent{$nue,$mue})>=$cutprod_loc) {$prd_prod.="1";} 
	else {$prd_prod.=" ";}
    } 
    $seq=~s/^x//; $sec=~s/^x//; $bdg=~s/^x//; 
    $prd_cons=~s/^x//; $prd_var=~s/^x//; $prd_prod=~s/^x//; 

    if ($nres[$nue] > 0) {
#       ------------------------------
#       write prediction
#       ------------------------------
	printf $fhcons "\# 1 %-6s %5d\n", $name[$nue], $nres[$nue];
	&write80_data_prepdata($seq,$sec,$bdg,$prd_cons);
	&write80_data_preptext("AA ", "SS ", "Obs", "Prd"); 
	&write80_data_do("$fhcons"); 

	printf $fhvar "\# 1 %-6s %5d\n", $name[$nue], $nres[$nue];
	&write80_data_prepdata($seq,$sec,$bdg,$prd_var);
	&write80_data_preptext("AA ", "SS ", "Obs", "Prd"); 
	&write80_data_do("$fhvar"); 

	printf $fhprod "\# 1 %-6s %5d\n", $name[$nue], $nres[$nue];
	&write80_data_prepdata($seq,$sec,$bdg,$prd_prod);
	&write80_data_preptext("AA ", "SS ", "Obs", "Prd"); 
	&write80_data_do("$fhprod"); 
    }
}
print $fhcons "END\n"; close($fhcons); print $fhvar "END\n"; close($fhvar);
print $fhprod "END\n"; close($fhprod);

&myprt_empty; &myprt_line; &myprt_txt(" $script_name has ended fine .. -:\)"); 
&myprt_empty; &myprt_txt(" output cons:$foutcons, var:$foutvar, prod:$foutprod "); 

exit;

#==========================================================================
sub read_bdghssp_rdb {
    local ($fhin) = @_ ;
    local ($ctrl,$ctprot,$ctres,$tmp,$t1,$t2,$t3,$Lok,@atmp);

#--------------------------------------------------
#   reads bdghssp_rdb files (extracted from A&C)
#   GLOBAL
#   associative {number_of_protein,number_of_residue}: 
#      %aa,%sec,%acc,%var,%sbdg,%hbdg,%ndel,%nins,%rent,%cons
#   normal: @name, @nres
#--------------------------------------------------

    $ctrl=0; $ctprot=0;
    while ( <$fhin> ) {
	$tmp=$_;$tmp=~s/\n//g;
	if ( (length($tmp)>0)&&($tmp!~/\# /) ) { ++$ctrl; $Lok=1;} else {$Lok=0;}

#       ------------------------------
#       get PDBID
#       ------------------------------
	if ($tmp=~/\# PDBID /) { # 
	    ++$ctprot;
	    $tmp=~s/\# PDBID *//g; ($t1,$t2,$t3)=split(/ +/,$tmp);$t1=~s/\s//g;$t3=~s/\s//g;
	    $name[$ctprot]=$t1; $nres[$ctprot]=$t3;
	    $ctres=0; print "--- $ctprot = prot:$t1, nres=$t3\n";
	}
	
#       ------------------------------
#       residue info
#       ------------------------------
	if ( $Lok && ($ctrl>2) ) {
	    ++$ctres;
	    @atmp=split(/\t/,$tmp); 
	    $aa{$ctprot,$ctres}=$atmp[1];   $sec{$ctprot,$ctres}=$atmp[3];
	    $acc{$ctprot,$ctres}=$atmp[4];  $var{$ctprot,$ctres}=$atmp[5];
	    $sbdg{$ctprot,$ctres}=$atmp[6]; $hbdg{$ctprot,$ctres}=$atmp[7];
	    $ndel{$ctprot,$ctres}=$atmp[29];$nins{$ctprot,$ctres}=$atmp[30];
	    $rent{$ctprot,$ctres}=$atmp[31];$cons{$ctprot,$ctres}=$atmp[32];
	}
	
    }
    close($fhin);
}
1;
