#! /usr/bin/perl -w

($StripFile,$FileListOut,$TempNumb,$dbg)=@ARGV;

$par{'dssp_dir'}    ="/data/dssp/";
if(! defined $StripFile){
    die "$0: argument StripFile not defined, stopped";
}
if(! -e $StripFile){
    die "$0: StripFile=$StripFile not found, stopped";
}
if(! defined $FileListOut){
    die "$0: FileListOut=$FileListOut not defined, stopped";
}

$dbg=0 if(! defined $dbg);

if(! defined $TempNumb){
    print "INFO $0: limiting number of templates for 2-nd pass not defined, taking all\n";
    $TempNumb=1000000;
}

($Lok,$msg,$hr_StripData)=&parse_strip($StripFile);
die "ERROR $msg, stopped" if(! $Lok);

open(FHOUT,">".$FileListOut) ||
    die "$0: failed to open FileListOut=$FileListOut for writing, stopped";

$Rank=0;
foreach $homid (sort { $$hr_StripData{$b}{'Zscore'} <=> $$hr_StripData{$a}{'Zscore'} } keys %{ $hr_StripData } ){
    if($homid !~ /^\d/){ die "$0: homid=$homid has not a proper format, stopped"; }
    elsif( length($homid) == 4){
	$dsspfile=$par{'dssp_dir'}.$homid.".dssp";
    }
    elsif( length($homid) == 6 && $homid =~ /(\S{4,4})_(\S)/ ){
	$coreid=$1; $chain=$2;
	$dsspfile=$par{'dssp_dir'}.$coreid.'.dssp_!_'.$chain;
    }
    else{ die "$0: homid=$homid has not a proper format, stopped"; }
    
    $Rank++;
    last if($Rank > $TempNumb);
    
    print FHOUT $dsspfile,"\n";
}
close FHOUT;


#==============================================================================
sub parse_strip{
    $sbr='parse_strip';
    my ($StripFile)=@_;
    my ($FileOut,$HomID,$Iden,$Query,$Rank,$Read,$Score,$Zscore);
    my (@data,@fields);
    my (%h_field2column,%h_Results);   
    
    open(FHIN,$StripFile) ||
	die "StripFile=$StripFile not found, stopped";
    $Read=0;
    while(<FHIN>){
	next if(/^\#|^\s*$/);
	s/^\s*|\s*$//g;
	if(/test\s*sequence\s*:\s*(\S+)/){
	    $Query=$1; $Query=~s/.*\///; $Query=~s/\..*$//;
	    $Query=~s/_//;
	}
	last if(/==\s*ALIGNMENTS/);
	if(/==\s*SUMMARY/){ $Read=1; next;}
	next if(! $Read);
	if(/IAL\s*VAL\s*LEN/){ 
	    @fields=split(/\s+/,$_);
	    #print "Fields:\t",@fields,"\n";
	    for $i (0 .. $#fields){
		#print "field=".$fields[$i]."\tcolumn=".$i."\n";
		$h_field2column{ $fields[$i] }= $i;
	    }
	    next;
	}
	@data=split(/\s+/,$_);
	$HomID    =$data[ $h_field2column{'NAME'} ]; #$HomID=~s/_//;
	$Zscore   =$data[ $h_field2column{'ZSCORE'} ];
	$Score    =$data[ $h_field2column{'VAL'} ];
	$Iden    =$data[ $h_field2column{'%IDEN'} ];
	if(defined $h_Results{ $HomID } )  { next; }  #take best alignment
	else{
	    $h_Results{$HomID}{'Zscore'}  =$Zscore;
	    $h_Results{$HomID}{'VAL'}     =$Score;
	    $h_Results{$HomID}{'%IDEN'}   =$Iden;
	}
    }
    close FHIN;
    if($dbg > 1){
	$FileOut=$StripFile; $FileOut=~s/.*\/|\..*$//g;
	$FileOut.=".ParsedStirp";
	open(FHOUT,">".$FileOut) ||
	    die "failed to open FileOut=$FileOut, stopped";
	print FHOUT "QUERY=".$Query."\n";
	$Rank=0;
	foreach $HomID (sort { $h_Results{$b}{'Zscore'} <=> $h_Results{$a}{'Zscore'} } keys %h_Results ){
	    $Rank++;
	    print FHOUT $Query."\t".$Rank."\t".$HomID."\t".$h_Results{$HomID}{'Zscore'}."\n";
	}
	close FHOUT;
    }
    return(1,"$sbr: OK",{%h_Results});
}
#===============================================================================
