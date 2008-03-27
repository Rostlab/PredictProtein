#!/usr/sbin/perl
#
#  
#
$[ =1 ;
				# include libraries
 push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables

if ($#ARGV<1){print"goal:   \n";
	      print"usage:  \n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut=$fileIn;$fileOut=~s/\.dat/\.msf/;

&open_file("$fhin", "$fileIn");
while (<$fhin>) {print "xx before:$_";
		 last if (/\# SAF/i);}
$#safLoc=0;
while (<$fhin>) {last if (/\# END/); # temporary
		 $_=~s/\n//g;
		 push(@safLoc,$_);}close($fhin);

print "xx entering extract ($fhin,$fileOut)\n";
&extractSaf($fileOut,@safLoc);

print "--- output in $fileOut\n";
exit;


#===============================================================================
sub extractSaf {
    local($fileOutLoc,@safInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   extractSaf                  extraction of SAF format
#       in:                     output file (for MSF),
#                               @safInLoc=lines read from file
#       out:                    fileMsf
#   
#   specification of format
#   
#   ------------------------------
#   EACH ROW
#   ------------
#   two columns: 1. name (protein identifier, shorter than 15 characters)
#                2. one-letter sequence (any number of characters)
#                   insertions: dots (.), or hyphens (-)
#   
#   ------------
#   EACH BLOCK
#   ------------
#   rows:        1. row must be guide sequence (i.e. always the same name,
#                   this implies, in particular, that this sequence shold
#                   not have blanks
#                2, ..., n the aligned sequences
#
#   comments:    *  rows beginning with a '#' will be ignored
#                *  rows containing only blanks, dots, numbers will also be ignored
#                   (in particular numbering is possible)
#   
#   unspecified: *  order of sequences 2-n can differ between the blocks,
#                *  not all 2-n sequences have to occur in each block,
#                *  
#                *  BUT: whenever a sequence is present, it should have
#                *       dots for insertions rather than blanks
#                *  
#   ------------
#   NOTE
#   ------------
#                The 'freedom' of this format has various consequences:
#                *  identical names in different rows of the same block
#                   are not identified.  Instead, whenever this applies,
#                   the second, (third, ..) sequences are ignored.
#                   e.g.   
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                      name-1   GGAPTLPETL
#                   will be interpreted as:
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                   wheras:
#                      t2_11751 EFQEDQENVN 
#                      name-1   ...EDQENvk
#                      name_1   GGAPTLPETL
#                   has three different names.
#                * 
#   
#   
#   ------------
#   EXAMPLE 1
#   ------------
#   
#     t2_11751 EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_1   EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_2   ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#     name_22  ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#
#     t2_11751 GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_1   GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#   
#
#   ------------
#   EXAMPLE 2
#   ------------
#                         10         20         30         40         
#     t2_11751 EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_1   EFQEDQENVN PEKAAPAQQP RTRAGLAVLR AGNSRGAGGA PTLPETLNVA
#     name_2   ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#     name_22  ...EDQENvk PEKAAPAQQP RTRAGLAVLR AGNSRG.... ...PETLNV.
#
#              50         60         70         80         90
#
#     t2_11751 GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_22  .......... .......... .......... ........
#     name_1   GGAPTLPETL NVAGGAPTLP ETLNVAGGAP TLPETLNV
#     name_2   .......... NVAGGAPTLP 
#   
#   
#   
#   
#   
#   
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}$sbrName="$tmp"."extractSaf";
    
				# ------------------------------
				# extract blocks
    $#nameLoc=0;$ctBlocks=0;%safLoc=0;
    foreach $_(@safInLoc){
	next if (/\#/);		# ignore comments
	$line=$_;
	$tmp=$_;$tmp=~s/[^A-Za-z]//g;
	next if (length($tmp)<1); # ignore lines with numbers, blanks, points only
	$line=~s/^\s*|\s*$//g;	# purge leading blanks
	$name=$line;$name=~s/^\s*([^\s\t]+)\s+.*$/$1/;
#	$seq=$line;$seq=~s/^\s*//;$seq=~s/^$name//;$seq=~s/\s//g;
	$seq=$line;$seq=~s/^\s*//;$seq=~s/^[^\s\t]+//;$seq=~s/\s//g;
	print "xx name=$name, seq=$seq,\n";
	if ($#nameLoc==0){	# detect first name
	    $nameFirst=$name;}
	if ($name eq "$nameFirst"){ # count blocks
	    ++$ctBlocks;%nameInBlock=0;
	    if ($ctBlocks==1){
		$lenFirstBeforeThis=0;}
	    else{
		$lenFirstBeforeThis=length($safLoc{"$nameFirst"});}
	    if ($ctBlocks>1){	# manage proteins that didnt appear
		&extractSafFillUp;}}
	next if (defined $nameInBlock{"$name"}); # avoid identical names
	if (! defined ($safLoc{"$name"})){
	    push(@nameLoc,$name);
	    print "xx new name=$name,\n";
	    if ($ctBlocks>1){	# fill up with dots
		print "xx file up for $name, with :$lenFirstBeforeThis\n";
		$safLoc{"$name"}="." x $lenFirstBeforeThis;}
	    else{
		$safLoc{"$name"}="";}}
	$seq=~s/[^A-Za-z]/\./g; # any non-character to dot
	$seq=~tr/[a-z]/[A-Z]/;
	$safLoc{"$name"}.=$seq;
	$nameInBlock{"$name"}=1; # avoid identical names
    } close($fhinLoc);
    $#safInLoc=0;		# save space

				# fill up ends
    &extractSafFillUp;
				# store names for passing variables
    foreach $it (1..$#nameLoc){
	$safLoc{"$it"}=$nameLoc[$it];}
    $safLoc{"NROWS"}=$#nameLoc;

    $safLoc{"FROM"}="PP_"."$nameLoc[1]";
    $safLoc{"TO"}=$fileOutLoc;
				# ------------------------------
				# write an MSF formatted file
    &wrtMsf($fileOutLoc,%safLoc);

}				# end of extractSaf

#===============================================================================
sub extractSafFillUp {
    local($sbrName,$fhinLoc,$tmp,$lenLoc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   extractSafFillUp            fill up with dots if sequences shorter than guide
#     all GLOBAL
#       in:                     $safLoc{"$name"}=seq
#                               @nameLoc: names (first is guide)
#-------------------------------------------------------------------------------
    if ($scriptName){$tmp="$scriptName".":";}else{$tmp="";}$sbrName="$tmp"."extractSafFillUp";
    
    foreach $tmp(@nameLoc){
	if ($tmp eq "$nameLoc[1]"){ # guide sequence
	    $lenLoc=length($safLoc{"$tmp"});
	    next;}
	$safLoc{"$tmp"}.="." x ($lenLoc-length($safLoc{"$tmp"}));}
}				# end of extractSafFillUp

