#! /usr/bin/perl -w
$| =1;

($mpearson,$fileOutmpdb,$fileOutAL,$queryName)=@ARGV;

$this=$0; $this=~s/.*\///;

die "$this: arguments not defined mpearson=$mpearson fileOutmpdb=$fileOutmpdb $fileOutAL=$fileOutAL, stopped"
    if(! defined $mpearson || ! defined $fileOutmpdb || ! defined $fileOutAL);

$configFile     ="/home/dudek/server/pub/agape/scr/agape_config.pm";

require $configFile == 1 || 
    die "$this: ERROR $0 main: failed to require config file: $configFile\n";

if(! defined $par{'db_pdb_dir'}){
    die "$this: pdb directory not defined, stopped";
}
$pdbDir=$par{'db_pdb_dir'};

%h_one2three= (G=>'GLY',A=>'ALA',V=>'VAL',L=>'LEU',I=>'ILE',P=>'PRO',F=>'PHE',Y=>'TYR',W=>'TRP',S=>'SER',T=>'THR',C=>'CYS',M=>'MET',N=>'ASN',Q=>'GLN',D=>'ASP',E=>'GLU',K=>'LYS',R=>'ARG',H=>'HIS',X=>'UNK');

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
$headerTmp .="AUTHOR AGAPE-0.3-SERVER\n";
$headerTmp .="METHOD automatic alignment by AGAPE\n";
$s_mpdbFile ="";
$s_mpdbFile ="PFRMAT TS\n".$headerTmp;
$s_ALfile   ="";
$s_ALfile   ="PFRMAT AL\n".$headerTmp;

$qID="";
foreach $homCt (sort {$a <=> $b} keys %h_pearsons){
    $qID=$h_pearsons{$homCt}{"qid"};
    $sID=$h_pearsons{$homCt}{"sid"};
    $s_mpdbFile.="MODEL  $homCt\n";
    #$s_mpdbFile.="REMARK SCORE ???\n";
    $s_mpdbFile.="PARENT $sID\n";

    $s_ALfile.="MODEL  $homCt\n";
    #$s_ALfile.="REMARK SCORE ???\n";
    $s_ALfile.="PARENT $sID\n";
    
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
    
    
    @l_fileOut=(); @l_fileOutAL=();
    $Qpos=0; $Spos=0; $ctMissCB=0; $modelLen=0;
    for $i (0 .. $#l_qAli){
	$qRes=$l_qAli[$i];
	$sRes=$l_sAli[$i];
	if($qRes ne "-"){ $Qpos++; }
	if($sRes ne "-"){ $Spos++; }
	if($qRes ne "-" && $sRes ne "-"){
	    $modelLen++;
	    $sResCheck=$h_resNo2coor{$Spos}{"res"};
	    die "error on sequences, stopped" if($sRes ne $sResCheck);
	    $qRes3=$h_one2three{$qRes};
	    die "error: unknown residue $qRes, stopped" if(! defined $qRes3);
	    
	    $CAline=$h_resNo2coor{$Spos}{"atom"}{"CA"};
	    
	    $sRes3=$h_one2three{$sRes};
	    die "error: unknown residue $sRes, stopped" if(! defined $sRes3);
	    $sRes3check=substr($CAline,17,3);
	    die "error: residues $sRes3 and $sRes3check not equal, stopped"
		if($sRes3 ne $sRes3check);

	    $sPdbPos=substr($CAline,22,4); $sPdbPos=~s/\s//g;
	    $insCode=substr($CAline,26,1);

	    #die "CAline for for Sres=$sRes Spos=$Spos in $sPdbFile not found, stopped"
	    #if(! defined $CAline);
	    #pretending that CB is on CA (also, wrong atom sequential number)
	    if($sRes eq "G"){ 
		$CBline=$CAline;
		substr($CBline,11,4)="  CB";
	    }else{
		$CBline=$h_resNo2coor{$Spos}{"atom"}{"CB"};
		if(! defined $CBline){
		    #print "CB not defined for sRes=$sRes Spos=$Spos in $sPdbFile\n";
		    $CBline=$CAline;
		    substr($CBline,11,4)="  CB";
		    $ctMissCB++;
		}
	    }
	    
	    #$qResTmp=$qRes; $qResTmp=sprintf "%4s", $qResTmp;
	    $QposTmp=$Qpos; $QposTmp=sprintf "%4d", $QposTmp;
	    #print "qResTmp: $qResTmp\n";
	    #print "CAline:\n$CAline";
	    substr($CAline,22,4)=$QposTmp;
	    substr($CBline,22,4)=$QposTmp;
	    
	    $qRes3Tmp=$qRes3; $qRes3Tmp=sprintf "%3s", $qRes3Tmp;
	    substr($CAline,17,3)=$qRes3Tmp;
	    substr($CBline,17,3)=$qRes3Tmp;
	    
	    push @l_fileOutAL, $qRes." ".$Qpos." ".$sRes." ".$sPdbPos.$insCode."\n";
	    push @l_fileOut, $CAline;
	    #if($qRes ne "G"){
		#push @l_fileOut, $CBline;
	    #}
	}
    }
#print "INFO: missing $ctMissCB of CB in out of $modelLen in $sPdbFile\n";
    #if($ctMissCB > $modelLen/5){
#	die "too many missing CB in $sPdbFile, stopped";
#    }

    foreach $line (@l_fileOut)   { $s_mpdbFile.=$line; }
    $s_mpdbFile.="TER\nEND\n\n";
    foreach $line (@l_fileOutAL) { $s_ALfile.=$line; }
    $s_ALfile.="TER\nEND\n\n";
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
	if(/^>(\S+)/){ $subjectID=$1; $ct=0; $homCt++;}
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
    my (%h_three2one,%h_resNumbPresent);
    
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
	    $h_resNumbPresent{$chain}{$numbCode}{$atomLoc}++;
	    next if($atom !~ /^\s*CA\s*$/); #getting only C alpha
	    next if($chain ne $chainNeeded);
	    if ($chain eq $chainNeeded){
		if($fields[16] !~ /\s/){
		    if($h_resNumbPresent{$chain}{$numbCode}{$atomLoc} > 1){ next; }
		}
		$h_resNumbPresent{$pdbResNum}{$atomLoc}++;
		$resCt++;
		$oneRes=$h_three2one{$threeRes};
		if(! defined $oneRes){
		    print "oneRes not defined for threeRes=$threeRes in $PDBFile, assigning X \n";
		    $oneRes="X";
		}
		$SeenFlag=1;
		$fields[21]=" ";
		$line=join "", @fields;
		$atomTmp=$atom; $atomTmp=~s/\s//g;
		
		$$hr_resNo2coor{$resCt}{"atom"}{$atomTmp}=$line;;
		$$hr_resNo2coor{$resCt}{"res"}=$oneRes;
	    }
	}
    }
    close $fh;
    return (1,"ok");
}
#=========================================================================
