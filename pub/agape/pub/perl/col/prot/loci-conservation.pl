#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads file pairs and file lociTrans, checks evolutionary conservation of location\n";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	1998	       #
#	Burkhard Rost		rost@EMBL-Heidelberg.DE			       #
#	Wilckensstr. 15		http://www.embl-heidelberg.de/~rost/	       #
#	D-69120 Heidelberg						       #
#				version 0.1   	Oct,    	1998	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$sep="\t";
$add="";
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName pairs.rdb lociTrans.rdb'  (note: 'pairs' and 'trans' recognised)\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",       "";
    printf "%5s %-15s=%-20s %-s\n","","add",      "x",       "add to column names (note: '-add' added)";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";
$fhout="FHOUT"; $fhoutNot="FHOUT_NOT"; $fhoutCons="FHOUT_CONS";
$#fileIn=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^add=(.*)$/)            { $add=    "-".$1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); }
    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g; $tmp=~s/\..*$//g; $tmp.=".dat";
    $fileOut=    "Out-".    $tmp;
    $fileOutNot= "OutNot-". $tmp;
    $fileOutCons="OutCons-".$tmp;
    $fileOutHis= "his-".    $tmp; }
else {
    $fileOutNot= $fileOut."-not";
    $fileOutCons=$fileOut."-cons";
    $fileOutHis= $fileOut."-his"; }


				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{"$kwd"})==0 || $par{"$kwd"} eq "unk" );
    $par{"$kwd"}.="/"          if ($par{"$kwd"} !~ /\/$/);}


				# ------------------------------
				# (1) digest file (list?)
				# ------------------------------
if    ($fileIn[2] =~ /pairs/i) {
    $filePairs=$fileIn[2]; 
    $fileTrans=$fileIn[1]; }
elsif ($fileIn[1] =~ /trans/i) {
    $filePairs=$fileIn[1]; 
    $fileTrans=$fileIn[2]; }
else {
    $filePairs=$fileIn[1]; 
    $fileTrans=$fileIn[2]; }

				# ------------------------------
				# (2) read trans
				# ------------------------------
print "--- $scrName: working on '$fileTrans'\n";
open("$fhin","$fileTrans") || die "*** $scrName ERROR opening file $fileTrans";

