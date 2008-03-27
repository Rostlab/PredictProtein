#! /usr/bin/perl -w

($mfasta,@l_args)=@ARGV;

$g_minLen=30;
$g_maxUnkFract=0.1;

foreach (@l_args){
    if(/minlen=(\S+)/i) { $g_minLen=$1; }
    elsif(/unk=(\S+)/i) { $g_maxUnkFract=$1; }
    elsif(/fileout=(\S+)/i) { $fileOut=$1; }
}

if(! defined $fileOut){
    $fileOut=$mfasta; $fileOut=~s/^.*\///; 
    $fileOut.="-processed";
}
open(FHOUT,">".$fileOut) ||
    die "failed to open fileOut=$fileOut, stopped";

$lineCt=0;
open(FHIN,$mfasta) || die "did not open mfasta=$mfasta, stopped";
while(<FHIN>){
    next if(/^\s*$|^\#/);
    $lineCt++;
    if(/^>(\S+)/){ 
	$idNew=$1;
	if($lineCt > 1){
	    $seq=~s/\s//g; $seq=~s/\n//g;
	    $seq=~s/\!//g;
	    $seq=~tr[a-z][A-Z];
	    $exclude=&process_seq($seq);
	    if(! $exclude){ 
		print FHOUT ">$id\n";
		print FHOUT "$seq\n";
	    }else{ print "excluded: $id $seq\n"; }
	}
	$id=$idNew;
	$seq="";
	
    }else{
	$seq.=$_;
    }
}
$exclude=&process_seq($seq);
if(! $exclude){ 
    print FHOUT ">$id\n";
    print FHOUT "$seq\n";
}else{ print "excluded: $id $seq\n"; }
close FHIN;
close FHOUT;
    
#======================================================================	
sub process_seq{
    my $sbr="process_seq";
    my ($seq)=@_;
    die "$sbr: seq not defined, stoppe" if(! defined $seq);
    my ($exclude,$len,$xesNumb,$unkFract);

    $exclude=0;
    $seq=~s/\s//g; $seq=~s/\n//g;
    $seq=~s/\!//g;
    $seq=~tr[a-z][A-Z];
    $len=length($seq);
    if($len < $g_minLen){ $exclude=1; print "too short\n";}
    
    @l_xes=($seq=~/(X)/g);
    $xesNumb=$#l_xes+1;
    if($len > 0){ $unkFract=$xesNumb/$len; }
    else{ $unkFract=0; }
    if($unkFract > $g_maxUnkFract){ $exclude=1; print "too x'y\n";}
    
    if($seq !~ /[^ACGUTIXF]/i){ $exclude=1; print "nucleic\n" }
    return($exclude);
}
#======================================================================
