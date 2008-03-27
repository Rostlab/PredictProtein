package blastp;

INI:{

    $exeBlastDef= "/dodo2/dudek/blast/blastpgp";
    $databaseDef= "/data/blast/bigx_coil_seg";
    $blastargDef= "-j 3 -e .001 -b 5000 -d";
    $optNiceDef=  "nice -15 ";

    $scrName=$0;  $scrName=~s/^.*\/|\.pl//g;
    $scrGoal=     "runs Psi-Blast and produces saf format output\n";

    $extBlast=    ".blastpgp";
    $extSaf=      ".saf";
    $extMat=      ".blastmat";
}

#===============================================================================
sub blastit { 
    local($fileIn,$exeBlast,$dbBlast,$argBlast,
	  $fileOutBlast,$fileOutMat,$fileOutSaf,$dirWork,$dirOut,$optNice,$Ldebug)=@_;
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
    $database=   $dbBlast;
    $blastCmdStr=$argBlast;
    $PWD=        $dirWork;
    $PWD=        ""             if (! $dirWork);
    $dirOut=     ""             if (! $dirOut);

				# correct arguments
    $execBlast=  $exeBlastDef   if (! defined $exeBlast || 
				    ! $exeBlast         ||
				    (! -e $exeBlast && ! -l $exeBlast));
    $database=   $databaseDef   if (! defined $dbBlast  || ! $dbBlast);

    $blastCmdStr=$blastargDef   if (! defined $blastCmdStr || ! $blastCmdStr);

    return(0,"missing exeBlast=$execBlast!")    if (! -e $execBlast && ! -l $execBlast);
    $tmp=$database.".psq";
    return(0,"missing dbBlast=$database|$tmp!") if (! -e $tmp  && ! -l $tmp);

				# further correction
    $blastCmdStr.=" ".$database;

				# get working directory
    $PWD= $PWD || $ENV{'PWD'};
    $PWD=~s/\s//g;
    $dirOut.=    "/"            if ($dirOut && length($dirOut)>1 && $dirOut !~/\/$/);
    $PWD.=       "/"            if ($PWD    && length($PWD)>1    && $PWD !~/\/$/);
    
				# ------------------------------
				# output files
    $idOut=$fileIn; $idOut=~s/\..*$//; 
    $idOut=~s/.+\///; 
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

				# change blast argument
    $blastCmdStr="-i $fileIn -o $fileOut ".$blastCmdStr;
    $blastCmdStr="-Q $mat ".$blastCmdStr
	if ($mat);

				#------- nice option
    if    ($optNice eq "1"){
	$optNice=$optNiceDef;}
    elsif (! $optNice){
	$optNice="";}

				#------- now ready to BLAST it
    ($Lok,$msg)=
	&runBlast($execBlast,$blastCmdStr,$optNice);   
    return(0,"*** ERROR blastit: failed runBlast\n".$msg."\n") if (! $Lok);

    if ($saf){
	($Lok,$msg)=
	    &blastp_to_saf($fileOut,$fileIn,$saf);
	return(0,"*** ERROR blastit: blast_to_saf failed\n".$msg."\n")  if(! $Lok );
    }
       
    return (1,"ok");
}				# end of blastit

#===============================================================================
sub runBlast {
    local($execBlastLoc,$blastCmdStrLoc,$optNice)=@_;
    local($cmdLoc);

    return(0,"*** ERROR missing BLAST exe=$execBlast! (LINE=".__LINE__.")\n")
	if (! -e $execBlast);    
    
    $cmdLoc="$execBlast $blastCmdStrLoc";
    $cmdLoc=$optNice." ".$cmdLoc 
	if (defined $optNice && $optNice);

    system($cmdLoc);

    print "--- runBlast system '$cmdLoc'\n"    
	if (defined $Ldebug && $Ldebug);

    return (1,"ok");
}				# end of runBlast

