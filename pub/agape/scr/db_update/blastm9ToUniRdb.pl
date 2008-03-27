#! /usr/bin/perl -w

($fileIn,$minDist)=@ARGV;

$minDist=0 if(! defined $minDist);
$maxEval=1;
$minLali=12;
@l_headerFields=("id1","id2","lali","pide","dist","prob","score");

if($fileIn =~ /\.list/){
    open(FHIN,$fileIn) || die "here";
    while(<FHIN>){
	next if(/^\#|^\s*$/);
	s/\s//g;
	$h_filesIn{$_}=1;
    }
    close FHIN;
}else{
    $h_filesIn{$fileIn}=1; 
}

$fh="FHINLOC";
foreach $fileIn (sort keys %h_filesIn){
    if($fileIn=~/\.gz$/){
	$cmd="gunzip -c $fileIn";
	open($fh,"$cmd |") ||
	    die "ERROR failed to open $cmd, stopped";
    }else{
	open($fh,$fileIn) ||
	    die "ERROR failed to open fileIn=$fileIn, stopped";
    }
    $HeaderFound=0;
    undef %h_data;
    $aliCt=0;
    while(<$fh>){
	if(/\# Fields: Query id, Subject id, % identity, alignment length, mismatches, gap openings, q. start, q. end, s. start, s. end, e-value, bit score/){ $HeaderFound=1; }
	next if(/^\#|^\s*$/);
	die "header not found in $fileIn, stopped"
	    if(! $HeaderFound);
	s/\n$//;
	@l_lineData=split(/\t/,$_);
	foreach $it (@l_lineData){
	    die "data in line:\n$_\nnot defined, stopped"
		if(! defined $it);
	}
	($id1,$id2,$ideWgap,$lenWgap,$mismatchNo,$gapOpenNo,$qstart,$qend,$sstart,$send,$eValue,$bitScore)=@l_lineData;
	undef $gapOpenNo; undef ($psim);
	$id1=~s/.*\|//; $id2=~s/.*\|//; 
	$ideNo=sprintf "%3.0f", $lenWgap * $ideWgap/100;
	$aliLen=$ideNo + $mismatchNo;
	$gapLen=2 * $lenWgap -($qend-$qstart +1 + $send-$sstart +1);
	$aliLenCheck=$lenWgap -$gapLen;
	#print "WARNING: alignment lengths in file=$fileIn $id1 $id2 calculated in independent ways not eqal: $aliLen vs $aliLenCheck in line:\n$_\n $aliLen $aliLenCheck\n" 
	    #if($aliLen != $aliLenCheck);
	$aliLen=$aliLenCheck;
	$pide=$ideNo/$aliLen * 100;
	$psim=$mismatchNo/$aliLen * 100;
	$dist=&hssp_dist($pide,$aliLen);
	$pide=sprintf "%3.2f", $pide; $pide=~s/\s//g;
	$dist=sprintf "%3.2f", $dist; $dist=~s/\s//g;
	
	next if($dist <= $minDist && $eValue >= $maxEval);
	if($aliLen < $minLali){ next; }
	next if(defined $h_data{$id1}{$id2} &&
		$h_data{$id1}{$id2}{"dist"} >= $dist);
	$h_data{$id1}{$id2}{"id1"}   =$id1;
	$h_data{$id1}{$id2}{"id2"}   =$id2;
	$h_data{$id1}{$id2}{"dist"}  =$dist;
	$h_data{$id1}{$id2}{"pide"}  =$pide;
	$h_data{$id1}{$id2}{"lali"}  =$aliLen;
	$h_data{$id1}{$id2}{"prob"}  =$eValue;
	$h_data{$id1}{$id2}{"score"} =$bitScore;
	$aliCt++;
    }
    close $fh;
    if($aliCt ==0){
	print "WARNING: did not find any alignments in fileIn=$fileIn\n";
    }
    $fileOut=$fileIn; $fileOut=~s/.*\///; $fileOut=~s/\..*//;
    $fileOut.=".rdbBlast";
    open(FHOUT,">".$fileOut) ||
	die "failed to open $fileOut for writing, stopped";
    $rdbHeader=&get_rdbHeader;
    print FHOUT $rdbHeader;
    foreach $id2 (sort {$h_data{$id1}{$b}{"dist"} <=> $h_data{$id1}{$a}{"dist"} } keys %{ $h_data{$id1} }){
	$lineRdb="";
	foreach $field (@l_headerFields){
	    $val=$h_data{$id1}{$id2}{$field};
	    die "val not defined, stopped" if(! defined $val);
	    $lineRdb.=$val."\t";
	}
	$lineRdb=~s/\t$/\n/;
	print FHOUT $lineRdb;
    }
    close FHOUT;
    system("gzip -f $fileOut")==0 ||
	die "failed to zip $fileOut, stopped";
}
	
#=========================================================================
# calculates HSSP-Distance using the formula from Burkhard's
# HSSP-Paper 1999
sub hssp_dist {
    my $sbr="hssp_dist";
    my($pi) = shift;
    my($len) = shift;

    die "$sbr: args not defined, stopped"
	if(! defined $pi || ! defined $len);
    if ($len <= 11) {
        return -999;
    }
    elsif ($len > 450) {
        return $pi - 19.5;
    }
    else {
        my($exp) = -0.32 * (1 + exp(- $len / 1000));
        return $pi - (480 * ($len ** $exp));
    }
}
#=====================================================================

#=====================================================================
sub get_rdbHeader{
    my $sbr="get_rdbHeader";
    my $header;

$header=
"# Perl-RDB  format
# --------------------------------------------------------------------------------
# FORM  beg          
# FORM  general:     - lines starting with hashes contain comments or PARAMETERS
# FORM  general:     - columns are delimited by tabs
# FORM  format:      '# FORM  SPACE keyword SPACE further-information'
# FORM  parameters:  '# PARA: SPACE keyword SPACE=TAB value TAB (further-info)'
# FORM  notation:    '# NOTA: SPACE keyword SPACE=TAB explanation'
# FORM  1st row:     column names  (tab delimited)
# FORM  2nd row (may be): column format (tab delimited)
# FORM  rows 2|3-N:  column data   (tab delimited)
# FORM  end          
# --------------------------------------------------------------------------------
# NOTA  begin        ABBREVIATIONS
# NOTA               column names 
# NOTA: id1          =	guide sequence
# NOTA: id2          =	aligned sequence
# NOTA: lali         =	alignment length
# NOTA: pide         =	percentage sequence identity
# NOTA: dist         =	distance from new HSSP curve
# NOTA: prob         =	BLAST probability
# NOTA: score        =	BLAST raw score
# NOTA               parameters
# NOTA  end          ABBREVIATIONS
# --------------------------------------------------------------------------------
# PARA  beg          
# PARA: minLali      =  $minLali
# PARA: minDist      =	$minDist
# PARA  end          
# --------------------------------------------------------------------------------
id1\tid2\tlali\tpide\tdist\tprob\tscore\n";

    return($header);
}
#=======================================================================
