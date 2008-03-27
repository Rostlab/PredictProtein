#!/usr/bin/perl
#package blastp;

INI:{

    $exeBlastDef= "/usr/pub/molbio/blast/blastpgp";
    $databaseXDef= "/data/blast/bigx_coil_seg";
    $databaseBDef= "/data/blast/big";
    $blastXargDef= "-j 3 -e .001 -h 1e-10 -d";
    $blastBargDef= "-e .001 -b 3000 -d";
    $optNiceDef=  "nice -15 ";

    $scrName=$0;  $scrName=~s/^.*\/|\.pl//g;
    #$scrGoal=     "runs Psi-Blast and produces saf format output\n";

     $extBlast=    ".blastpgp";
     $extSaf=      ".saf";
     $extMat=      ".blastmat";
     $extRdb=      ".blastRdb";
}

#===============================================================================
sub blastit {
    local($fileIn,$exeBlast,$dbBlastX,$dbBlastB,$argBlastX,$argBlastB,
	  $fileOutBlast,$fileOutMat,$fileOutSaf,$dirWork,$dirOut,$optNice,$filter,$maxAli,$rdb,$tile,$eThresh,$Ldebug)=@_;

#-------------------------------------------------------------------------------
#   blastit                     runs iterated PSI-BLAST
#       in:                     $fileIn:       fasta formatted file
#       in:                     $exeBlast:     BLAST binary   (0 to take default)
#       in:                     $dbBlast:      BLAST database (0 to take default)
#       in:                     $argBlast:     BLAST argument (0 for default)
#       in:                     $fileOutBlast: output BLAST file
#       in:                     $fileOutMat:   <0|1|name of output matrix> (0 for none)
#       in:                     $fileOutSaf:   <0|1|name of output SAF>    (0 for none)
#       in:                     $dirWork:      <0|name of working directory>
#       in:                     $dirOut:       <0|name of output directory>
#       in:                     $optNice:      <0|1|nice option>           (1 for default, 0 for none)
#       in:                     $: 
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
				# check input
    return(0,"not def fileInLoc!")          if (! defined $fileIn);
    return(0,"missing fileIn=$fileIn!")     if (! -e $fileIn && ! -l $fileIn);
    $Ldebug=0                   if (! defined $Ldebug);

				# get arguments
    $execBlast=  $exeBlast;
    $databaseX=  $dbBlastX;
    $databaseB=  $dbBlastB; 
    $blastXCmdStr=$argBlastX;
    $blastBCmdStr=$argBlastB;

    $dirOut=     ""             if (! $dirOut);
    $dirOut.=    "/"            if ($dirOut && length($dirOut)>1 && $dirOut !~/\/$/);

				# correct arguments
    $execBlast=  $exeBlastDef   if (! defined $exeBlast || 
				    ! $exeBlast         ||
				    (! -e $exeBlast && ! -l $exeBlast));
    $databaseX=   $databaseXDef   if (! defined $dbBlastX  || ! $dbBlastX);
    $databaseB=   $databaseBDef   if (! defined $dbBlastB  || ! $dbBlastB);

    $blastXCmdStr=$blastXargDef   if (! defined $blastXCmdStr || ! $blastXCmdStr);
    $blastBCmdStr=$blastBargDef   if (! defined $blastBCmdStr || ! $blastBCmdStr);

    return(0,"missing exeBlast=$execBlast!")    if (! -e $execBlast && ! -l $execBlast);
    $tmp=$databaseX.".psq";
    return(0,"missing dbBlastX=$databaseX|$tmp!") if (! -e $tmp  && ! -l $tmp);
    $tmp=$databaseB.".psq";
    return(0,"missing dbBlastB=$databaseB|$tmp!") if (! -e $tmp  && ! -l $tmp);

				# further correction
    $blastXCmdStr.=" ".$databaseX;
    $blastBCmdStr.=" ".$databaseB;
				# output files
    $idOut=$fileIn; $idOut=~s/\..*$//; 
    $idOut=~s/^.+\///; 
    $blastCheckFile=$idOut.".check_$$";
    $blastXFile=$idOut.".tmp_$$";
				# BLAST output file
    if (! $fileOutBlast){
	$fileOut=$dirOut.$idOut.$extBlast;}
    else {
	$fileOut=$fileOutBlast;}
                            	# SAF output file 
    if ($fileOutSaf){
	if ($fileOutSaf eq "1"){
	    $saf=$dirOut.$idOut.$extSaf;}
	else {
	    $saf=$fileOutSaf;}}
    else {
	$saf=0;}
				# BLAST matrix output file
    if ($fileOutMat){
	if ($fileOutMat eq "1"){
	    $mat=$dirOut.$idOut.$extMat;}
	else {
	    $mat=$fileOutMat;}}
    else {
	$mat=0;}

    if ($rdb){
	if ($rdb eq "1"){
	    $rdb=$dirOut.$idOut.$extRdb;}
	else {
	    $rdb=$rdb;}}
    else {
	$rdb=0;}

				# change blast argument
    $blastXCmdStr="-i $fileIn -o $blastXFile -C $blastCheckFile ".$blastXCmdStr;
    $blastBCmdStr="-i $fileIn -o $fileOut -R $blastCheckFile ".$blastBCmdStr;
    $blastBCmdStr=" -Q $mat ".$blastBCmdStr
	if ($mat);

				#------- nice option
    if    ($optNice eq "1"){
	$optNice=$optNiceDef;}
    elsif (! $optNice){
	$optNice="";}
    if ($rdb && !$saf){ return(0,"*** ERROR : you can not obtain rdb file withot saf file\n"); }

				#------- now ready to BLAST it
 
    ($Lok,$msg)=
	&runBlast($execBlast,$blastXCmdStr,$blastBCmdStr,$optNice);   
    return(0,"*** ERROR blastit: failed runBlast\n".$msg."\n") if (! $Lok);
    
    if ($saf){
	($Lok,$msg)=
	    &blastp_to_saf($fileOut,$fileIn,$saf,$rdb,$filter,$maxAli,$tile,$eThresh);
	return(0,"*** ERROR blastit: blast_to_saf failed\n".$msg."\n")  if(! $Lok );
	return(2,$msg)       if ($Lok == 2 );
    }
       
    return (1,"ok");
}				# end of blastit

