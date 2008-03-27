#!/usr/bin/perl
# colstat.pl
# some statistics from columns in file; colstat.pl -h for details
# the numeric fields are determined from the first line
#
# Written by Philip lijnzaad@embl-heidelberg.de

$INTEGER = '[-+]?\\d+';			      # strict int
$FLOAT   = '[-+]?\\d*\\.\\d+(e[-+]?\\d+)?';    # strict float
$NUMBER  = '[-+]?\\d*(\\.\\d+)?(e[-+]?\\d+)?'; # float or int

$HUGE = '1.0e+35';

sub abs {				# absolute value
    local($a) = @_; 
    die "'$a' not a number" if $a !~ /^$NUMBER$/o;
    $a<0?-$a:$a;
}

sub quote {
    local($string) = @_;
    local($*) = 1;
    $string =~ s/^:\t?//g;
    $string;
}

$Usage = &quote(<<ENDUSAGE);
:	Usage:
:	
:	  fstat.pl -[hcdfij] [-t SEP] [-s N] [-J N] [-D N] [-F FMT] [-I fields] [-C f1,f2]  [FILES]
:	
:	  Calculate some simple statistics on numbers in all columns of FILES
:	  or stdin. The number of fields and the valid numerical ones to
:	  consider are obtained from the first line (line N if using -s N)
:	
:	Options:
:	
:	   -h print this help message;
:	   -s N start at line number N; default is 1
:	   -t SEP use SEP as field separator. Can be a regular expression.
:	      Default is whitespace.
:	   -c check mode: check for (and ignore) invalid records (i.e. ones that
:	      do not look like the first one). 
:	   -i numbers have to be strict integers (cannot contain '.'; ignore floats)
:	   -f numbers have to be strict floats  (must contain '.'; ignore integers)
:	
:	   -j give info on line-to-line jumps (differences)
:	   -d give info on line-to-line distances
:	   -I FLDS ignore fields. FLDS is a comma (or whitespace) separated list of
:	      field numbers; counting is done relative to 'valid' fields; use
:	      negative numbers for 'absolute' fields. Counting starts at 1;
:	      Useful mainly when using J or D options.
:	   -C F1,F2 give correlation of fields F1 and F2. If there are only 2
:	      numeric fields in input anyway, this is done automatically. Field
:	      specification as in -I option.
:	   -J N consider every line-to-line (absolute) difference bigger than N
:	      to be a jump to be warned about.
:	   -D N above N, line-to-line euclidean distances are warned about.
:	      The first three (two) fields are taken to be 3D coordinates; use -I
:	      to skip other fields. (Implies -d)
:	   -F FMT print format to use; default is "%.3g"
ENDUSAGE


# process command line options:
require "getopts.pl";
&Getopts('cdhfijt:s:J:D:F:I:C:');

$check= $opt_c;
$start = $opt_s?$opt_s:1;		# line to start with
$field_sep= $opt_t?$opt_t:' ';		# field separator
die $Usage if $opt_h; 

PAT: {					# little case statement
    die $usage if $opt_i && $opt_f;	# mutually exclusive
    $opt_f && ( $number_pat = "^$FLOAT$"   , last PAT );
    $opt_i && ( $number_pat = "^$INTEGER$" , last PAT );
    $number_pat = "^$NUMBER$";
}

$jump = $opt_J; $opt_j=1 if $opt_J;
$delta = $opt_D; $opt_d=1 if $opt_D;

$fmt = $opt_F? $opt_F : "%.3g";
@ignore = split(/[, ]+/,$opt_I);
@corrl = split(/[, ]+/,$opt_C);
die $usage if @corrf && @corrf != 2;	# what else

