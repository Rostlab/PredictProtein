#!/usr/sbin/perl -w
#
# does the hopping on files detT-all.dat (detF-all.dat)
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# defaults

$interv= 1;			# compute histogram for every percentage point
@intervHopp= ("1","2","3","5","10"); # testing different minimal numbers
#@intervHopp= ("1"); # testing different minimal numbers

@kwdRd=      ("id1","id2","pide","psim","lali","old","ide","sim");
%ptrRd=      ('id1',"1",'id2',"2",'pide',"3",'psim',"4",'old',"10",'ide',"11",'sim',"12");
@kwdRd=     ("old","ide","sim");
#@kwdRd=     ("old");
				# note the final row will be 'nold-1' for interval 1
@kwdOutDis=  ("dist",
	      "nold","nCold","nTold","nFold","nTCold","nFCold",
	      "nide","nCide","nTide","nFide","nTCide","nFCide",
	      "nsim","nCsim","nTsim","nFsim","nTCsim","nFCsim",
	      );

$fhin="FHIN";$fhout="FHOUT";
$minDis=  -15;
$maxDis=   15;

$Lverb= 1;
$Lverb2=1;
$Lverb3=0;
				# initialise variables
if ($#ARGV<2){print"goal:   does the hopping on files detT-all.dat (detF-all.dat)\n";
	      print"usage:  'script Matrix-cross.dat detT-all.dat' (and or detF-all.dat)\n";
	      print"note:   files recognised by 'T' and 'F'\n";
	      print"        you can give many detT-tmp*\n";
	      exit;}

$fileIn=$ARGV[1];$fileOutDis="Out-hopping.tmp";
				# ------------------------------
				# read command line 
$fileTrue=$fileFalse="";
foreach $_ (@ARGV){
    if   (/^not(_?[sS]creen|_?[vV]erbose)/) {$Lverb=0;}
    elsif(/^verbose/)    {$Lverb=1;}
    elsif(/^verb2/)      {$Lverb2=1;}
    elsif(/^verb3/)      {$Lverb3=1;}
    elsif(-e $_){
	if   (/^Mat/){$fileMat=$_;}
	elsif(/T/)   {$fileTrue.= "$_".",";}
	elsif(/F/)   {$fileFalse.="$_".",";}
	else { print "*** unrecognised file $_ (^Mat, T, F)\n";
	       exit;}}
    else {print "*** unrecognised argument $_ \n";
	  exit;}}
				# ------------------------------
$#fileIn=$#mode=0;		# input files
if (defined $fileTrue) {$fileTrue=~s/,$//g;
			@tmp=split(/,/,$fileTrue);
			foreach $fileTrue (@tmp){
			    if (-e $fileTrue){push(@fileIn,$fileTrue);push(@mode,"true");}}}
$#tmp=0;
if (defined $fileFalse){$fileFalse=~s/,$//g;
			@tmp=split(/,/,$fileFalse);
			foreach $fileFalse (@tmp){
			    if (-e $fileFalse){push(@fileIn,$fileFalse);push(@mode,"false");}}}
				# ------------------------------
				# read matrix
if (! -e $fileMat || ! defined $fileMat){
    print "*** must give matrix file (Matrix-cross.dat)\n";
    exit;}
