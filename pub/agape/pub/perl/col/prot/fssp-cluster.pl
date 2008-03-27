 #!/usr/sbin/perl -w
#
# finds clusters in FSSP 
# -  first read PDBids from HSSP (first N)
# -  foreach : grep in FSSP for all others
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal :   finds clusters in FSSP\n";
	      print"in:      hssp files (several in a row, will all be used)\n";
	      print"option:  nExtr (number of proteins considered)\n";
	      exit;}
				# defaults
$fhin="FHIN"; $fileOut="out-fssp.tmp";
$par{"nExtr"}=5;
$par{"dirFssp"}="/data/fssp/";
$par{"exeFsspExtrPdbid"}="/home/rost/perl/scr/fssp_extr_ids.pl";

				# read command line
$#fileIn=0; 
foreach $arg(@ARGV){
    if    ($arg =~ /^nExtr=/){$arg=~s/^nExtr=//g;$par{"nExtr"}=$arg;}
    elsif ($arg =~ /^dirFssp=/){$arg=~s/^dirFssp=//g;$par{"dirFssp"}=$arg;}
    elsif (-e $arg){push(@fileIn,$arg);}}

				# read files
$#pos=$#id=0;
%Lid=0;
foreach $file (@fileIn){
    &open_file("$fhin", "$file");
    while (<$fhin>) {last if (/^  NR\./);}
    while (<$fhin>) {
	$_=~s/\n//g;
	$pos=substr($_,1,5);$pos=~s/\s//g;
	print "x.x $file pos=$pos,\n";
	last if ($pos > $par{"nExtr"});
	$id=substr($_,9,6);$id=~s/\s|_|-//g;
	if (! defined $Lid{"$id"}){
	    print "x.x $file id=$id,\n";
	    $Lid{"$id"}=1;
	    push(@pos,$pos);push(@id,$id);}}close($fhin);
}

$idTxt="";foreach $id (@id) {$idTxt.="$id".",";}$idTxt=~s/,$//g;

foreach $id (@id){
    $fssp=$par{"dirFssp"}."$id".".fssp";
    print "searches fssp '$fssp'\n";
    if (! -e $fssp){
	next;}
    $tmp=$idTxt;$tmp=~s/$id//g;$tmp=~s/,,/,/g;
    $exe=$par{"exeFsspExtrPdbid"};
    $get=" get=$tmp ";
    print "--- system '$exe $fssp $get notScreen >> $fileOut'\n";
    system ("$exe $fssp $get notScreen ");
    system ("$exe $fssp $get notScreen  >> $fileOut");
}

system ("echo 'threaders=$idTxt' >> $fileOut");

print "--- output in '$fileOut'\n";

exit;
