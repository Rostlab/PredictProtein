#! /usr/bin/perl -w
$| =1;

($mpearson,$fileOutmpdb,$fileOutAL,$queryName,$maxAli,$dbRelatFile)=@ARGV;

$this=$0; $this=~s/.*\///;

die "$this: arguments not defined mpearson=$mpearson fileOutmpdb=$fileOutmpdb $fileOutAL=$fileOutAL, stopped"
    if(! defined $mpearson || ! defined $fileOutmpdb || ! defined $fileOutAL || ! defined $dbRelatFile );

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

$qID=""; undef %h_fragments;
foreach $homCt (sort {$a <=> $b} keys %h_pearsons){
    $qID=$h_pearsons{$homCt}{"qid"};
    $sID=$h_pearsons{$homCt}{"sid"};
    $Pvalue=$h_pearsons{$homCt}{"pvalue"};
    
    $h_fragments{$homCt}{"parent"} =$sID;
    $h_fragments{$homCt}{"score"}  =$Pvalue;

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
    $qLen=length $qSeq;
    
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
		
		$resLinesLoc         .=$lineLoc;
		
	    }
	    
	    $sResCheck=$h_three2one{$sRes3check};
	    die "error: unknown residue $sRes3check, stopped" 
		if(! defined $sResCheck);
	    
	    die "error: residues $sRes and $sResCheck not equal, stopped"
		if($sRes ne $sResCheck);
	    
	    $sPdbPos=substr($anyAtomLine,22,4); $sPdbPos=~s/\s//g;
	    $insCode=substr($anyAtomLine,26,1);
	    
	    
	    push @l_fileOutAL, $qRes." ".$Qpos." ".$sRes." ".$sPdbPos.$insCode."\n";
	    push @l_fileOutTS, $resLinesLoc;
	    $h_fragments{$homCt}{"qPos2TS"}{$Qpos}=$resLinesLoc;
	    $h_fragments{$homCt}{"qPos2AL"}{$Qpos}=$qRes." ".$Qpos." ".$sRes." ".$sPdbPos.$insCode."\n";
	    
	}	
    }
    
    $h_fragments{$homCt}{"qBeg"}=$l_qAliPos[0];
    $h_fragments{$homCt}{"qEnd"}=$l_qAliPos[$#l_qAliPos];
    $h_fragments{$homCt}{"sID"} =$sID;
    foreach $line (@l_fileOutTS) { $h_fragments{$homCt}{"TS"}.=$line; }
    foreach $line (@l_fileOutAL) { $h_fragments{$homCt}{"AL"}.=$line; }
}

undef %h_tiled; undef %h_fragmentsUsed;
#tile alignments that do not overlap
@l_modelNos=sort {$a <=> $b} keys %h_fragments;
foreach $modelNo (@l_modelNos){
    undef %h_qPos;
    for $i (1 .. $qLen){ 
	$h_qPos{$i}=0; 
    } 
    foreach $homCt (sort {$a <=> $b} keys %h_fragments){
	next if( defined $h_fragmentsUsed{$homCt} );
	$sID=$h_fragments{$homCt}{"parent"};
	$overlapCt=0;
	for $i ( $h_fragments{$homCt}{"qBeg"} .. $h_fragments{$homCt}{"qEnd"} ){ 
	    if($h_qPos{$i}==1){ $overlapCt++;}
	}
	
	if($overlapCt ==0){
	    for $qPos ( $h_fragments{$homCt}{"qBeg"} .. $h_fragments{$homCt}{"qEnd"} ){ 
		$h_qPos{$qPos}=1; 
		if(defined $h_tiled{$modelNo}{"qPos2TS"}{$qPos}){
		    die "aligment for qPos=$qPos already defined, stopped";
		    $h_tiled{$modelNo}{"qPos2parent"}{$qPos}  =$h_fragments{$homCt}{"parent"};
		    $h_tiled{$modelNo}{"qPos2score"}{$qPos}   =$h_fragments{$homCt}{"score"};
		    $h_tiled{$modelNo}{"qPos2TS"}{$qPos}      =$h_fragments{$homCt}{"qPos2TS"}{$qPos};
		    $h_tiled{$modelNo}{"qPos2AL"}{$qPos}      =$h_fragments{$homCt}{"qPos2AL"}{$qPos};
		}
	    }
	    $h_fragmentsUsed{$homCt}=1;
	}
    }
}

