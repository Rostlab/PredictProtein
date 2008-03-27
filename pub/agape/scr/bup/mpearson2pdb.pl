#! /usr/bin/perl -w
$| =1;

($mpearson,$fileOutmpdb,$fileOutAL,$queryName,$maxAli,$dbRelatFile,$fileParsedCombined)=@ARGV;

$this=$0; $this=~s/.*\///;

die "$this: arguments not defined mpearson=$mpearson fileOutmpdb=$fileOutmpdb $fileOutAL=$fileOutAL, stopped"
    if(! defined $mpearson || ! defined $fileOutmpdb || ! defined $fileOutAL || 
       ! defined $dbRelatFile || ! defined $fileParsedCombined);

$configFile     ="/home/dudek/server/pub/agape/scr/agape_config.pm";

require $configFile == 1 || 
    die "$this: ERROR $0 main: failed to require config file: $configFile\n";

if(! defined $par{'db_pdb_dir'}){
    die "$this: pdb directory not defined, stopped";
}
$pdbDir=$par{'db_pdb_dir'};

%h_one2three= (G=>'GLY',A=>'ALA',V=>'VAL',L=>'LEU',I=>'ILE',P=>'PRO',F=>'PHE',Y=>'TYR',W=>'TRP',S=>'SER',T=>'THR',C=>'CYS',M=>'MET',N=>'ASN',Q=>'GLN',D=>'ASP',E=>'GLU',K=>'LYS',R=>'ARG',H=>'HIS',X=>'UNK');
%h_three2one= (GLY=>'G',ALA=>'A',VAL=>'V',LEU=>'L',ILE=>'I',PRO=>'P',PHE=>'F',TYR=>'Y',TRP=>'W',SER=>'S',THR=>'T',CYS=>'C',MET=>'M',ASN=>'N',GLN=>'Q',ASP=>'D',GLU=>'E',LYS=>'K',ARG=>'R',HIS=>'H',UNK=>'X');


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

#-------read combined parsed data to be able to compute significance of fragments
open(FHINCOMBLOC,$fileParsedCombined) || 
    die "ERROR failed to open fileParsedCombined=$fileParsedCombined, stopped";