$#idTrans=0; undef %trans;
while (<$fhin>) {
    $_=~s/\n//g;
    next if ($_=~/^\#/);	# skip comments
    next if ($_=~/^\s*(lineNo|5[NS])/); # skip names, formats

    $_=~s/^\s*|\s*$//g;
    @tmp=split(/[\s\t]+/,$_);   foreach $tmp (@tmp){$tmp=~s/\s//g;}

    next if ($tmp[3] eq "unk");	# skip unknown locations

    push(@idTrans,$tmp[2]);
    $trans{$tmp[2]}=$tmp[3];	# tmp[2]=id, tmp[3]=location
				# => $trans{$id}=location
} close($fhin);

				# ------------------------------
				# (3) read pairs
				# ------------------------------
print "--- $scrName: working on '$filePairs'\n";
open("$fhin","$filePairs") || die "*** $scrName ERROR opening file $filePairs";

undef %pairs;
while (<$fhin>) {
    $_=~s/\n//g;
    $_=~s/^.*\///g;

    next if ($_=~/^\#/);	# skip comments
    next if ($_=~/^id/); # skip names

    @tmp=split(/[\s\t]+/,$_);  foreach $tmp (@tmp){$tmp=~s/\s//g;}
    
    $id1=$tmp[1];
    $id2=$tmp[3];
    $dis=$tmp[4];
				# skip if no location given
    next if (! defined $trans{$id1});

    $pairs{$id1}=      1;
    $pairs{$id1,"id2"}=$id2;
    $pairs{$id1,"dis"}=$dis;
} close($fhin);

				# --------------------------------------------------
				# (3) compile evolutionary conservation
				# --------------------------------------------------
open("$fhout",">$fileOut")         || warn "*** $scrName ERROR creating file out=$fileOut";
printf $fhout    
    "%-s".$sep."%-s".$sep."%6s".$sep."%-s".$sep."%-s".$sep."%-s\n",
    "id1","id2","dis","loci1","loci2","cons?";

open("$fhoutNot",">$fileOutNot")   || warn "*** $scrName ERROR creating file not=$fileOutNot";
printf $fhoutNot
    "%-s".$sep."%-s".$sep."%6s".$sep."%-s".$sep."%-s\n",
    "id1","id2","dis","loci1","loci2";

open("$fhoutCons",">$fileOutCons") || warn "*** $scrName ERROR creating file cons=$fileOutCons";
printf $fhoutCons
    "%-s".$sep."%-s".$sep."%6s".$sep."%-s".$sep."%-s\n",
    "id1","id2","dis","loci1","loci2";

$ctAll=$ctCons=0;
				# $his{"Ncons",$dis} = number of conserved for $dis=-50..100
				# $his{"Nnot",$dis}  = number of not conserved for $dis=-50..100
undef %his;

foreach $id1 (@idTrans) {
				# skip if missing
    next if (! defined $pairs{$id1});
    next if (! defined $pairs{$id1,"id2"});

    @id2=split(/,/,$pairs{$id1,"id2"});
    @dis=split(/,/,$pairs{$id1,"dis"});

    next if ($#id2 < 1);

    foreach $it (1..$#id2) {
				# skip if location for 2nd not given
	next if (! defined $trans{$id2[$it]});

				# conserved?
	$LisConserved=1;
	$LisConserved=0         if ($trans{$id1} ne $trans{$id2[$it]});

				# statistics
	++$ctAll;
	$dis=int($dis[$it]);
	++$his{"N",$dis};
	if ($LisConserved) {
	    ++$ctCons;
	    ++$his{"Ncons",$dis}; }
	else {
	    ++$his{"Nnot",$dis};}

				# write '
	$tmpWrt=  sprintf("%-s".$sep."%-s".$sep."%6d",   $id1,$id2[$it],$dis[$it]);
	$tmpWrt.= sprintf($sep."%-s".$sep."%-s",         $trans{$id1},$trans{$id2[$it]});

	print $fhoutNot   $tmpWrt,"\n" if (! $LisConserved);
	print $fhoutCons  $tmpWrt,"\n" if ($LisConserved);

	$tmpWrt.= sprintf($sep."%4d\n",                  $LisConserved);
#	print $tmpWrt;
	print $fhout $tmpWrt;
    }
}
close($fhout);close($fhoutCons);close($fhoutNot);
$ctNot=$ctAll-$ctCons;

				# --------------------------------------------------
				# write histogram
				# --------------------------------------------------
open("$fhout",">$fileOutHis")      || warn "*** $scrName ERROR creating fileOutHis=$fileOutHis";
				# names
printf $fhout    
    "%4s".$sep."%6s".$sep."%6s".$sep."%8s".$sep."%8s".$sep.
    "%8s".$sep."%8s".$sep."%8s".$sep."%8s".$sep.
    "%8s".$sep."%8s".$sep."%8s".$sep."%8s"."\n",
				# numbers (N=simple, NC=cumulative)
    "dis","Ncons".$add,"Nnot".$add,"NCcons".$add,"NCnot".$add,
				# percentages of all
    "Pcons/all".$add,"Pnot/all".$add,"PCcons/all".$add,"PCnot/all".$add,
				# percentages of cons resp not
    "PCcons/cons".$add,"PCnot/not".$add,
				# overall accuracy
    "Pok/Ncons+Nnot".$add,"PCok/NCcons+NCnot".$add;

				# ------------------------------
				# data
				# ------------------------------
$NCcons=$NCnot=$NCall=0;
for ($dis=100; $dis>=-50; $dis-=1) {
				# --------------------
				# skip non occurring
    next if (! defined $his{"N",$dis});
				# --------------------
				# cumulative numbers
    $NCall+= $his{"N",$dis}     if (defined $his{"N",$dis});
    $NCcons+=$his{"Ncons",$dis} if (defined $his{"Ncons",$dis});
    $NCnot+= $his{"Nnot",$dis}  if (defined $his{"Nnot",$dis});

				# --------------------
				# prepare write
    $wrtNcons=$wrtNnot=$wrtNCcons=$wrtNCnot="";
    $wrtPconsAll=$wrtPnotAll=$wrtPCconsAll=$wrtPCnotAll=
	$wrtPCconsCons=$wrtPCnotNot=$wrtPok=$wrtPCok="";
				# conserved simple
    if (defined $his{"Ncons",$dis}) {
	$wrtNcons=     sprintf ("%6d",$his{"Ncons",$dis});
	$wrtPconsAll=  sprintf ("%8.1f",100*($his{"Ncons",$dis}/$ctAll));
	$wrtPok=       sprintf ("%8.1f",
				100*($his{"Ncons",$dis}/($his{"Ncons",$dis}+$his{"Nnot",$dis})))
	    if (defined $his{"Nnot",$dis});
	$wrtPok=       sprintf ("%8.1f",100)
	    if (! defined $his{"Nnot",$dis});}
				
				# not cons simple
    if (defined $his{"Nnot",$dis}) {
	$wrtNnot=      sprintf ("%6d",$his{"Nnot",$dis});
	$wrtPnotAll=   sprintf ("%8.1f",100*($his{"Nnot",$dis}/$ctAll));}
				# conserved cumulative
    if ($NCcons > 0) {
	$wrtNCcons=    sprintf ("%6d",  $NCcons);
	$wrtPCconsAll= sprintf ("%8.1f",100*($NCcons/$ctAll));
	$wrtPCconsCons=sprintf ("%8.1f",100*($NCcons/$ctCons));
	$wrtPCok=      sprintf ("%8.1f",100*($NCcons/($NCcons+$NCnot)));}
				# not cons cumulative
    if ($NCnot  > 0) {
	$wrtNCnot=     sprintf ("%6d",$NCnot);
	$wrtPCnotAll=  sprintf ("%8.1f",100*($NCnot/$ctAll));
	$wrtPCnotNot=  sprintf ("%8.1f",100*($NCnot/$ctNot)); }

				# --------------------
				# write
    $tmpWrt=  sprintf ("%4d".$sep."%6s".$sep."%6s".$sep."%6s".$sep."%6s",
		       $dis,$wrtNcons,$wrtNnot,$wrtNCcons,$wrtNCnot);

				# percentages
    $tmpWrt.= sprintf ($sep."%8s".$sep."%8s".$sep."%8s".$sep."%8s".
		       $sep."%8s".$sep."%8s".$sep."%8s".$sep."%8s",
				# perc of all
		       $wrtPconsAll,$wrtPnotAll,$wrtPCconsAll,$wrtPCnotAll,
				# perc of cons or not
		       $wrtPCconsCons,$wrtPCnotNot,
				# perc correct and cumulative
		       $wrtPok,$wrtPCok);
    print $fhout $tmpWrt,"\n";
    $tmpWrt=~s/$sep/,/g;
    print "xx:$tmpWrt\n";
}
close($fhout);


print  "--- output in   $fileOut\n"     if (-e $fileOut);
print  "---        cons $fileOutCons\n" if (-e $fileOutCons);
print  "---        not  $fileOutNot\n"  if (-e $fileOutNot);
print  "---        his  $fileOutHis\n"  if (-e $fileOutHis);
printf "--- total pairs     %6d\n",$ctAll;
printf "--- conserved pairs %6d\n",$ctCons;
printf "--- percentage cons %8.1f\n",100*($ctCons/$ctAll);
exit;


#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

#===============================================================================
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

