#! /usr/bin/perl -w

($QueryFastaFile,$HsspFile,$StripFile,$FileOutAL,$SeqName)=@ARGV;

$dbg=0; 
$server="PSPT";
if(! -e $QueryFastaFile || ! -e $HsspFile || ! -e $StripFile ||
   ! defined $FileOutAL || ! defined $SeqName){
    die "fasta=$QueryFastaFile, hssp=$HsspFile or strip=$StripFile or SeqName=$SeqName not found or not defined, stopped";
}
$par{'bl2seq'}           ="/usr/pub/molbio/blast/bl2seq";
$par{'PDB_dir'}          ="/data/pdb/";
$par{'PDB_dir_obsolete'} ="/data/pdb_obsolete/";

$pack  ="pack/hssp_parser.pm";
if (! -e $pack){ 
    $dir=$0; 
    $dir=~s/\.\///g;
    $dir=~s/^(.*\/).*$/$1/;
    $pack=$dir.$pack; 
}
$get=require $pack;
die "ERROR $0 main: failed to require hssp_parser.pm\n" if(!$get);


($Lok,$msg,$hr_StripData)=&parse_strip($StripFile);
die "ERROR $msg, stopped" if(! $Lok);

$IDQuery=$HsspFile; $IDQuery=~s/^.*\/|\.\S*$//g;
if(! defined $FileOutAL){ $FileOutAL=$IDQuery.".AL"; }

($Lok,$msg,$IDQuery,@RESULT)=
    &hssp_parser::run_hssp_parser($HsspFile,5,$hr_StripData);
die "ERROR: $msg, stopped" if(! $Lok);

$HsspParsedFile=$IDQuery.".HsspParsed";
open(FHPARSED,">".$HsspParsedFile) || 
    die "ERROR failed to open HsspParsedFile=$HsspParsedFile, stopped";
