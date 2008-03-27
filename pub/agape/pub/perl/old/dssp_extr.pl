#!/usr/bin/perl -w
##!/usr/sbin/perl 
#----------------------------------------------------------------------
# read_dssp
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	read_dssp.pl file.DSSP
#
# task:		reads some columns from DSSP files
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost			May,	        1994           #
#			changed:		,      	1994           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "read_dssp";
$script_goal      = "reads some columns from DSSP files";
$script_input     = "file.DSSP";
$script_opt_ar[1] = "note: chain by  : file.dssp_x_A";
$script_opt_ar[2] = "residue range   : give as n1-n2 ";
$script_opt_ar[3] = "columns, default: no_chain_aa_acc_ss";



#----------------------------------------
# about script
#----------------------------------------
if ($#ARGV < 1) {&myprt_line; &myprt_txt("perl script to $script_goal"); &myprt_empty;
		 &myprt_txt("usage: \t $script_name $script_input"); &myprt_txt("optional:");
		 for ($it=1; $it<=$#script_opt_ar; ++$it) {
		     print"--- opt $it: \t $script_opt_ar[$it] \n"; 
		 } &myprt_empty; 
		 exit;}

#----------------------------------------
# read input
#----------------------------------------
$Lscreen=1;
foreach $_(@ARGV){
    if (/^notScreen|^not_screen/){$Lscreen=0;}}

$file_in	= $ARGV[1]; 	
$fileOut=$file_in."_out"; 

