#!/usr/bin/perl -w
#----------------------------------------------------------------------
# read_rdb
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	read_rdb.pl file_license
#
# task:		convert rdb file to readable = 1space
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost			August,	        1994           #
#			changed:	January	,      	1996           #
#			changed:	May	,      	1996           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "read_rdb";
$script_input     = "file_license";
$script_opt_ar[1] = "columns to be excluded: 'excl=n1-n2', 'excl=n1,n3', 'excl=id1,id2'\n".
    "\t\t '*' allowed for ranges, also names, but in that case no ranges!";
$script_opt_ar[2] = "columns to be included: 'incl=n1-n2', or: 'incl=n1,n3'";
$script_opt_ar[3] = "condition: include line if col x > val 'if(name>val)'";
$script_opt_ar[4] = "sep=',' will separate columns by comma";
$script_opt_ar[5] = "do_header    (write RDB header '\#')";
$script_opt_ar[6] = "do_blabla    (messages onto screen)";
$script_opt_ar[7] = "file         (write output file with extension '.dat')";
$script_opt_ar[8] = "format       (write columns in this format e.g. '5.1f')";
$script_opt_ar[8] = "noformat ";

#----------------------------------------
# about script
#----------------------------------------
if ( ($#ARGV<1)||($ARGV[1]=~/^help|^man|^-h/) ) {
    print "--- use: $script_name $script_input\n";
    for ($it=1; $it<=$#script_opt_ar; ++$it) {
	print"--- opt $it: \t $script_opt_ar[$it] \n"; } 
    print "--- \n";
    print "--- example: (rdb2screen file 'sep=,' 'incl=1-4,7-9,10,11,14' 'if(TPok<=0)')\n";
    print "--- note:    sep=tab  for tab separation of columns\n";
    exit;}

#----------------------------------------
# read input
#----------------------------------------
$file_in=    $ARGV[1];

$sep=" ";
$LfileOut=0; $fhout="FHOUT"; $fileOut=$file_in;$fileOut=~s/\.rdb/\.dat/g;
$Lno_header=1; $Lscreen=$Lcond=0; $LnoFormat=0;
$Lprintf=0;$#pos_excl=$#pos_incl=0;
foreach $_(@ARGV){
    if    ($_=~/^excl=/)       { @pos_excl=&get_arg_range($_);}
    elsif ($_=~/^incl=/)       { @pos_incl=&get_arg_range($_);}
    elsif ($_=~/^do.?head/)    { $Lno_header=0; }
    elsif ($_=~/^do.?bla/)     { $Lscreen=1; }
    elsif ($_=~/^sep=(.*)/)    { $sep=$1; $sep="\t" if ($sep =~ /tab/i); }
    elsif ($_=~/^form.*=(.*)/) { $formatWant=$1; }
    elsif ($_=~/^noform/i)     { $LnoFormat=1;}
    elsif ($_=~/^file/)        { $LfileOut=1;}
    elsif ($_=~/^if\(/) {
	$name=substr($_,4);$name=~s/[=<>_]+.*$//g;
	$cond=substr($_,4);$cond=~s/^[^<>=_]*([_eqne<>=]+)[^_<>=]*$/$1/g;$cond=~s/\_//g;
	$val= substr($_,4,(length($_)-4));$val=~s/^[^_]+[=><_]+//g;$val=~s/eq_|ne_//g;
#	print "x.x cond=$cond,name=$name,val=$val\n";exit;
	$Lcond=1;$cond_name=$name;$cond_cond=$cond;$cond_val=$val;}
}
				# ------------------------------
				# format to write given?
$formatWant="%".$formatWant     if (defined $formatWant);

				# ------------------------------
				# file existing
if ( ! -e $file_in ) { print "*** ERROR in filein=$file_in\n";
		       exit;}

#----------------------------------------
# read list
#----------------------------------------

open("FILE_IN", "$file_in") || die "*** failed opening input file=$file_in";
if ($LfileOut){
    open("$fhout", ">$fileOut") || die "*** failed creating $fileOut";}
else{
    $fhout="STDOUT";}

$ct=0;
while ( <FILE_IN> ) {
    $tmp=$_;$tmp=~s/\n//g;
    if ($tmp=~/\t/) {$sep_in="\t";}elsif($tmp=~/\,/){$sep_in=",";}else{$sep_in=" ";}
    if ($tmp=~/^\#/ && ! $Lno_header) { 
	print $fhout "$tmp\n"; }
    next if ($tmp=~/^\#/);

    ++$ct;
    $tmp=~s/^\s+|\s+$//g;
				# no formats?
    ++$ct                       if ($ct==2 && $_ !~/\d+[SNF]\t|\d+[SNF]\t/);
				# --------------------------------------------------
				# read names
				# --------------------------------------------------
    if ($ct==1)    { 
	@ar_name=  split(/$sep_in+/,$tmp);  $#new_excl=$#new_incl=0;
	foreach $it(1..$#ar_name){
	    $ar_name[$it]=~s/^\s*|\s*$//g;}
	if ($Lcond) {		# find conditional column
	    foreach $it (1..$#ar_name){
		if ($ar_name[$it] eq $cond_name){
		    $cond_pos=$it;
		    last;}}}
	if ( $#pos_excl > 0 ){	# convert arguments read to numbers of columns
	    if ($pos_excl[$#pos_excl] eq "*"){
		pop @pos_excl; 
		foreach $it ($pos_excl[$#pos_excl]..$#ar_name){
		    push(@pos_excl,$it);}}
	    @new_excl= &get_names2pos(@ar_name,"xxx",@pos_excl); }
	if ( $#pos_incl > 0 ) {
	    if ($pos_incl[$#pos_incl] eq "*"){
		pop @pos_incl; 
		foreach $it ($pos_incl[$#pos_incl]..$#ar_name){
		    push(@pos_incl,$it);}}
	    @new_incl= &get_names2pos(@ar_name,"xxx",@pos_incl); }
	if ( ($#pos_excl + $#pos_incl)==0){
	    @new_incl= (1..$#ar_name);} 
	$#col_take=0;

	foreach $it (1..$#ar_name){
				# exclude/include?
	    if ($#new_excl>0){
		$Lex=0;$Lin=1;}
	    foreach $ex(@new_excl){ 
		if ($it == $ex) { 
		    $Lex=1;$Lin=0; 
		    last; }}
	    if ($#new_incl>0){
		$Lin=0;}
	    foreach $in(@new_incl){ 
		if ($it == $in) { 
		    $Lin=1;$Lex=0; last; }}
	    if ( ($#new_excl+$#new_incl)<1) {
		$Lin=1;}
				# condition ?
	    if ( $Lin && (! $Lex) ) {
		push(@col_take,$it);}}
				# write names
	foreach $itcol (@col_take){
	    if    ($Lprintf){
		printf  $fhout "$prt_form[$itcol]".$sep,$ar_name[$itcol]; }
	    elsif (defined $formatWant) {
		printf  $fhout "$formatWant".$sep,$ar_name[$itcol]; }
	    else {$tmp=$ar_name[$itcol];$tmp=~s/^\s*|\s*$//g;
		  print  $fhout $tmp.$sep;} }
	print $fhout "\n"; 
    }
				# --------------------------------------------------
				# formats
				# NOTE: skipped above if not present!
				# --------------------------------------------------
    elsif ( ($ct==2) && ($sep_in eq "\t") && 
	   $tmp=~/\d+N|\dS|\dF/) { 
	@ar_form=  split(/$sep_in+/,$tmp); 
	$#prt_form=0;
	foreach $ar(@ar_form){
	    $prt=&form_rdb2perl($ar);$prt=~s/\s//g;
	    push(@prt_form,$prt);}
	$Lprintf=1                  if ($#prt_form>0);
	$Lprintf=0                  if ($LnoFormat);
	foreach $itcol (@col_take){ # now print names
	    $tmp=substr($prt_form[$itcol],2);$tmp=~s/(\d)+[\D]*$/$1/g;$tmp2="\%".$tmp."s";
	    printf $fhout "$tmp2$sep",$ar_name[$itcol]; }print $fhout "\n";}
				# --------------------------------------------------
				# data
				# --------------------------------------------------
    elsif ($ct>=3) {
	@ar=split(/$sep_in+/,$tmp); 
	if ($Lcond){		# condition?
	    $ar[$cond_pos]=~s/\s//g;
	    if ((($cond_cond eq "==") && ($ar[$cond_pos] == $cond_val)) ||
		(($cond_cond eq ">=") && ($ar[$cond_pos] >= $cond_val)) ||
		(($cond_cond eq ">" ) && ($ar[$cond_pos] >  $cond_val)) ||
		(($cond_cond eq "<=") && ($ar[$cond_pos] <= $cond_val)) ||
		(($cond_cond eq "<" ) && ($ar[$cond_pos] <  $cond_val)) ||
		(($cond_cond eq "eq") && ($ar[$cond_pos] eq $cond_val)) ||
		(($cond_cond eq "ne") && ($ar[$cond_pos] ne $cond_val))) {
		$Lok=1;}else{$Lok=0;}}
	else{$Lok=1;}
	next if (! $Lok);
	foreach $itcol (@col_take){
	    if    ($Lprintf){
		printf  $fhout "$prt_form[$itcol]".$sep,$ar[$itcol]; }
	    elsif (defined $formatWant) {
		printf  $fhout "$formatWant".$sep,$ar[$itcol]; }
	    else {
		$tmp=$ar[$itcol];$tmp=~s/^\s*|\s*$//g;
		print  $fhout $tmp.$sep;} }
	print $fhout "\n"; }
} close(FILE_IN);

if ($LfileOut){
    print"output in '$fileOut'\n";close($fhout);} 
exit;

#===============================================================================
sub form_rdb2perl {
    local ($format) = @_ ;
    local ($tmp);
#--------------------------------------------------------------------------------
#   form_perl2rdb               converts RDB (N,F, ) to printf perl format (d,f,s)
#--------------------------------------------------------------------------------
    $format=~tr/[A-Z]/[a-z]/;
    $format=~s/n/d/;$format=~s/(\d+)$/$1s/;
    if ($format =~ /[s]/){
	$format="%-".$format;}
    else {
	$format="%".$format;}
    return $format;
}				# end of form_rdb2perl

#==========================================================================================
sub get_arg_range {
    local ($arg) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_arg_range              extracts two values or an array separated by tabs
#       in:                     excl=1-5 or so
#--------------------------------------------------------------------------------
    $arg=~s/^excl=|^incl=//g;$#res=$#tmp=0;
    if   ($arg=~/,/){@tmp=split(/,/,$arg);}
    else            {@tmp=($arg);}
    foreach $x (@tmp) {
	if ($x=~/[0-9*]-[0-9*]/){
	    ($beg,$end)=split(/-/,$x);
	    if ( ($beg eq "*") || ($end eq "*") ) {
		push(@res,$beg,$end);}
	    else {
		foreach $it($beg..$end){
		    push(@res,$it);}}}
	elsif ($x !~/-/){
	    push(@res,$x);}
	elsif ($x =~/\w-\w/){
	    ($beg,$end)=split(/-/,$x);
	    push(@res,"xxxbeg_$beg","xxxend_$end");}
	else {
	    print "*** ERROR get_arg_range: cannot process '$x'\n";
	    exit;}}
    return(@res);
}				# end of get_arg_range

#==========================================================================================
sub get_names2pos {
    local (@in) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_names2pos              extracts two values or an array separated by tabs
#       in:                     excl=1-5 or so
#--------------------------------------------------------------------------------
    $#tmp_name=$#tmp_pos=$#new=0;
    $Lnames=1;			# pre-process input
    foreach $in (@in){
	if ($in eq "xxx") { $Lnames=0;
			    next;}
	if ($Lnames)        { push(@tmp_name,$in);}
	else                { push(@tmp_pos,$in);} }
    $Lnot_num=0;
    foreach $pos(@tmp_pos){
	if ($pos=~/[^0-9]/){$Lnot_num=1;
			   last;}}
    if (! $Lnot_num) {		# ok : all numbers
	return (@tmp_pos);}
				# convert id's passed on command line to positions
    $Lbeg=0;
    foreach $it1 (1..$#tmp_pos){
	$Lok=0;
	$des=$tmp_pos[$it1];
	if ( $des =~ /xxxbeg_/){
	    $Lbeg=1;                  $des=~s/xxx..._//g;
	    $des_end=$tmp_pos[$it1+1];$des_end=~s/xxx..._//g; }
	if ( $des =~ /xxxend_/) {
	    $Lbeg=0;
	    next;}
	$it2=1;
	while ($it2 <= $#tmp_name){
	    if ($tmp_name[$it2] eq $des) {
		push (@new,$it2);
		if ($Lbeg) {while ( $tmp_name[$it2] ne $des_end ) {
		    ++$it2; push(@new,$it2);
		    if ($it2>$#tmp_name) {
			print "*** ERROR get_names2pos: it2=$it2, search '$des_end' ?\n";
			exit;} }}
		$Lok=1;
		last;}
	    ++$it2;}
	if (!$Lok){		# one found?
	    print "*** ERROR '$des' not to be found in RDB id's=\n";
	    print join(',',@tmp_name,"\n");
	    exit;}
    }
    return(@new);
}				# end of get_names2pos