#==============================================================================
sub blastp_to_saf {
    $sbr="blastp_to_saf";
    return(0,"*** ERROR $sbr: too few arguments")  if ( $#_ < 2 );

    local ($blastfile,$queryfile,$fileout)=@_;
    local (@query, %sequences,@alignedids,@namesSort);
    local (@tmp_seq,@inserted_query,@seq,@alignedNames );
    local ($key,$first,$last,$fhin,$fhout,$local_counter,$beg,$index,$iter,$Score_count);
    
    return(0,"*** ERROR $sbr: missing blast file=$blastfile!\n")  if (! -e $blastfile);
    return(0,"*** ERROR $sbr: missing query file=$queryfile!\n")  if (! -e $queryfile);
    
    $fhin= "FHIN";     $fhout= "FHOUT"; 

                                  #------------------- gets the query sequence and its length
    undef @query;
    open($fhin,$queryfile) || return(0,"*** ERROR sbr: blastp_to_sat $queryfile  - no such file\n"); 
    while(<$fhin>){
	next if($_=~/^\n/ || $_=~/\//);
	if ($_=~/^>/){
	    $_=~s/^>//;
	    @tmp=split(/\s+/,$_);
	    $queryName=$tmp[0];
	    next;
	}
	$_=~s/\s+//g;
	@tmp=split(//,$_);
	push @query, @tmp;
    }
    close $fhin;
    $queryLength=$#query+1;
                                #..........................................................

                                #------------------- finds number of iterations in blast file
    open($fhin,$blastfile) || return(0,"*** ERROR $sbr: failed to open blast file $blastfile\n");
    $iter=0;
    while(<$fhin>){
	if($_=~/^Sequences producing significant/){
	    $iter++;
	}
    }
    close $fhin;
    return(0,"*** ERROR $sbr: blast file format not recognized\n") if ($iter == 0);
                                #............................................................

                                #--------------------------------skips to the last iteration
    open($fhin,$blastfile) || return(0,"*** ERROR $sbr: failed to open blast file $blastfile\n");
    $local_counter=0;
    while(<$fhin>){
	if($_=~/^Sequences producing significant/){
	    $local_counter ++;
	}
	last if($local_counter == $iter);
    }
    #print "# of iterations is $iter\n";
    #............................................................
    undef @alignedNames; undef @alignedids; $Score_count=0;
    while(<$fhin>){
	if($_=~/^>/){ 
	    undef @seq; $Score_count=0; 
							     #--- getting name of aligned sequence
	    for($it=0;$it<=$queryLength-1;$it++){            #- and initialising its array @seq   
		$seq[$it]=".";
	    }
	    $_=~s/^>//; #print $_;
	    @tmp=split(/\s+/,$_);
	    $id=$tmp[0];	
	    #if ($id=~/swiss/){@tmp=split(/\|/,$id); $id=$tmp[2];}
	    #if ($id=~/trembl/){@tmp=split(/\|/,$id); $id=$tmp[2];}
	    push @alignedids, $id;
	}                                                    #------------------------------------

	$Score_count++              if ( $_=~ /Score/ );
	next                        if ( $Score_count > 1);
	if($_=~/^Query:/){ @tmp=split(/\s+/,$_); undef @aligned; undef @inserted_query;
			   $beg=$tmp[1]-1; $end=$tmp[3]-1;
			   @inserted_query=split(//,$tmp[2]);
		      }
	if($_=~/^Sbjct:/){
	    @tmp=split(/\s+/,$_); #print $_;
	    @aligned=split(//,$tmp[2]);
						     #getting rid of insertions at query sequence
	    print " *** ERROR sbr: blastp_to_satin lenghts for $id\n"  if ($#inserted_query != $#aligned);
	    $local_counter=0;
	    undef @tmp_seq;
	    for($it=0;$it <= $#inserted_query; $it++){
		if ($inserted_query[$it] =~ /[a-z_A-Z]/){
		    $tmp_seq[$local_counter]=$aligned[$it];
		    $local_counter++;
		}
	    }    
	    @aligned=@tmp_seq;                     #-------------------------------------------

	    @seq[$beg .. ($beg+$#aligned)]=@aligned; #----alignig part of the subject seguence
	    foreach $elem (@seq){
		if(($elem ne ".") && ($elem !~ /[a-z_A-Z]/)){
		    $elem=".";
		}
	    }
	    $sequences{$id}=[ @seq ];                #---------------------------------------------
	}
    }
    close $fhin;				     #------- getting rid of the querry seq from alignment
    foreach $it (@alignedids){
	if($it ne $queryName){ push @namesSort, $it; }
    } 
						     #--------------------------------------------
                                   
    foreach $it (@namesSort){                       #getting rid of repeats in the list
	$indicator=0;
	foreach $es (@namesSort){
	    if ( $it eq $es ){ $indicator++;}
	}
	if ($indicator <= 1){ push @alignedNames, $it; }
    }                                               #-------------------------------------

    #----------------------------------- printing out the resulting file
    $pages=int $queryLength/50;
    if ($queryLength%50 != 0){$pages++;}

    open($fhout,">$fileout") || return(0,"*** ERROR $sbr: failed to open fileout=$fileout!");
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
	    print$fhout  "\n";
	}
	print $fhout "\n";
    }
    close $fhout;
    return (1,"ok")             if (-e $fileout); 
}				# end of blastp_to_saf
