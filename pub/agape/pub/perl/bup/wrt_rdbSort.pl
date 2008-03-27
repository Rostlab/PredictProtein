#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="resorting RDB files";
#  
#

$[ =1 ;
				# ------------------------------
foreach $arg(@ARGV){		# include libraries
    last if ($arg=~/dirLib=(.*)$/);}
$dir=$1 || "/home/rost/perl/" || $ENV{'PERLLIB'}; 
$dir.="/" if (-d $dir && $dir !~/\/$/);
$dir= ""  if (! defined $dir || ! -d $dir);
foreach $lib("lib-ut.pl","lib-br.pl","lib-br5.pl"){
    require $dir.$lib ||
	die("*** $scrName: failed to require perl library '$lib' (dir=$dir)\n");}
				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);

$modeSort="decr"; 
$sep="\t";


				# ------------------------------
if ($#ARGV<2){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName file.rdb (or *rdb) col=column-number-to-sort (many: a,b,c)'\n";
    print  "note:        maximally 1 column can be specified to sort (at the moment)!\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "      %-15s= %-20s %-s\n","fileOut",  "x",        "";
    printf "      %-15s  %-20s %-s\n","noNum",    "no value", "final file without counting rows";
#    printf "      %-15s  %-20s %-s\n","noScreen", "no value","";
#    printf "      %-15s  %-20s %-s\n","",   "","";
#    printf "      %-15s  %-20s %-s\n","",   "no value","";
    printf "      %-15s  %-20s %-s\n","incr",   "no value",  "sort by increasing val (def=$modeSort)";
    printf "      %-15s  %-20s %-s\n","decr",   "no value",  "sort by decreasing val (def=$modeSort)";
    printf "      %-15s  %-20s %-s\n","decr,incr,incr", " ", "sorting for col1, col2, col3";
    printf "      %-15s  %-20s %-s\n","sep",    "x",         "separator of columns (\t,',',' ')";
    if (defined %par && $#kwd > 0){
	$tmp= sprintf("      %-15s  %-20s %-s\n","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("      %-15s  %-20s %-s\n","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{"$kwd"} || length($par{"$kwd"})<1 );
	    if    ($par{"$kwd"}=~/^\d+$/){
		$tmp2.=sprintf("      %-15s= %10d %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    elsif ($par{"$kwd"}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("      %-15s= %10.3f %9s %-s\n",$kwd,$par{"$kwd"}," ","(def)");}
	    else {
		$tmp2.=sprintf("      %-15s= %-20s %-s\n",$kwd,$par{"$kwd"},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;$LnoNum=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=$1;}
    elsif ($arg=~/^incr[a-z]*$/)          { $modeSort="incr";}
    elsif ($arg=~/^decr[a-z]*$/)          { $modeSort="decr";}
    elsif ($arg=~/([in|de]cr)/)           { @modeSort=split(/,/,$arg); }
    elsif ($arg=~/^col=(.*)$/)            { $colList=$1;}
    elsif ($arg=~/^nonum$/i)              { $LnoNum=1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); push(@chainIn,"*");}
    elsif ($arg=~/^(\.hssp)\_([A-Z0-9])/) { push(@fileIn,$1);   push(@chainIn,$2);}
    elsif (defined %par && $#kwd>0)       { 
	$Lok=0; 
	foreach $kwd (@kwd){
	    if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{"$kwd"}=$1;
				       last;}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     die;}}
    else { print "*** wrong command line arg '$arg'\n"; 
	   die;}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
				# ------------------------------
				# digest column list
@col=split(/,/,$colList);
if    ($#modeSort < 1){
    foreach $it (1..$#col){
	push(@modeSort,$modeSort); } }
elsif ($#modeSort != $#col){
    print "*** ERROR modesort and col not same number\n";
    exit;}
    

$#fileOut=0;
				# --------------------------------------------------
				# (1) loop file(s)
				# --------------------------------------------------
foreach $fileIn(@fileIn){
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on '$fileIn'\n";
				# open
    &open_file("$fhin", "$fileIn") || die '*** $scrName ERROR opening file $fileIn';
				# ------------------------------
    $ct=$it=$ncol=0;		# read 
    undef @Lnum;
    while (<$fhin>) {
	next if ($_=~/^\#/);	# skip comments
	++$ct;
	next if ($ct==1);	# skip names
	next if ($ct==2 && $_=~/\d+[NFS]?[\s\t]+|[\s\t]+\d+[NFS]?/); # skip formats
	++$it;
	$_=~s/\n//g;
	@tmp=split(/\t/,$_);
	foreach $tmp (@tmp) {
	    $tmp=~s/\s//g; }
	$ncol=$#tmp            if ($#tmp > $ncol);
	foreach $itcol (1..$#tmp){
	    $rd[$it][$itcol]=$tmp[$itcol];
	    $Lnum[$itcol]=1    if (! defined $Lnum[$itcol]);     # ini: all numerical
	    $Lnum[$itcol]=0    if ($tmp[$itcol] !~ /^[\d\.]+$/); # non numerical
	}
    }
    $nrow=$it;
    close($fhin);

    foreach $itcol (1..$ncol){
	$#tmp2=0;
	foreach $itrow (1..$nrow){
	    push(@tmp2,$rd[$itrow][$itcol]);}
	my (@tmp) = @tmp2;
	$ra_col[$itcol]=\@tmp; }

   				# ------------------------------
				# sort
    foreach $ittmp (1..$#col){
	$itcolsort=$col[$ittmp];
	if    ($modeSort[$ittmp] eq "decr" && $Lnum[$itcolsort]) {
	    my (@tmp)=sort bynumber_high2low (@{$ra_col[$itcolsort]});
#	    print "xx 1: tmp=",join(',',@tmp,"\n");
	    $ra_col_sort[$itcolsort]=\@tmp; }
	elsif ($modeSort[$ittmp] eq "incr" && $Lnum[$itcolsort]) {
	    my (@tmp)=sort bynumber (@{$ra_col[$itcolsort]});
#	    print "xx 2: tmp=",join(',',@tmp,"\n");
	    $ra_col_sort[$itcolsort]=\@tmp; }
	elsif ($modeSort[$ittmp] eq "decr" && ! $Lnum[$itcolsort]) {
	    my (@tmp)=sort (@{$ra_col[$itcolsort]});
#	    print "xx 3: tmp=",join(',',@tmp,"\n");
	    $ra_col_sort[$itcolsort]=\@tmp; }
	elsif ($modeSort[$ittmp] eq "incr" && ! $Lnum[$itcolsort]) {
	    my (@tmp)=sort reverse (@{$ra_col[$itcolsort]});
#	    print "xx 4: tmp=",join(',',@tmp,"\n");
	    $ra_col_sort[$itcolsort]=\@tmp; } }

				# ------------------------------
				# retrieve pointers
				# first column to sort
    $itcolsort=$col[1];
    undef @Lok;
    $itcolsort=$col[1];
    @row=@{$ra_col_sort[$itcolsort]};
    $#tmp=0;
    foreach $itrowsort (1..$nrow){ # 
	foreach $itrow (1..$nrow){
	    next if (defined $Lok[$itrow]);
	    next if ($rd[$itrow][$itcolsort] ne $row[$itrowsort]);
	    $Lok[$itrow]=1;
	    push(@tmp,$itrow);
	    last;} }

#    my(@rowsort)=@tmp;

				# ------------------------------
				# write

    if (! defined $fileOut || -e $fileOut){
	$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}

    &open_file("$fhout",">$fileOut"); 

    $ct=0;
    foreach $itrow (@tmp){
	++$ct;
	$tmpWrt="";
	$tmpWrt.=     sprintf ("%5s$sep%5s$sep",$ct,$itrow) if (! $LnoNum);
	foreach $itcol (1..$ncol){
	    $tmpWrt.= sprintf ("%-s$sep",$rd[$itrow][$itcol]);
	}
	$tmpWrt=~s/$sep$//g;
	print $fhout $tmpWrt,"\n";
    }
    close($fhout);
    push(@fileOut,$fileOut)     if (-e $fileOut);
}

print "--- output in:\n";
foreach $file (@fileOut){
    print $file,"," if (-e $file);}print "\n";

exit;

	
