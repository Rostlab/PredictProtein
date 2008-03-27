#! /usr/bin/perl -w

if ($#ARGV < 0) { print  "*** ERROR blastpgp_to_saf.pl : no arguments given\n"; print  FHERROR "*** ERROR blastpgp_to_saf.pl : no arguments given\n"; die; }

foreach $arg (@ARGV){
        if    ($arg=~/^fileInBlast=(.*)$/)       { $fileInBlast =        $1;}
        elsif ($arg=~/^fileInQuery=(.*)$/)       { $fileInQuery =        $1;}
	elsif ($arg=~/^fileOutSaf=(.*)$/)        { $fileOutSaf  =        $1;}
	elsif ($arg=~/^fileOutRdb=(.*)$/)        { $fileOutRdb  =        $1;}
	elsif ($arg=~/^fileOutErr=(.*)$/)        { $fileOutErr  =        $1;}
	elsif ($arg=~/^red=(.*)$/)               { $filterThre  =        $1;}
	elsif ($arg=~/^maxAli=(.*)$/)            { $maxAli      =        $1;}
        elsif ($arg=~/^tile=(.*)$/)              { $alignTiling =        $1;}
	else {
	    print "*** wrong command line arg '$arg'\n";
	    print FHERROR "*** wrong command line arg '$arg'\n";
	    die;
	}
}

if ($#ARGV < 0) { print  "*** ERROR blastpgp_to_saf.pl : no arguments given\n"; 
		  print  FHERROR "*** ERROR blastpgp_to_saf.pl : no arguments given\n"; die; }

if (! defined $fileOutErr)  { 
    print "*** ERROR blastpgp_to_saf : fileOutErr output filename is not definded\n";
    die;}  

open(FHERROR,">".$fileOutErr) || die "*** ERROR could not open error log file=$fileOutErr for writing\n";	   
$inicheck=0;
if (! defined $fileInBlast)  { 
    print "*** ERROR blastpgp_to_saf : blast input file name is not defined\n"; 
    print FHERROR "*** ERROR blastpgp_to_saf : blast input file name is not defined\n"; 
    $inicheck++;}
else { if (! -e $fileInBlast){ 
    print "*** ERROR blastpgp_to_saf : no input blast file $fileInBlast found\n"; 
    print FHERROR "*** ERROR blastpgp_to_saf : no input blast file $fileInBlast found\n";
    $inicheck++;} }

if (! defined $fileInQuery)  { 
    print "*** ERROR blastpgp_to_saf : query input file name is not defined\n";
    print FHERROR "*** ERROR blastpgp_to_saf : query input file name is not defined\n";
    $inicheck++;}
else{ if(! -e $fileInQuery)  { 
    print "*** ERROR blastpgp_to_saf : no input query file $fileInQuery found\n";
    print FHERROR "*** ERROR blastpgp_to_saf : no input query file $fileInQuery found\n";
    $inicheck++;} }

if (! defined $fileOutSaf)  { 
    print "*** ERROR blastpgp_to_saf : SAF output filename is not definded\n";
    print FHERROR "*** ERROR blastpgp_to_saf : SAF output filename is not definded\n";
    $inicheck++;}
if (! defined $fileOutRdb)  { 
    print "*** ERROR blastpgp_to_saf : blastRdb output filename is not definded\n";
    print FHERROR "*** ERROR blastpgp_to_saf : blastRdb output filename is not definded\n";
    $inicheck++;}

if (! defined $filterThre)  { 
    print "*** ERROR blastpgp_to_saf : filter threshold is not definded\n";
    print FHERROR "*** ERROR blastpgp_to_saf : filter threshold is not definded\n";
    $inicheck++;}
if (! defined $maxAli)      { 
    print "*** ERROR blastpgp_to_saf : maximum number of aligned sequences to be included in saf output file is not definded\n";
    print FHERROR "*** ERROR blastpgp_to_saf : maximum number of aligned sequences to be included in saf output file is not definded\n";
    $inicheck++;}
if (! defined $alignTiling) { 
    print "*** ERROR blastpgp_to_saf : tiling method of Blast alignment  is not definded\n";
    print FHERROR "*** ERROR blastpgp_to_saf : tiling method of Blast alignment  is not definded\n";
    $inicheck++;}

die           if ($inicheck != 0);

($Lok,$msg)=   &blastp_to_saf($fileInBlast,$fileInQuery,$fileOutSaf,$fileOutRdb,$filterThre,$maxAli,$alignTiling);

if (! $Lok )    {print "*** ERROR blastpgp_to_saf.pl : $msg\n"; 
	         print FHERROR "*** ERROR blastpgp_to_saf.pl : $msg\n"; die;}
if ($Lok == 2 ) {print "*** WARNING blastpgp_to_saf.pl : $msg\n";
		 print FHERROR "*** WARNING blastpgp_to_saf.pl : $msg\n"; exit;}



#=============================================================================================
sub blastp_to_saf {
    my ($Lok,$msg);
    my $sbr="blastp_to_saf";	# 
    local ($blastfile,$queryfile,$fileout,$rdb,$filter,$maxAli,$tile)=@_; # 
    local (@query, %sequences,@alignedids,@namesSort,%rdb_lines); # 
    local (@tmp_seq,@inserted_query,@seq,@alignedNames ); # 
    local ($key,$first,$last,$fhin,$local_counter,$beg,$index,$iter,$Score_count); 

    $fhin= "FHIN"; 		# 
                                       #------------------- gets the query sequence and its length
    undef @query;		# 
    open($fhin,$queryfile) || return(0,"*** ERROR sbr: could not open $queryfile  - no such file");
    $queryName='query';		# 
    while(<$fhin>){
	next   if( $_=~/^\n/ || $_=~/\// || $_=~/>/ || $_=~/#/ );
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
		@seq=@{ $multi_aligned{'1'} };
		if($tile ne "0"  && $Score_count > 1){
		    $u_endings{'1'}[0]=$endings{'1'}[0]; $u_endings{'1'}[1]=$endings{'1'}[1];
		    foreach $itnum (2 .. $Score_count){
			@temp=@{ $multi_aligned{$itnum} };
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
			}	
			else{delete $rdb_lines{$id}{$itnum}; }
		    }
		}
		foreach $elem (@seq){
		    if(($elem ne ".") && ($elem !~ /[a-z_A-Z]/)){
			$elem=".";
		    }
		}
		$sequences{$id}=[ @seq ];
	    }
	    $global_count++;

	    undef @seq; $Score_count=0; undef %multi_aligned; undef %endings; 
	    undef %u_endings;
							                   #--- getting name of aligned sequence
	    for($it=0;$it<=$queryLength-1;$it++){   $seq[$it]="."; }       #initialising array seq
	
	    $_=~s/^>//; 
	    $id=$_; $id=~s/^(\S*)\s+(.*)\s*$/$1/;
	    $protDspt=$2;  chomp $protDspt; 
	    if ($id !~ /Number/){push @alignedids, $id;}
	    
	}                                                   #------------------------------------
	if ($_=~/^ Score/){ 
	       $Score_count++; 
	       for($it=0;$it<=$queryLength-1;$it++){ $block_seq[$it]="."; }
	       undef @ali_para;
	}

	next                   if ( $Score_count > 1 && $tile==0 );
#-----------------------------------------------------------------------------------------------------
	if ( $rdb ne '0' && $rdb ne ''){
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
#    $Lname=$queryName; $Lname=~tr/A-Z/a-z/;
#    $Cname=$Lname; $Cname=~tr/a-z/A-Z/;
#    foreach $it (@alignedids){
#	$rflag=0; @tmp=split(/\|/,$it);
#	if( $it eq $queryName || $it eq $Lname || $it eq $Cname){ $rflag=1;}
#	else { 
#	    foreach $elem (@tmp){
#		if($elem eq $queryName || $elem eq $Lname || $elem eq $Cname){$rflag=1;}
#	    }
#	}
#	if($rflag == 0){push @namesSort, $it;}
#    }

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
	    $identifier=$id;
	    foreach $score (sort keys %{ $rdb_lines{$id} }){		
		#if($score > 1){ foreach $it ( @{ $rdb_lines{$id}{$score} }){$it='!'.$it;} };
		($qLength,$len2,$lali,$pid,$sim,$gap,$bitScore,$expect,$protDspt)= @{ $rdb_lines{$id}{$score} };
		if($score > 1){ $expect='!'.$expect;
				$protDspt='!'.$protDspt;
				$identifier='!'.$identifier;
		}
		print FHRDB "$identifier\t$len2\t$pid\t$sim\t$lali\t$gap\t$bitScore\t$expect\t$protDspt\n";  
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

    $header="
#PERL-RDB
#SEQLENGTH\t $queryLength
#ID\t:\tidentifier of the aligned (homologous) protein
#LSEQ2\t:\tlength of the entire sequence of the aligned protein
#LALI\t:\tlength of the alignment excluding insertions and deletions
#%IDE\t:\tpercent indentity
#%SIM\t:\tpercent similarity
#LGAP\t:\ttotal gap length
#BSCORE\t:\tblast score (bits)
#BEXPECT\t:\tblast expectation value
#PROTEIN\t:\tone-line description of aligned protein
#'!'\t:\tindicates lower scoring alignment that is combined with 
#the higher scoring adjacent one  
##ID\tLSEQ2\t%IDE\t%SIM\tLALI\tLGAP\tBSCORE\tBEXPECT\tPROTEIN\n";

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






