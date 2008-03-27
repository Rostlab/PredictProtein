#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="reads column in RDB file and writes histogram";
#  
#
$[ =1 ;
				# include libraries
				# ------------------------------
				# defaults
$nhisto=    100;
$nhisto=     50;
$modeDef=   "l";
$modeDef=   "h";
				# ------------------------------
				# help
if ($#ARGV<1){
    print "goal:\t $scrGoal\n";
    print "use: \t '$scrName file'\n";
    print "opt: \t col=COLUMN-No   (default: all columns, many as: col=11,5,3,2,1)\n";
    print "e.g. \t col=6:h,8:l     (read col 6 + 8, cumulative 6: high->low, 8: low->high)\n";
    print "     \t mode=h|l        (high 2 low, or low 2 high, default: $modeDef)\n";
    print "     \t nhisto=         (default: $nhisto, number of bins)\n";
    print "     \t                  note: this may be changed of too small!\n";
    print "     \t fileOut=x\n";
    print "     \t add=title       added to column names\n";
    print "     \t min=x           minimal value to start histogram\n";
    print "     \t max=x           maximal value to start histogram\n";
    print "     \t itrvl=x         give interval\n";
#    print "     \t \n";
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
				# read command line
$fileIn=$ARGV[1];
$tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Outhis-".$tmp;
$title=0;			# added to column names

foreach $arg (@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)     {$fileOut=$1;}
    elsif ($arg=~/^col=(.*)$/)         {$col=    $1;}
    elsif ($arg=~/^nhisto=(.*)$/)      {$nhisto= $1;}
    elsif ($arg=~/^mode=(.*)$/)        {$modeDef=$1;}
    elsif ($arg=~/^add=(.*)$/)         {$title=  $1;}
    elsif ($arg=~/^title=(.*)$/)       {$title=  $1;}
    elsif ($arg=~/^min=(.*)$/)         {$min=    $1;}
    elsif ($arg=~/^max=(.*)$/)         {$max=    $1;}
    elsif ($arg=~/^itrvl=(.*)$/)       {$itrvl=  $1;}
#    elsif($arg=~/^=(.*)$/){$=$1;}
    else  {print"*** wrong command line arg '$arg'\n";
	   die;}}
				# ------------------------------
				# (1) process command line
$#txt=0;
if (defined $col){
    @txt=split(/,/,$col);
    if ($col=~/:/){
	foreach $it (1..$#txt){
	    $txt[$it]=~s/\:([hl])//;
	    if    ($1 eq "h")   {$mode[$it]="h";}
	    elsif ($1 eq "l")   {$mode[$it]="l";}
	    elsif (length($1)>0){print "*** ERROR mode in col=$txt either h or l\n";
				 die;}
	    else                {$mode[$it]=$modeDef;}}}
    else {
	foreach $it(1..$#txt){
	    $mode[$it]=$modeDef;}}}
else             {
    push(@txt,"");}
$nhistoMax=$nhisto;
$ncol=$#txt;
				# --------------------------------------------------
				# (3) compile histogram
				# --------------------------------------------------
$ctCol=0;undef %res;
$#name=0;

foreach $col (@txt){
    ++$ctCol;
				# ------------------------------
				# read file for one column
				# ------------------------------
    open($fhin,$fileIn) || die "*** $scrName failed opening fileIn=$fileIn";

    $#col=0;
				# out GLOBAL: @col
    ($nrow,$name)=
	&here_rdRdbAssociativeNum_5($fhin,$col);
    close($fhin);

    push(@name,$name);

    print "xx after read (col=$col, ct=$ctCol): number of rows=$nrow\n";

				# ------------------------------
    if (! defined $min){	# get min
	$min=10000;
	foreach $tmp (@col) { next if ($tmp >= $min);
			      $min=$tmp; } }
				# ------------------------------
    if (! defined $max){	# get max
	$max=-100000;
	foreach $tmp (@col) { next if ($tmp <= $max);
			      $max=$tmp; } }
				# ------------------------------
    $ave=$var=0;		# get ave
    foreach $i (@col) { $ave+=$i; } # sum
    $AVE=($ave/$nrow);
    foreach $i (@col) { $tmp=($i-$AVE); 
			$var+=($tmp*$tmp); } 
    $VAR=0;
    $VAR=($var/($nrow-1))       if ($nrow > 1);
    $ave=$AVE; $var=$VAR;
    print "xx after ave\n";
				# ------------------------------
				# determine interval
    if (! defined $itrvl){
	$itrvl[$ctCol]=
	    &func_absolute($max-$min)/$nhisto; }
    else {
	$itrvl[$ctCol]=$itrvl;}

    print "xx col=$ctCol, min=$min, max=$max, itrvl=$itrvl[$ctCol], nh=$nhisto, \n";

				# ------------------------------
				# high 2 low
    if    (defined $mode[$ctCol] &&
	   $mode[$ctCol] eq "h"){
				# sort
	@col= sort bynumber_high2low (@col);
	print "xx after sort\n";
				# histogram
				# in  GLOBAL: @col
				# out GLOBAL: @his (1..$nhisto)
	&array2histo_high2low($min,$max,$itrvl[$ctCol]);

	$#col=0;		# slim-is-in!
	print "xx after sort 2\n";

	foreach $it (1..$#his){	# values
	    $res{$ctCol,"val",$it}=$max-($itrvl[$ctCol]*$it);
	} 
    }

				# ------------------------------
    else {			# low 2 high
				# sort
	@col= sort bynumber (@col);
	print "xx after sort 1\n";
				# histogram
				# in  GLOBAL: @col
				# out GLOBAL: @his (1..$nhisto)
	&array2histo_low2high($min,$max,$itrvl[$ctCol]);

	$#col=0;		# slim-is-in!
	print "xx after sort 2\n";

	foreach $it (1..$#his){	# values
	    $res{$ctCol,"val",$it}=$min+($itrvl[$ctCol]*$it);
	} 
    }

				# ------------------------------
				# store maximal count (may be higher than nhisto)
    $nhistoMax= $#his           if ($nhistoMax < $#his);

				# ------------------------------
    $sum=0;			# get sums
    foreach $it (1..$#his){
	$sum+=           $his[$it];
	$res{$ctCol,$it}=$his[$it];}

    printf "xx sum=%5d, no of elements=%5d ave=%6.1f var=%6.1f\n",$sum,$#his,$ave,$var;
    $res{$ctCol,"sum"}=$sum;$res{$ctCol,"min"}=$min;$res{$ctCol,"max"}=$max;
    $res{$ctCol,"ave"}=$ave;$res{$ctCol,"sig"}=sqrt($var);

    print "xx end of col=$ctCol\n";
}

				# ------------------------------
                                # (4) write output
open($fhout,">".$fileOut) || warn "*** $scrName failed opening fileout=$fileOut\n";
print $fhout  "\# Perl-RDB\n";
print $fhout  "\# produced by $scrName\n";
printf $fhout "\# SYN     : %3s %5s %6s %6s %6s %6s\n","col","sum","max","min","ave","sig";
foreach $ctCol (1..$ncol){	# overall info
    printf $fhout 
	"\# SYN     : %3d %5d %6.1f %6.1f %6.1f %6.1f\n",
	$ctCol,$res{$ctCol,"sum"},$res{$ctCol,"max"},$res{$ctCol,"min"},
	$res{$ctCol,"ave"},$res{$ctCol,"sig"};}
				# ------------------------------
				# write names
print $fhout "n";
$addTitle="";
$addTitle=$title		if ($title);

foreach $it (1..$ncol){
    print $fhout 
	"\t","V".    $name[$it].$addTitle,
	"\t","Vend". $name[$it],
	"\t","N". $name[$it].$addTitle,
	"\t","%". $name[$it].$addTitle,
	"\t","NC".$name[$it].$addTitle,"\t","%C".$name[$it].$addTitle;}
print $fhout "\n";
				# ------------------------------
				# write body
foreach $ctCol (1..$ncol){
    $cum[$ctCol]=0;}		# initialise cumulative sums
foreach $it (1 .. $nhistoMax){
    $Lok=0;			# ignore if non defined/non-zero
    foreach $ctCol (1..$ncol){
	if (defined $res{$ctCol,$it} && length($res{$ctCol,$it})>=1 &&
	    $res{$ctCol,$it}>=1){
	    $Lok=1;
	    last;}}
    next if (! $Lok);
				# --------------------
				# count nHisto
    print $fhout 
	$it;
    foreach $ctCol (1..$ncol){
	if (! defined $res{$ctCol,$it} || length($res{$ctCol,$it})<1 ||
	    $res{$ctCol,$it}<1){
	    $val=" ";$num=" " ;$per=" ";}
	else {
	    $num=$res{$ctCol,$it};
	    $per=100*($num/$res{$ctCol,"sum"});
	    $val=$res{$ctCol,"val",$it};       
				# reduce accuracy
	    $per=~s/(\.\d\d).*$/$1/g;
	    $val=~s/(\.\d\d).*$/$1/g;

	    if ($res{$ctCol,$it}=~/\D/){
		print "xx not number it=$it, col=$ctCol, res=",$res{$ctCol,$it},",\n";}
	    $cum[$ctCol]+=$num;}
	if ($cum[$ctCol]==0){
	    $numC=" ";$perC=" ";}
	else{
	    $numC=$cum[$ctCol]; 
	    if (int($numC) != $numC){
		print "xxx ??? $numC, ctCol=$ctCol, it=$it,\n";exit;}
	    $perC=100*($cum[$ctCol]/$res{$ctCol,"sum"});$perC=~s/(\.\d\d).*$/$1/g; }
	printf $fhout 
	    "\t%-s\t%5.2f\t%-s\t%-s\t%-s\t%-s",
	    $val,($val+$itrvl),$num,$per,$numC,$perC;
	    
    }
    print $fhout "\n";
}close($fhout);

print "--- output in $fileOut\n";
exit;

#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

#===============================================================================
sub func_absolute {
    local ($num)=@_;local ($tmp);
#----------------------------------------------------------------------
#   func_absolute               compiles the absolute value
#       in:                     $num
#       out:                    returned |$num|
#----------------------------------------------------------------------
    if ($num>=0){
	return($num);}
    else {
	$tmp=(-1)*$num;
	return($tmp);}
}				# end of func_absolute

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

#===============================================================================
sub here_rdRdbAssociativeNum_5 {
    my ($fhLoc2,$readnum) = @_ ;
    my ($ctLoc,@tmpar,$it, $ipos, $tmp);
    $[ =1 ;
#----------------------------------------------------------------------
#   here_rdRdbAssociativeNum_5  reads RDB format for one column
#       in:                     $fhLoc,@readnum
#         $fhLoc:               file handle for reading
#         @readnum:             vector containing the number of columns to be read, if empty,
#                               then all columns will be read!
#         $READHEADER:          returns the complete header as one string
#         @READCOL:             returns all columns to be read (tab separated)
#         @READNAME:            returns the names of the columns
#         @READFORMAT:          returns the format of each column
#----------------------------------------------------------------------
    $ctLoc=$ctRow=$#col=0;
				# ------------------------------
				# read file
				# ------------------------------
    while ( <$fhLoc2> ) {
	next if ( /^\#/ );	# skip comments
	$rd=$_;$rd=~s/^\s+|\s+$//g;
	next if (length($rd)<2);
	++$ctLoc;		# count non-comment
				# ------------------------------
				# names
	if ($ctLoc==1){
	    $rd=$_;$rd=~s/^\t+|\t$//g;@tmpar=split(/\t/,$rd);
				# process wild card
	    $tmp_name=$tmpar[$readnum];$tmp_name=~s/\s|\n//g;
	    $READNAME=$tmp_name; 
	    next; }
				# ------------------------------
				# skip format?
	++$ctLoc if ($ctLoc==2 && $rd !~ /\d+[SNF]\t|\t\d+[SNF]/);
	next if ($ctLoc==2);	# skip format

				# ------------------------------
				# data
	$rd=$_;$rd=~s/^\t+|\t$//g; @tmpar=split(/\t/,$rd);
	++$ctRow;

	next if (! defined $tmpar[$readnum]); 
	$tmp=$tmpar[$readnum];
	$tmp=~s/\s//g;
	$col[$ctRow]=$tmp; }

    $#tmpar=0;			# slim-is-in!

    return($ctRow,$READNAME);
}				# end of here_rdRdbAssociativeNum_5

#===============================================================================
sub array2histo_high2low {
    my($minLoc,$maxLoc,$itrvl) = @_ ;
    my($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   array2histo_high2low        reads array, returns histogram (high to low)
#       in GLOBAL:              @col
#       out GLOBAL:             @his
#       in:                     $min,$max,$itrvl,@array
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."array2histo_high2low";$fhinLoc="FHIN"."$sbrName";

    $ct=1;$#his=0;
    foreach $tmp (@col){
				# value larger  -> first interval
	if ($tmp >= $maxLoc) {
	    ++$his[$ct];
	    next; }
				# value smaller -> count down
	while ($tmp < $maxLoc-($itrvl*$ct)){
	    die ("*** ERROR count down ct=$ct, $itrvl, min=$minLoc, max=$maxLoc, tmp=$tmp\n")
		if (($maxLoc-($itrvl*$ct)) < $minLoc);
	    ++$ct;
	    $his[$ct]=0;}
#	print "xx ct=$ct, tmp=$tmp, point=",$maxLoc-($itrvl*$ct),",\n" if ($tmp[$ct]==0);
	$now= $maxLoc-$itrvl*$ct;
	$now2=$maxLoc-($itrvl*($ct-1));
	die ("*** ERROR $sbrName too high ct=$ct, tmp=$tmp, now=$now,\n")
	    if  ( $tmp < $now ); # error: should never come here...
	die ("*** ERROR $sbrName too low  ct=$ct, tmp=$tmp, now2=$now2 now=$now\n")
	    if ($tmp > $now2);
	++$his[$ct];}
#    return(@tmp);
}				# end of array2histo_high2low

#===============================================================================
sub array2histo_low2high {
    my($minLoc,$maxLoc,$itrvl) = @_ ;
    my($sbrName,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   array2histo_low2high        reads array, returns histogram (low to high)
#       in GLOBAL:              @col
#       out GLOBAL:             @his
#       in:                     $min,$max,$itrvl,@array
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName="$tmp"."array2histo_low2high";$fhinLoc="FHIN"."$sbrName";

    $ct=1;$#his=0;
    foreach $tmp(@col){
				# value smaller  -> first interval
	if ($tmp <= $minLoc) {
	    ++$his[$ct];
	    next; }
				# value larger-> count up
	while ($tmp > $minLoc+$itrvl*$ct){
	    die("*** ERROR count up $ct, $itrvl, min=$minLoc, max=$maxLoc, tmp=$tmp\n")
		if (($minLoc+$itrvl*$ct) > $maxLoc);
	    ++$ct;
	    $his[$ct]=0;}

	$now= $minLoc+$itrvl*$ct;
	$now2=$minLoc+$itrvl*($ct-1);
	die ("*** ERROR $sbrName too high ct=$ct, tmp=$tmp, now=$now,\n")
	    if ($tmp > $now);	# error: should never come here...
	die ("*** ERROR $sbrName too low  ct=$ct, tmp=$tmp, now2=$now2 now=$now\n")
	    if ($tmp < $now2);
	++$his[$ct];}
#    return(@tmp);
}				# end of array2histo_low2high