$opt_passed = "";for ( $it=1; $it <= $#ARGV; ++$it ) { $opt_passed .= " " . "$ARGV[$it]"; }

if ($Lscreen){&myprt_empty;&myprt_txt("file in: \t \t $file_in");
	      &myprt_txt("options passed: \t $opt_passed"); }

$ireadbeg=1;$ireadend=10000;
if ( $opt_passed =~ /-*\d+-+\d+/ ) {
    $lreadall = 0;
    $tmp = $opt_passed; 
    $ireadbeg = $tmp; $ireadbeg =~ s/[^-]* (-*\d+)-(-*\d+).*/$1/g;
    $ireadend = $tmp; $ireadend =~ s/[^-]* (-*\d+)-(-*\d+).*/$2/g;}
else {$lreadall = 1;}
if ( ($ireadend-$ireadbeg+1)<10 ) {
    $ctend=($ireadend-$ireadbeg+1);}
else {$ctend=10;}

if ( $opt_passed =~ / no| chain| aa| acc| ss/ ) {
    $colout="";
    if ($opt_passed =~ / no\W/)    { $colout.="no_"; }
    if ($opt_passed =~ / chain/) { $colout.="chain_"; }
    if ($opt_passed =~ / aa/)    { $colout.="aa_"; }
    if ($opt_passed =~ / ss/)    { $colout.="ss_"; }
    if ($opt_passed =~ / acc/)   { $colout.="acc_"; }}
else {$colout="no_chain_aa_ss_acc_";}

foreach $_(@ARGV){if (/^fileOut=/){ $_=~s/^fileOut=//g;$fileOut=$_;}}

#------------------------------
# check chain
#------------------------------
if ( $file_in =~ /_[A-Za-z0-9]$/ ) {
    $tmp=$file_in; $tmp=~s/.*_(.)/$1/g; 
    $file_in=~s/(.*)_.$/$1/g;
    $chain = $tmp; }
else {
    $chain = "*";}

#------------------------------
# check existence of file
#------------------------------
if ( ! -e $file_in ) {
    &myprt_empty; &myprt_txt("ERROR: \t file $file_in does not exist"); exit;
}

#----------------------------------------
# read list
#----------------------------------------
&open_file("FILE_IN", "$file_in");

while ( <FILE_IN> ) {
    last if ( /^  \#  RESIDUE/ );
}
$prevchain="x"; $actchain="x"; $tmp2seq=""; $ct=0; $lhomodimer=0;
while ( <FILE_IN> ) {
    $tmpres=substr($_,6,5);$tmpres=~s/\s//g;$tmpchain=substr($_,12,1);$tmpaa=substr($_,14,1);
    if ( ($tmpchain ne $actchain) && ($tmpaa ne "!") ) { 
	$prevchain=$actchain; $actchain =$tmpchain; $ct=0; $tmp2seq="";}
    if (! $lreadall ) {
	if ( ($chain eq "*") && ($tmpres>=$ireadbeg) && ($tmpres<=$ireadend) ) {
	    $lwrite=1;}
	elsif ( ($chain eq $tmpchain)&&($tmpres>=$ireadbeg)&&($tmpres<=$ireadend) ) {
	    $lwrite=1;}
	else {$lwrite=0;}}
    else {
	if ( $chain eq "*" ) {
	    $lwrite=1;}
	elsif ($chain eq $tmpchain) {
	    $lwrite=1;}
	else {$lwrite=0;}}

    if ( $lwrite && ($chain eq "*") ) {
	++$ct;
	if ($ct<$ctend) { 
	    $tmp2seq.=$tmpaa; }
	elsif (($ct==$ctend)&&($#Aaa>($ctend+1))) {
	    $tmp2seq.=$tmpaa; $tmpprev="";
	    for ($i=1;$i<=$ctend;++$i) { $tmpprev.=$Aaa[$i]; }

#	    print "x.x 1:$tmpprev\n";
#	    print "x.x 2:$tmp2seq\n"; 
	    if ($tmpprev =~ $tmp2seq) { 
		$lhomodimer=1; $lwrite=0; }
	    else {$lhomodimer=0; }}
    }

    if ($lwrite && !$lhomodimer) {
	$tmpss =substr($_,17,1);
	$tmpacc=substr($_,36,3);
	if ($colout =~ /no_/ )    { push(@Ares,$tmpres); }
	if ($colout =~ /chain_/ ) { push(@Achain,$tmpchain); }
	if ($colout =~ /aa_/ )    { push(@Aaa,$tmpaa); }
	if ($colout =~ /ss_/ )    { push(@Ass,$tmpss); }
	if ($colout =~ /acc_/ )   { push(@Aacc,$tmpacc); }
    } 
}
close(FILE_IN);

$lwrite=1;
if ($lwrite && $Lscreen) {
    if ($lhomodimer) {$iend=$#Ares-$ctend+1;}
    else {
	($iend,$pos)=&get_max($#Ares,$#Achain,$#Aaa,$#Ass,$#Aacc);}

    for ($i=1;$i<=$iend;++$i) {
	if ($colout =~ /no_/ )    { print "$Ares[$i],"; }
	if ($colout =~ /chain_/ ) { print "$Achain[$i],"; }
	if ($colout =~ /aa_/ )    { print "$Aaa[$i],"; }
	if ($colout =~ /ss_/ )    { print "$Ass[$i],"; }
	if ($colout =~ /acc_/ )   { print "$Aacc[$i],"; }
	print "\n";}
} 

if ($fileOut=~/^\/data/){$fileOut=~s/^.*\///g;}
if    ($colout=~ /^aa_/){&open_file("FHOUT",">$fileOut");$aax="";foreach $aa(@Aaa){$aax.=$aa;}
			 for ($it=1;$it<=length($aax);$it+=50){
			     $tmp=substr($aax,$it,50);print FHOUT "$tmp\n";}close(FHOUT);}
elsif ($colout=~ /^ss_/){&open_file("FHOUT",">$fileOut");$ssx="";foreach $ss(@Ass){$ssx.=$ss;}
			 for ($it=1;$it<=length($ssx);$it+=50){
			     $tmp=substr($ssx,$it,50);print FHOUT "$tmp\n";}close(FHOUT);}
print "x.x colout=$colout,\n";
print "x.x Ass='";foreach $x(@Ass){print"$x";}print"'\n";
if ($Lscreen){ &myprt_txt(" $script_name has ended fine .. -:\)"); }

if (-e $fileOut){print "--- $script_name: output in '$fileOut'\n";}

exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub get_max { $[=1;local($ct,$pos,$max);$max=-1000000;$ct=$pos=0; 
#----------------------------------------------------------------------
#   get_max                     returns the maximum of all elements of @in
#       in:                     @in
#       out:                    returned $max,$pos (position of maximum)
#----------------------------------------------------------------------
	      foreach $_(@_){if(defined $_){
		  ++$ct; 
		  if($_>$max){$max=$_;$pos=$ct;}}}
	      return ($max,$pos); } # end of get_max


#==============================================================================
sub myprt_empty {
    local($fhx)=@_;
#   myprt_empty                 writes line with '--- \n'
    $fhx="STDOUT" if (! defined $fhx);print $fhx "--- \n"; 
}				# end of myprt_empty

#==============================================================================
sub myprt_txt  {
    local($tmp,$fhx)=@_; 
#-------------------------------------------------------------------------------
#   myprt_txt                   adds '---' and '\n' for writing text
#-------------------------------------------------------------------------------
    $fhx="STDOUT" if(! defined $fhx);
    print $fhx "--- $tmp \n"; 
}				# end of myprt_txt

#==============================================================================
sub open_file {
    local ($file_handle,$file_name,$log_file) = @_ ;
    local ($temp_name) ;
#-------------------------------------------------------------------------------
#   open_file                  opens file, writes warning asf
#-------------------------------------------------------------------------------
    $temp_name = $file_name ;
    $temp_name =~ s/^>>|^>//g ;
    if ( ($file_name =~ /^>>/ ) && ( ! -e $temp_name ) ) {
	print "*** INFO (open_file): append file=$temp_name, does not exist-> create it\n" ;
	open ($file_handle, ">$temp_name") || ( do {
	    warn "***\t Cannot create new file: $temp_name\n" ;
	    if ( $log_file ) {
		print $log_file "***\t Cannot create new file: $temp_name\n" ;}
	    return (0);
	} );
	close ("$file_handle") ;}
  
    open ($file_handle, "$file_name") || ( do {
	warn "*** ERROR lib-br:open_file: Cannot open file '$file_name'\n" ;
	if ( $log_file ) {
	    print $log_file "*** lib-br:open_file: Cannot create new file '$file_name'\n" ;}
	return(0);
    } );
    return(1);
}				# end of open_file



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;
