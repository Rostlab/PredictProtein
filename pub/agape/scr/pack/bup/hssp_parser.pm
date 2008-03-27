package hssp_parser;
#================================================================
sub run_hssp_parser{
    my $sbr='run_hssp_parser';
    my ($PredProteinFile,$MaxHits,$hr_StripData)=@_;
    my (@RESULT);
    my ($IDQuery);
    
    return(0,"ERROR $sbr: undefined filein argument") 
	if (!defined $PredProteinFile);
    
    $dbg=$::dbg;
    ($Lok,$msg,$IDQuery,@RESULT)=
	&parse_hssp($PredProteinFile,$MaxHits,$hr_StripData);
    return(0,"ERROR $sbr: $msg") if (!$Lok);
    
    
    if(defined $MaxHits){ 
	if($MaxHits-1 > $#RESULT ){$MaxHits=$#RESULT+1};
	@RESULT=@RESULT[0 .. $MaxHits-1]; 
    }

    return(1,'0k',$IDQuery,@RESULT);
}
#=================================================================
sub parse_hssp{
    my $sbr='parse_hssp';
    my ($hsspFile,$howmany,$hr_StripData)=@_;
    my ($nalign,$proteins,$alignments,$insertions,$cutter,$rank,
	$alignedId,$cut,$IFIR,$ILAS,$JFIR,$JLAS,$aminapos,$chainpos,
	$ResNum,$Residue,$Chain,$PDBID,$chain,$coreid);
    my ($AliNo,$IPOS,$JPOS,$Len,$PrevInserAliNo,$Sequence);
    my (@header,@data,@aliData,@AliStrings,@queryRes,
	@queryChain,@queryNum,@CASPALSTRING,@RESULT);
    my (%InsertionsHash,%h_AlignedAtHigherRank);

    
    if(! defined $hr_StripData){
	print "WARNING: hr_StripData not defined, score set to be equal to rank\n";
    }
    $proteins=0;$alignments=0;$insertions=0;$page=-1;$cutter=0;
    $lineCount=0;
    $aliData[0]='';   #first alignment corresponds to array element 1
    return(0,"ERROR $sbr: missing arguments in: @_") 
	if ($#_<1);
    for $i (0 ..$#_){ $j=$i+1; 
		      return(0,"ERROR $sbr: argument number $j not defined") 
			  if(! defined $_[$i]);    }
   
    $PrevInserAliNo=-1;
    open(FHHSSP,$hsspFile) || 
	return(0,"ERROR $sbr: hssp file=$hsspFile not opened\n");
    while(<FHHSSP>){
	next if($_=~/^\/\//);
	if($_=~/\!\s+\!\s+/){next;}
	if($_=~/^NALIGN/){($nalign)=m/^NALIGN\s+(\S*)\s*$/;
	       $howmany=$nalign if($howmany eq 'all' || $howmany > $nalign); 
	       return(0,"ERROR $sbr: undefined nalign field in $hsspFile\n")
		   if (! defined $nalign);     }
	if($_=~/^PDBID/){($PDBID)=m/^PDBID\s+(\S*)\s*$/;
			 $PDBID=~m/(\S{4,4})_{0,1}(\S*)\s*$/;
			 $COREID=$1; $CHAIN=$2;
			 $CHAIN='_' if(! defined $CHAIN);
			 #$PDBID=$COREID.':'.$CHAIN;
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
		$alignedId=~/^(\S{4,4})_{0,1}(\S{0,1})$/ ||
		    return(0,"ERROR $sbr: alignedid=$alignedId does not conform to expected format");
		$chain=$2; $coreid=$1;
		if($chain=~/\S/){$alignedId=$coreid.'_'.$chain;}
		else{$alignedId=$coreid;}
		return(0,"ERROR $sbr: failed to get rank and id in line $_") if(! (defined $rank && defined $alignedId) );
		@data=split(//,$_);
		splice (@data,0,$cutter);
		$cut=join '', @data;
		@data=split(/\s+/,$cut);
		$IFIR=$data[2];$ILAS=$data[3];
		$JFIR=$data[4];$JLAS=$data[5];
		push @aliData,[$rank,$alignedId,$IFIR,$ILAS,$JFIR,$JLAS];
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
	#$PrevInserAliNo=-1;
	if($insertions==1){
	    next if ($_=~/^\n|AliNo\s*IPOS\s*JPOS.*/);
	    $_=~s/^\s*|\s*$//g;
	    @data=split(/\s+/,$_);
	    return(0,"ERROR $sbr: incorrect number of insertion data fields:\n $_\n") if ($#data != 4);
	    ($AliNo,$IPOS,$JPOS,$Len,$Sequence)=@data;
	    #print "$_\n";
	    #print "AliNo=$AliNo\n";
	    next if($AliNo !~ /^\d+$/);   #does not take something like "*****" from maxhom
	    if($PrevInserAliNo > $AliNo){ last; } #does not take garbage from maxhom
	    else{ $PrevInserAliNo=$AliNo; }
	    #print "later AliNo=$AliNo \n";
	    #print "PrevInserAliNo=$PrevInserAliNo\n";
	    #$InsertionsHash{$data[0]}.=$AliNo."\t".$IPOS."\t".$Len."\t".$Sequence.',';
	    push @{ $InsertionsHash{$data[0]} }, [ @data ];
	}
    }
    # parsing hsspFile finished here!!!
    # now getting CASP alignments:
    #for $i (0 .. $#aliData){
    for $i (1 .. $#aliData){
	$IFIR=@{ $aliData[$i] }[2];
	$ILAS=@{ $aliData[$i] }[3];
	$JFIR=@{ $aliData[$i] }[4];
	$JLAS=@{ $aliData[$i] }[5];
	@tmpAli=split(//,$AliStrings[$i]);
	$AliCount=$JFIR-1;$QueryCount=0;
	@QRes=@QNum=@ARes=@ANum=();
	for($k=0;$k<=$#tmpAli;$k++){
	    if($tmpAli[$k]=~/\s/ || (! defined $tmpAli[$k] )){$QueryCount++;next;}
	    elsif($tmpAli[$k] =~ /\w/){
         	$AliCount++; $QueryCount++;
		push @QRes,$queryRes[$queryNum[$QueryCount]];
		if($queryChain[ $queryNum[ $QueryCount] ]=~/\S/){
		    $tmp=$queryNum[ $QueryCount ].$queryChain[ $queryNum[ $QueryCount] ];
		    push @QNum,$tmp; }
		else { push @QNum,$queryNum[ $QueryCount ]; }
		push @ARes,$tmpAli[$k];
		push @ANum,$AliCount;
		if(exists $InsertionsHash{$i}){
		    foreach $ref (@{ $InsertionsHash{$i} } ){ 
			if(@{$ref}[2] == $AliCount+1){
			    $AliCount+=@{$ref }[3];
			    last; }
		    }
		}
	    }
	    elsif($tmpAli[$k] eq '.'){$QueryCount++;next;}
	    else{return(0,"ERROR $sbr: unexpected alignment symbol: $tmpAli[$k]\n"); }
	}
	for $n (0 .. $#QRes){
	    $QRes[$n]=~tr[a-z][A-Z]; $ARes[$n]=~tr[a-z][A-Z]; 
	    $CASPALSTRING[$i].=$QRes[$n]."\t".$QNum[$n]."\t".$ARes[$n]."\t".$ANum[$n].',';
	}
    }
    $rank=0;    #getting CASPAL format and removing multiple hits
    @RESULT=();
    for $i (1 .. $nalign){
	#$rank=@{$aliData[$i]}[0];
	last if($rank == $howmany);
	#print "here: rank=$rank\n";
	$alignedId=@{ $aliData[$i] }[1];
	if(! defined $h_AlignedAtHigherRank{$alignedId} ){
	    $rank++;
	    $score=$rank;
	    if(defined $hr_StripData){
		if(! defined $$hr_StripData{$alignedId} ){
		    die "StripData for alignedId=$alignedId not defined, stopped";
		}
		$score=$$hr_StripData{$alignedId}{"Zscore"};
		if(! defined $score){
		    die "Zscore in StripData for  alignedId=$alignedId not defined, stopped";
		}
	    }
	    #print $alignedId."\t".$rank."\t".$score.';;;'."\n";
	    push @RESULT, $alignedId."\t".$rank."\t".$score.';;;'.$CASPALSTRING[$i]; 
	    #$RESULT[$i-1]=$alignedId."\t".$rank."\t".$score.';;;'.$CASPALSTRING[$i];
	    $h_AlignedAtHigherRank{$alignedId}=1;
	}
    }
return(1,'ok',$PDBID,@RESULT);
}
#=======================================================================

1;	    







