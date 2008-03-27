#! /usr/bin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="converts blastpgp output file into saf (optional Rdb)".
    "     \t \n".
    "     \t ";
#
&helpLocal()                 if ($#ARGV<0 || $ARGV[0]=~/^(-h|help|\?|def)$/i);

if ($#ARGV < 0) { print  "*** ERROR blastpgp_to_saf.pl : no arguments given\n"; die; }
foreach $arg (@ARGV){
    if ($arg=~/ErrDir=(.*)$/)             { $par{"ErrDir"}  =     $1;}
}
if(!defined $par{"ErrDir"} )                  { $par{"ErrDir"}="./"; }
else{ $par{"ErrDir"}.='/'               if( $par{"ErrDir"} !~ /\/$/);}   

$fileErr=$par{"ErrDir"}."b2saf.tmp_".$$;
open(FHERROR, ">$fileErr") || die "*** could not open error log file \n";
INI:{
    $par{"extSaf"}=".saf";
    $par{"extRdb"}=".rdbBlast";
    $par{"extFasta"}=".f";
}
foreach $arg (@ARGV){
        #if    ($arg=~/^blast=(.*)$/)             { $fileInBlast =        $1;}
        if ($arg=~/^fasta=(.*)$/)                { $fileInQuery =        $1;}
	elsif ($arg=~/^saf=(.*)$/)               { $fileOutSaf  =        $1;}      
	elsif ($arg=~/^rdb=(.*)$/)               { $fileOutRdb  =        $1;}
	elsif ($arg=~/^rdb$/)                    { $fileOutRdb  =         1;}
	elsif ($arg=~/^short$/)                  { $short       =         1;}
	elsif ($arg=~/^red=(.*)$/)               { $filterThre  =        $1;}
	elsif ($arg=~/^maxAli=(.*)$/)            { $maxAli      =        $1;}
        elsif ($arg=~/^tile=(.*)$/)              { $alignTiling =        $1;}
	elsif ($arg=~/eSaf=(.*)$/)               { $eThresh      =       $1;}
	elsif ($arg=~/extSaf=(.*)$/)             { $par{"extSaf"}  =     $1;}
	elsif ($arg=~/extFasta=(.*)$/)           { $par{"extFasta"}=     $1;}
	elsif ($arg=~/extRdb=(.*)$/)             { $par{"extRdb"}  =     $1;}
	elsif (-e $arg)                          { push(@fileIn,$arg);      }
	else {
	    print "*** wrong command line arg '$arg'\n";
	    print FHERROR "*** wrong command line arg '$arg'\n";
	    die;
	}
    }
$fileIn=$fileIn[0];
die ("missing input $fileIn\n") if (! -e $fileIn);

 
$alignTiling =1            if (! defined $alignTiling) ;
$maxAli      =5000         if (! defined $maxAli) ;
$filterThre  =100          if (! defined $filterThre) ;
$eThresh     =1000          if (! defined $eThresh   ) ;
$short       =0            if (! defined $short) ;

$#fileTmp=-1;
foreach $fileIn (@fileIn){
	if ( $fileIn =~/\.list/ ) {
	    ($Lok,$msg,$file,$tmp)=
		&fileListRd($fileIn);if (! $Lok){ print "*** ERROR $scrName: input list\n",$msg,"\n";
						  exit; }
	    @tmpf=split(/,/,$file); 
	    push(@fileTmp,@tmpf);
	    next;}
	if ($fileIn !~ /\.list/) {push(@fileTmp,$fileIn);}
}
@fileIn= @fileTmp; 
$#fileTmp=-1;		                # slim-is-in
     
foreach $fileIn (@fileIn){
    ++$ctfile; 
    if (! -e $fileIn){print "-*- WARN $scrName: no fileInBlast=$fileIn\n";
		      next;}
				# output files
    $id=$fileIn; $id=~s/^(.*\/)//; $dirIn=$1;
    $id=~s/\..*$//;
    $dirIn=''     if (! defined $dirIn);
				# BLAST output
    if ($ctfile > 1 ){
	$fileOutSaf=$id.$par{"extSaf"}; 
        $fileInQuery=$dirIn.$id.$par{"extFasta"}; 
	if ( $fileOutRdb ne '0'  ) {$fileOutRdb=$id.$par{"extRdb"}; }
        else{ $fileOutRdb=0; }
    }
    else { 
	if (! defined $fileOutSaf) {$fileOutSaf=$id.$par{"extSaf"};}
	if (! defined $fileOutRdb) {$fileOutRdb="0"; }
	elsif ($fileOutRdb eq "1") {$fileOutRdb=$id.$par{"extRdb"};}

	if (! defined $fileInQuery)  {$fileInQuery=$dirIn.$id.$par{"extFasta"}; }
	
    }
	   
    if (! defined $fileInQuery)  { 
	print "*** WARNING $scrName : query input file name is not defined\n";
    }
    

    ($Lok,$msg)=   &blastp_to_saf($fileIn,$fileInQuery,$fileOutSaf,$fileOutRdb,$filterThre,$maxAli,$alignTiling,$eThresh,$short);

    if (! $Lok )    {print "*** ERROR blastpgp_to_saf.pl : $msg\n"; 
	         print FHERROR "*** ERROR blastpgp_to_saf.pl : $msg\n"; die;}
    if ($Lok == 2 ) {print "*** WARNING blastpgp_to_saf.pl : $msg\n";
		 print FHERROR "*** WARNING blastpgp_to_saf.pl : $msg\n";}
}
close FHERROR;
unlink $fileErr; 


#=============================================================================================
sub blastp_to_saf {
    my ($Lok,$msg);
    my $sbr="blastp_to_saf";
    my ($blastfile,$queryfile,$fileout,$rdb,$filter,$maxAli,$tile,$eThresh,$short)=@_;
    my (@query, %sequences,@alignedids,@namesSort,%rdb_lines);
    my (@tmp_seq,@inserted_query,@seq,@alignedNames,%u_endings,%endings );
    my ($key,$first,$last,$fhin,$local_counter,$beg,$index,$iter,$Score_count);
    my ($Qflag,$fastaFlag); 
    local $queryLength;
    $fhin= "FHIN"; 
                                      #------------------- gets the query sequence and its length
    undef @query; $fastaFlag='0';
    $queryName=$blastfile; $queryName=~s/^.+\/|\..+$//g; #$queryName.="_query";
    if (-e $queryfile){
	open($fhin,$queryfile) || return(0,"*** ERROR sbr: could not open $queryfile  - no such file"); 
	#$queryName='query';
	while(<$fhin>){
	    next if($_=~/^\n/ || $_=~/\// || $_=~/>/ || $_=~/#/ );
	    $_=~s/\s+//g;
	    @tmp=split(//,$_);
	    push @query, @tmp;
	}
	close $fhin; $fastaFlag='1';
	$queryLength=$#query+1; 
    }
    else { $fastaFlag='0';$queryName='query';}

                                #..........................................................

   #if ( $rdb ne '0' && $rdb ne '' ){ 
	#$rdbFile=$rdb;
	#($Lok,$msg)= &printRdbHeader();
	#if (! $Lok){ return(0,"*** ERROR $sbr : $msg"); }
    #}

                                #------------------- finds number of iterations in blast file
    open($fhin,$blastfile) || return(0,"*** ERROR $sbr: failed to open blast file $blastfile\n");
    $iter=0; $nohits=0; $Qflag='closed';
    while(<$fhin>){
	if (! $fastaFlag){
	    if($_=~/^Query=/){$Qflag='open'; next;}
	    if( $_=~/letters\)/ && $Qflag eq 'open'){
		$queryLength=$_; chomp $queryLength;
		$queryLength=~s/^\s*\(([0-9]*)\s*letters.*$/$1/;
	    }
	}
	if($_=~/^Database:/){ $Qflag='closed';}
	if($_=~/No hits found/){$nohits=1; last;}
	if($_=~/^Searching../){
	    $iter++;
	}
    }
    close $fhin;
    if( ! defined $queryLength ) {return(0,"*** ERROR $sbr: failed to obtain length of query"); } 
    if ( $rdb ne '0' && $rdb ne '' ){ 
	$rdbFile=$rdb;
	($Lok,$msg)= &printRdbHeader();
	if (! $Lok){ return(0,"*** ERROR $sbr : $msg"); }
    }

    if( ! $fastaFlag) { for ($i=0;$i<$queryLength;$i++){$query[$i]='.';} }
    if ($nohits eq '1'){
	$sequences{''}=''; @alignedNames=();
	($Lok,$msg)=&print_saf_file($fileout,$queryName,$queryLength,\%sequences,\@alignedNames,@query);
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
		if ($includeFlag eq 'yes') {
		    $tmp=join '',@seq;
		    $sequences{$id}=$tmp; $tmp='';
		}
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
	if ( 1 > 0){
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
		    if(! $fastaFlag){$query[$beg + $local_counter]=$inserted_query[$it];}
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
	($Lok,$msg)=&saf_filter(\@alignedNames,\%sequences,\@query,$filter,$maxAli);
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
if($short eq "1"){
    undef @short_alignedNames; undef %tmp_sequences;
    foreach $key (@alignedNames){
	if($key =~ /trembl/ || $key =~/swiss/ || $key=~/pdb/){
	    @tmp=split(/\|/,$key); $short=$tmp[2];
	}
	else { $short=$key;}
	push @short_alignedNames, $short;
    }
    @alignedNames=@short_alignedNames;
    foreach $key (keys %sequences){
	if($key =~ /trembl/ || $key =~/swiss/ || $key =~/pdb/){
	    @tmp=split(/\|/,$key); 
	    $temp=$tmp[$#tmp];
	    $tmp_sequences{$temp}=$sequences{$key};
	}
	else { $tmp_sequences{$key}=$sequences{$key}; }
    }
    %sequences=%tmp_sequences;
}
#foreach $key (@alignedNames){ 
#    print ">>>>>>>>>>>>".$key,"\n";
#    print @{ $sequences{$key} },"\n";
#}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ($Lok,$msg)=&print_saf_file($fileout,$queryName,$queryLength,\%sequences,\@alignedNames,@query);
    return (0,"*** ERROR $sbr : $msg")                                       if ( ! $Lok );
    return (2,"*** WARNIG $sbr : no hits found after filtering for $queryName") if ( $#alignedNames < 0);
    if (-e $fileout) { return (1,"ok"); }
    else { return (0,"*** ERROR $sbr : failed to produce the saf output file"); }
}				# end of blastp_to_saf

#==============================================================================

sub saf_filter{
    my $sbr='saf_filter';
    my ($Lok,$msg);
    local($array_name,$ali_hash,$query,$red,$bound)=@_;
    my @ord_ali_list=@$array_name;
    my %alignment=%$ali_hash;
    my @queryLoc=@$query;
    my @new_aligned_names=();
    my ($count,$ct,$same);
    @last= @queryLoc;
    $len=$#last;
    $count=0;
    Floop:for($index=0; $index <= $#ord_ali_list; $index++){
	if ( ! defined $alignment{$ord_ali_list[$index]}) { return(0,"*** ERROR $sbr : alignment to be filtered is not defined\n")}
	@maybe=split (//,$alignment{$ord_ali_list[$index]});
	$ct=$same=0;
	foreach $itres (0..$len) {
	    next if ($maybe[$itres] !~ /[a-z_A-Z]/);
	    next if ( $last[$itres] !~ /[a-z_A-Z]/);
	    ++$same if ($maybe[$itres] eq $last[$itres]);
	    ++ $ct;
	}
	if ( ( $ct > 30 && (100*$same/$ct) < $red ) || $ct<=30 ){
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
$header="#PERL-RDB"."\n";
$header.="#SEQLENGTH\t $queryLength"."\n";
$header.="#ID\t:\tidentifier of the aligned (homologous) protein"."\n";
$header.="#LSEQ2\t:\length of the entire sequence of the aligned protein"."\n";
$header.="#LALI\t:\tlength of the alignment excluding insertions and deletions"."\n";
$header.="#%IDE\t:\tpercent indentity"."\n";
$header.="#%SIM\t:\tpercent similarity"."\n";
$header.="#LGAP\t:\ttotal gap length"."\n";
$header.="#BSCORE\t:\tblast score (bits)"."\n";
$header.="#BEXPECT\t:\tblast expectation value"."\n";
$header.="#PROTEIN\t:\tone-line description of aligned protein"."\n";
$header.="#'!'\t:\tindicates adjacent blast alignment combined with the previous one"."\n";
$header.="#ID\tLSEQ2\t%IDE\t%SIM\tLALI\tLGAP\tBSCORE\tBEXPECT\tPROTEIN\n";

    open(FHRDB,">$rdbFile") || return(0, "*** ERROR $sbr :  could not open rdbfile=$rdbFile for writing\n");
    print FHRDB $header;
    return( 1,'ok');
}
#==============================================================================================
#==============================================================================================
sub print_saf_file{
    my $sbr='print_saf_file';
    my ($Lok,$msg);
    local($fileout,$queryName,$queryLength,$alignment,$aliNames,@query)=@_;
    my %sequences=%$alignment;
    my @alignedNames=@$aliNames;
    my ($fhout,$pages,$nameField);
    #foreach $key (@alignedNames){
	#print $key."\n";
	#print @{ $sequences{$key} },"\n";
    #}
    #exit;
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
	    #print "@query\n",$query[$first]," $query[$last]\n"; 
	    if ($last <= $queryLength -1 ){print $fhout  @query[$first .. $last]," " ;}
	    else { print $fhout @query[$first .. ($queryLength-1)]; }
	}
	print $fhout  "\n";
	foreach $key (@alignedNames){
	    @tmpL=split (//,$sequences{$key});       #5
	    printf $fhout "%-${nameField}.${nameField}s", $key;
	    for($index=0;$index<50;$index=$index+10){
	       $first=$beg+$index; $last=$first+9; 
	       if ($last <= $queryLength -1 ){ 
		   print $fhout @tmpL[$first .. $last]," " ;
	       }
	       else { print $fhout @tmpL[$first .. ($queryLength-1)]," " ; }
	    }
	    print $fhout  "\n";
	}
	print $fhout "\n";
    }
    close $fhout;
    return (1,'ok');
}
#======================================================================
sub helpLocal {
#-------------------------------------------------------------------------------
#   helpLocal                       
#-------------------------------------------------------------------------------


    if ($#ARGV<0 ||			# help
	$ARGV[0] =~/^(-h|help|special)/){
	print  "goal: $scrGoal\n";
	print  "use:   $scrName file_blastpgp fasta=(file_fasta) \n \n";
	print  "       will convert without file_fasta specified \n";
        print  "       but in some cases you may loose part of query \n";
	print  "       submitted to blastpgp \n";
	print  "opt:  \n";
				#      'keyword'   'value'    'description'
	printf "%5s %-15s=%-20s %-s\n","","saf", "x",           "name of saf output file; if not specified"; 
	printf "%5s %-15s %-20s %-s\n","","",        "",        "default 'saf' extension used";
	printf "%5s %-15s=%-20s %-s\n","","rdb", "x",           "either just 'rdb' -> will write blastRdb file";
	printf "%5s %-15s %-20s %-s\n","","",        "",        "or full name of blastRdb file";
	printf "%5s %-15s=%-20s %-s\n","","red", "x",           "value for filtering saf file (def=100)";
	printf "%5s %-15s=%-20s %-s\n","","maxAli", "x",        "maximum number of aligned sequnces";
	printf "%5s %-15s %-20s %-s\n","","",        "",        "after filtering (def: 1500)";
	printf "%5s %-15s=%-20s %-s\n","","tile",     "x",      "either just 'tile' -> will tile blast prediction in saf";
	printf "%5s %-15s %-20s %-s\n","","",        "",        "or 'tile=(0|1)' to enable|disable tiling (def 1)";
	printf "%5s %-15s=%-20s %-s\n","","eSaf",   "x",         "maximum blast expect value to be included in 'saf' file";
	printf "%5s %-15s%-20s %-s\n","","short",                "will write short id's in the in the saf output file \n";
	printf "%5s %-15s=%-20s %-s\n","","extSaf",   "x",         "specify an extension for the saf file(useful for list processing";
	printf "%5s %-15s=%-20s %-s\n","","extFasta",   "x",       "specify an extension for the fasta file(useful for list processing";
	printf "%5s %-15s=%-20s %-s\n","","extRdb",   "x",       "specify an extension for the rdb file(useful for list processing";
	exit;
    }
}				# end of helpLocal

#===============================================================================

sub fileListRd {
    local($fileInLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!")         if (! defined $fileInLoc);
    #$fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print  "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#==================================================================================



