#! /usr/bin/perl -w

($mfasta,$hsspFile,$dirOut)=@ARGV;
die "args mfasta,hsspFile,dirOut not defined, stopped" if(! defined $mfasta || 
				   ! defined $hsspFile || 
				   ! defined $dirOut);

$stripFlag=0;
$dirOut.="/" if($dirOut !~ /\/$/);

open(FHIN,$mfasta) || die "failed to open $mfasta, stopped";
while(<FHIN>){
    if(/>(\S+)/){ $id=$1; $id=~s/.*\|//; next;}
    $h_fastas{$id}.=$_;
}
close FHIN;
foreach $id (sort keys %h_fastas){
    $h_fastas{$id}=~s/\s//g;
}

    
($Lok,$msg,$query)=&parse_hssp($hsspFile,'50');
return(0,"ERROR $msg") if (!$Lok);


$dir=$dirOut.$query;
if(! -e $dir){
    system("mkdir $dir")==0 ||
	die "failed to mkdir $dir, stopped";
}
foreach $subject (keys %h_aliId2pearson){    
    $fileOut=$dir."/".$query."-".$subject.".pearson";
    next if(-e $fileOut);
    $totqali=$h_aliId2pearson{$subject}{'query'};
    $totsali=$h_aliId2pearson{$subject}{'subject'};

    #print "subject: $subject\n";
    #print "totqali: $totqali\n";
    #print "totsali: $totsali\n";

    $qfasta=$h_fastas{$query};
    $sfasta=$h_fastas{$subject};
    $qpiece=$totqali; $qpiece=~s/-//g;
    $spiece=$totsali; $spiece=~s/-//g;

    ($qfront,$qmatch,$qend)=($qfasta=~/^(\S*)($qpiece)(\S*)$/);
    die "match not found for query   $query:\npiece: $qpiece\nfasta: $qfasta\n"
	if(! defined $qmatch);

    ($sfront,$smatch,$send)=($sfasta=~/^(\S*)($spiece)(\S*)$/);
    die "match not found for subject $subject:\npiece: $spiece\nfasta: $sfasta\n"
    	if(! defined $smatch);
    
    $len=length ($qfront);
    $q2sfront="";
    for $i (1 .. $len){ $q2sfront.="-"; }

    $len=length ($sfront);
    $s2qfront="";
    for $i (1 .. $len){ $s2qfront.="-"; }

    $len=length ($qend);
    $q2send="";
    for $i (1 .. $len){ $q2send.="-"; }

    $len=length ($send);
    $s2qend="";
    for $i (1 .. $len){ $s2qend.="-"; }

    open(FHOUT,">".$fileOut) ||
	die "failed to open $fileOut for writing";
    print FHOUT $query."\t".$s2qfront.$qfront.$totqali.$qend.$s2qend."\n";
    print FHOUT $subject."\t".$sfront.$q2sfront.$totsali.$q2send.$send."\n";
    close FHOUT;
    system("gzip -f $fileOut");
}


#=================================================================
sub parse_hssp{
    my $sbr='parse_hssp';
    my ($hsspFile,$maxAli)=@_;
    my ($nalign,$proteins,$alignments,$insertions,$cutter,$rank,
	$alignedId,$cut,$IFIR,$ILAS,$JFIR,$JLAS,$aminapos,$chainpos,
	$ResNum,$Residue,$Chain,$PDBID,$chain,$coreid,$howmany);
    my ($AliNo,$IPOS,$JPOS,$Len,$Sequence);
    my (@header,@data,@aliData,@AliStrings,@queryRes,
	@queryChain,@queryNum,@CASPALSTRING,@RESULT);
    my (%InsertionsHash,%h_AlignedAtHigherRank);
    my $fh="FH_".$sbr;

    $proteins=0;$alignments=0;$insertions=0;$page=-1;$cutter=0;
    $lineCount=0;
    $aliData[0]='';   #first alignment corresponds to array element 1
    return(0,"ERROR $sbr: missing arguments in: @_") 
	if ($#_<1);
    for $i (0 ..$#_){ $j=$i+1; 
		      return(0,"ERROR $sbr: argument number $j not defined") 
			  if(! defined $_[$i]);    }
    if($hsspFile=~/\.gz$/){
	$cmd="gunzip -c $hsspFile";
	open($fh,"$cmd |") ||
	    return(0,"ERROR failed to open $cmd, stopped");
    }else{
	open($fh,$hsspFile) ||
	    return(0,"ERROR failed to open hsspFile=$hsspFile, stopped");
    }

    $howmany=0;
    while(<$fh>){
	next if($_=~/^\/\//);
	if($_=~/\!\s+\!\s+/){next;}
	#if($_=~/^NALIGN/){($nalign)=m/^NALIGN\s+(\S*)\s*$/;
	#       $howmany=$nalign if($howmany eq 'all' || $howmany > $nalign); 
	#       return(0,"ERROR $sbr: undefined nalign field in $hsspFile\n")
	#	   if (! defined $nalign);     }
	if($_=~/^PDBID/){($PDBID)=m/^PDBID\s+(\S*)\s*$/;
	       return(0,"ERROR $sbr: undefined nalign field in $hsspFile\n")
		   if (! defined $PDBID);     }
	if($_=~/^\#\# PROTEINS :/){$proteins=1;next;}
	if($_=~/^\#\# ALIGNMENTS/){$alignments=1;$proteins=0;
				   $page++;$cutter=0;$lineCount=0;next;}
	if($_=~/^\#\# SEQUENCE/){$alignments=0;$proteins=0;next;}
	if($_=~/^\#\# INSERTION /){$insertions=1;next;}
	if($proteins==1){
	    next if($_=~/^\n/);
	    if($_=~/^\s*NR\.\s*ID\s*STRID\s*.*\s*$/){
		@header=split(//,$_);
		for($i=0;$i<=$#header;$i++){
		    if($header[$i] eq '%' &&
		             $header[$i+1] eq 'I'){$cutter=$i; last; }
		}
		next;
	    }
	    if($cutter >0){
		$_=~m/^\s*(\d*)\s*:\s*(\S*)\s+.*/;
		$rank=$1; $alignedId=$2;
		return(0,"ERROR $sbr: failed to get rank and id in line $_") 
		    if(! (defined $rank && defined $alignedId) );
		@data=split(//,$_);
		splice (@data,0,$cutter);
		$cut=join '', @data;
		@data=split(/\s+/,$cut);
		$IFIR=$data[2];$ILAS=$data[3];
		$JFIR=$data[4];$JLAS=$data[5];
		push @aliData,[$rank,$alignedId,$IFIR,$ILAS,$JFIR,$JLAS];
		$howmany=$rank;
		next;
	    }
	}
	if($alignments==1){
	 next if($_=~/^\n/);
	    if($_=~/^\s*SeqNo\s*PDBNo\s*AA\s*.*\s*$/){
		@header=split(//,$_);
		for($i=0;$i<=$#header;$i++){
		    if($header[$i] eq 'A' &&
		       $header[$i+1] eq 'A'){$aminapos=$i;$chainpos=$i-2;}
		    if($header[$i] eq '.' && $header[$i+1] eq '.'){
			$cutter=$i; last; }
		}
		next;
	    }   
	    if($cutter >0){
		$_=~m/^\s*(\d*)\s*.*\s*$/;
		$ResNum=$1;
		return(0,"ERROR $sbr: failed to get rank and id in line $_") if(! defined $ResNum );
		$lineCount++;
		@data=split(//,$_);
		$Residue=$data[$aminapos];
		$Chain=$data[$chainpos];
		if(! defined $queryRes[$ResNum]){
		    $queryRes[$ResNum]=$Residue;$queryChain[$ResNum]=$Chain;
		    $queryNum[$lineCount]=$ResNum; }
		elsif( $queryRes[$ResNum] eq $Residue){
		    $queryRes[$ResNum]=$Residue;$queryChain[$ResNum]=$Chain;
		    $queryNum[$lineCount]=$ResNum; }
		else{ return(0,"ERROR $sbr: residue conflict in $hsspFile $queryRes[$ResNum] vs. $Residue");    }
		splice (@data,0,$cutter);
		$cut=join '', @data;
		$cut=~s/\n$//;
		@data=split(//,$cut);
		if($#data > 69){return(0,"ERROR $sbr: unexpected number of alignments in one line: expected less or equal 69, is $#data, in line:\n$_ \n"); }
		for $i (0 .. 69){
		    if(defined $data[$i]){$AliStrings[$i+1+$page*70].=$data[$i];}
		    else{$AliStrings[$i+1+$page*70].=' '; } 
		}
		next;
	    }
        }
	if($insertions==1){
	    next if ($_=~/^\n|AliNo\s*IPOS\s*JPOS.*/);
	    $_=~s/^\s*|\s*$//g;
	    @data=split(/\s+/,$_);
	    return(0,"ERROR $sbr: incorrect number of insertion data fields:\n $_\n") if ($#data != 4);
	    ($AliNo,$IPOS,$JPOS,$Len,$Sequence)=@data;
	    #$InsertionsHash{$data[0]}.=$AliNo."\t".$IPOS."\t".$Len."\t".$Sequence.',';
	    push @{ $InsertionsHash{$data[0]} }, [ @data ];
	}
    }
    close $fh;
    # parsing hsspFile finished here!!!
    # now getting CASP alignments:
    #for $i (0 .. $#aliData){
    for $i (1 .. $howmany){
	$IFIR=@{ $aliData[$i] }[2];
	$ILAS=@{ $aliData[$i] }[3];
	$JFIR=@{ $aliData[$i] }[4];
	$JLAS=@{ $aliData[$i] }[5];
	@tmpAli=split(//,$AliStrings[$i]);
	$AliCount=$JFIR-1;$QueryCount=0;
	@QRes=@QNum=@ARes=@ANum=();
	$qali=$sali="";
	for($k=0;$k<=$#tmpAli;$k++){
	    if($tmpAli[$k]=~/\s/ || (! defined $tmpAli[$k] )){
		$QueryCount++;
		$sali.="-";
		$qali.=$queryRes[$queryNum[$QueryCount]];
		next;
	    }
	    elsif($tmpAli[$k] =~ /\w/){
         	$AliCount++; $QueryCount++;
		push @QRes,$queryRes[$queryNum[$QueryCount]];
		$qali.=$queryRes[$queryNum[$QueryCount]];
		if($queryChain[ $queryNum[ $QueryCount] ]=~/\S/){
		    $tmp=$queryNum[ $QueryCount ].$queryChain[ $queryNum[ $QueryCount] ];
		    push @QNum,$tmp; }
		else { push @QNum,$queryNum[ $QueryCount ]; }
		push @ARes,$tmpAli[$k];
		push @ANum,$AliCount;
		$sali.=$tmpAli[$k];
		if(exists $InsertionsHash{$i}){
		    foreach $ref (@{ $InsertionsHash{$i} } ){ 
			if(@{$ref}[2] == $AliCount+1){
			    $insLen=@{$ref }[3];
			    $insSeq=@{$ref }[4];
			    $insSeq=~s/^\w//;
			    $insSeq=~s/\w$//;
			    $AliCount+=$insLen;
			    for (1 .. $insLen){ $qali.="-"; }
			    $sali.=$insSeq;				
			    last; 
			}
		    }
		}
	    }
	    elsif($tmpAli[$k] eq '.'){
		$QueryCount++;
		$qali.=$queryRes[$queryNum[$QueryCount]];
		$sali.="-";
		next;
	    }
	    else{return(0,"ERROR $sbr: unexpected alignment symbol: $tmpAli[$k]\n"); }
	    
	}
	for $n (0 .. $#QRes){
	    $QRes[$n]=~tr[a-z][A-Z]; $ARes[$n]=~tr[a-z][A-Z]; 
	    $CASPALSTRING[$i].=$QRes[$n]."\t".$QNum[$n]."\t".$ARes[$n]."\t".$ANum[$n].',';
	}
	$qali=~tr[a-z][A-Z];
	$sali=~tr[a-z][A-Z];
	$h_i2pearson{$i}{'query'}=$qali;
	$h_i2pearson{$i}{'subject'}=$sali;
    }
    $rank=0;    #getting CASPAL format and removing multiple hits
    @RESULT=();
    for $i (1 .. $maxAli){
	#$rank=@{$aliData[$i]}[0];
	$alignedId=@{ $aliData[$i] }[1];
	if(! defined $h_AlignedAtHigherRank{$alignedId} ){
	    $rank++;
	    if($stripFlag){
		$score=$h_id2zscore{$alignedId};
		$h_id2zscore{$alignedId}=$h_id2zscore{$alignedId};
		return(0,"ERROR stripFile exists but zscore for $alignedId not defined")
		    if(! defined $score);
	    }else{ $score=$rank; }
	    push @RESULT, $alignedId."\t".$rank."\t".$score.';;;'.$CASPALSTRING[$i]; 
	    #$RESULT[$i-1]=$alignedId."\t".$rank."\t".$score.';;;'.$CASPALSTRING[$i];
	    $h_AlignedAtHigherRank{$alignedId}=1;
	    $h_aliId2pearson{$alignedId}{'query'}=$h_i2pearson{$i}{'query'};
	    $h_aliId2pearson{$alignedId}{'subject'}=$h_i2pearson{$i}{'subject'};
	}
    }
return(1,'ok',$PDBID,@RESULT);
}
#=======================================================================

1;	    







