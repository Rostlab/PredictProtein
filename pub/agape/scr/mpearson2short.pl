#! /usr/bin/perl -w
$| =1;


($mpearson,$fileOutShort,$fileOutLong,$maxAli,$dbRelatFile)=@ARGV;

die "$0: arguments not defined mpearson=$mpearson, fileOutShort=$fileOutShort, fileOutLong=$fileOutLong, maxAli=$maxAli, dbRelatFile=$dbRelatFile, stopped"
    if(! defined $mpearson || ! defined $fileOutShort || ! defined $fileOutLong || ! defined $maxAli || ! defined $dbRelatFile );



#--------------------------------------------------------
undef %h_id2related;
open(FHIN,$dbRelatFile) ||
    die "failed to open dbRelatFile=$dbRelatFile, stopped";
while(<FHIN>){
    next if(/^\#|^\s*$/);
    s/\s*$//;
    ($id,$related)=split(/\t/,$_);
    die "in file $dbRelatFile id or group not found in line:\n$_\n, stopped"
	if(! defined $id || ! defined $related);
    $related=~s/\s//g;
    @l_related=split(/\,/,$related);
    foreach $idRel (@l_related){
	$h_id2related{$id}{$idRel}=1;
    }
}
close FHIN;  #-------------------------------------------


undef %h_pearsons;
($querySeq)=&read_mpearson($mpearson,\%h_pearsons);


undef %h_aliForm;
foreach $homCt (sort {$a <=> $b} keys %h_pearsons){
    last if($homCt > $maxAli);
    $qID  =$h_pearsons{$homCt}{'qid'};
    $sID  =$h_pearsons{$homCt}{'sid'};
    $qAli =$h_pearsons{$homCt}{'qali'};
    $sAli =$h_pearsons{$homCt}{'sali'};
    $info =$h_pearsons{$homCt}{'info'};

    $h_aliForm{$homCt}{'data'}{'qid'}=$qID;
    $h_aliForm{$homCt}{'data'}{'sid'}=$sID;
    $h_aliForm{$homCt}{'data'}{'info'}=$info;

    @l_qAli=split(//,$qAli);
    @l_sAli=split(//,$sAli);

    $qPos=$sPos=0; undef $qFirstAliPos; undef $sFirstAliPos;
    $qLastAliPos=$sLastAliPos=-1;
    undef $aliBegIndex; undef $aliEndIndex;
    die "ERROR: wrong lengths, stopped" if(length($qAli) != length($sAli));
    foreach $i (0 .. $#l_qAli){
	$qRes=$l_qAli[$i]; $sRes=$l_sAli[$i];
	$qIn=$sIn=0;
	if($qRes !~ /-/){ $qPos++; $qIn=1;}
	if($sRes !~ /-/){ $sPos++; $sIn=1;}
	if(! defined $qFirstAliPos && $qIn && $sIn){
	    $qFirstAliPos=$qPos; $sFirstAliPos=$sPos; $aliBegIndex=$i;
	}
	if($qIn && $sIn){ $qLastAliPos=$qPos; $sLastAliPos=$sPos; $aliEndIndex=$i;}
    }
    
    $linePos=$lineNumb=0; $qSeg=$sSeg=""; 
    $qPos=$qFirstAliPos -1; $sPos=$sFirstAliPos -1;
    for $i ($aliBegIndex .. $aliEndIndex){
	$qRes=$l_qAli[$i]; $sRes=$l_sAli[$i];
	if($qRes !~ /-/){ $qPos++;}
	if($sRes !~ /-/){ $sPos++;}
	$linePos++; $qSeg.=$qRes; $sSeg.=$sRes;
    
	if($linePos%60 ==1){
	    $lineNumb++;
	    $h_aliForm{$homCt}{'ali'}{$lineNumb}{'qBeg'}=$qPos;
	    $h_aliForm{$homCt}{'ali'}{$lineNumb}{'sBeg'}=$sPos;
	}
	if($linePos%60 ==0 || $i == $aliEndIndex ){
	    $h_aliForm{$homCt}{'ali'}{$lineNumb}{'qSeg'}=$qSeg;
	    $h_aliForm{$homCt}{'ali'}{$lineNumb}{'sSeg'}=$sSeg;
	    $h_aliForm{$homCt}{'ali'}{$lineNumb}{'qEnd'}=$qPos;
	    $h_aliForm{$homCt}{'ali'}{$lineNumb}{'sEnd'}=$sPos;
	    $qSeg=$sSeg="";
	}
    }

}

@l_qSeqBlocs=($querySeq=~/(\S{1,60})/g);
foreach $it (@l_qSeqBlocs){ $it="\# ".$it; }
$qSeqOutForm=join "\n", @l_qSeqBlocs;



open(FHOUT,">".$fileOutShort) ||
    die "failed to open fileOutShort=$fileOutShort, stopped";
print FHOUT "\# \"short\" alignment format (showing only aligned regions)\n";
print FHOUT "\# P-value, E-value : statistical significance of \"bi-directional\" scores (caution: too optimistic for highly significant values)\n";
print FHOUT "\# P-frwd, E-frwd   : statistical significance of \"forward\" scores (generalized profile of a query against a database of generalized sequences)\n";
print FHOUT "\# P-frwd, E-frwd   : statistical significance of \"reversed\" scores (generalized sequence of a query against a database of generalized profiles)\n";
print FHOUT "\# query sequence   :\n$qSeqOutForm\n\#\n";

foreach $homCt (sort {$a <=> $b} keys %h_aliForm){
    $sID  =$h_aliForm{$homCt}{'data'}{'sid'};
    $info =$h_aliForm{$homCt}{'data'}{'info'};
    print FHOUT ">$sID"." "."$info\n";
    foreach $lineNumb (sort {$a <=> $b} keys %{ $h_aliForm{$homCt}{'ali'} }){
	$qLine="Query:"; $sLine="Sbjct:";
	$qSeg=$h_aliForm{$homCt}{'ali'}{$lineNumb}{'qSeg'};
	$sSeg=$h_aliForm{$homCt}{'ali'}{$lineNumb}{'sSeg'};

	$qBeg=$h_aliForm{$homCt}{'ali'}{$lineNumb}{'qBeg'};
	$qBeg=sprintf "%-5.5s", $qBeg;

	$qEnd=$h_aliForm{$homCt}{'ali'}{$lineNumb}{'qEnd'};
	$qEnd=sprintf "%-5.5s", $qEnd;
	
	$sBeg=$h_aliForm{$homCt}{'ali'}{$lineNumb}{'sBeg'};
	$sBeg=sprintf "%-5.5s", $sBeg;
    
	$sEnd=$h_aliForm{$homCt}{'ali'}{$lineNumb}{'sEnd'};
	$sEnd=sprintf "%-5.5s", $sEnd;
	
	$qLine="Query: ".$qBeg.$qSeg." ".$qEnd."\n";
	$sLine="Sbjct: ".$sBeg.$sSeg." ".$sEnd."\n";
	print FHOUT $qLine;
	print FHOUT $sLine;
	print FHOUT "\n";
    }
}
close FHOUT;

open(FHOUTLONG,">".$fileOutLong) ||
    die "failed to open fileOutLong=$fileOutLong, stopped";
print FHOUTLONG "\# \"long\" alignment format (showing entire sequences)\n";
print FHOUTLONG "\# P-value, E-value : statistical significance of \"bi-directional\" scores (caution: too optimistic for highly significant values)\n";
print FHOUTLONG "\# P-frwd, E-frwd   : statistical significance of \"forward\" scores (generalized profile of a query against a database of generalized sequences)\n";
print FHOUTLONG "\# P-frwd, E-frwd   : statistical significance of \"reversed\" scores (generalized sequence of a query against a database of generalized profiles)\n";
print FHOUTLONG "\# query sequence   :\n$qSeqOutForm\n\#\n";
foreach $homCt (sort {$a <=> $b} keys %h_pearsons){
    last if($homCt > $maxAli);
    $qID  =$h_pearsons{$homCt}{'qid'};
    $sID  =$h_pearsons{$homCt}{'sid'};
    $qAli =$h_pearsons{$homCt}{'qali'};
    $sAli =$h_pearsons{$homCt}{'sali'};
    $info =$h_pearsons{$homCt}{'info'};
    print FHOUTLONG ">$sID"." "."$info\n";
    print FHOUTLONG "Query:\t".$qAli."\n";
    print FHOUTLONG "Sbjct:\t".$sAli."\n";
    print FHOUTLONG "\n";
}
close FHOUTLONG;

#======================================================================
sub read_mpearson{
    my $sbr="read_mpearson";
    my ($file,$hr_pearson)=@_;
    my ($ct,$qID,$qAli,$qFasta,$sID,$subjectID,$sAli,
	$sFasta,$homCt,$info,$Pvalue,$Evalue);
    my $fh="FH".$sbr;

    if($file=~/\.gz$/){
	$cmd="gunzip -c $file";
	open($fh,"$cmd |") ||
	    return(0,"ERROR failed to open $cmd, stopped");
    }else{
	open($fh,$file) ||
	    return(0,"ERROR failed to open file=$file, stopped");
    }
    
    $ct=0; $homCt=0;
    while(<$fh>){
	next if(/^\#|^\s*$/);
	s/\s*$//;
	if(/^>(\S+)\s*(.*)/){ 
	    $subjectID=$1; $info=$2; $ct=0; $homCt++;
	    $$hr_pearson{$homCt}{"info"}  =$info;
	    ($Pvalue)=($info=~/P-value=(\S+)/);
	    ($Evalue)=($info=~/E-value=(\S+)/);
	    $$hr_pearson{$homCt}{"pvalue"}=$Pvalue;
	    $$hr_pearson{$homCt}{"evalue"}=$Evalue;
	}
	elsif(/^(\S+)\t(\S+)/){
	    $ct++;
	    if($ct ==1){
		($qID,$qAli)=split(/\s+/,$_);
		$qAli=~tr[a-z][A-Z];
		$qFasta=$qAli; $qFasta=~s/-//g;
		$$hr_pearson{$homCt}{"qid"}   =$qID;
		$$hr_pearson{$homCt}{"qali"}  =$qAli;
		$$hr_pearson{$homCt}{"qfasta"}=$qFasta;
	    }elsif($ct ==2){
		($sID,$sAli)=split(/\s+/,$_);
		die "wrong pearson format in $file, stopped"
		    if($sID ne $subjectID);
		$sAli=~tr[a-z][A-Z];
		$sFasta=$sAli; $sFasta=~s/-//g;	
		$$hr_pearson{$homCt}{"sid"}   =$sID;
		$$hr_pearson{$homCt}{"sali"}  =$sAli;
		$$hr_pearson{$homCt}{"sfasta"}=$sFasta;
	    }else{ die "wrong pearson format in $file, stopped"; }
	}else{ die "wrong pearson format in $file, stopped"; }
	
    }
    return ($qFasta);
}
#=======================================================================
