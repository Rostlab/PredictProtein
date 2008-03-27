#!/usr/pub/bin/perl4 -w
#----------------------------------------------------------------------
# phd2dssp
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	phd2dssp.pl phd.rdb (optional: output dir_phd dir_dssp)
#
# task:		write phd output into DSSP format
# 		
# sub here:     write_dssp_phd (file-handle-out,id-in)
# 		
# external:     read_rdb_num [lib-prot]
#
#----------------------------------------------------------------------#
#	Burkhard Rost			July,	        1994           #
#			changed:	October,      	1994           #
#			changed:	August,      	1995           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "phd2dssp";
#$script_goal      = "write phd output into DSSP format";
$script_input     = "phd.rdb (optional: output dir_phd(.rdb) dir_dssp)";

require "/home/phd/ut/perl/ctime.pl";
require "/home/phd/ut/perl/lib-prot.pl";
require "/home/phd/ut/perl/lib-ut.pl";
require "/home/phd/ut/perl/lib-comp.pl";

#------------------------------
# number of arguments ok?
#------------------------------
if ( ($ARGV[1]=~/help/)||($#ARGV<1) ) {
    print "*** ERROR: \n*** usage: \t $script_name $script_input \n";
    print "number of arguments:  \t$#ARGV \n";
    print "options:                    say 1st argument called id.rdb\n";
    print "         file_out=x,     => output file (DSSP) named x\n";
    print "         dir_phd=x,      => input= 'x/id.rdb'\n";
    print "         dir_dssp=x(out),=> output='x/id.dssp_phd'\n";
    print "         chain=A         => output file named 'idA.dssp_phd' \n";
    print "         ext_out=x       => output file named 'id.x' \n \n";
    print "input can be: one rdb file or a list of rdb files\n";
    exit;
}

#------------------------------
# defaults
#------------------------------
#$dir_dssp= "out_dssp/"; 
#$dir_dssp= "dphd_dssp/"; 
#$dir_phd=  "dphd_rdb/"; 
$dir_phd=    "";
$dir_dssp=   "";
$ext_dssp=   ".dssp_phd"; 

$file_out="unk";
$CHAIN=" ";

$fhinphd="FHINPHD"; $fhoutdssp="FHOUTDSSP";
$Lscreen=1;
@des =("No","AA","PHEL","RI_S","PACC","RI_A");

#----------------------------------------
# read input
#----------------------------------------
				# input file (phd.rdb)
$file_in= $ARGV[1]; 	        &myprt_txt("file in: \t \t $file_in"); 
$id=$file_in;$id=~s/\/.*\///g;$id=~s/\s|\n|\.rdb.*//g;

				# optional: dir_phd, dir_dssp (i.e. input and output directory)
for ($a=2;$a<=$#ARGV;++$a) {
    if ($ARGV[$a]=~/dir_phd=/) {
	$dir_phd=$ARGV[$a];$dir_phd=~s/\n|\s|unk|dir_phd=//g;
	if ($dir_phd !~ /\/$/)  {$dir_phd.="/";}  }
    elsif ($ARGV[$a]=~/dir_dssp=/) {
	$dir_dssp=$ARGV[$a];$dir_dssp=~s/\n|\s|unk|dir_dssp=//g;
	if ($dir_dssp !~ /\/$/)  {$dir_dssp.="/";}  }
    elsif ($ARGV[$a]=~/file_out=/) {
	$file_out=$ARGV[$a];$file_out=~s/\n|\s|unk|file_out=//g; }
    elsif ($ARGV[$a]=~/ext_out=/) {
	$ext_dssp=$ARGV[$a];$ext_dssp=~s/\n|\s|unk|ext_out=//g; }
    elsif ($ARGV[$a]=~/chain=/) {
	$CHAIN=$ARGV[$a];$CHAIN=~s/\n|\s|unk|chain=//g;}
}

				# change output file?
if (length($file_out)<4) {$file_out="$dir_dssp"."$id"."$ext_dssp";}
				# change input file?
if (length($dir_phd)>2)  {$tmp=$file_in;$file_in="$dir_phd"."$tmp";}
    
#------------------------------
# check existence of file
#------------------------------
if (! -e $file_in) {&myprt_empty; &myprt_txt("ERROR:\t file $file_in does not exist"); exit; }

				# ------------------------------
				# input = list?
				# ------------------------------
$#file_in=0;
if (&is_rdbf($file_in)){push(@file_in,$file_in);}
else {
    &open_file("$fhinphd", "$file_in");
    while(<$fhinphd>){$_=~s/\s|\n//g;
		      push(@file_in,$_);}
    close($fhinphd); }

#----------------------------------------------------------------------
# read phd .rdb file (i.e. the prediction)
#----------------------------------------------------------------------
foreach $file_in (@file_in) {
    if ($#file_in>1){
	$id=$file_in;$id=~s/\/.*\///g;$id=~s/\s|\n|\.rdb.*//g;
	$file_out="$dir_dssp"."$id"."$ext_dssp";}

    %rd=
	&rd_rdb_associative($file_in,"body",@des);
				# -------------------------------------------
				# store into NUM, SEQ, SEC, RISEC, ACC, RIACC
				# -------------------------------------------
    $#NUM=$#SEQ=$#SEC=$#RISEC=$#ACC=$#RIACC=0;
    foreach $des (@des) {
	if (! defined $rd{"$des","1"}) {next;}
	if    ($des eq "No") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@NUM,$rd{"$des","$ct"});++$ct;}}
	elsif ($des eq "AA") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@SEQ,$rd{"$des","$ct"});++$ct;}}
	elsif ($des eq "PHEL") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@SEC,$rd{"$des","$ct"});++$ct;}}
	elsif ($des eq "RI_S") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@RISEC,$rd{"$des","$ct"});++$ct;}}
	elsif ($des eq "PACC") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@ACC,$rd{"$des","$ct"});++$ct;}}
	elsif ($des eq "RI_A") {
	    $ct=1; while(defined $rd{"$des","$ct"}){push(@RIACC,$rd{"$des","$ct"});++$ct;}}
    }
				# convert L->' '
    foreach $it(1..$#SEC){$SEC[$it]=~s/L/ /;}
	    
#----------------------------------------------------------------------
# writing phd into DSSP format
#----------------------------------------------------------------------
    if ($Lscreen) { 
	&myprt_txt("now writing \t id=$id, chain=$CHAIN, output file '$file_out'"); }
    &open_file("$fhoutdssp", ">$file_out");
    &write_dssp_phd($fhoutdssp,$id);
    close($fhoutdssp);
}
exit;