if ($Lverb){print "--- reading fileMat \t $fileMat\n";}
&open_file("$fhin", "$fileMat"); # external lib-ut.pl
%common=0;
while(<$fhin>){$_=~s/\n//g;$_=~s/^\s*|\s*$//g;
	       if (/^\# ALL/){
		   $_=~s/^.*: //g;$_=~s/,$//g;
		   @id=split(/,/,$_);
		   next if ($#id < 2);
		   foreach $id1 (@id){foreach $id2 (@id){
		       $id1Sub=substr($id1,1,4);$id2Sub=substr($id2,1,4);
		       
		       $common{"$id1Sub","$id2Sub"}=0;
#		       $common{"$id1","$id2"}=0;
		   }}}
	       next if (/^\#|^id/); # skip header
	       next if (length($_)<5); # skip empty
	       @tmp=split(/\t/,$_);foreach $tmp(@tmp){$tmp=~s/\s//g;}
	       $id1=$tmp[1];$id2=$tmp[2];$id1Sub=substr($id1,1,4);$id2Sub=substr($id2,1,4);
	       next if ((!defined $tmp[3]) || (!defined $id1) || (! defined $id2));
#	       $common{"$id1","$id2"}=$tmp[3];
				# also no chain for first
	       $common{"$id1Sub","$id2Sub"}=$tmp[3];
}close($fhin);
$#tmp=0;
print "--- after read of matrix\n";
@tmp = keys %common;

print "--- xx after keys\n";
				# set zero
foreach $des (@kwdRd){foreach $itrvl(@intervHopp){foreach $dis (-100..100){
    $des1="T"."$des";$des2="F"."$des";
    $res{"$des","$itrvl","$dis"}=
	$res{"$des1","$itrvl","$dis"}=$res{"$des2","$itrvl","$dis"}=0;}}}
				# --------------------------------------------------
				# loop over det files
$ctFound=$ctFoundTrue=$ctMissed=$ctMissedTrue=0;
foreach $itFile(1..$#fileIn){
    $fileIn=$fileIn[$itFile];
    if ($mode[$itFile] eq "true"){$Ltrue=1;}else{$Ltrue=0;}

    &open_file("$fhin", "$fileIn"); # external lib-ut.pl
    if ($Lverb){print "--- reading fileHeader \t $fileIn\n";}
    $ct=$ct1=0;
    while(<$fhin>){
	$_=~s/\n//g;
	++$ct; if ($ct>50000){++$ct1;$ct=0;printf "--- line %8d\n",$ct1*50000;}
#	++$ct; if ($ct>10000){last;}	# xx
	next if (/^\#|^NoAll|\s+\d+N|^id/); # skip header
	$_=~s/^\s*|\s*$//g;@tmp=split(/\t/,$_);foreach $tmp(@tmp){$tmp=~s/\s//g;}
	$old=$tmp[$ptrRd{"old"}]; # include only certain window of distance
	next if (($old > $maxDis)||($old<$minDis));
	$id1=$tmp[$ptrRd{"id1"}];$id2=$tmp[$ptrRd{"id2"}];
	$id1Sub=substr($id1,1,4);$id2Sub=substr($id2,1,4);
	next if (! defined $common{"$id1Sub","$id2Sub"}); # is not candidate
	if ($common{"$id1Sub","$id2Sub"}==0){	# count pairs that could have been in there
	    ++$ctMissed;if ($Ltrue){++$ctMissedTrue;}
	    next;}
				# ------------------------------
				# is hopping candidate
	++$ctFound;$numHopp=$common{"$id1Sub","$id2Sub"};if ($Ltrue){++$ctFoundTrue;}
	foreach $kwd(@kwdRd){$ptr=$ptrRd{"$kwd"};
			      $tmp{"$kwd"}=$tmp[$ptr];}
				# ------------------------------
				# compute statistics
	foreach $des (@kwdRd){
	    $dis=&fRound($tmp{"$des"});	# external lib-comp.pl
	    if ($dis>75){$dis=75;}elsif($dis<-100){$dis=-100;}
	    foreach $itrvl(@intervHopp){
		next if ($numHopp<$itrvl);
		++$res{"$des","$itrvl","$dis"};
		if ($Ltrue){$tmpDes="T"."$des";}else{$tmpDes="F"."$des";}
		++$res{"$tmpDes","$itrvl","$dis"};}}
    }close($fhin);
}				# end of loop over input files
				# ------------------------------
				# write output files
print "--- number of hopping candidates found $ctFound (ok=$ctFoundTrue)\n";
print "--- number of hoppings missed $ctMissed (ok=$ctMissedTrue)\n";

&wrtDis($fileOutDis,@kwdOutDis);

print "--- output in $fileOutDis\n";
exit;

#===============================================================================
sub wrtDis {
    local($fileOutLoc,@kwdLoc)=@_;
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrtDis                      writes histogram for distances from HSSP thresh
#       out:                    all GLOBAL
#-------------------------------------------------------------------------------
    $fhout="FHOUT_LOCAL";
    @fhLoc=("$fhout"); if ($Lverb2){push(@fhLoc,"STDOUT");}

    $tmp=$interv;$#interv=0;
    while( (100-$tmp)>=-100){
	push(@interv,(100-$tmp));$tmp+=$interv;}
				# write file
    &open_file("$fhout", ">$fileOutLoc");
				# header
    foreach $fhLoc(@fhLoc){
	if ($fhLoc eq "STDOUT"){$sep=" ";}else{$sep="\t";}
	if ($fhLoc eq "STDOUT"){$sep="\t";}else{$sep="\t";} # xx
	print $fhLoc 
	    "\# Nhopp found       = $ctFound\n",
	    "\# Nhopp found true  = $ctFoundTrue\n",
	    "\# Nhopp missed      = $ctMissed\n",
	    "\# Nhopp missed true = $ctMissedTrue\n";
	print $fhLoc "dist";
	foreach $itrvl(@intervHopp){
	    foreach $kwd(@kwdLoc){next if ($kwd =~/^dis/);
				  $des="$kwd-$itrvl";
				  print $fhLoc "$sep$des";}}
	print $fhLoc "\n";}
				# ------------------------------
				# write histogram
				# set zero cumulative stuff
    foreach $kwdLoc(@kwdLoc){next if ($kwdLoc =~/^dis/);next if ($kwdLoc !~/C/);
			     foreach $itrvl(@intervHopp){$des="$kwdLoc-$itrvl";
							 $loc{"$des"}=0;}}
    foreach $it(1..$#interv){	# loop over all distances
#	$dist=$interv[$#interv-$it+1];
	$dist=$interv[$it];
				# ignore 0 counts
	$tmp=0;foreach $itrvl(@intervHopp){$tmp+=$res{"old","$itrvl","$dist"};}
	next if ($tmp==0);
				# intermediate store and cumulative
	foreach $kwdLoc(@kwdLoc){
	    next if ($kwdLoc=~/C|^dist/);
	    $des= $kwdLoc;$des=~s/^n//g;
	    $kwdc=$kwdLoc;$kwdc=~s/^n([TF]?)(.*)$/n$1C$2/;
	    foreach $itrvl (@intervHopp){
		$tmpLoc="$kwdLoc-$itrvl";$tmpc="$kwdc-$itrvl";
		$loc{"$tmpLoc"}=$res{"$des","$itrvl","$dist"}; # simple
		$loc{"$tmpc"}+= $res{"$des","$itrvl","$dist"}; }} # cumulative
				# write
	foreach $fhLoc(@fhLoc){
	    if ($fhLoc eq "STDOUT"){$sep=" ";}else{$sep="\t";}
	    if ($fhLoc eq "STDOUT"){$sep="\t";}else{$sep="\t";} # xx
	    print $fhLoc "$dist";
	    foreach $itrvl (@intervHopp){
		foreach $kwdLoc(@kwdLoc){
		    next if ($kwdLoc =~ /^dist/);
		    $tmpLoc="$kwdLoc-$itrvl";
		    print $fhLoc "$sep",$loc{"$tmpLoc"};}}
	    print $fhLoc "\n";}
    }close($fhout); 
}				# end of wrtDis