for $j (0 .. $#RESULT){ print FHPARSED $RESULT[$j],"\n"; }
close FHPARSED; @RESULT=();


($Lok,$msg,$serverALfilesRef)=&get_proper_AL_files($server,$IDQuery,$QueryFastaFile,$HsspParsedFile);
die "ERROR $msg, stopped" if(! $Lok);


open(FHOUTAL,">".$FileOutAL) ||
    die "failed to open FileOutAL=$FileOutAL for writing, stopped";

foreach $it (@{ $serverALfilesRef }){
    @tmp=&read_file_to_array($it);
    foreach $line (@tmp){ print FHOUTAL $line; }
    print FHOUTAL "\n";
    if(! $dbg){ unlink $it; }
}
unlink $HsspParsedFile;
#======================================================================
sub get_proper_AL_files{
    my $sbr='get_proper_AL_files';
    my ($server,$IDQuery,$QueryFastaFile,$serverParsedFile)=@_;
    return(0,"ERROR $sbr: missing arguments among @_")
	if(!defined $server || !defined $IDQuery || 
	   !defined $serverParsedFile || ! defined $QueryFastaFile);
    my (%ServerData,%TemplateRanks);
    my (@hits);
    my ($Rank,$ServAlignment,$serverALfilesRef,$ServScore,$Template);

    open(FHLOC,$serverParsedFile) || 
	die "ERROR $sbr: failed to open file $serverParsedFile, stopped";
    while(<FHLOC>){
	next if($_=~/^\n/);
	$_=~s/\s*$//;
	@tmp=split(/;;;/,$_);
	($Template,$Rank,$ServScore)=split(/\t/,$tmp[0] ); # @data contains [id,rank,zscore,...]
	$ServAlignment=$tmp[1];

	if(! defined $ServerData{$IDQuery}{$Rank} ){
	    $TempNo=1;
	}
	else{ $TempNo++; }
	push @{ $TemplateRanks{$Template} }, [$Rank,$TempNo] ;
 
	$ServerData{$IDQuery}{$Rank}{$TempNo}{'Template'}=$Template;
	#print "Query $IDQuery Rank $Rank TempNo $TempNo Template $Template\n";
	$ServerData{$IDQuery}{$Rank}{$TempNo}{'score'}=$ServScore;
	$ServerData{$IDQuery}{$Rank}{$TempNo}{'alignment'}=$ServAlignment;
    }
    close FHLOC;
  
    @hits=("1","2","3","4","5");
    ($Lok,$msg,$serverALfilesRef)=&write_AL_files($IDQuery,$QueryFastaFile,$server,{%ServerData},@hits);
    return(0,"ERROR $sbr: $msg") if(!$Lok);
    
    return(1,'ok',$serverALfilesRef);
}
#======================================================================



#========================================================================
sub write_AL_files{
    my $sbr='write_AL_files';
    my ($IDQuery,$QueryFastaFile,$server,$rh_Data,@hits)=@_;

    return(0,"ERROR $sbr: not all arguments are defined") 
	if(! $rh_Data || ! defined $IDQuery || ! defined $server 
	   || ! defined $QueryFastaFile);
    return(0,"ERROR $sbr: hits to be evaluated missing in sub argument") if($#hits<0);
    my %Data=%{ $rh_Data };
    my (@AL,@ALArray,@ALChecked,@ALfiles,@PDBData,@QueryFromAL,@QueryNumbersFromAL,@SubjFromAL,
	@SubjNumbersFromAL,@TempNos);
    my ($ALfile,$alignment,$Chain,$CountNotFixed,$fileID,$ErrorFlag,$FixQueryNumbering,$FixSubjectNumbering,$index,
	$hitId,$HitPdbFile,$NumQuery,$NumSubject,$PDBChain,$QueryFastaDir,
	$QueryPDBFile,$Rank,$ResQuery,$ResSubject,$splitPdbID,$ServScore,$TempNo);

    my (@QueryFromFile,@FixedQuery,@FixedSubject,@QueryAsAligned,
	@QueryResFromFile,@SubjectAsAligned);
    my (%h_PDBNumbering);

    
    #reading sequence into array form $QueryFastaFile
    ($Lok,$msg,@QueryFromFile)=&read_numbering_from_FASTA_file($QueryFastaFile);
    
    undef %h_PDBNumbering;
    foreach $it (@QueryFromFile){
	$Residue=@{ $it }[0]; $Number=@{ $it }[1];
	$h_PDBNumbering{$Number}=$Residue;
    }
 
    
    @ALfiles=();
    #@RanksTmp=sort keys %{ $Data{$IDQuery} } ;
	
    for $itloc (0 .. $#hits){      #-------getting alignments and checking them
	$Rank=$hits[$itloc];
	@TempNos=();
	
	if (! defined $Data{$IDQuery}{$Rank}){
	    print "Data for IDQuery=$IDQuery Rank=$Rank not defined\n";
	    next;
	}
	@TempNos=sort { $a <=> $b } keys %{ $Data{$IDQuery}{$Rank} };
	
	foreach $TempNo ( @TempNos ){
	    $tmp=$Data{$IDQuery}{$Rank}{$TempNo}{'Template'};
	
	}
	foreach $TempNo ( @TempNos ){ 
	    $alignment='';
	    $alignment  =$Data{$IDQuery}{$Rank}{$TempNo}{'alignment'};    #last element in @$DataRef is 
	    $Template   =$Data{$IDQuery}{$Rank}{$TempNo}{'Template'};
	    $ServScore  =$Data{$IDQuery}{$Rank}{$TempNo}{'score'}; 
	    if(! defined $Template){ 
		$errmsg="ERROR $sbr: no Template name found for rank=$Rank TempNo=$TempNo";
		$errmsg.="for IDQuery=$IDQuery, stopped";
		die "$errmsg";
	    }
	    if(! defined $alignment){ $alignment=''; }
	    if($alignment =~ /\w/){
		$alignment=~/\,/ || 
		    die "ERROR $sbr: no alignment found for hit number $hits[$i] for IDQuery=$IDQuery, stopped";
	    }
	    $alignment=~s/\,\s*$|\s*$//;
	    @AL=@ALArray=();                      
	    @QueryFromAL=@SubjFromAL=@QueryNumbersFromAL=@SubjNumbersFromAL=();
	    @AL=split(/\,/,$alignment);        #AL contains alignment in CASP4-AL format including tabs     
	    for $i (0 .. $#AL){                 
		$AL[$i]=~m/^(\S*)\t(\S*)\t(\S*)\t(\S*)\s*$/;   
		$ResQuery=$1; $NumQuery=$2; $ResSubject=$3; $NumSubject=$4;
		#print $ResSubject;
		return(0,"ERROR $sbr: failed to read residue and its number from alignment data:\n$AL[$i]") 
		    if (! defined $ResQuery || ! defined $NumQuery || 
			! defined $ResSubject || ! defined $NumSubject);
		#ALArray contains CASP4-AL in a form of array
		push @ALArray, [$ResQuery,$NumQuery,$ResSubject,$NumSubject] ;
		push @QueryFromAL, $ResQuery; push @SubjFromAL, $ResSubject;
		push @QueryNumbersFromAL, $NumQuery; push @SubjNumbersFromAL, $NumSubject;
	    }
	    @AL=();
	#print "xxxxxxxx\n";
	#------------------------------here checking correct numbering of query sequence
	                               #read Fasta file from $par{'query_fasta_dir'}	
	
	
	    $FixQueryNumbering=0;
	    @QueryAsAligned=();
	    for $i (0 .. $#ALArray){              #reading query numbering from alignment
		# and checking if agrees with numbering
		#from @QueryFromFile
		$Residue=@{ $ALArray[$i] }[0]; $Number=@{ $ALArray[$i] }[1];
		return(0,"ERROR $sbr: resid & numb in ALArray not defined -> @{$ALArray[$i]}\n")
		    if (! defined $Residue || ! defined $Number);
		push @QueryAsAligned,[$Residue,$Number];  
		push @ALChecked,@{ $ALArray[$i] }[0]."\t".@{ $ALArray[$i] }[1]."\t".@{ $ALArray[$i] }[2]."\t".@{ $ALArray[$i] }[3];
		$FixedQuery[$i+1]=[$Residue,$Number,$Residue,$Number];
		if (! defined $h_PDBNumbering{$Number}    ||
		    $Residue ne $h_PDBNumbering{$Number} )  {
		    $FixQueryNumbering=1; #do not put 'last' here because you need QueryAsAligned
		}
	    }	
	    if($FixQueryNumbering){                 #fixing numbering of Query
		@FixedQuery=();
		$fileID=$QueryFastaFile; $fileID=~s/\.f//; $fileID.="_FASTA_".$server;
		$dbg==0 || 
		    print "exec sec: &fix_numbering($IDQuery,$fileID,QueryFromFileRef,QueryAsAlignedRef)"." for query file $QueryFastaFile\n";
		($Lok,$msg,@FixedQuery)=&fix_numbering($IDQuery,$fileID,[@QueryFromFile],[@QueryAsAligned] );
		return(0,"ERROR $sbr: $msg") if(!$Lok);
		#print "FixedQuery is: $#FixedQuery +1\n";
	    } 
	    else { }#print "no need to fix Query Numbering\n"; }
	    @QueryAsAligned=();
	    #-------------------------------------------------------------------------
	    
	    # now checking correct numbering of aligned sequences	

	    $HitPdbFile=$Chain='';
	    $HitPdbFile=$Template;             #getting name of pdb file
	    if($HitPdbFile !~/_/){$HitPdbFile.=".pdb";$Chain='';}
	    else{ $HitPdbFile=~s/^(\S*)_(\S)/$1/; $Chain=$2;$HitPdbFile.=".pdb";}
	    
	    $PDBDir=$par{'PDB_dir'};
	    die "ERROR $sbr: PDB directory not defined, stopped" 
		if(! defined $PDBDir);
	    $PDBDir=~/\/$/ || ($PDBDir.='/');
	    $HitPdbFile=$PDBDir.$HitPdbFile;
	    
	    if(! -e $HitPdbFile){
		$HitPdbFile=~s/.*\///;
		$PDBDir=$par{'PDB_dir_obsolete'};
		die "ERROR $sbr: PDB directory not defined, stopped" 
		    if(! defined $PDBDir);
		$PDBDir=~/\/$/ || ($PDBDir.='/');
		$HitPdbFile=$PDBDir.$HitPdbFile;
	    }
	    @PDBData=();
	    $dbg==0 || print 'exec sub: &get_PDB_sequence('.$HitPdbFile.','.$Chain.')'."\n";
	    ($Lok,$msg,@PDBData)=&get_PDB_sequence($HitPdbFile,$Chain);
	    return(0,"ERROR $sbr: $msg") if (! $Lok);
	    #checking if PDB sequence numbering is unique
	    undef %h_PDBNumbering;
	    foreach $it (@PDBData){
		$Residue=@{ $it }[0]; $Number=@{ $it }[1];
		if(defined $h_PDBNumbering{$Number}){ 
		    return(0,"ERROR, found instance of non unique sequence numbering for $HitPdbFile, chain=$Chain in $ServerFile, stopped");
		}
		else{ $h_PDBNumbering{$Number}=$Residue; }
	    }

	    $FixSubjectNumbering=0;
	    @SubjectAsAligned=();
	    #print "HERE!!! Subject as aligned:\n";
	    for $i (0 .. $#ALArray){                  #reading subject numbering from alignment
		$Residue=@{ $ALArray[$i] }[2]; $Number=@{ $ALArray[$i] }[3]; 
		if (! defined $Residue || ! defined $Number){
		    return(0,"ERROR $sbr: resid & numb in ALArray not defined -> @{$ALArray[$i]}\n"); }	
		push @SubjectAsAligned,[$Residue,$Number];
		#print "$Residue $Number\n";
		$FixedSubject[$i+1]= [$Residue,$Number,$Residue,$Number];
		if ( ( ! defined $h_PDBNumbering{$Number} )    ||
		     ( $Residue ne $h_PDBNumbering{$Number} ) ){
			 $FixSubjectNumbering=1; #do not put 'last' here because you need SubjectAsAligned
		}
	    }
	    #print "\nxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n";
	    if($FixSubjectNumbering){
		@FixedSubject=();
		$fileID=$Template; $fileID.="_PDB_".$server;
		$dbg==0 || 
		    print "exec sec: &fix_numbering($IDQuery,$fileID,PDBDataRef,SubjectAsAlignedRef)"." for Subject file $HitPdbFile 2!\n"; 
		#print "@@ before PDBData: $#PDBData\n";
		($Lok,$msg,@FixedSubject)=&fix_numbering($IDQuery,$fileID,[@PDBData],[@SubjectAsAligned] );
		return(0,"ERROR $sbr: $msg") if(!$Lok);
		#print "FixedSubject is $#FixedSubject +1\n"; 
	    }
	    else{}
	    @PDBData=@SubjectAsAligned=();
	    $ResQuery=$ResSubject=$NumQuery=$NumSubject='';
	#print "@@@@@@@@ before is for server $server: $#ALArray\n";
	    if ($FixQueryNumbering || $FixSubjectNumbering){
		@ALChecked=(); $CountNotFixed=0;
		for $i (0 .. $#ALArray){
		    $ServAliNumber=$i+1;
		    $ResQuery=@{ $ALArray[$i] }[0]; $NumQuery=@{ $ALArray[$i] }[1]; 
		    $ResSubject=@{ $ALArray[$i] }[2]; $NumSubject=@{ $ALArray[$i] }[3];
		    #print "FROM ALArray: ResQuery=$ResQuery NumQuery=$NumQuery ResSubject=$ResSubject NumSubject=$NumSubject\n";
		    if (! defined $ResQuery || ! defined $NumQuery || 
			! defined $ResSubject || ! defined $NumSubject){
			return(0,"ERROR $sbr: failed to read residue & number from ali data:\n$AL[$i]");
		    }                  #throwing out 'X' from alignment since can not check them using
		    next if($ResQuery eq 'X' || $ResSubject eq 'X'); #bl2seq program
		    $ErrorFlag=0;
		    if (defined $FixedQuery[$ServAliNumber] && defined $FixedSubject[$ServAliNumber] ){
			if( @{ $FixedQuery[$ServAliNumber] }[2]     eq 'X' || 
			    @{ $FixedSubject[$ServAliNumber] }[2] eq 'X'    ){ next;}
			if( $ResQuery   ne @{ $FixedQuery[$ServAliNumber] }[0] ){ 
			    $ErrorFlag=1;
			    print "ResQuery=$ResQuery FixedQuery=@{ $FixedQuery[$ServAliNumber] }[0]\n";
			}
			if( $ResSubject ne @{ $FixedSubject[$ServAliNumber] }[0] ){ 
			    $ErrorFlag=1;
			    print "ResSubject=$ResSubject NumSubject=$NumSubject FixedSubject=@{ $FixedSubject[$ServAliNumber] }[0] NumFixedSubject=@{ $FixedSubject[$ServAliNumber] }[3]\n"
			    #dumpValue(\@FixedSubject );
			}
			if( @{ $FixedQuery[$ServAliNumber] }[0] ne  @{ $FixedQuery[$ServAliNumber] }[2] ){
			    $ErrorFlag=1;
			    print "FixedQuery=@{ $FixedQuery[$ServAliNumber] }[0] FixedQueryAligned= @{ $FixedQuery[$ServAliNumber] }[2]\n";
			    #dumpValue(\@FixedQuery);
			}
			if( @{$FixedSubject[$ServAliNumber] }[0] ne @{$FixedSubject[$ServAliNumber] }[2]){
			    $ErrorFlag=1;
			    print "FixedSubject=@{ $FixedSubject[$ServAliNumber] }[0] FixedSubjectAligned= @{ $FixedSubject[$ServAliNumber] }[2]\n";
			    #dumpValue(\@FixedSubject );
			}
			if($ErrorFlag==1){
			    return(0,"ERROR $sbr: residues not equal IDQuery=$IDQuery $ServerFile::".__FILE__.' '.__LINE__); 
			}
			else{ push @ALChecked, $ResQuery."\t".@{ $FixedQuery[$ServAliNumber] }[3]."\t".$ResSubject."\t".@{ $FixedSubject[$ServAliNumber] }[3];
			  }
		    }
		    else{ $CountNotFixed++; }
		}
		$tmp=$CountNotFixed/($#ALArray +1);
		if($tmp > 5){ 
		    die "ERROR IDQuery=$IDQuery, percent of residues for which fixed alingment was not defined is $tmp (bigger than 5) out of $#ALArray +1, stopped";
		}
	    }
	    @AL=@ALChecked; @ALChecked=@ALArray=();
	    @FixedQuery=@FixedSubject=();
	    #$after=$#AL;
	    #print "@@@@@@@@@@ After is for server $server: $after\n";
	    
	    if($server ne 'CE'){
		#$ALfile=$serverWorkDir.$IDQuery.'-vs-'.$Template."___".$server."-hit".$Rank."-AL";
		$ALfile=$serverWorkDir.$IDQuery."___".$server."-hit".$Rank."-AL";
	    }
	    else {
		#$ALfile=$serverWorkDir.$IDQuery.'-vs-'.$Template."___".$server."-AL";
		$ALfile=$serverWorkDir.$IDQuery."___".$server."-AL";
	    }
	    #print "Query=$IDQuery Rank=$Rank TempNo=$TempNo Template=$Template \n";
	    if($TempNo==1){
		if(-e $ALfile){ 
		    unlink ($ALfile) ||  
			return (0,"ERROR $sbr : could not unlink ALfile=$ALfile");
		}
		push @ALfiles,$ALfile;
	    }
	    open(FHAL,">>".$ALfile) ||
		return(0,"ERROR $sbr: failed to open $ALfile for writing");
	    if($TempNo==1){
		print FHAL "PFRMAT AL\n";
		$tmploc=$IDQuery; $tmploc=~s/:_//; $tmploc=~s/:/_/;
		if(defined $SeqName){ $tmploc=$SeqName; }
		print FHAL "TARGET $tmploc\n";
		#print FHAL "AUTHOR ...\n";
		print FHAL "REMARK automatic alignment by $server\n";
		print FHAL "SCORE $ServScore\n";
		print FHAL "MODEL $Rank\n";
	    }
	    $tmploc=$Template; $tmploc=~s/:_//; $tmploc=~s/:/_/;
	    print FHAL "PARENT $tmploc\n";
	    for $j (0 .. $#AL){$AL[$j]=~tr[a-z][A-Z]; print FHAL $AL[$j],"\n"; }
	    print FHAL "TER\n";
	    if($TempNo eq $TempNos[$#TempNos] ){   print FHAL "END\n";  }
	    close FHAL;
	}               #foreach $TempNo ...  loop ends here
    }                   #for $hitIndex ...  loop ends here
    return(1,'ok',[@ALfiles]);
}
#========================================================================

#=========================================================================
sub read_numbering_from_FASTA_file{
    my $sbr='read_numbering_from_FASTA_file';
    my $FastaFileName=$_[0];
    die "ERROR $sbr: fasta file name argument not defined, stopped"
	if(! defined $FastaFileName);
    my (@seq,@tmp,@l_numbering);
    my ($ct);
    open(FHFASTA,$FastaFileName) || 
	die "ERROR $sbr: failed to open FastaFileName=$FastaFileName, stopped";
    while(<FHFASTA>){
	next if ($_=~/^\n|^>/);
	$_=~s/\s//g; @tmp=split(//,$_);
	push @seq, @tmp;
    }
    $ct=0;
    foreach $it (@seq){
	$ct++;
	push @l_numbering,[$it,$ct];
    }
    close FHFASTA;
    return(1,'ok',@l_numbering);
}
#=========================================================================
#========================================================================
sub get_PDB_sequence{
    my $sbr='get_PDB_sequence';
    my ($PDBFile,$chain)=@_;   #note $PDBFile is a full adress (with PDB directory)
    my ($add,$chainflag,$countFalseChain,$PrevNo,$ReadingFlag,$ResidueNo,$warnFlag,$modelCount);
    my (@fields,@SeqData);
    my (%ThreeToOneAminoTrans);
    return(0,"ERROR $sbr: not all arguments are defined") if(! defined $PDBFile || ! defined $chain);
    %ThreeToOneAminoTrans= (GLY=>'G',ALA=>'A',VAL=>'V',LEU=>'L',ILE=>'I',PRO=>'P',PHE=>'F',TYR=>'Y',TRP=>'W',SER=>'S',THR=>'T',CYS=>'C',MET=>'M',ASN=>'N',GLN=>'Q',ASP=>'D',GLU=>'E',LYS=>'K',ARG=>'R',HIS=>'H',UNK=>'X');
    if($chain !~ /\S/){$chainflag='no';}
    else {$chainflag='yes';}
    
    open(FHPDB,"$PDBFile")  ||   return (0,"ERROR $sbr : could not open PDBFile=$PDBFile");
    $PrevNo='-----'; $modelCount=$countFalseChain=0; $ReadingFlag=0;
    while (<FHPDB>){
	if($_=~/^MODEL /){ 
	    $modelCount++; 
	    if ( $modelCount >1 && $#SeqData > -1){last;} 
	    elsif( $modelCount > 1 && $#SeqData==-1){ 
		print FHWARNING "found to consequtive MODEL fields in file $PDBFile\n";
		print "found to consequtive MODEL fields in file $PDBFile\n";
	    }
	}
	if($_=~/^TER / && $ReadingFlag==1){ last; }
	if ($_=~/^ATOM/){
	    @fields=split(//,$_);
	    $ResidueNo=''; $ResidueTrip='';
	    if ($chainflag eq 'no'){ 
		if($fields[21] !~ /\s/){
		    print "WARNIG $sbr: chain found in PDB file with chainless id. pdbline=$_ pdbFile=$PDBFile chain=$chain ".__LINE__." ".__FILE__."\n"; 
		    $countFalseChain++;
		    if($countFalseChain<10){ next; }
		    else{ return(0,"ERROR $sbr: chain found in PDB file with chainless id. pdbline=$_ pdbFile=$PDBFile chain=$chain ".__LINE__." ".__FILE__ ); }
		}
		for $i (22 .. 26){
			if($fields[$i] !~ /\w|\s|-/){return (0,"ERROR $sbr: incorrect sequence number "); }
			$ResidueNo.=$fields[$i];
		}
		$ResidueNo=~s/\s//g;
		for $i (17 .. 19){
			if($fields[$i] !~ /[A-Z]/){return (0,"ERROR $sbr: incorrect residue name @fields[17 .. 19]"); }
			$ResidueTrip.=$fields[$i];
		}
		$Residue=$ThreeToOneAminoTrans{$ResidueTrip};
		#return (0,"ERROR $sbr: did not find single letter name for residue $ResidueTrip") 
		if (! defined $Residue){   #since there are multiple atom entrences for each residue
		    $Residue='X';    }#pushing is only when ResidueNo changes
		if($PrevNo ne $ResidueNo){
		    push @SeqData,[$Residue,$ResidueNo]; $PrevNo=$ResidueNo; $ReadingFlag=1; 
		}
		if($fields[27] !~/\s/){$warnFlag=1;}
	    }
	    if ($chainflag eq 'yes'){ 
		if ($fields[21] eq $chain){
		    for $i (22 .. 26){
			if($fields[$i] !~ /\w|\s|-/){return (0,"ERROR $sbr: incorrect sequence number "); }
			$ResidueNo.=$fields[$i];
		    }
		    $ResidueNo=~s/\s//g;
		    for $i (17 .. 19){
			if($fields[$i] !~ /[A-Z]/){return (0,"ERROR $sbr: incorrect residue name @fields[17 .. 19]"); }
			$ResidueTrip.=$fields[$i];
		    }
		    $Residue=$ThreeToOneAminoTrans{$ResidueTrip};
		    #return (0,"ERROR $sbr: did not find a single letter name for residue $ResidueTrip")
		    if (! defined $Residue){#since there are multiple atom entrences for each residue
			$Residue='X'; }			#pushing is only when ResidueNo changes
		    if($PrevNo ne $ResidueNo){ 
			push @SeqData,[$Residue,$ResidueNo]; $PrevNo=$ResidueNo; $ReadingFlag=1;
		    }
		    if($fields[27] !~/\s/){$warnFlag=1;}
		}
		else { next ; }
	    }
	}
    }
    close FHPDB;
    if($warnFlag){ print "WARNING $sbr: coordinates close to residue numbers, check file $PDBFile\n"; }

    return(1,'ok',@SeqData);
}
#=========================================================================
#========================================================================
sub fix_numbering{
    #returns array, as it was aligned. Each element contains an array: [ $QueryRes[$j],$IndexQuery,$SubjectRes[$j],$IndexSubject ]
    my $sbr='fix_numbering';
    my ($IDQuery,$fileID,$SeqFromFileRef,$SeqAsAlignedRef)=@_;
    my (@SequenceToFix);
    my (@FullSeqAsAligned,@FullSeqFromFile,@Query,@Subject,@AsignmentData);
    my (%h_allNumbers,%h_ResNumtoFileResNum);
    my ($Number);
    return(0,"ERROR $sbr: not all arguments are defined") 
	if(! defined $SeqFromFileRef || ! defined $SeqAsAlignedRef || ! defined $fileID
	   || ! defined $IDQuery);
    #print "check in\n";
    #writing customized array of FullSeqFromFile  no need to calculate full sequence
    @SequenceToFix=@{ $SeqFromFileRef };
    
    #print "SequenceFromFile:\n"; #&print_reference_array([@SequenceToFix]);
    @FullSeqFromFile=();
    for $i (0 .. $#SequenceToFix){
	#print @{ $SequenceToFix[$i] },"\n";
	$FileRes=@{ $SequenceToFix[$i] }[0];
	$FileResNum=@{ $SequenceToFix[$i] }[1];
	$Num=$i+1;
	push @FullSeqFromFile, [ $FileRes, $Num ];
	#print "$i $FileRes $FileResNum\n";
	die "not defined $FileResNum for $Num\n" if(! defined $FileResNum);
	$h_ResNumtoFileResNum{$Num}= $FileResNum;  #allows two types of numbering simple sequential and that found in file
    }
    #info: %h_ResNumtoFileResNum has keys correspending to simple sequential numbering of all residues
    ####
    
    @SequenceToFix=@$SeqAsAlignedRef;
    undef %h_allNumbers; @tmp=();
    #print "SeqAsAligned before calculate_full_sequence:\n";
    #&print_reference_array([@SequenceToFix]);
    ($Lok,$msg,@FullSeqAsAligned)=&calculate_full_sequence($fileID,$IDQuery,@SequenceToFix);
    return(0,"ERROR $sbr: $msg") if(!$Lok);
    #print "SeqAsAligned after calculate_full_sequence:\n";
    # &print_reference_array([@FullSeqAsAligned]);
    #info: new FullSeqAsAligned contains sometimes third entry in each subarray, indicating sequential number in server alignment 
    @SequenceToFix=();
    
    #print "here:\n";
    #foreach $it (@FullSeqAsAligned){ print @{$it},"\n"; }


    my ($FileResNumb,$FirstQuery,$FirstSubj,$SeqAsAligned,$SeqFromFile,$line,$bl2seqOut);
    my (@Residues);
    
    $SeqFromFile=$SeqAsAligned='';
    @Residues=();

    for $i (0 .. $#FullSeqAsAligned){ push @Residues, @{ $FullSeqAsAligned[$i] }[0]; }
    $SeqAsAligned=join '',@Residues; #that means that i-th residue of SeqAsAligned equals i-1 th residue of FullSequenceAsAligned 
    @Residues=();
    
    for $i (0 .. $#FullSeqFromFile){ push @Residues, @{ $FullSeqFromFile[$i] }[0]; }
    $SeqFromFile =join '',@Residues;
    @Residues=(); 

    #writing input files to bl2seq program
    my ($CountMisaligned,$SeqAsAlignedFileName,$SeqFromFileFileName,
	$FileBL2SEQout,$FoundAlignment,$fileIDLoc);
    $fileIDLoc=$fileID; $fileIDLoc=~s/^.*\///;
    $SeqAsAlignedFileName="SeqAsAligned_".$fileIDLoc.".f_".$$;
    $SeqFromFileFileName="SeqFromFile_".$fileIDLoc.".f_".$$;
    $FileBL2SEQout="bl2seq_out_".$fileIDLoc.'_'.$$;
    @tmp=();
    @tmp=split(//,$SeqAsAligned); $SeqAsAligned=''; $count=0;
    for $k (0 .. $#tmp){
	$count++;
	$SeqAsAligned.=$tmp[$k];
	if($count % 50 eq 0 ){$SeqAsAligned.="\n"; }
	elsif($count % 10 eq 0 ){$SeqAsAligned.=" "; }
    }
    @tmp=();
    open(FH1,">".$SeqAsAlignedFileName)||  return(0,"ERROR $sbr: could not open file  $SeqAsAlignedFileName for writing"); 
    $line=">".$SeqAsAlignedFileName."\n".$SeqAsAligned."\n";
    #print $line;
    print FH1 $line;
    close FH1; #$SeqAsAligned='';
    @tmp=split(//,$SeqFromFile); $SeqFromFile=''; $count=0;
    for $k (0 .. $#tmp){
	$count++;
	$SeqFromFile.=$tmp[$k];
	if($count % 50 eq 0 ){$SeqFromFile.="\n"; }
	elsif($count % 10 eq 0 ){$SeqFromFile.=" "; }
    }
    @tmp=();
    open(FH2,">".$SeqFromFileFileName) || 
            return(0,"ERROR $sbr: could not open file $SeqFromFileFileName for writing"); 
    $line=">".$SeqFromFileFileName."\n".$SeqFromFile."\n";
    #print $line;
    print FH2 $line;
    close FH2; $SeqFromFile='';

    @Query=@Subject=();
                                          #running bl2seq
    $bl2seq_exe=$par{'bl2seq'};
    die "ERROR $sbr: executable bl2seq not defined, stopped"
	if(! defined $bl2seq_exe);
    $dbg==0 || 
       print "run: system($bl2seq_exe -F F -W 2 -i $SeqAsAlignedFileName -j $SeqFromFileFileName  -o $FileBL2SEQout)\n";
       
    system("$bl2seq_exe -F F -W 2 -i $SeqAsAlignedFileName -j $SeqFromFileFileName -o $FileBL2SEQout -M BLOSUM80")==0 ||
	return(0,"ERROR $sbr: bl2seq failed ",__FILE__,__LINE__);
    open(FHIN,"$FileBL2SEQout") || 
	return(0,"ERROR $sbr: failed to open bl2seqOut=$FileBL2SEQout file");
    $ScoreCount=$FoundAlignment=0;
    while(<FHIN>){
	if($_=~/^>/){ $FoundAlignment=1; }
	next if($_ !~ /^Query:|^Sbjct:| Score =/);
	if($_=~/ Score =/){$ScoreCount++; next if($ScoreCount==1); last if($ScoreCount > 1);}
	$_=~s/\s*$//;
	if($_=~/^Query:/){
	    $_=~m/^Query:\s*(\d*)\s*(\S*)\s*(\d*)$/;
	    $QueryBeg=$1;$QueryEnd=$3; $QueryAli=$2;
	    return(0,"ERROR $sbr: failed to grep all Query fields from file bl2seqOut=$FileBL2SEQout
                      in:\n$_\n")
		if(! defined $QueryBeg || ! defined $QueryEnd || ! defined $QueryAli);
	    push @Query, $QueryBeg."\t".$QueryAli."\t".$QueryEnd;
	}
	elsif($_=~/^Sbjct:/){
	    $_=~m/^Sbjct:\s*(\d*)\s*(\S*)\s*(\d*)$/;
	    $SubjectBeg=$1;$SubjectEnd=$3; $SubjectAli=$2;
	    return(0,"ERROR $sbr: failed to grep all Subject fields from file bl2seqOut=$FileBL2SEQout in:\n$_\n")
		if(! defined $SubjectBeg || ! defined $SubjectEnd || ! defined $SubjectAli);
	    push @Subject, $SubjectBeg."\t".$SubjectAli."\t".$SubjectEnd;
	}
	else{ return(0,"ERROR $sbr: unexpected line in $FileBL2SEQout:\n$_\n"); }	    
    }
    close FHIN;
    @AsignmentData=();                      #calculating alignment
    return(0,"ERROR $sbr: number of Query and Subject fields is not equal") 
	if( $#Query != $#Subject );
    if($FoundAlignment==1){
	$CountMisaligned=0;
	for($i=0;$i<=$#Query;$i++){
	    $dataQuery=$Query[$i] ;
	    #print "Query block:\n$dataQuery\n";
	    @tmp=split(/\t/,$dataQuery); $QueryBeg=$tmp[0]; $QueryEnd=$tmp[2];
	    $tmp[1]=~tr[a-z][A-Z]; @QueryRes=split(//,$tmp[1]);
	    
	    $dataSubject=$Subject[$i] ;

	    @tmp=split(/\t/,$dataSubject); $SubjectBeg=$tmp[0]; $SubjectEnd=$tmp[2];
	    $tmp[1]=~tr[a-z][A-Z]; @SubjectRes=split(//,$tmp[1]);
	    return(0,"ERROR $sbr: number of Query and Subject residues is not equal")
		if($#QueryRes != $#SubjectRes);
	    
	    #$IndexQuery=$QueryBeg+$FirstQuery; $IndexSubject=$SubjectBeg;
	    $IndexQuery=$QueryBeg; $IndexSubject=$SubjectBeg;
	    
	    for($j=0;$j<=$#QueryRes;$j++){	    
		if( $QueryRes[$j] =~m/[A-Z]/ && $SubjectRes[$j]=~m/[A-Z]/ ){
		    if( $QueryRes[$j] eq $SubjectRes[$j] || $QueryRes[$j] eq 'X' || $SubjectRes[$j] eq 'X') {
			
			#$ResNumb=@{ $FullSeqFromFile[$IndexSubject-1] }[1];
			$FileResNumb=$h_ResNumtoFileResNum{$IndexSubject};
			if(! defined $FileResNumb ) {
			    foreach $key (sort { $a <=> $b } keys %h_ResNumtoFileResNum){
				print $key,"\t";
			    } 
			    print "\n";
			    die "undefined FileResNumb=$FileResNumb\n"; 
			}
			if(defined @{ $FullSeqAsAligned[$IndexQuery-1] }[2] ){
			    $ServAliNumber=@{ $FullSeqAsAligned[$IndexQuery-1] }[2];
			    $ServNumber=@{ $FullSeqAsAligned[$IndexQuery-1] }[1];
			    $AsignmentData[$ServAliNumber]=
				[ $QueryRes[$j],$ServNumber,$SubjectRes[$j],$FileResNumb ];
			    #print $QueryRes[$j],',',$ServNumber,',',$SubjectRes[$j],',',$FileResNumb,"\n";
			}
			$IndexQuery++; $IndexSubject++;
		    }
		    else{ 
			$IndexQuery++; $IndexSubject++;
			$CountMisaligned++;
		    }
		}
		elsif( $QueryRes[$j]=~/-/) { $IndexSubject++;}
		elsif($SubjectRes[$j]=~/-/){ $IndexQuery++;  }
		else{ $IndexQuery++; $IndexSubject++; }
	    }
	    if( ($IndexQuery -1 ) !=  $QueryEnd    || 
		($IndexSubject -1) != $SubjectEnd   ){
		return(0,"ERROR $sbr: alignment indices did not agree in the end 
                      of segment:\n@QueryRes\n@SubjectRes\n$IndexQuery $QueryEnd $IndexSubject $SubjectEnd"); 
	    }
	}
	if($CountMisaligned > 2 ){
	    $tmp=$#AsignmentData +1; 
	    $tmp= int (100 * $CountMisaligned/$tmp);
	    if($tmp > 10){
		return(0,"ERROR $sbr: too many misaligned residues $tmp % (more than 10 percent) in $ServerFile");
	    }
	}
    }
    else{
	print "\nWARNING 'bl2seq failed to find alignment for seqasaligned:\n$SeqAsAligned\nassuming the one from server is ok\n\n";
	$SeqAsAligned='';
	for $i (0 .. $#FullSeqAsAligned){
	    $IndexQuery=@{ $FullSeqAsAligned[$i] }[1];
	    $QueryRes=  @{ $FullSeqAsAligned[$i] }[0];
	    $AsignmentData[$i+1]=
			    [ $QueryRes,$IndexQuery,$QueryRes,$IndexQuery ];
	}
    }
    if($dbg < 2){ unlink $SeqAsAlignedFileName,$SeqFromFileFileName,$FileBL2SEQout; }

    return(1,'ok',@AsignmentData);
}
#========================================================================
#========================================================================
sub calculate_full_sequence{
    #gets as an argument sequence of 2D arrays containing residue and number
    my $sbr='calculate_full_sequence';
    my ($fileID,$IDQuery,@SeqToWorkOn)=@_;
    
    
    return(0,"ERROR $sbr: arguments not defined at $fileID,$IDQuery,@SeqToWorkOn ::".__FILE__.' '.__LINE__) 
	if(! defined $fileID || ! defined $IDQuery || ! @SeqToWorkOn); 

    my ($CountAliNumber,$FirstNumb,$LastN,$NextRN,$NextNumb,$ThisNumb,$PrevNumb,$NextRes,$NextN);
    my (@FullSeqCalculated,@tmpHolder);

    $LastN= @{ $SeqToWorkOn[ $#SeqToWorkOn ] }[1];
    return(0,"ERROR $sbr: last number from aligned seq not defined\n")
	if(! defined $LastN);
    $NextN='10000000';
    $FirstNumb=@{ $SeqToWorkOn[0] }[1];
    $FirstNumb=~s/\D*$//;
    if($FirstNumb < 0){ $PrevNumb=$FirstNumb; }
    else{ $PrevNumb=0; }
    @tmpHolder=@SeqToWorkOn;
    $CountAliNumber=0;
    while($NextN ne $LastN ){
	$NextRN=shift @SeqToWorkOn; $NextN=@{$NextRN}[1];
	$NextRes=@{$NextRN}[0]; $NextNumb=$NextN; $NextNumb=~s/\D*$//;
	if($NextNumb > $PrevNumb+1 ){
	    $ThisNumb=$PrevNumb+1;
	    unshift @SeqToWorkOn, $NextRN;
	    push @FullSeqCalculated,['X',$ThisNumb];
	    $PrevNumb++;
	}
	elsif($NextNumb == $PrevNumb + 1 || $NextNumb==$PrevNumb){
	    $CountAliNumber++;
	    push @FullSeqCalculated,[ $NextRes,$NextN,$CountAliNumber];
	    $PrevNumb=$NextNumb;
	}
	elsif( $NextNumb < $PrevNumb ){ #&&  
	       #($NextN=~/\D/ || @{$FullSeqCalculated[$#FullSeqCalculated]}[1]=~/\D/) ){
	    print 
		"WARNING: unexpected numbering, PrevNumb=$PrevNumb NextN=$NextN in $fileID for query=$IDQuery\n";
	    print FHWARNING
		"WARNING: unexpected numbering, PrevNumb=$PrevNumb NextN=$NextN in $fileID for query=$IDQuery\n";
	    $CountAliNumber++;
	    push @FullSeqCalculated,[ $NextRes,$NextN,$CountAliNumber];
	    $PrevNumb=$NextNumb;
	}
	else{ 
	    for $i (0 .. @tmpHolder){
		print @{ $tmpHolder[$i] }[0],"\t",@{ $tmpHolder[$i] }[1],"\,\t";
	    }					   
	    print "\n";
	    return(0,"ERROR $sbr: unexpect order of alignment\n
                   PrevNumb=$PrevNumb NextNumb=$NextNumb\n
                   query=$IDQuery fileId=$fileID ServerFile=$ServerFile");    
	}
    }
    @tmpHolder=();
    return(1,'ok',@FullSeqCalculated);
}
#=========================================================================
sub print_reference_array{
    my $sbr='print_reference_array';
    my ($lr_array)=@_;

    return(0,"ERROR $sbr: argument array not defined")
	if(! defined $lr_array);
    
    my (@unitArray,@array);
    my ($Indices,%h_posit);
    
    @array=@{ $lr_array };
    for $i (0 .. $#array ){
	$Indices.= sprintf "%4s", $i;
	for $j (0 .. $#{$array[$i] } ){
	    $h_posit{$j}.= sprintf "%4s", @{ $array[$i] }[$j];  
	}
    }
    print $Indices,"\n";
    foreach $key (sort { $a <=> $b } keys %h_posit){
	print $h_posit{$key},"\n";
    } 

    return(1,'ok');
}
#==================================================================================
#======================================================================
sub read_file_to_array{
    my $sbr='read_file_to_array';
    my ($File)=$_[0];
    my @array;
    die "ERROR $sbr: file to be read not defined"
	if (! defined $File);
    open(FHFILELOC,$File) or 
	die "ERROR $sbr: failed to open file=$File";
    while(<FHFILELOC>){
	push @array,$_;
    }
    close FHFILELOC;
    return(@array);
}	
#======================================================
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