#==========================================================================
sub write_dssp_phd {
    local ($fhout,$id_in)=@_;
    local ($it);
    $[ =1 ;
#--------------------------------------------------
#   writes DSSP format for
#   GLOBAL
#   @NUM, @SEQ, @SEC(HE ), @ACC, @RISEC, @RIACC
#--------------------------------------------------
    print $fhout "**** SECONDARY STRUCTURE DEFINITION BY THE PROGRAM DSSP, here PHD prediction\n";
    print $fhout "REFERENCE  B. ROST AND C. SANDER, PROTEINS 19 (1994) 55-72 \n";
    print $fhout "HEADER     $id_in \n";
    print $fhout "COMPND        \n";
    print $fhout "SOURCE        \n";
    print $fhout "AUTHOR        \n";
    print $fhout 
	"  \#  RESIDUE AA STRUCTURE BP1 BP2  ACC   N-H-->O  O-->H-N  N-H-->O  O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA  \n";
    if ( (! defined $CHAIN) || (length($CHAIN)!=1) ) {$CHAIN=" ";}
    for ($it=1; $it<=$#SEC; ++$it) {
	if (defined $NUM[$it]){$num=$NUM[$it];}else{$num=$it;}
	if (defined $SEQ[$it]){$seq=$SEQ[$it];}
	   else{$seq="U"; print "*** ERROR phd2dssp it=$it, SEQ not defined\n";}
	if (defined $SEC[$it]){$sec=$SEC[$it];}
	   else{$sec="U"; print "*** ERROR phd2dssp it=$it, SEC not defined\n";}
	if (defined $ACC[$it]){$acc=$ACC[$it];}
	   else{$acc="999";print "*** ERROR phd2dssp it=$it, ACC not defined\n";}
	if (defined $RISEC[$it]){$risec=$RISEC[$it];}else{$risec=0;}
	if (defined $RIACC[$it]){$riacc=$RIACC[$it];}else{$riacc=0;}
	printf $fhout 
	    " %4d %4d %1s %1s  %1s           0   0  %3d    %1d  %1d\n",
	    $num, $num, $CHAIN, $seq, $sec, $acc, $risec, $riacc;
    }
}