# now tile fragments of fragments into gaps between non overlaping alignments
foreach $modelNo (sort {$a <=> $b} keys %h_tiled){
    undef %h_fragmentsUsedLoc; 
    foreach $homCt (keys %{ $h_tiled{$modelNo} }){ $h_fragmentsUsedLoc{$homCt}=1; }
    foreach $homCt ( sort {$a <=> $b} keys %h_fragments ){
	next if(defined $h_fragmentsUsedLoc{$homCt}); #skip those already present in this model
	#look for contiguous fragments fitting into the model
	undef %h_fragLocCt2qPosList; $fragLocCt=1;
	foreach $qPos (sort {$a <=> $b} keys %{ $h_fragments{$homCt}{"qPos2TS"} }){
	    if( ! defined $h_tiled{$modelNo}{"qPos2TS"}{$qPos} ){ 
		push @{ $h_fragLocCt2qPosList{$fragLocCt} }, $qPos;
	    }
	    else{ $fragLocCt++; }
	}
	#check for any stratches longer than 25 residues
	foreach $fragLocCt (sort keys %h_fragLocCt2qPosList ){
	    @l_qPos=@{ $h_fragLocCt2qPosList{$fragLocCt} };
	    if($#l_qPos > 24){
		foreach $qPos (@l_qPos){ 
		    $h_tiled{$modelNo}{"qPos2parent"}{$qPos}  =$h_fragments{$homCt}{"parent"};
		    $h_tiled{$modelNo}{"qPos2score"}{$qPos}   =$h_fragments{$homCt}{"score"};
		    $h_tiled{$modelNo}{"qPos2TS"}{$qPos}      =$h_fragments{$homCt}{"qPos2TS"}{$qPos};
		    $h_tiled{$modelNo}{"qPos2AL"}{$qPos}      =$h_fragments{$homCt}{"qPos2AL"}{$qPos};
		}
	    }
	}
    }
}

#remove those models composed of only proteins with homologs present in higher rank models
#undef %h_relatedPresent;
#$modelNo=0;
#foreach $modelNoTmp (sort {$a <=> $b} keys %h_tiled){
#    @l_homCtsLoc=keys %{ $h_tiled{$modelNoTmp} };
#    @l_sIdsLoc=();
#    foreach $homCt (@l_homCtsLoc){ push @l_sIdsLoc, $h_tiled{$modelNoTmp}{$homCt}{"sID"}; }
#    $sizeLoc=$#l_sIdsLoc +1;
#    $homsPresentCt=0;
#    foreach $sID (@l_sIdsLoc){
#	if(defined $h_relatedPresent{$sID}){ $homsPresentCt++; }
 #   }
 #   if($homsPresentCt == $sizeLoc){
	##each domain protein has homologs present at higher rank, skipping the model
	#delete $h_tiled{$modelNoTmp};
#    }else{
#	foreach $sID (@l_sIdsLoc){
#	    $h_relatedPresent{$sID}=1;
#	    foreach $hID ( keys %{ $h_id2related{$sID} } ){ $h_relatedPresent{$hID}=1; }
#	}
#    }
#}

foreach $modelNo (sort {$a <=> $b} keys %h_tiled){
    last if($modelNo > $maxAli);
    $s_mpdbFile .="MODEL ".$modelNo."\n";
    $s_ALfile   .="MODEL ".$modelNo."\n";
    @l_scoresTmp=();
    foreach $qPos (keys %{ $h_tiled{$modelNo}{"qPos2score"} }){
	push @l_scoresTmp, $h_tiled{$modelNo}{"qPos2score"}{$qPos};
    }
    @l_scoresTmp=sort {$a <=> $b} @l_scoresTmp;
    $bestScore=$l_scoresTmp[0];
    $s_mpdbFile .="SCORE ".$bestScore."\n";
    $s_ALfile   .="SCORE ".$bestScore."\n";
    $oldParent="whatever";
    foreach $qPos ( sort { $a <=> $b } keys %{ $h_tiled{$modelNo}{"qPos2TS"} } ){
	$parent      =$h_tiled{$modelNo}{"qPos2parent"}{$qPos};
	$score       =$h_tiled{$modelNo}{"qPos2score"}{$qPos};
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
    $s_mpdbFile .="END\n\n";
    $s_ALfile   .="END\n\n";
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
	    $h_resNumbPresent{$chain}{$numbCode}++;
	    next if($atomLoc ne "CA" && $atomLoc ne "C" && $atomLoc ne "N" && $atomLoc ne "O"); #getting only C alpha and beta
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