$[ = 1;					# set array base to 1

$_ = <> while ($. != $opt_s);		# first line
chop;
@F = split($field_sep);

# determine which fields are numeric (from first record), and skip
# unwanted ones; fields are numbered absolute if negative, relative (to
# valid ones) otherwise

for ($j=0,$i=1; $i <= @F; $i++) {
    next if  ($F[$i] !~ /$number_pat/o); # first of all, should be a number
    $j++;				# $j counts 'valid' numbers
    push(@numeric, $i)			# keep it 
	unless grep(($_ == ($_<0?-$i:$j)), @ignore); # if not to be ignored
    if (@corrl) {			# if correlations wanted
	push(@corr, $j)			# keep relative field nr
 	    if grep(($_ == ($_<0?-$i:$j)), @corrl); # 
    }
}

$n=@numeric;				# nr of fields to consider
# @corr=@numeric if @numeric==2;        # give correlation etc. automatically 
@corr=(1, 2) if !@corrl && @numeric==2;	# give correlation etc. automatically 


if (@corr) {				# (p)open filenames
    $xname="/usr/tmp/sortx$$";
    $yname="/usr/tmp/sorty$$";
    open(XFILE, ">$xname") || die "$xname: $!";
    open(YFILE, ">$yname") || die "$yname: $!";
}

for ($i = 1; $i <= $n; $i++) {		# initialize arrays
    $min[$i]=$mindiff[$i]= $HUGE;
    $max[$i]=$maxdiff[$i]= -$HUGE;
}
$maxdist = -1.0;
$mindist = $HUGE;			# "

@G = @F[ @numeric ];			# select numeric stuff by slicing
&update;				# don't forget first line

for ($i = 1; $i <= $n; $i++) {
    $prev[$i] = $G[$i];
}
$prevline = $_;
$nrec++;

LINE:					# main loop
while (<>) {
    chop;
    @F = split($field_sep, $_);
    @G = @F[ @numeric ];		# select numeric stuff by slicing
    if ($check) { next LINE if &check; }
    $nrec++; 

    &update;				# averages and such 
    next unless $opt_j;			# 

    for ($i = 1; $i <= $n; $i++) {
	$f = &abs($prev[$i] - $G[$i]);	# differences and jumps
	printf "jump of $fmt in col $numeric[$i]\n$.:$_\n<->\n%d:$prevline\n\n"
	    , $f , $. -1 if $jump && ( $f > $jump );
	($mindiff[$i], $mindiffnr[$i]) = ($f , $.) if ($f < $mindiff[$i]);
	($maxdiff[$i], $maxdiffnr[$i]) = ($f , $.) if ($f > $maxdiff[$i]);
	$sumdiff[$i] += $f;
	$sumdiff2[$i] += $f * $f;
    }

    &dists if opt_d;

    for ($i = 1; $i <= $n; $i++) { $prev[$i] = $G[$i]; }
    $prevline = $_;
}

&pstatistics;

if (@corr) {
    print STDERR "\nCalculating correlations ...\n";
    &pcorr;
}

&pdiffs if $opt_j;
&pdists if $opt_d;
exit;

sub update {				# get everything we want
    for ($i = 1; $i <= $n; $i++) {
	$sum[$i] += $G[$i];
	$sum2[$i] += $G[$i] * $G[$i];
	($min[$i],  $minnr[$i]) = ($G[$i], $. ) if ($G[$i] < $min[$i]);
	($max[$i],  $maxnr[$i]) = ($G[$i], $. ) if ($G[$i] > $max[$i]);
    }
    if (@corr) { 
	($x, $y) = @G[ @corr ];
	$cross += $x*$y;
	print XFILE "$. : $x \n"; 
	print YFILE "$. : $y \n"; 
    }
}

sub check {				# return 1 if wrong line;
    local($f) = grep(/$number_pat/o , @F);
    $f = grep(/$number_pat/o , @F);
    if ( $f != @numeric ) { # should be same number
	print "line $.:\n$_:\n $f numeric fields "
	    ."instead of exspected $n; ignored\n";
	1;
    } else { 0;}
}

sub dists {
    local($d, $d2);
    # calculate squared distance
    for ($i = 1; $i <= 3 ; $i++) {	# makes more sense than $n
	$d = $prev[$i] - $F[$i]; 
	$d2 += $d*$d;
    }
    $d = sqrt($d2);
    printf "distance jump of $fmt in line $.:\n$_\n<->\n$prevline\n", $d
	if ($delta && $d > $delta);
    ($mindist, $mindistnr) = ($d,  $.) if ($d < $mindist);
    ($maxdist, $maxdistnr) = ($d,  $.) if ($d > $maxdist);
    $sumdist += $d;
    $sumdist2 += $d2;
}

sub pstatistics {
    local($av, $dev);
    print "\n\nstatistics:\n";
    for ($i = 1; $i <= $n; $i++) {
	$nvar = $nvar[ $i ] = $sum2[$i] -
	    (&square($sum[$i])/$nrec);	# need later on 
	$dev = sqrt($nvar / ($nrec -1)); # -1 !!!
	$av=$sum[$i]/$nrec;
	printf "col %d: avg $fmt stddev $fmt (%.1f %%)\t".
	    "N %d sum $fmt sum2 $fmt\n"
	    ,$numeric[$i], $av, $dev, $dev/$av*100.0
		, $nrec, $sum[$i], $sum2[$i];

 	printf "         min $fmt [line %d] max $fmt [line %d] "
	    ."diff $fmt",
	    $min[$i], $minnr[$i], 
	    $max[$i], $maxnr[$i], 
	    $max[$i] - $min[$i];
	if (&abs($dev) > 0.01) {
	    printf " ($fmt s)\n", ($max[$i] - $min[$i])/$dev; 
	} else {
	    print " (Infinity s)\n";
	}	    
    }
}
 
sub pcorr {
    print "\n";
    # first the rank correlation (Spearman)
    local($t, $r, $denom, $n, $signif, $rcross);
    local(@xranks, $sumx, $sumx2, $avx, $nvarx);
    local(@yranks, $sumy, $sumy2, $avy, $nvary);

#    local($oldoffset) = $[;
    close(XFILE);
    close(YFILE);

    @xranks = &rank($xname);		# rank them, including midranking
    @yranks = &rank($yname);
#    unlink( $xname, $yname);
    die "x and y unequal length" if ( ($n=scalar(@xranks)) !=
				     scalar(@yranks) );

    for ($i=1; $i <= $n; $i++) { $rcross += $xranks[$i]*$yranks[$i]; }
    ($sumx, $sumx2) = &sumn_n2(@xranks);
    $avx = $sumx/$n; $nvarx = $sumx2 - $n*$avx*$avx;
    ($sumy, $sumy2) = &sumn_n2(@yranks);
    $avy = $sumy/$n; $nvary = $sumy2 - $n*$avy*$avy;

    $denom= $nvarx*$nvary;
    if ($denom == 0.0 ) { 
	print "zero variance; no rank correlation coefficient\n"; }
    else  {
	$r = ($rcross - $n*$avx*$avy)/ sqrt($denom);

#	$df = $n-2;			# degrees of freedom
#	$t = $r*sqrt( $df/(1-$r*$r));
#	$cmd= sprintf "betai %f %f %f ", 0.5*$df, 0.5, $df/($df + $t*$t);
#	$signif = chop `echo $cmd  | math`;
	$" = " and ";			# set the intra-string array separator
	printf "rank correlation between col @numeric[@corr]: $fmt\n", $r;
	printf "significance $fmt\n" if $signif;
    }

    # now the linear correlation
    $denom = $nvar[ $corr[1] ] *$nvar[ $corr[2] ];
    die "\$denom < 0 " if $denom < 0; 

    if ($denom == 0.0 )  { 
	printf "zero variance; no linear correlation coefficient\n";}
    else  {
	$r = ($cross - ($sum[$corr[1]]*$sum[$corr[2]]/$nrec) )
	    /sqrt($denom);
#	    $t = &abs(r)*sqrt($nrec)/$SQRT2;
#	    $signif = chop `echo erfc $t |math`;
	printf "linear correlation between col @numeric[@corr]: $fmt\n", $r;
	printf "significance $fmt\n" if $signif;
    }
#    $[= $oldoffset;
}


sub rank  {
# do ranking for stuff in xfile and yfile, including midranks
    local($file) = @_;			# file name
    local($id, $val, %occ, %rank, @ties, @tiid, $midrank);

    open(FILE, "sort -t: +1n $file |") || die "$file: $!";

    while(<FILE>) { 
	(($id, $val) = /^\s*(\d+)\s*:\s*($NUMBER)\s*$/o); # == 2
#	    || die "'$id' '$val' not \$id : \$val";
	$rank{$id} = $.; 
	$occ{$val} .= ":$id";
    }
    close(FILE);

    foreach $val (keys %occ) {
	@tiid = split(/:/, $occ{$val});	# $id(s) of value $val
	shift @tiid;			# get rid of first colon
	die "Bug" unless @tiid;		# cannot be empty;
	next if @tiid==1;		# not interesting

	@ties = sort bynum @rank{ @tiid }; # @ties is the range of ranks
					   # given for ties
	$midrank = 0.5 *( @ties[ $[ ] + @ties[ $#ties ] ); # the average 
	grep ( $_ = $midrank, @rank{ @tiid } );	# adjust the rank of tied id's
	$ties += &cubic(scalar(@ties)) - @ties; 
    }
    ;
    @rank{ sort keys %rank } ;		# return value
}

sub pdiffs {
    print "\nline-to-line differences:\n";
    for ($i = 1; $i <= $n; $i++) {
	$S = (sqrt($nrec * $sumdiff2[$i] - &square($sumdiff[$i]))/($nrec-1));
	printf "col %d: avg $fmt stddev $fmt\n"
#	,$i,$sumdiff[$i]/$nrec , $S;
	    ,$numeric[$i],$sumdiff[$i]/$nrec , $S;
	printf "        min $fmt [line %d] max $fmt [line %d] "
	    ."diff $fmt ($fmt s)\n", $mindiff[$i], $mindiffnr[$i],
	    $maxdiff[$i], $maxdiffnr[$i], $maxdiff[$i] - $mindiff[$i],
	    ($maxdiff[$i] - $mindiff[$i]) / ($S == (0.0 ? $HUGE : $S)); 
	# often in sorted data one field constant increase, so s==0.0
    }
}

sub pdists {
    print "\nline-to-line euclidean distances:\n";
    $S = (sqrt($nrec * $sumdist2 - &square($sumdist)) / ($nrec-1));
    printf "avg $fmt stddev $fmt \n", $sumdist / $nrec, $S; 
    printf "min $fmt [line %d] max $fmt [line %d] diff $fmt ($fmt s)\n", 
    $mindist, $mindistnr, $maxdist, $maxdistnr, 
    $maxdist - $mindist, ($maxdist - $mindist) / ($S == (0.0 ? $HUGE : $S));
}