#===============================================================================
sub runBlast {
    local($execBlastLoc,$blastXCmdStrLoc,$blastBCmdStrLoc,$optNice)=@_;
    local($cmdLoc);

    return(0,"*** ERROR missing BLAST exe=$execBlast! (LINE=".__LINE__.")\n")
	if (! -e $execBlast);    
    
    $cmdXLoc="$execBlast $blastXCmdStrLoc";
    $cmdXLoc=$optNice." ".$cmdXLoc 
	if (defined $optNice && $optNice);

    $tmp=system($cmdXLoc);
    $tmp == 0  || return(0,"*** ERROR blast on $databaseX returned with exit signal equal to $tmp \n");

    print "--- runBlastX system '$cmdXLoc'\n"    
	if (defined $Ldebug && $Ldebug);

    $cmdBLoc="$execBlast $blastBCmdStrLoc";
    $cmdBLoc=$optNice." ".$cmdBLoc 
	if (defined $optNice && $optNice);

    $tmp=system($cmdBLoc);
    $tmp == 0  || return(0,"*** ERROR blast on $databaseB returned with exit signal equal to $tmp \n");

    print "--- runBlastB system '$cmdBLoc'\n"    
	if (defined $Ldebug && $Ldebug);
    
    unlink $blastCheckFile, $blastXFile    if (! defined $Ldebug || ! $Ldebug);
    return (1,"ok");
}				# end of runBlast