while(<FHINCOMBLOC>){
    next if(/^\s*$|^\#/);
    next if(/^queryID/);
    s/\s*$//;
    ($queryID,$rank,$HomID,$Pval,$better,$Eval,$score,$miu,$lambda)=split(/\t/,$_);
    return(0,"ERROR $sbr: data not defined in $fileParsedCombined: queryID=$queryID, rank=$rank, HomID=$HomID, Pval=$Pval, better=$better, Eval=$Eval, score=$score, miu=$miu, lambda=$lambda")
	if(! defined $queryID || ! defined $rank || ! defined $HomID || ! defined $Pval  || ! defined $better || ! defined $Eval || ! defined $score || ! defined $miu || ! defined $lambda);
    return(0,"ERROR $sbr: ranking data not defined in line=$_\n, stopped")
	if(! defined $better);
    return(0,"ERROR $sbr: rank for HomID=$HomID already defined, stopped")
	if(defined $h_homID2aliDat{$HomID}{'rank'});
    $h_homID2aliDat{$HomID}{'rank'}   =$rank;
    $h_homID2aliDat{$HomID}{'pval'}   =$Pval;
    $h_homID2aliDat{$HomID}{'eval'}   =$Eval;
    $h_homID2aliDat{$HomID}{'score'}  =$score;
    $h_homID2aliDat{$HomID}{'miu'}    =$miu;
    $h_homID2aliDat{$HomID}{'lambda'} =$lambda;
}
close FHINCOMBLOC; #----------------------------------------------------------


undef %h_pearsons;
($Lok,$msg)=&read_mpearson($mpearson,\%h_pearsons);
die "$this: $msg, stopped" if(! $Lok);

#PFRMAT     Format specification code:  TS , SS , RR , DR or AL
#TARGET     Target identifier from the CASP5 target table
#AUTHOR     XXXX-XXXX-XXXX   Registration code of the Group Leader
#REMARK     Comment record (may appear anywhere, optional)
#METHOD     Records describing the methods used
#MODEL      Beginning of the data section for the submitted model
#PARENT     Specifies structure template used to generate the TS/AL model 
#TER        Terminates independent segments of structure in the TS/AL model
#END        End of the submitted model

$headerTmp="";
$headerTmp .="TARGET $queryName\n";
$headerTmp .="AUTHOR AGAPE-0.3\n";
$headerTmp .="METHOD automatic alignment by AGAPE\n";
$s_mpdbFile ="";
$s_mpdbFile ="PFRMAT TS\n".$headerTmp;
$s_ALfile   ="";
$s_ALfile   ="PFRMAT AL\n".$headerTmp;

$qID=""; undef %h_alignments;
foreach $homCt (sort {$a <=> $b} keys %h_pearsons){
    $qID=$h_pearsons{$homCt}{"qid"};
    $sID=$h_pearsons{$homCt}{"sid"};
    $Pvalue=$h_pearsons{$homCt}{"pvalue"};
    
    $h_alignments{$homCt}{"parent"} =$sID;
    $h_alignments{$homCt}{"pval"}  =$Pvalue;

    $sFasta=$h_pearsons{$homCt}{"sfasta"};

    $sPdbFile=$pdbDir.$sID.".pdb";
    if(! -e $sPdbFile){
	$sPdbFilegz=$sPdbFile.".gz";
	if(! -e $sPdbFilegz){ die "$sPdbFile not found, stopped"; }
	else{ $sPdbFile=$sPdbFilegz; }
    }
    
    $chain=" ";
    undef %h_resNo2coor;
    ($Lok,$msg)=&get_PDB_single_chain($sPdbFile,$chain,\%h_resNo2coor);
    die "$this: $msg, stopped" if(! $Lok);
    
    $sFastaCheck="";
    foreach $resNo ( sort {$a <=> $b} keys %h_resNo2coor){
	#print "resNo $resNo res $h_resNo2coor{$resNo}{res}\n";
	$sFastaCheck.=$h_resNo2coor{$resNo}{"res"};
    }
    if($sFasta ne $sFastaCheck){
	print "problem with sequence for $sID\n";
	print "sfasta:\n$sFasta\n";
	print "check :\n$sFastaCheck\n";
	die "fastas not equal for $sID, stopped";
    }

    $qAli=$h_pearsons{$homCt}{"qali"}; @l_qAli=split(//,$qAli);
    $sAli=$h_pearsons{$homCt}{"sali"}; @l_sAli=split(//,$sAli);
    die "wrong lengths, stopped"
	if($#l_qAli != $#l_sAli);

    $qSeq=$qAli; $qSeq=~s/-//g;

    
    @l_fileOutTS=(); @l_fileOutAL=();
    @l_boneAtoms=("N","CA","C","O"); @l_qAliPos=();
    $Qpos=0; $Spos=0; $modelLen=0; #$ctMissCB=0;
    for $i (0 .. $#l_qAli){
	$qRes=$l_qAli[$i];
	$sRes=$l_sAli[$i];
	if($qRes ne "-"){ $Qpos++; }
	if($sRes ne "-"){ $Spos++; }
	if($qRes ne "-" && $sRes ne "-"){
	    push @l_qAliPos, $Qpos;
	    $modelLen++;
	    $sResCheck=$h_resNo2coor{$Spos}{"res"};
	    die "error on sequences, stopped" if($sRes ne $sResCheck);
	    $qRes3=$h_one2three{$qRes};
	    die "error: unknown residue $qRes, stopped" if(! defined $qRes3);
	
	    $resLinesLoc=""; $atomNoLoc=4 * ($Qpos-1);
	    $CAline=""; undef $sRes3check; undef $anyAtomLine;
	    foreach $atomLoc (@l_boneAtoms){
		$lineLoc=$h_resNo2coor{$Spos}{"atom"}{$atomLoc};
		next if(! defined $lineLoc);
		substr($lineLoc,72,8)="        ";
		if($atomLoc eq "CA"){ $CAline=$lineLoc; }
		if(! defined $anyAtomLine){ $anyAtomLine=$lineLoc; }
		if(! defined $sRes3check){ $sRes3check=substr($lineLoc,17,3); }
		$atomNoLoc++;
		$QposForm             =sprintf "%4s", $Qpos;
		$atomNoLocForm        =sprintf "%5s", $atomNoLoc;
		substr($lineLoc,17,3) =$qRes3;
		substr($lineLoc,22,4) =$QposForm;
		substr($lineLoc,6,5)  =$atomNoLocForm;
		
		#remove alternative location and insertion codes
		substr($lineLoc,16,1) =" ";
		substr($lineLoc,26,1) =" ";
		#set occupancy to 1.00
		substr($lineLoc,54,6)="  1.00";

		$resLinesLoc         .=$lineLoc;
		
	    }
	    
	    $sResCheck=$h_three2one{$sRes3check};
	    #die "error: unknown residue $sRes3check, stopped" 
	    if(! defined $sResCheck){
		$sResCheck="X";
		print "warning: unknown residue $sRes3check, assigning X\n";
	    }
		
	    
	    die "error: residues $sRes and $sResCheck not equal, stopped"
		if($sRes ne $sResCheck);
	    
	    $sPdbPos=substr($anyAtomLine,22,4); $sPdbPos=~s/\s//g;
	    $insCode=substr($anyAtomLine,26,1);
	    
	    
	    push @l_fileOutAL, $qRes." ".$Qpos." ".$sRes." ".$sPdbPos.$insCode."\n";
	    push @l_fileOutTS, $resLinesLoc;
	    $h_alignments{$homCt}{"qPos2TS"}{$Qpos}=$resLinesLoc;
	    $h_alignments{$homCt}{"qPos2AL"}{$Qpos}=$qRes." ".$Qpos." ".$sRes." ".$sPdbPos.$insCode."\n";
	    
	}	
    }
    
    $h_alignments{$homCt}{"qBeg"}=$l_qAliPos[0];
    $h_alignments{$homCt}{"qEnd"}=$l_qAliPos[$#l_qAliPos];
    $h_alignments{$homCt}{"sID"} =$sID;
    foreach $line (@l_fileOutTS) { $h_alignments{$homCt}{"TS"}.=$line; }
    foreach $line (@l_fileOutAL) { $h_alignments{$homCt}{"AL"}.=$line; }
}



# now tile fragments of fragments into gaps between non overlaping alignments
undef %h_tiled;
@l_tmp=keys %h_alignments; $fragNo=$#l_tmp+1;
foreach $modelNo (1 .. $fragNo){
    #print "modelNo: $modelNo\n";
    #put best entire lacal alignment first
    @l_tmp= sort {$a <=> $b} keys %h_alignments;
    last if($#l_tmp < 0);
    $bestHomCt=$l_tmp[0];
    foreach $qPos (sort {$a <=> $b} keys %{ $h_alignments{$bestHomCt}{"qPos2TS"} }){
	$h_tiled{$modelNo}{"qPos2parent"}{$qPos}  =$h_alignments{$bestHomCt}{"parent"};
	$h_tiled{$modelNo}{"qPos2pvalue"}{$qPos}  =$h_alignments{$bestHomCt}{"pval"};
	$h_tiled{$modelNo}{"qPos2TS"}{$qPos}      =$h_alignments{$bestHomCt}{"qPos2TS"}{$qPos};
	$h_tiled{$modelNo}{"qPos2AL"}{$qPos}      =$h_alignments{$bestHomCt}{"qPos2AL"}{$qPos};
    }
    delete $h_alignments{$bestHomCt}; #remove since used in its entirety

    $fragmentsExist=1; $loopCt=0;
    while($fragmentsExist){
	$loopCt++;
	#print "loopCt: $loopCt\n";
	#find contiguous fragments of fragments and assign scores
	undef %h_number2data;  
	$fragCt=0;
	foreach $homCt ( sort {$a <=> $b} keys %h_alignments ){
	    $fragCt++; 
	    $parent=$h_alignments{$homCt}{"parent"};
	    #print "------------PARENT $parent  fragCt=$fragCt -------------------\n";
	    #print "homCt: $homCt  parent: $parent\n";
	    #look for contiguous fragments fitting into the model
	    @l_tmp= keys %{ $h_alignments{$homCt}{"qPos2TS"} };
	    $fragLenTot=$#l_tmp +1;
	    foreach $qPos (sort {$a <=> $b} keys %{ $h_alignments{$homCt}{"qPos2TS"} }){
		if( ! defined $h_tiled{$modelNo}{"qPos2TS"}{$qPos} ){
		    if(defined $h_number2data{$fragCt}{"qPos2TS"}{$qPos}){
			die "alignment already defined, stopped";
		    }
		    $h_number2data{$fragCt}{"qPos2TS"}{$qPos} =$h_alignments{$homCt}{"qPos2TS"}{$qPos};
		    $h_number2data{$fragCt}{"qPos2AL"}{$qPos} =$h_alignments{$homCt}{"qPos2AL"}{$qPos};
		    $h_number2data{$fragCt}{"lenLoc"}++;
		    $h_number2data{$fragCt}{"parent"}      =$parent;
		    $h_number2data{$fragCt}{"lenTot"}      =$fragLenTot;
		    $h_number2data{$fragCt}{"pvalTot"}     =$h_alignments{$homCt}{"pval"};
		    $h_number2data{$fragCt}{"entireFragCt"}=$homCt;
		}
		else{ $fragCt++; }
	    }
	    $scoreTot  =$h_homID2aliDat{$parent}{'score'};
	    $miuLoc    =$h_homID2aliDat{$parent}{'miu'};
	    $lambdaLoc =$h_homID2aliDat{$parent}{'lambda'};
	    #print "entering::::: fragCt=$fragCt\n";
	    foreach $it (keys %h_number2data ){
		$parentCheck=$h_number2data{$it}{"parent"};
		next if($parentCheck ne $parent);
		$lenLoc   =$h_number2data{$it}{"lenLoc"};
		$lenTot   =$h_number2data{$it}{"lenTot"};
		if($lenLoc < 25){ 
		    delete $h_number2data{$it};
		    next;
		}
		$fracLoc  =$lenLoc/$lenTot;
		$scoreLoc =$scoreTot * $fracLoc;
		$PvalLoc  =1-exp( -exp( -$lambdaLoc * ($scoreLoc -$miuLoc) ) );
		$PvalLoc  =sprintf "%1.5e", $PvalLoc; $PvalLoc=~s/\s//g;
		$h_number2data{$it}{"pvalLoc"} =$PvalLoc;
		#print "parent: $parent lenLoc: $lenLoc lenTot: $lenTot PvalLoc=$PvalLoc   fragLocCt=$it\n";
	    }
	    
	} #---------------------------------------------------------------------------
	@l_tmp=sort keys %h_number2data;
	#print "first time fragLocCts: @l_tmp\n";
	#print "l_tmp: @l_tmp\n";
	if($#l_tmp < 0){
	    #no fragments larger than 25 residues can be found
	    $fragmentsExist=0;
	    last;
	}
	#@l_tmp=("lenLoc","parent","lenTot","pvalTot","entireFragCt","pvalLoc");
	#foreach $fragLocCt (keys %h_number2data){
	#    print "modelNo: $modelNo fragLocCt: $fragLocCt\n";
	#    foreach $it (@l_tmp){
	#	print "  $it: $h_number2data{$fragLocCt}{$it}\n";
	#    }
	#}
	#now add most significant fragments to the model 
	#first find most significant fragment (just one!!!) and include it in the model
	$includedOneFlag=0;
	@l_tmp=();
	foreach $fragLocCt ( sort {$h_number2data{$a}{"pvalLoc"} <=> $h_number2data{$b}{"pvalLoc"}} 
			     keys %h_number2data ){ 
	    $parent=$h_number2data{$fragLocCt}{"parent"};
	    push @l_tmp, $parent."---".$h_number2data{$fragLocCt}{"pvalLoc"};
	}
	#print "sorted: @l_tmp\n";

	foreach $fragLocCt ( sort {$h_number2data{$a}{"pvalLoc"} <=> $h_number2data{$b}{"pvalLoc"}} 
			     keys %h_number2data ){
	    last if($includedOneFlag==1);
	    #check if fits
	    $parent=$h_number2data{$fragLocCt}{"parent"};
	    #$pvalLoc=$h_number2data{$fragLocCt}{"pvalLoc"};
	    #print "candidate: $parent pvalLoc: $pvalLoc   fragLocCt: $fragLocCt\n";
	    $overlapCt=0;
	    foreach $qPos (keys %{ $h_number2data{$fragLocCt}{"qPos2TS"} }){
		$overlapCt++ if(defined $h_tiled{$modelNo}{"qPos2TS"}{$qPos});
	    }
	    
	    if($overlapCt > 0){ 
		die "error: overlap should be 0, since choosing one at a time, stopped";
	    }
	    else{
		$lenLoc   =$h_number2data{$fragLocCt}{"lenLoc"};
		$lenTot   =$h_number2data{$fragLocCt}{"lenTot"};
		$entireFragCt   =$h_number2data{$fragLocCt}{"entireFragCt"};
		foreach $qPos ( keys %{ $h_number2data{$fragLocCt}{"qPos2TS"} } ){ 
		    $h_tiled{$modelNo}{"qPos2parent"}{$qPos}  =$h_number2data{$fragLocCt}{"parent"};
		    $h_tiled{$modelNo}{"qPos2pvalue"}{$qPos}  =$h_number2data{$fragLocCt}{"pvalLoc"};
		    $h_tiled{$modelNo}{"qPos2TS"}{$qPos}      =$h_number2data{$fragLocCt}{"qPos2TS"}{$qPos};
		    $h_tiled{$modelNo}{"qPos2AL"}{$qPos}      =$h_number2data{$fragLocCt}{"qPos2AL"}{$qPos};
		}
		delete $h_alignments{$entireFragCt} if($lenLoc == $lenTot); #delete since entire used
		$includedOneFlag=1;
	    }
	}
    }
}



foreach $modelNo (sort {$a <=> $b} keys %h_tiled){
    last if($modelNo > $maxAli);
    $s_mpdbFile .="MODEL ".$modelNo."\n";
    $s_ALfile   .="MODEL ".$modelNo."\n";
    @l_scoresTmp=();
    foreach $qPos (keys %{ $h_tiled{$modelNo}{"qPos2pvalue"} }){
	push @l_scoresTmp, $h_tiled{$modelNo}{"qPos2pvalue"}{$qPos};
    }
    @l_scoresTmp=sort {$a <=> $b} @l_scoresTmp;
    $bestScore=$l_scoresTmp[0];
    $s_mpdbFile .="SCORE ".$bestScore."\n";
    $s_ALfile   .="SCORE ".$bestScore."\n";
    $oldParent="whatever";
    foreach $qPos ( sort { $a <=> $b } keys %{ $h_tiled{$modelNo}{"qPos2TS"} } ){
	$parent      =$h_tiled{$modelNo}{"qPos2parent"}{$qPos};
	$score       =$h_tiled{$modelNo}{"qPos2pvalue"}{$qPos};
	if($parent ne $oldParent){
	    if($oldParent ne "whatever"){ 
		$s_mpdbFile .="TER\n";
		$s_ALfile .="TER\n";
	    }
	    $s_mpdbFile .="PARENT ".$parent."\n";
	    $s_ALfile   .="PARENT ".$parent."\n";
	    $s_mpdbFile .="REMARK SCORE ".$score."\n";
	    $s_ALfile   .="REMARK SCORE ".$score."\n";
	    $oldParent=$parent;
	}
	$s_mpdbFile .=$h_tiled{$modelNo}{"qPos2TS"}{$qPos};
	$s_ALfile   .=$h_tiled{$modelNo}{"qPos2AL"}{$qPos};
    }
    $s_mpdbFile .="TER\nEND\n\n";
    $s_ALfile   .="TER\nEND\n\n";
}

open(FHOUTMPDB,">".$fileOutmpdb) || 
    die "failed to open fileOutmpdb=$fileOutmpdb for output, stopped";
print FHOUTMPDB $s_mpdbFile;
close FHOUTMPDB;

open(FHOUTAL,">".$fileOutAL) || 
    die "failed to open fileOutAL=$fileOutAL for output, stopped";
print FHOUTAL $s_ALfile;
close FHOUTAL;
#======================================================================
sub read_mpearson{
    my $sbr="read_mpearson";
    my ($file,$hr_pearson)=@_;
    my ($ct,$qID,$qAli,$qFasta,$sID,$subjectID,$sAli,$sFasta,$homCt);
    my ($Pvalue,$Evalue,$info);
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
	#if(/^>(\S+)/){ #$subjectID=$1; $ct=0; $homCt++;}
	if(/^>(\S+)\s+(.*)/){ 
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
		return(0,"wrong pearson format in $file, stopped")
		    if($sID ne $subjectID);
		$sAli=~tr[a-z][A-Z];
		$sFasta=$sAli; $sFasta=~s/-//g;	
		$$hr_pearson{$homCt}{"sid"}   =$sID;
		$$hr_pearson{$homCt}{"sali"}  =$sAli;
		$$hr_pearson{$homCt}{"sfasta"}=$sFasta;
	    }else{ return(0,"wrong pearson format in $file, stopped"); }
	}else{ return(0,"wrong pearson format in $file, stopped"); }
	
    }
    return (1,"ok");
}
#=======================================================================
#========================================================================
sub get_PDB_single_chain{
    my $sbr='get_PDB_single_chain';
    my ($PDBFile,$chainNeeded,$hr_resNo2coor)=@_;   #note $PDBFile is a full adress (with PDB directory)
    die "sbr: $sbr arguments not defined, stopped"
	if(! defined $PDBFile || ! defined $chain || ! defined $hr_resNo2coor);
    my ($atom,$ResidueNo,$line,$modelCount,$SeenFlag,$pdbResNum,$chain,$inserCode,$numbCode);
    my ($oneRes,$threeRes,$resCt,$atomTmp);
    my (@fields,@Pdb_single_chain_file); 
    my $fh="FH".$sbr;
    my (%h_three2one,%h_resNumbPresent,%h_resNumbAtomPresent);
    
    %h_three2one= (GLY=>'G',ALA=>'A',VAL=>'V',LEU=>'L',ILE=>'I',PRO=>'P',PHE=>'F',TYR=>'Y',TRP=>'W',SER=>'S',THR=>'T',CYS=>'C',MET=>'M',ASN=>'N',GLN=>'Q',ASP=>'D',GLU=>'E',LYS=>'K',ARG=>'R',HIS=>'H',UNK=>'X');
    
    if($PDBFile=~/\.gz$/){
	$cmd="gunzip -c $PDBFile";
	open($fh,"$cmd |") ||
	    return(0,"ERROR failed to open $cmd, stopped");
    }else{
	open($fh,$PDBFile) ||
	    return(0,"ERROR failed to open PDBFile=$PDBFile, stopped");
    }
    
    $modelCount=0; $SeenFlag=0; $resCt=0;
    while (<$fh>){
	if($_=~/^SEQRES /){
	    @fields=split(//,$_);
	    if($fields[11] eq $chain){
		substr($_,11,1)=" "; #blank for chain identifier
		push @Pdb_single_chain_file, $_;
	    }
	    next;
	}
	if($_=~/^MODEL /){ 
	    $modelCount++; 
	    if ( $modelCount >1 && $SeenFlag){last;} 
	}
	if($_=~/^TER / && $SeenFlag){ last; }
	if ($_=~/^ATOM/){
	    @fields=split(//,$_);   
	    $atom       =substr($_,12,4); $atomLoc=$atom; $atomLoc=~s/\s//g;
	    $threeRes   =substr($_,17,3);
	    $chain      =substr($_,21,1);
	    $pdbResNum  =substr($_,22,4); $pdbResNum=~s/\s//g;
	    $inserCode  =substr($_,26,1); $inserCode=~s/\s//g;
	    $numbCode   =$pdbResNum.$inserCode;
	    $h_resNumbAtomPresent{$chain}{$numbCode}{$atomLoc}++;
	    next if($atomLoc ne "CA" && $atomLoc ne "C" && $atomLoc ne "N" && $atomLoc ne "O"); #getting only C alpha and beta
	    $h_resNumbPresent{$chain}{$numbCode}++;
	    next if($chain ne $chainNeeded);
	    if ($chain eq $chainNeeded){
		if($fields[16] !~ /\s/){
		    if($h_resNumbAtomPresent{$chain}{$numbCode}{$atomLoc} > 1){ next; }
		}
		if($h_resNumbPresent{$chain}{$numbCode} ==1){ 
		    $resCt++;
		    $oneRes=$h_three2one{$threeRes};
		    if(! defined $oneRes){
			print "oneRes not defined for threeRes=$threeRes in $PDBFile, assigning X \n";
			$oneRes="X";
		    }
		    $$hr_resNo2coor{$resCt}{"res"}=$oneRes;
		} 
		$SeenFlag=1;
		$fields[21]=" ";
		$line=join "", @fields;
		$atomTmp=$atom; $atomTmp=~s/\s//g;
		
		$$hr_resNo2coor{$resCt}{"atom"}{$atomTmp}=$line;;
	    }
	}
    }
    close $fh;
    return (1,"ok");
}
#=========================================================================
