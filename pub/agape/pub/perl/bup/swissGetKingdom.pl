#!/usr/sbin/perl -w
#
# goal:   finds all species for given kingdom (in SWISS-PROT)
# usage:  'script kingdom speclist.txt'
#
$[ =1 ;
				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
# require "ctime.pl"; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
if ($#ARGV<1){print "goal:   finds all species for given kingdom (in SWISS-PROT)\n";
	      print "usage:  'script kingdom' (all|euka|proka|archae|virus)\n";
	      print "output: flat file (listing all species)\n";
	      print "option: spec=x     (def: /data/swissprot/speclist.txt)\n";
	      print "        dir=x      (directory of swissprot)\n";
	      print "        fileOutSpec=x  (flat file default 'Out-swissKing.tmp')\n";
	      print "        fileOutId=x    (flat file default 'Out-swissKingId.tmp')\n";
	      print "        doId=1     (compile list of id's)\n";
	      print "        verbose \n";
	      exit;}

$fhout="FHOUT_swissGetKingdom";$fhin="FHIN_swissGetKingdom";
$Lscreen=1;			# write output onto screen?
$par{"speclist"}="/data/swissprot/speclist.txt";
$par{"speclist"}="speclist.txt";
$par{"doId"}=0;
$par{"doId"}=1;

				# ------------------------------
				# read command line
$swissKingdom=$ARGV[1];		# allowed: all,euka,proka,virus,archae
foreach $it (2..$#ARGV){
    if ($ARGV[$it]=~/^dir=/){	# keyword (swissprot directory)
	$tmp=$ARGV[$it];$tmp=~s/^dir=//g;$par{"dir"}=&complete_dir($tmp);} # external lib-ut.pl
    elsif ($ARGV[$it]=~/^verbose/){
	$Lscreen=1;}
    elsif ($ARGV[$it]=~/^fileOutSpec=|^fileOut=/){ # output file name
	$tmp=$ARGV[$it];$tmp=~s/^fileOut.*=//g;$par{"fileOutSpec"}=$tmp;}
    elsif ($ARGV[$it]=~/^fileOutId=/){ # output file name
	$tmp=$ARGV[$it];$tmp=~s/^fileOutId=//g;$par{"fileOutId"}=$tmp;}
    elsif ($ARGV[$it]=~/^spec.*=/){ # output file name
	$tmp=$ARGV[$it];$tmp=~s/^spec.*=//g;$par{"speclist"}=$tmp;}
    elsif ($ARGV[$it]=~/^doId=/){ # output file name
	$tmp=$ARGV[$it];$tmp=~s/^doId=//g;$par{"doId"}=$tmp;}
    elsif ($ARGV[$it]=~/^doId/){ # output file name
	$tmp=$ARGV[$it];$par{"doId"}=1;}
    else {
	print "*** ERROR script swissGetKingdom: unrecognised command line arg=$ARGV[$it],\n";
	exit;}}
				# ------------------------------
                                # process input
if ($swissKingdom !~ /^(all|euka|proka|archae|virus)/){
    print "*** ERROR script swissGetKingdom: give one of the following as first argument:\n";
    print "***                               all|euka|proka|archae|virus\n";
    exit;}
foreach $des ("fileOutSpec","fileOutId"){
    if (! defined $par{"$des"}){
	$desOut=$des;$desOut=~s/fileOut/swiss/;
	$par{"$des"}="Out-"."$desOut".$swissKingdom.".tmp";}}

$fileOutSpec=$par{"fileOutSpec"};$fileOutId=$par{"fileOutId"};
if (!defined $par{"dir"}){
    $par{"dir"}="/data/swissprot/";}
if (! -e $par{"speclist"}){	# append directory
    if (length($par{"dir"})>0){$par{"dir"}=&complete_dir($par{"dir"});
			       $par{"speclist"}=$par{"dir"}.$par{"speclist"};}}
if (! -e $par{"speclist"}){	# still not: exit
    print "*** ERROR script swissGetKingdom: file with speclist not found\n";
    print "***                               def=/data/swissprot/speclist.txt\n";
    exit;}
if ($Lscreen){
    print 
	"--- end of ini settings:\n","--- file out: \t '$fileOutSpec,$fileOutId'\n",
	"--- dirSwiss: \t '",$par{"dir"},"'\n","--- kingdom: \t '$swissKingdom'\n",
	"--- specList: \t '",$par{"speclist"},"'\n";}

				# ------------------------------
				# now do for list
$#specNames=0;
@specNames=
    &swissGetKingdom($par{"speclist"},$swissKingdom); # external lib-prot.pl
				# ------------------------------
				# output file (flat list)
&open_file("$fhout", ">$fileOutSpec");
foreach $spec (@specNames){$spec=~s/\s//g;
			   print $fhout "$spec\n";
			   if ($Lscreen){print "$spec\n";}}close($fhout);
				# ------------------------------
				# compile ids
if ($par{"doId"}){
                                # sort alphabetically
    foreach $tmpLetter ("a".."z"){$specNames{"$tmpLetter"}="";
				  foreach $spec (@specNames){
				      if (substr($spec,1,1) ne $tmpLetter){
					  next;}
				      $specNames{"$tmpLetter"}.="$spec".",";}
				  $specNames{"$tmpLetter"}=~s/,$//g;}
				# output file: ids (flat list)
    $dir=$par{"dir"}."current/";
    foreach $tmpLetter ("a".."z"){	# loop over all dirs /data/swissprot/current/[a-z]
	$dirTmp="$dir"."$tmpLetter"."/";
	$#tmpFile=0;
	open($fhin,"find $dirTmp -print |");
	while (<$fhin>){$_=~s/\s//g;
			if (-e $_){
			    push(@tmpFile,$_);}}close($fhin);
	@tmpSpec=split(/,/,$specNames{"$tmpLetter"}); # get species to read
	foreach $tmpFile (@tmpFile){
	    foreach $spec (@tmpSpec){ # for all species
		if ($tmpFile =~/$spec/){
		    push(@fin,$tmpFile);
		    last;}}}}
    &open_file("$fhout", ">$fileOutId");
    foreach $id (@fin){$id=~s/\s//g;
		       print $fhout "$id\n";}close($fhout);
}

if ($Lscreen){$Lok=0;
	      if (-e $fileOutSpec){print "--- fileOutSpec=$fileOutSpec\n";$Lok=1;}
	      if (-e $fileOutId)  {print "--- fileOutId  =$fileOutId\n";$Lok=1;}
	      if (! $Lok){
		  print "*** no output file written => ERROR\n";}}
exit;

