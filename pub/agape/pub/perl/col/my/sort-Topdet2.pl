#!/usr/sbin/perl -w
#
# sorts the 'Topdet2' files written by 'evalhtm_top.pl ' in mode prd
#
$[ =1 ;

push (@INC, "/home/rost/perl") ;
require "ctime.pl";		# require "rs_ut.pl" ;
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

if ($#ARGV<1){print"goal:   sorts 'Topdet2' files written by 'evalhtm_top.pl ' in mode prd\n";
	      print"usage:  'script file (s)'\n";
	      exit;}
$fhin="FHIN";
$fhout="FHOUT";

foreach $file (@ARGV){
    if (! -e $file){
	print "*** missing '$file'\n";
	next;}
    $title=$file;$title=~s/Topdet2-|-rdb[Hh]tm|0.|\..*$//g;
    $fileOut="GeneHtm-".$title.".dat"; $fileHtml="GeneHtm-".$title.".html";
     $#id=$#top=$#nhtm=$#nali=$#fstRes=$#seg=0;
				# read
    &open_file("$fhin", "$file");
    while (<$fhin>) {
	$_=~s/\n//g;
	@tmp=split(/\s+/,$_);
	if ($_=~/^id/){ #@col=@tmp;
			next;}
	else {push(@id,$tmp[1]);push(@top,$tmp[2]);push(@nhtm,$tmp[3]);push(@nali,$tmp[4]);
	      push(@fstRes,$tmp[6]);push(@seg,$tmp[7]);}}close($fhin);
				# sort
    $#ptr=0;foreach $it(1..$#id){$Ldone[$it]=0;}
    foreach $x (1..30){
	$nhtm=31-$x;
	foreach $it (1..$#id){
	    if (($nhtm[$it]>$nhtm)&&(! $Ldone[$it])){
		push(@ptr,$it);
		$Ldone[$it]=1;}}}
				# wrt into tab delimited file
    &open_file("$fhout", ">$fileOut");
    printf $fhout
	"%-s\t%-3s\t%-4s\t%-5s\t%-10s\t%-s\n","Name","Top","Nhtm","Nali","1st 10 res","Seg";
    foreach $ptr (@ptr){
	printf $fhout
	    "%-s\t%-3s\t%-4d\t%-5d\t%-10s\t%-s\n",
	    $id[$ptr],$top[$ptr],$nhtm[$ptr],$nali[$ptr],$fstRes[$ptr],$seg[$ptr];
	printf 
	    "%-s %-3s %-4d %-5d %-10s %-s\n",
	    $id[$ptr],$top[$ptr],$nhtm[$ptr],$nali[$ptr],$fstRes[$ptr],$seg[$ptr];
    }close($fhout);

				# wrt into HTML
    &open_file("$fhout", ">$fileHtml");
				# description
    print $fhout
	"<HR><P>\n",
	"Notation:<P>\n",
	"<UL><LI><A NAME=\"name\">Name</A>: <BR>\n\t sequence identifier\n",
	"    <LI><A NAME=\"top\">Top</A>: <BR>\n\t topology ",
	    "(in-> N-term, i.e. first non transmembrane region, intra-cytoplasmic, ",
	    " out-> N-term extra-cytoplasmic)\n",
	"    <LI><A NAME=\"nhtm\">Nhtm</A>: <BR>\n\t number of transmembrane helices\n",
	"    <LI><A NAME=\"nali\">Nali</A>: <BR>\n\t number of sequences in protein",
	    "family used for prediction\n",
	"    <LI><A NAME=\"1st10\">1st 10 res</A>: <BR>\n\t first 10 residues\n",
	"    <LI><A NAME=\"seg\">Seg</A>: <BR>\n\t positions of predicted transmembrane",
	    " helices (with respect to first residue)\n",
	"</UL>\n";
				# first row (names)
    print $fhout
	"<HR><P>\n",
	"<TABLE BORDER>\n",    
	"<STRONG>\n",
	"<TR>\t<TH><A HREF=\"#name\">Name</A></TH>\n",
	"    \t<TH><A HREF=\"#top\">Top</A></TH>\n",
	"    \t<TH><A HREF=\"#nhtm\">Nhtm</A></TH>\n",
	"    \t<TH><A HREF=\"#nali\">Nali</A></TH>\n",
	"    \t<TH><A HREF=\"#1st10\">1st 10 res</A></TH>\n",
	"    \t<TH><A HREF=\"#seg\">Seg</A></TH>\n",
	"</STRONG>\n";
				# all other columns
    foreach $ptr (@ptr){
	printf $fhout
	    "<TR>\t<TD>%-s<TD>%-3s<TD>%-4d<TD>%-5d<TD>%-10s<TD>%-s\n",
	    $id[$ptr],$top[$ptr],$nhtm[$ptr],$nali[$ptr],$fstRes[$ptr],$seg[$ptr];
    }
    print $fhout "</TABLE><P>\n";
    close($fhout);
    
    print "--- files '$fileOut', '$fileHtml'\n";
}
exit;