#==============================================================================
sub blastp_to_saf {
    my ($Lok,$msg);
    my $sbr="blastp_to_saf";
    local ($blastfile,$queryfile,$fileout,$rdb,$filter,$maxAli,$tile,$eThresh)=@_;
    local (@query, %sequences,@alignedids,@namesSort,%rdb_lines,%endings,%u_endings);
    local (@tmp_seq,@inserted_query,@seq,@alignedNames,@tmp_seq );
    local ($key,$first,$last,$fhin,$local_counter,$beg,$index,$iter,$Score_count);
       
    $fhin= "FHIN"; 
                                      #------------------- gets the query sequence and its length
    undef @query;
    open($fhin,$queryfile) || return(0,"*** ERROR sbr: could not open $queryfile  - no such file"); 
    $queryName='query';
    while(<$fhin>){
	next if($_=~/^\n/ || $_=~/\// || $_=~/>/ || $_=~/#/ );
		$_=~s/\s+//g;
	@tmp=split(//,$_);
	push @query, @tmp;
    }
    close $fhin;
    $queryLength=$#query+1; 
                                #..........................................................

   if ( $rdb ne '0' && $rdb ne '' ){ 
	$rdbFile=$rdb;
	($Lok,$msg)= &printRdbHeader();
	if (! $Lok){ return(0,"*** ERROR $sbr : $msg"); }
    }

                                #------------------- finds number of iterations in blast file
    open($fhin,$blastfile) || return(0,"*** ERROR $sbr: failed to open blast file $blastfile\n");
    $iter=0; $nohits=0;
    while(<$fhin>){
	if($_=~/No hits found/){$nohits=1; last;}
	if($_=~/^Searching../){
	    $iter++;
	}
    }
    close $fhin;

    if ($nohits eq '1'){
	$sequences{''}=''; $alignedNames='';
	($Lok,$msg)=&print_saf_file($queryName,$queryLength,\%sequences,\@alignedNames,@query);
	return(0,"*** ERROR $sbr : $msg")            if (! $Lok );
	return(2,"*** WARNING $sbr : no hits found in Blastpgp search ");  
    }

    return(0,"*** ERROR $sbr: blast file format not recognized")              if ($iter == 0);
                                #............................................................

                                #--------------------------------skips to the last iteration
    open($fhin,$blastfile) || return(0,"*** ERROR $sbr: failed to open blast file $blastfile\n");
    $local_counter=0;
    while(<$fhin>){
	if($_=~/^Searching../){
	    $local_counter ++;
	}
	last if($local_counter == $iter);
    }
   
    #............................................................

    undef @alignedNames; undef @alignedids; $Score_count=0; undef %multi_aligned; $global_count=0; undef %rdb_lines;
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    while(<$fhin>){ 
	if($_=~/^>/ || $_=~/^Number of Hits/){
	    if($global_count > 0){
		undef %u_endings;
		undef @blastdat; @blastdat=@ { $rdb_lines{$id}{'1'} };
		$bexp=$blastdat[$#blastdat-1];
		if($bexp =~ /e/){ @tmp=split(/e/,$bexp); 
				  if($tmp[0] eq ''){$tmp[0]=1;}
				  $bexp=$tmp[0] * 10**($tmp[1]);
		}
		$includeFlag='yes';
		if ($bexp > $eThresh) { $includeFlag='no'; }
		@seq=@{ $multi_aligned{'1'} };
		if( ($includeFlag eq 'yes') && ($tile ne "0")  && ($Score_count > 1) ){
		    $u_endings{'1'}[0]=$endings{'1'}[0]; $u_endings{'1'}[1]=$endings{'1'}[1];
		    $mflag=0;@store_rdb_lines=();
		    foreach $itnum (2 .. $Score_count){
			@temp=@{ $multi_aligned{$itnum} };
			undef @blastdat; @blastdat=@ { $rdb_lines{$id}{$itnum} };
			$bexp=$blastdat[$#blastdat-1];
			if($bexp =~ /e/){ @tmp=split(/e/,$bexp);
					  if($tmp[0] eq ''){$tmp[0]=1;}
					  $bexp=$tmp[0] * 10**($tmp[1]);
			}
			if ($bexp > $eThresh) { delete $rdb_lines{$id}{$itnum}; next; }
			$iffy=1;
			foreach $it ( 1 .. ($itnum-1)){	
			    if (defined $u_endings{$it}){
				if ($endings{$itnum}[0] >= $u_endings{$it}[0]  && $endings{$itnum}[0] <= $u_endings{$it}[1] ){ $iffy=0;last;}
				if ($endings{$itnum}[1] >= $u_endings{$it}[0]  && $endings{$itnum}[1] <= $u_endings{$it}[1] ){ $iffy=0;last;}
			     
			    }
			}
			if ($iffy==1){
			    $u_endings{$itnum}[0]=$endings{$itnum}[0]; $u_endings{$itnum}[1]=$endings{$itnum}[1];
			    $one=$u_endings{$itnum}[0]; $two=$u_endings{$itnum}[1];
			    @seq[$one .. $two]=@temp[$one .. $two];    
			    $mflag=1; push @store_rdb_lines, $itnum;
			}	
			else{delete $rdb_lines{$id}{$itnum}; }
		    }
		}
		foreach $elem (@seq){
		    if(($elem ne ".") && ($elem !~ /[a-z_A-Z]/)){
			$elem=".";
		    }
		}
		if ($includeFlag eq 'yes') { $sequences{$id}=[ @seq ]; }
		else { $tmp=pop @alignedids; }
	    }
	    $global_count++;

	    undef @seq; $Score_count=0; undef %multi_aligned; undef %endings; 
	    undef %u_endings;
							                   #--- getting name of aligned sequence
	    for($it=0;$it<=$queryLength-1;$it++){   $seq[$it]="."; }       #initialising array seq
	
	    $_=~s/^>//; 
	    $id=$_; $id=~s/^(\S*)\s+(.*)\s*$/$1/;
	    $protDspt=$2;  chomp $protDspt; 
	    if ($id !~ /Number/){ push @alignedids, $id; }
	    
	}     #------------------------------------
	if ($_=~/^ Score/){ 
	       $Score_count++; 
	       for($it=0;$it<=$queryLength-1;$it++){ $block_seq[$it]="."; }
	       undef @ali_para;
	}

	next                   if ( $Score_count > 1 && $tile==0 );
#-----------------------------------------------------------------------------------------------------
	#if ( $rdb ne '0' && $rdb ne ''){
	if (defined $rdb){
	    if ( $_=~ /\s+Length/){ $len2=$_;$len2=~s/.+=\s*([0-9]+).*$/$1/;$len2=~s/\s//g;} 
	    if ( $_=~ /Score/ ){
		$lali=$pid=$sim=$bitScore=$expect=''; $gap=0;
		$line=$_;
		chomp $line; @tmp=split(/\,/,$line);
		push @ali_para,@tmp;
	    }
	    if ( $_=~ /Identities/){
		$line=$_; chomp $line;
		@tmp=split(/\,/,$line); push @ali_para,@tmp;
		foreach $param (@ali_para){
		    $param=~s/\s+//g;
		    if ($param=~/Score/){ $bitScore=$param; $bitScore=~s/^.+=(.+)bits.*$/$1/;}
		    elsif ($param=~/Expect/){@temp=split(/=/,$param); $expect=$temp[1];}
		    elsif ($param=~/Identities/){$lali=$param; $lali=~s/.+\/([0-9]+)\(([0-9]+)%\).*$/$1/;
						 $pid=$2;}
		    elsif ($param=~/Positives/){$sim=$param; $sim=~s/^.+\(([0-9]+)%\).*$/$1/;}
		    elsif ($param=~/Gaps/){$gap=$param; $gap=~s/^.+=([0-9]+)\/.*$/$1/;}
		}
		$lali=$lali-$gap;
		$qLength=$queryLength;
		$rdb_lines{$id}{$Score_count}=[$qLength,$len2,$lali,$pid,$sim,$gap,$bitScore,$expect,$protDspt];
	    } 	
	}
#-----------------------------------------------------------------------------------------------------
	if($_=~/^Query:/){ @tmp=split(/\s+/,$_); undef @aligned; undef @inserted_query;
			   $beg=$tmp[1]-1; $end=$tmp[3]-1;
			   if (! defined $endings{$Score_count}[0]){ $endings{$Score_count}[0]=$beg;}
			   $endings{$Score_count}[1]=$end;
			   @inserted_query=split(//,$tmp[2]);
		      }
	if($_=~/^Sbjct:/){
	    @tmp=split(/\s+/,$_); 
	    @aligned=split(//,$tmp[2]);
						     #getting rid of insertions at query sequence
	    print " *** ERROR sbr: blastp_to_saf in lenghts for $id\n"  if ($#inserted_query != $#aligned);
	    $local_counter=0;
	    undef @tmp_seq;
	    for($it=0;$it <= $#inserted_query; $it++){
		if ($inserted_query[$it] =~ /[a-z_A-Z]/){
		    $tmp_seq[$local_counter]=$aligned[$it];
		    $local_counter++;
		}
	    }    
	    #@aligned=@tmp_seq;                     #-------------------------------------------
#+++++++++++=
	    
	    @block_seq[$beg .. ($beg+$#tmp_seq)]=@tmp_seq;    #----alignig part of the subject seguence
	    
	    $multi_aligned{$Score_count}=[ @block_seq ]; 
	}
    }
    close $fhin;

				                      #getting rid of repeats in the list    
    undef @namesSort;
    push @namesSort, $queryName;
    $Lname=$queryName; $Lname=~tr/A-Z/a-z/;
    $Cname=$Lname; $Cname=~tr/a-z/A-Z/;
    
    foreach $it (@alignedids){
	$rflag=0; @tmp=split(/\|/,$it);
	if( $it eq $queryName || $it eq $Lname || $it eq $Cname){ $rflag=1;}
	else { 
	    foreach $elem (@tmp){
		if($elem eq $queryName || $elem eq $Lname || $elem eq $Cname){$rflag=1;}
	    }
	}
	if($rflag == 0){push @namesSort, $it;}
    }
    @alignedids=@namesSort[1 .. $#namesSort];
    undef @namesSort;
    push @namesSort, $queryName;
    foreach $it (@alignedids){                      
	$indicator=0;
	foreach $es (@namesSort){
	    if ( $it eq $es ){ $indicator++; last;}
	}
	if ($indicator < 1){ push @namesSort, $it; }
    } 
    @alignedNames=@namesSort[1 .. $#namesSort];
                                                       #-------------------------------------
 
                                                       #--filtering alignment
    
    if($filter != 100){
	($Lok,$msg)=&saf_filter(\@alignedNames,\%sequences,$filter,$maxAli);
	return(0,"*** ERROR $sbr : $msg")               if(! $Lok );
    }
  
                          #----------------------------------- printing out the resulting files
    
    if ($rdb ne '0' ){
	foreach $id (@alignedNames){
	    foreach $score (sort keys %{ $rdb_lines{$id} }){
		if($score > 1){ foreach $it ( @{ $rdb_lines{$id}{$score} }){$it='!'.$it;} }
		($qLength,$len2,$lali,$pid,$sim,$gap,$bitScore,$expect,$protDspt)= @{ $rdb_lines{$id}{$score} };
		#write FHRDB;
		print FHRDB  "$id\t$len2\t$pid\t$sim\t$lali\t$gap\t$bitScore\t$expect\t$protDspt\n"; 
	    }
	}
    } 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~      short naming format
#    undef %short_alignedNames;
#    foreach $key (@alignedNames){
#	if($key =~ /trembl/ || $key =~/swiss/){
#	    @tmp=split(/\|/,$key); $short=$tmp[2];
#	}
#	else { $short=$key;}
#	$short_alignedNames{$key}=$short;
#    }
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    ($Lok,$msg)=&print_saf_file($queryName,$queryLength,\%sequences,\@alignedNames,@query);
    return (0,"*** ERROR $sbr : $msg")                        if ( ! $Lok );
    return (2,"*** WARNIG $sbr : no hits found after filtering")             if ( $#alignedNames < 0);
    if (-e $fileout) { return (1,"ok"); }
    else { return (0,"*** ERROR $sbr : failed to produce the saf output file"); }
}				# end of blastp_to_saf

#==============================================================================

sub saf_filter{
    my $sbr='saf_filter';
    my ($Lok,$msg);
    local($array_name,$ali_hash,$red,$bound)=@_;
    my @ord_ali_list=@$array_name;
    my %alignment=%$ali_hash;
    my @new_aligned_names=();
    my ($count,$ct,$same);

    @last= @query;
    $len=$#last;
    $count=0;
    Floop:for($index=0; $index <= $#ord_ali_list; $index++){
	if ( ! defined $alignment{$ord_ali_list[$index]}) { return(0,"*** ERROR $sbr : alignment to be filtered is not defined\n")}
	@maybe=@{ $alignment{$ord_ali_list[$index]} };
	$ct=$same=0;
	foreach $itres (0..$len){
	    next if ($maybe[$itres] !~ /[a-zA-Z]/);
	    next if ( $last[$itres] !~ /[a-zA-Z]/);
	    ++$same if ($maybe[$itres] eq $last[$itres]);
	    ++ $ct;
	}
	if ( ( $ct > 0 && (100*$same/$ct)<$red ) || $ct==0 ){
	    @last=@maybe; $count++;
	    push @new_aligned_names, $ord_ali_list[$index];
	    last Floop    if ($count >= $bound); 
	}
    }
    @$array_name=@new_aligned_names;
    return(1,"filtering is done");
}
	
#==============================================================================================
#==============================================================================================

sub printRdbHeader{
    my $sbr='printRdbHeader';
    my ($Lok,$msg);
#a report on blastpgp file
    $header="
#PERL-RDB
#SEQLENGTH\t $queryLength
#ID\t:\tidentifier of the aligned (homologous) protein
#LSEQ2\t:\length of the entire sequence of the aligned protein
#LALI\t:\tlength of the alignment excluding insertions and deletions
#%IDE\t:\tpercent indentity
#%SIM\t:\tpercent similarity
#LGAP\t:\ttotal gap length
#BSCORE\t:\tblast score (bits)
#BEXPECT\t:\tblast expectation value
#PROTEIN\t:\tone-line description of aligned protein
#'!'\t:\tindicates adjacent blast alignment combined with the previous one
#ID\tLSEQ2\t%IDE\t%SIM\tLALI\tLGAP\tBSCORE\tBEXPECT\tPROTEIN\n";

    open(FHRDB,">$rdbFile") || return(0, "*** ERROR $sbr :  could not open rdbfile=$rdbFile for writing\n");
    print FHRDB $header;
    return( 1,'ok');
}
#==============================================================================================
#==============================================================================================
sub print_saf_file{
    my $sbr='print_saf_file';
    my ($Lok,$msg);
    local($queryName,$queryLength,$alignment,$aliNames,@query)=@_;
    my %sequences=%$alignment;
    my @alignedNames=@$aliNames;
    my ($fhout,$pages,$nameField);

    $fhout="FHOUT"; 
    $pages=int $queryLength/50;
    if ($queryLength%50 != 0){$pages++;}

    open($fhout,">$fileout") || return(0,"*** ERROR $sbr: failed to open fileout=$fileout for writing");
    print $fhout "# SAF (Simple Alignment Format)\n";
    print $fhout "#\n";
    $nameField=0;
    @tmp=split(//,$queryName);
    if ($#tmp+2>$nameField){$nameField=$#tmp+2;}
    foreach $key (@alignedNames){
	@tmp=split(//,$key);
	if ($#tmp+2>$nameField){$nameField=$#tmp+2;}
    }


    for($it=1;$it<=$pages;$it++){
	$beg=($it-1)*50; $end=$it*50-1;
	printf $fhout "%-${nameField}.${nameField}s", $queryName;
	for($index=0;$index<50;$index=$index+10){
	    $first=$beg+$index; $last=$first+9;
	    if ($last <= $queryLength -1 ){print $fhout  @query[$first .. $last]," " ;}
	    else { print $fhout @query[$first .. ($queryLength-1)]; }
	}
	print $fhout  "\n";
	foreach $key (@alignedNames){
	    printf $fhout "%-${nameField}.${nameField}s", $key;
	    for($index=0;$index<50;$index=$index+10){
	       $first=$beg+$index; $last=$first+9; 
	       if ($last <= $queryLength -1 ){
		   print $fhout @{ $sequences{$key}}[$first .. $last]," " ;
	       }
	       else { print $fhout @{ $sequences{$key}}[$first .. ($queryLength-1)]," " ; }
	    }
	    print $fhout  "\n";
	}
	print $fhout "\n";
    }
    close $fhout;
    return (1,'ok');
}
#======================================================================









